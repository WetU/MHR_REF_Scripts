local Constants = _G.require("Constants.Constants");

local pairs = Constants.lua.pairs;

local sdk = Constants.sdk;
local find_type_definition = sdk.find_type_definition;
local to_managed_object = sdk.to_managed_object;
local hook = sdk.hook;

local TRUE_POINTER = Constants.TRUE_POINTER;
-- Cache
local GoodRelationship_type_def = find_type_definition("snow.gui.GuiHud_GoodRelationship");
local OtherPlayerInfos_field = GoodRelationship_type_def:get_field("_OtherPlayerInfos");
local gaugeAngleY_field = GoodRelationship_type_def:get_field("_gaugeAngleY");
local WaitTime_field = GoodRelationship_type_def:get_field("WaitTime");

local PlInfo_Enable_field = find_type_definition("snow.gui.GuiHud_GoodRelationship.PlInfo"):get_field("_Enable");
-- Main Function
local MAX_ANGLE_Y = 360.0;
local NO_WAIT_TIME = 0.0;

local sendReady = false;

local GoodRelationshipHud = nil;
local function PreHook_updatePlayerInfo(args)
	GoodRelationshipHud = to_managed_object(args[2]);

	if gaugeAngleY_field:get_data(GoodRelationshipHud) ~= MAX_ANGLE_Y then
		GoodRelationshipHud:set_field("_gaugeAngleY", MAX_ANGLE_Y);
	end

	if WaitTime_field:get_data(GoodRelationshipHud) ~= NO_WAIT_TIME then
		GoodRelationshipHud:set_field("WaitTime", NO_WAIT_TIME);
	end
end
local function PostHook_updatePlayerInfo()
	if sendReady ~= true then
		local OtherPlayerInfos = OtherPlayerInfos_field:get_data(GoodRelationshipHud);

		for i = 0, OtherPlayerInfos:get_size() - 1, 1 do
			local OtherPlayerInfo = OtherPlayerInfos:get_element(i);
			if PlInfo_Enable_field:get_data(OtherPlayerInfo) == true then
				OtherPlayerInfo:set_field("_good", true);
				OtherPlayerInfos[i] = OtherPlayerInfo;
			end
		end

		sendReady = true;
	end

	GoodRelationshipHud = nil;
end

local function PostHook_isOperationOn(retval)
	return sendReady == true and TRUE_POINTER or retval;
end

local function PreHook_sendGood()
	sendReady = false;
end
--
hook(GoodRelationship_type_def:get_method("updatePlayerInfo"), PreHook_updatePlayerInfo, PostHook_updatePlayerInfo);
hook(Constants.type_definitions.StmGuiInput_type_def:get_method("isOperationOn(snow.StmInputManager.UI_INPUT, snow.StmInputManager.UI_INPUT)"), nil, PostHook_isOperationOn);
hook(GoodRelationship_type_def:get_method("sendGood"), PreHook_sendGood);