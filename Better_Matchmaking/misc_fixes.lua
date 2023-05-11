local this = {};

local utils;
local config;

local require = require;

local sdk = sdk;
local sdk_find_type_definition = sdk.find_type_definition;
local sdk_get_managed_singleton = sdk.get_managed_singleton;
local sdk_hook = sdk.hook;
local sdk_SKIP_ORIGINAL = sdk.PreHookResult.SKIP_ORIGINAL;
local sdk_CALL_ORIGINAL = sdk.PreHookResult.CALL_ORIGINAL;

local get_CurrentStatus_method = sdk_find_type_definition("snow.SnowGameManager"):get_method("get_CurrentStatus");
local StatusType_Quest = get_CurrentStatus_method:get_return_type():get_field("Quest"):get_data(nil);

local quest_manager_type_def = sdk_find_type_definition("snow.QuestManager");
local isPlayQuest_method = quest_manager_type_def:get_method("isPlayQuest");
local isEndWait_method = quest_manager_type_def:get_method("isEndWait");

local reqOnlineWarning_method = sdk_find_type_definition("snow.SnowSessionManager"):get_method("reqOnlineWarning");
local setOpenNetworkErrorWindowSelection_method = sdk_find_type_definition("snow.gui.GuiManager"):get_method("setOpenNetworkErrorWindowSelection(System.Guid, System.Boolean, System.String, System.Boolean)");

function this.on_req_online_warning()
	if not config.current_config.hide_online_warning.enabled then
		return sdk_CALL_ORIGINAL;
	end
	return sdk_SKIP_ORIGINAL;
end

function this.on_set_open_network_error_window_selection()
	local cached_config = config.current_config.hide_network_errors;
	if cached_config.enabled then
		local quest_manager = sdk_get_managed_singleton("snow.QuestManager");
		if quest_manager then
			local is_play_quest = isPlayQuest_method:call(quest_manager);
			local is_end_wait = isEndWait_method:call(quest_manager);
			if is_play_quest ~= nil and is_end_wait ~= nil then
				local GameManager = sdk_get_managed_singleton("snow.SnowGameManager");
				if GameManager then
					if get_CurrentStatus_method:call(GameManager) == StatusType_Quest then
						if is_play_quest then
							if cached_config.when_to_hide.on_quests then
								return sdk_SKIP_ORIGINAL;
							end
						else
							if is_end_wait then
								if cached_config.when_to_hide.on_quests then
									return sdk_SKIP_ORIGINAL;
								end
							else
								if cached_config.when_to_hide.outside_quests then
									return sdk_SKIP_ORIGINAL;
								end
							end
						end
					else
						if cached_config.when_to_hide.outside_quests then
							return sdk_SKIP_ORIGINAL;
						end
					end
				end
			end
		end
	end
	return sdk_CALL_ORIGINAL;
end

function this.init_module()
	config = require("Better_Matchmaking.config");
	utils = require("Better_Matchmaking.utils");

	sdk_hook(reqOnlineWarning_method, this.on_req_online_warning);
	sdk_hook(setOpenNetworkErrorWindowSelection_method, this.on_set_open_network_error_window_selection);
end

return this;
