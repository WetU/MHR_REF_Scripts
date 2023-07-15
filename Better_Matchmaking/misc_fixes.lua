local Constants = require("Constants.Constants");
if not Constants then
	return;
end
--
local this = {};
--
local function PreHook_setOpenNetworkErrorWindowSelection()
	if Constants.checkGameStatus(Constants.GameStatusType.Quest) == true then
		return Constants.SDK.SKIP_ORIGINAL;
	end
end
--
function this.init_module()
	Constants.SDK.hook(Constants.type_definitions.GuiManager_type_def:get_method("setOpenNetworkErrorWindowSelection(System.Guid, System.Boolean, System.String, System.Boolean)"), PreHook_setOpenNetworkErrorWindowSelection);
end
--
return this;
