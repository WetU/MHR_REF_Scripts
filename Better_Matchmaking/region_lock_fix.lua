local require = require;

local this = {};

local utils;
local config;

local sdk = sdk;
local sdk_call_native_func = sdk.call_native_func;
local sdk_find_type_definition = sdk.find_type_definition;
local sdk_to_managed_object = sdk.to_managed_object;
local sdk_hook = sdk.hook;

local session_steam_type_def = sdk_find_type_definition("via.network.SessionSteam");
local setIsInvisible_method = session_steam_type_def:get_method("setIsInvisible(System.Boolean)"); -- native

local last_session_steam_object = nil;

function this.on_set_is_invisible(session_steam)
	local region_lock_fix_config = config.current_config.region_lock_fix;
	if not region_lock_fix_config.enabled then
		if session_steam ~= last_session_steam_object then
			sdk_call_native_func(session_steam, session_steam_type_def, "setLobbyDistanceFilter(System.UInt32)", 1);
		end
	else
		local distance_filter = region_lock_fix_config.distance_filter;
		local distance = distance_filter == "Worldwide" and 3 or distance_filter == "Far" and 2 or distance_filter == "Close" and 0 or 1;
		sdk_call_native_func(session_steam, session_steam_type_def, "setLobbyDistanceFilter(System.UInt32)", distance);
	end
	last_session_steam_object = session_steam;
end

function this.init_module()
	config = require("Better_Matchmaking.config");
	utils = require("Better_Matchmaking.utils");

	sdk_hook(setIsInvisible_method, function(args)
		this.on_set_is_invisible(sdk_to_managed_object(args[1]));
	end);
end

return this;
