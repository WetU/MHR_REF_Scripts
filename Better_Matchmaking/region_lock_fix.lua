local require = require;
local Constants = require("Constants.Constants");
if not Constants then
	return;
end
--
local this = {};
--
local session_steam_type_def = Constants.SDK.find_type_definition("via.network.SessionSteam");
local setLobbyDistanceFilter_method = session_steam_type_def:get_method("setLobbyDistanceFilter(System.UInt32)");
--
local function on_set_is_invisible(args)
	local session_steam = Constants.SDK.to_managed_object(args[1]);
	if session_steam == nil then
		return;
	end

	setLobbyDistanceFilter_method:call(session_steam, 3);
end

function this.init_module()
	Constants.SDK.hook(session_steam_type_def:get_method("setIsInvisible(System.Boolean)"), on_set_is_invisible);
end

return this;
