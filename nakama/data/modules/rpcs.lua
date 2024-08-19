
local nakama = require("nakama")


nakama.register_rpc(function(_context, payload)
	local payload_json = nakama.json_decode(payload)
	local match_config = payload_json["match_config"]
	local host_username = payload_json["host_username"]

	local match_params = {
		["match_config"] = match_config,
		["host_username"] = host_username,
	}

	-- NOTE: match name must be the same as the name of the
	-- match handler lua module (lobby.lua)
	local match_id = nakama.match_create("lobby", match_params)
	return nakama.json_encode({ ["match_id"] = match_id })
end, "create_match")
