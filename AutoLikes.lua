local Constants = require("Constants.Constants");
if not Constants then
	return;
end
-- Cache
local GoodRelationship_type_def = Constants.SDK.find_type_definition("snow.gui.GuiHud_GoodRelationship");
local gaugeAngleMax_field = GoodRelationship_type_def:get_field("_gaugeAngleMax");
local OtherPlayerInfos_field = GoodRelationship_type_def:get_field("_OtherPlayerInfos");

local gauge_set_Item_method = gaugeAngleMax_field:get_type():get_method("set_Item(System.Int32, System.Single)");

local OtherPlayerInfos_type_def = OtherPlayerInfos_field:get_type();
local PlInfos_get_Count_method = OtherPlayerInfos_type_def:get_method("get_Count"); -- retval
local PlInfos_set_Item_method = OtherPlayerInfos_type_def:get_method("set_Item(System.Int32, snow.gui.GuiHud_GoodRelationship.PlInfo)");
local PlInfos_get_Item_method = OtherPlayerInfos_type_def:get_method("get_Item(System.Int32)"); -- retval

local PlInfo_Enable_field = PlInfos_get_Item_method:get_return_type():get_field("_Enable");
-- Main Function
local GoodRelationshipHud = nil;
local sendReady = false;

local function PreHook_doOpen(args)
	GoodRelationshipHud = Constants.SDK.to_managed_object(args[2]);
	sendReady = false;
end
local function PostHook_doOpen()
	if GoodRelationshipHud ~= nil then
		local gaugeAngleMax = gaugeAngleMax_field:get_data(GoodRelationshipHud);
		if gaugeAngleMax ~= nil then
			gauge_set_Item_method:call(gaugeAngleMax, 1, 0.0);
			GoodRelationshipHud:set_field("_gaugeAngleMax", gaugeAngleMax);
		end
		GoodRelationshipHud:set_field("WaitTime", 0.0);
	end
end

local function PostHook_updatePlayerInfo()
	if GoodRelationshipHud ~= nil then
		local OtherPlayerInfos = OtherPlayerInfos_field:get_data(GoodRelationshipHud);
		if OtherPlayerInfos ~= nil then
			local PlInfos_count = PlInfos_get_Count_method:call(OtherPlayerInfos);
			if PlInfos_count > 0 then
				for i = 0, PlInfos_count - 1, 1 do
					local OtherPlayerInfo = PlInfos_get_Item_method:call(OtherPlayerInfos, i);
					if OtherPlayerInfo ~= nil and PlInfo_Enable_field:get_data(OtherPlayerInfo) == true then
						OtherPlayerInfo:set_field("_good", true);
						PlInfos_set_Item_method:call(OtherPlayerInfos, i, OtherPlayerInfo);
					end
				end
				sendReady = true;
			end
		end
	end
	GoodRelationshipHud = nil;
end

local function PreHook_isOperationOn(args)
	if sendReady == true then
		return Constants.SDK.SKIP_ORIGINAL;
	end
end
local function PostHook_isOperationOn(retval)
	if sendReady == true then
		return Constants.TRUE_POINTER;
	end
	return retval;
end

local function PostHook_sendGood()
	sendReady = false;
end

Constants.SDK.hook(GoodRelationship_type_def:get_method("doOpen"), PreHook_doOpen, PostHook_doOpen);
Constants.SDK.hook(GoodRelationship_type_def:get_method("updatePlayerInfo"), nil, PostHook_updatePlayerInfo);
Constants.SDK.hook(Constants.type_definitions.StmGuiInput_type_def:get_method("isOperationOn(snow.StmInputManager.UI_INPUT, snow.StmInputManager.UI_INPUT)"), PreHook_isOperationOn, PostHook_isOperationOn);
Constants.SDK.hook(GoodRelationship_type_def:get_method("sendGood"), nil, PostHook_sendGood);