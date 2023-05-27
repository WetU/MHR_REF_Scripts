local require = require;
local Constants = require("Constants.Constants");
if not Constants then
	return;
end

local this = {};
local config;

local get_CurrentStatus_method = Constants.SDK.find_type_definition("snow.SnowGameManager"):get_method("get_CurrentStatus"); -- retval
local GameStatusType_Quest = get_CurrentStatus_method:get_return_type():get_field("Quest"):get_data(nil);

function this.init_module()
	config = require("Better_Matchmaking.config");

	Constants.SDK.hook(Constants.type_definitions.GuiManager_type_def:get_method("setOpenNetworkErrorWindowSelection(System.Guid, System.Boolean, System.String, System.Boolean)"), function()
		if config.current_config.hide_network_errors.enabled then
			local GameManager = Constants.SDK.get_managed_singleton("snow.SnowGameManager");
			if GameManager then
				if get_CurrentStatus_method:call(GameManager) == GameStatusType_Quest then
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
	end);
end

return this;
