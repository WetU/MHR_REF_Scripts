local require = require;
local Constants = require("Constants.Constants");
if not Constants then
	return;
end

local this = {};
local config;

local function PreHook_setOpenNetworkErrorWindowSelection()
	if config.current_config.hide_network_errors.enabled == true then
		if Constants.checkGameStatus(Constants.GameStatusType.Quest) == true then
			if config.current_config.hide_network_errors.when_to_hide.on_quests == true then
				return Constants.SDK.SKIP_ORIGINAL;
			end
		else
			if config.current_config.hide_network_errors.when_to_hide.outside_quests == true then
				return Constants.SDK.SKIP_ORIGINAL;
			end
		end
	end
end

function this.init_module()
	config = require("Better_Matchmaking.config");
	Constants.SDK.hook(Constants.type_definitions.GuiManager_type_def:get_method("setOpenNetworkErrorWindowSelection(System.Guid, System.Boolean, System.String, System.Boolean)"), PreHook_setOpenNetworkErrorWindowSelection);
end

return this;
