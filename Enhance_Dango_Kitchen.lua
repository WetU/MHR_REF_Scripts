local Constants = _G.require("Constants.Constants");

local find_type_definition = Constants.sdk.find_type_definition;
local to_managed_object = Constants.sdk.to_managed_object;
local hook = Constants.sdk.hook;

-- Skip Dango Song cache
local GuiKitchen_BBQ_type_def = find_type_definition("snow.gui.GuiKitchen_BBQ");
local getDemoState_method = GuiKitchen_BBQ_type_def:get_method("getDemoState");
local BBQ_DemoHandler_field = GuiKitchen_BBQ_type_def:get_field("_DemoHandler");
local reqFinish_method = BBQ_DemoHandler_field:get_type():get_method("reqFinish(System.Single)");

local BBQ_DemoState = {
	[3] = true,  -- Update
	[6] = true   -- ResultDemoUpdate
};

--BBQ
local GuiKitchen_BBQ = nil;
local function PreHook_BBQ_updatePlayDemo(args)
	GuiKitchen_BBQ = to_managed_object(args[2]);
end
local function PostHook_BBQ_updatePlayDemo()
	if BBQ_DemoState[getDemoState_method:call(GuiKitchen_BBQ)] == true then
		reqFinish_method:call(BBQ_DemoHandler_field:get_data(GuiKitchen_BBQ), 0.0);
	end

	GuiKitchen_BBQ = nil;
end
hook(GuiKitchen_BBQ_type_def:get_method("updatePlayDemo"), PreHook_BBQ_updatePlayDemo, PostHook_BBQ_updatePlayDemo);