local require = require;
local Constants = require("Constants.Constants");
if not Constants then
	return;
end

local this = {};
local utils;
local config;

local get_CurrentStatus_method = Constants.SDK.find_type_definition("snow.SnowGameManager"):get_method("get_CurrentStatus"); -- retval
local StatusType_Quest = get_CurrentStatus_method:get_return_type():get_field("Quest"):get_data(nil);

function this.on_req_online_warning()
	if config.current_config.hide_online_warning.enabled then
		return Constants.SDK.SKIP_ORIGINAL;
	end
end

function this.on_set_open_network_error_window_selection()
	if config.current_config.hide_network_errors.enabled then
		local GameManager = Constants.SDK.get_managed_singleton("snow.SnowGameManager");
		if GameManager then
			if get_CurrentStatus_method:call(GameManager) == StatusType_Quest then
				if config.current_config.hide_network_errors.when_to_hide.on_quests then
					return Constants.SDK.SKIP_ORIGINAL;
				end
			else
				if config.current_config.hide_network_errors.when_to_hide.outside_quests then
					return Constants.SDK.SKIP_ORIGINAL;
				end
			end
		end
	end
end

function this.init_module()
	config = require("Better_Matchmaking.config");
	utils = require("Better_Matchmaking.utils");

	Constants.SDK.hook(Constants.SDK.find_type_definition("snow.SnowSessionManager"):get_method("reqOnlineWarning"), this.on_req_online_warning);
	Constants.SDK.hook(Constants.SDK.find_type_definition("snow.gui.GuiManager"):get_method("setOpenNetworkErrorWindowSelection(System.Guid, System.Boolean, System.String, System.Boolean)"), this.on_set_open_network_error_window_selection);
end

return this;
