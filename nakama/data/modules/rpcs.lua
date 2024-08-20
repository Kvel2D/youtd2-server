
local nakama = require("nakama")


-- NOTE: match name passed to match_create() must be the
-- same as the name of the match handler script
-- (lobby.lua)
nakama.register_rpc(function(_context, payload)
	local match_params = nakama.json_decode(payload)
	match_params = match_params or {}
	local match_id = nakama.match_create("lobby", match_params)

	local return_value_table = {
		match_id = match_id
	}
	local return_value = nakama.json_encode(return_value_table)

	return return_value
end, "create_match")
