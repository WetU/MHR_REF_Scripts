local Constants = require("Constants.Constants");
-- Cache
local GoodRelationship_type_def = sdk.find_type_definition("snow.gui.GuiHud_GoodRelationship");
local OtherPlayerInfos_field = GoodRelationship_type_def:get_field("_OtherPlayerInfos");
local gaugeAngleY_field = GoodRelationship_type_def:get_field("_gaugeAngleY");
local WaitTime_field = GoodRelationship_type_def:get_field("WaitTime");

local OtherPlayerInfos_type_def = OtherPlayerInfos_field:get_type();
local PlInfos_get_Count_method = OtherPlayerInfos_type_def:get_method("get_Count");
local PlInfos_set_Item_method = OtherPlayerInfos_type_def:get_method("set_Item(System.Int32, snow.gui.GuiHud_GoodRelationship.PlInfo)");
local PlInfos_get_Item_method = OtherPlayerInfos_type_def:get_method("get_Item(System.Int32)");

local PlInfo_Enable_field = PlInfos_get_Item_method:get_return_type():get_field("_Enable");
-- Main Function
local GoodRelationshipHud = nil;
local sendReady = false;

local function PreHook_updatePlayerInfo(args)
	GoodRelationshipHud = sdk.to_managed_object(args[2]);
	if gaugeAngleY_field:get_data(GoodRelationshipHud) ~= 360.0 then
		GoodRelationshipHud:set_field("_gaugeAngleY", 360.0);
	end
	if WaitTime_field:get_data(GoodRelationshipHud) ~= 0.0 then
		GoodRelationshipHud:set_field("WaitTime", 0.0);
	end
end

local function PostHook_updatePlayerInfo()
	if GoodRelationshipHud == nil then
		return;
	end

	if sendReady ~= true then
		local OtherPlayerInfos = OtherPlayerInfos_field:get_data(GoodRelationshipHud);

		for i = 0, PlInfos_get_Count_method:call(OtherPlayerInfos) - 1, 1 do
			local OtherPlayerInfo = PlInfos_get_Item_method:call(OtherPlayerInfos, i);
			OtherPlayerInfo:set_field("_good", PlInfo_Enable_field:get_data(OtherPlayerInfo));
			PlInfos_set_Item_method:call(OtherPlayerInfos, i, OtherPlayerInfo);
		end

		sendReady = true;
	end

	GoodRelationshipHud = nil;
end

local function PreHook_isOperationOn()
	return sendReady == true and sdk.PreHookResult.SKIP_ORIGINAL or sdk.PreHookResult.CALL_ORIGINAL;
end
local function PostHook_isOperationOn(retval)
	return sendReady == true and Constants.TRUE_POINTER or retval;
end

local function PreHook_sendGood()
	sendReady = false;
end
--
sdk.hook(GoodRelationship_type_def:get_method("updatePlayerInfo"), PreHook_updatePlayerInfo, PostHook_updatePlayerInfo);
sdk.hook(Constants.type_definitions.StmGuiInput_type_def:get_method("isOperationOn(snow.StmInputManager.UI_INPUT, snow.StmInputManager.UI_INPUT)"), PreHook_isOperationOn, PostHook_isOperationOn);
sdk.hook(GoodRelationship_type_def:get_method("sendGood"), PreHook_sendGood);