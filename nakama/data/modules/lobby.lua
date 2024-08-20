
local nakama = require("nakama")

local M = {}

local TICK_RATE = 10
local EMPTY_TICKS_MAX = TICK_RATE * 10

local OP_CODE_TRANSFER_FROM_LOBBY = 3


local function copy_table(table)
	local table_copy = {}

	for k, v in pairs(table) do
		table_copy[k] = v
	end

	return table_copy
end


function M.match_init(_context, params)
	local label_table = copy_table(params)
	label_table.player_count = 0
	local label = nakama.json_encode(label_table)

	local state = {
		players = {},
		player_count = 0,
		player_count_max = params.player_count_max or 2,
		empty_ticks = 0,
		original_label = label_table,
		lobby_closed = false
	}

	return state, TICK_RATE, label
end


function M.match_join_attempt(_context, _dispatcher, _tick, state, presence, _metadata)
	local accept = true

	if not state.lobby_closed then
		accept = false
	end

	local match_has_free_spot = state.player_count < state.player_count_max
	if not match_has_free_spot then
		accept = false
	end

	if match_has_free_spot then
		state.players[presence.user_id] = {presence = presence}
	end

	return state, accept
end


function M.match_join(_context, dispatcher, _tick, state, presences)
	for _, presence in ipairs(presences) do
		state.players[presence.user_id].presence = presence
		state.player_count = state.player_count + 1
	end

-- 	Update player count in label, other values remain the
-- 	same
	local label_table = copy_table(state.original_label)
	label_table.player_count = state.player_count
	local label = nakama.json_encode(label_table)
	dispatcher.match_label_update(label)

	return state
end


function M.match_leave(_context, _dispatcher, _tick, state, presences)
	for _, presence in ipairs(presences) do
		state.players[presence.user_id] = nil
		state.player_count = state.player_count - 1
	end

	return state
end


function M.match_loop(_context, dispatcher, _tick, state, messages)
	for _, message in ipairs(messages) do
		if message.op_code == OP_CODE_TRANSFER_FROM_LOBBY then
			state.lobby_closed = true

			dispatcher.broadcast_message(OP_CODE_TRANSFER_FROM_LOBBY, message.data)
		end
	end

	if state.player_count == 0 then
		state.empty_ticks = state.empty_ticks + 1
	else
		state.empty_ticks = 0
	end

	if state.empty_ticks > EMPTY_TICKS_MAX then
		return nil
	end

	return state
end


function M.match_terminate(_context, _dispatcher, _tick, state, _grace_seconds)
	return state
end


function M.match_signal(_context, _dispatcher, _tick, _state, _data)
end


return M
