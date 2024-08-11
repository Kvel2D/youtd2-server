
local nakama = require("nakama")


nakama.register_rpc(function(_context, _payload)
	local is_private = false

	-- local data = nakama.json_decode(payload)
	-- if data["is_private"] then
	-- 	is_private = true
	-- end

	-- NOTE: match name must be the same as the name of the
	-- match handler lua module
	local match_id = nakama.match_create("lobby", { is_private = is_private })
	return nakama.json_encode({ ["match_id"] = match_id })
end, "create_match")
