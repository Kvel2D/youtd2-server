
local nakama = require("nakama")

local M = {}

local TICK_RATE = 10
local EMPTY_TICKS_MAX = TICK_RATE * 10

local OP_CODE_TRANSFER_FROM_LOBBY = 3


function M.match_init(_context, params)
	local state = {
		players = {},
		player_count = 0,
		player_count_max = 2,
		is_private = false,
		empty_ticks = 0
	}

	local label = nakama.json_encode({
		["is_private"] = state.is_private,
		["player_count"] = state.player_count,
		["player_count_max"] = state.player_count_max,
		["match_config"] = params.match_config
	})

	return state, TICK_RATE, label
end


function M.match_join_attempt(_context, _dispatcher, _tick, state, presence, _metadata)
	local match_has_free_spot = state.player_count < state.player_count_max
	local accept = match_has_free_spot

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

	local label = nakama.json_encode({
		["is_private"] = state.is_private,
		["player_count"] = state.player_count,
		["player_count_max"] = state.player_count_max
	})
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
