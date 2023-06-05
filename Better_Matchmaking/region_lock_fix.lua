local require = require;
local Constants = require("Constants.Constants");
if not Constants then
	return;
end

local this = {};
local config;

local session_steam_type_def = Constants.SDK.find_type_definition("via.network.SessionSteam");
local setLobbyDistanceFilter_method = session_steam_type_def:get_method("setLobbyDistanceFilter(System.UInt32)");

local last_session_steam_object = nil;
local function on_set_is_invisible(args)
	local session_steam = Constants.SDK.to_managed_object(args[1]);
	if session_steam ~= nil then
		if config.current_config.region_lock_fix.enabled then
			local distance = config.current_config.region_lock_fix.distance_filter == "Worldwide" and 3
						  or config.current_config.region_lock_fix.distance_filter == "Far" and 2
						  or config.current_config.region_lock_fix.distance_filter == "Close" and 0
						  or 1;
			setLobbyDistanceFilter_method:call(session_steam, distance);
		else
			if session_steam ~= last_session_steam_object then
				setLobbyDistanceFilter_method:call(session_steam, 1);
			end
		end
		last_session_steam_object = session_steam;
	end
end

function this.init_module()
	config = require("Better_Matchmaking.config");
	Constants.SDK.hook(session_steam_type_def:get_method("setIsInvisible(System.Boolean)"), on_set_is_invisible);
end

return this;
