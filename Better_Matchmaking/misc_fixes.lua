local Constants = require("Constants.Constants");
if not Constants then
	return;
end
--
local this = {};
--
local function PreHook_setOpenNetworkErrorWindowSelection()
	return Constants.checkGameStatus(Constants.GameStatusType.Quest) == true and Constants.SDK.SKIP_ORIGINAL or Constants.SDK.CALL_ORIGINAL;
end
--
function this.init_module()
	Constants.SDK.hook(Constants.type_definitions.GuiManager_type_def:get_method("setOpenNetworkErrorWindowSelection(System.Guid, System.Boolean, System.String, System.Boolean)"), PreHook_setOpenNetworkErrorWindowSelection);
end
--
return this;
