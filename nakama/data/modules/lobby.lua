
local nakama = require("nakama")

local M = {}

local TICK_RATE = 10
local EMPTY_TICKS_MAX = TICK_RATE * 10

local OP_CODE_READY = 1
local OP_CODE_GAME_STARTING = 2


function M.match_init(_context, initial_state)
	local is_private = false

	if initial_state.is_private then
		is_private = initial_state.is_private
	end

	local state = {
		players = {},
		player_count = 0,
		required_player_count = 2,
		is_private = is_private,
		game_state = WAITING_FOR_PLAYERS,
		empty_ticks = 0
	}

	local label = nakama.json_encode({["is_private"] = state.is_private, ["player_count"] = state.player_count, ["required_player_count"] = state.required_player_count})

	return state, TICK_RATE, label
end


function M.match_join_attempt(_context, _dispatcher, _tick, state, presence, _metadata)
	local match_has_free_spot = state.player_count < state.required_player_count
	local accept = match_has_free_spot

	if match_has_free_spot then
		state.players[presence.user_id] = {presence = presence, is_ready = false}
	end

	return state, accept
end


function M.match_join(_context, dispatcher, _tick, state, presences)
	for _, presence in ipairs(presences) do
		state.players[presence.user_id].presence = presence
		state.player_count = state.player_count + 1
	end

	if state.player_count == state.required_player_count then
		state.game_state = WAITING_FOR_PLAYERS_READY
	end

	local label = nakama.json_encode({["is_private"] = state.is_private, ["player_count"] = state.player_count, ["required_player_count"] = state.required_player_count })
	dispatcher.match_label_update(label)

	-- Let joining players know about ready status of players in lobby.
	for _, player in pairs(state.players) do
		if player.is_ready then
			dispatcher.broadcast_message(OP_CODE_READY, nakama.json_encode({["user_id"] = player.presence.user_id}))
		end
	end

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
		if message.op_code == OP_CODE_READY then
			state.players[message.sender.user_id].is_ready = true
			dispatcher.broadcast_message(OP_CODE_READY, nakama.json_encode({["user_id"] = message.sender.user_id}))

			local all_ready = true
			for _, player in pairs(state.players) do
				if player.is_ready == false then
					all_ready = false
				end
			end

			if all_ready and state.player_count == state.required_player_count then
				state.game_state = IN_PROGRESS
				dispatcher.broadcast_message(OP_CODE_GAME_STARTING)
			end
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
