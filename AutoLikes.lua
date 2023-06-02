local Constants = require("Constants.Constants");
if not Constants then
	return;
end
-- Cache
local GoodRelationship_type_def = Constants.SDK.find_type_definition("snow.gui.GuiHud_GoodRelationship");
local isInBlockList_method = GoodRelationship_type_def:get_method("isInBlockList(System.Guid)"); -- retval

local gaugeAngleMax_field = GoodRelationship_type_def:get_field("_gaugeAngleMax");
local OtherPlayerInfos_field = GoodRelationship_type_def:get_field("_OtherPlayerInfos");

local gauge_set_Item_method = gaugeAngleMax_field:get_type():get_method("set_Item(System.Int32, System.Single)");

local OtherPlayerInfos_type_def = OtherPlayerInfos_field:get_type();
local get_Count_method = OtherPlayerInfos_type_def:get_method("get_Count"); -- retval
local set_Item_method = OtherPlayerInfos_type_def:get_method("set_Item(System.Int32, snow.gui.GuiHud_GoodRelationship.PlInfo)");
local get_Item_method = OtherPlayerInfos_type_def:get_method("get_Item(System.Int32)"); -- retval

local PlInfo_type_def = get_Item_method:get_return_type();
local Enable_field = PlInfo_type_def:get_field("_Enable");
local good_field = PlInfo_type_def:get_field("_good");
local uniqueHunterId_field = PlInfo_type_def:get_field("_uniqueHunterId");
-- Main Function
local GoodRelationshipHud = nil;
local sendGoodReady = nil;

local function PreHook_doOpen(args)
	GoodRelationshipHud = Constants.SDK.to_managed_object(args[2]);
	sendGoodReady = nil;
end

local function PostHook_doOpen()
	if GoodRelationshipHud then
		local gaugeAngleMax = gaugeAngleMax_field:get_data(GoodRelationshipHud);
		if gaugeAngleMax then
			gauge_set_Item_method:call(gaugeAngleMax, 1, 0.0);
			GoodRelationshipHud:set_field("_gaugeAngleMax", gaugeAngleMax);
		end
		GoodRelationshipHud:set_field("WaitTime", 0.0);
	end
end

local function PostHook_updatePlayerInfo()
	if GoodRelationshipHud then
		local OtherPlayerInfos = OtherPlayerInfos_field:get_data(GoodRelationshipHud);
		if OtherPlayerInfos then
			local count = get_Count_method:call(OtherPlayerInfos);
			if count > 0 then
				local isChanged = false;
				for i = 0, count - 1, 1 do
					local OtherPlayerInfo = get_Item_method:call(OtherPlayerInfos, i);
					if OtherPlayerInfo and Enable_field:get_data(OtherPlayerInfo) then
						local uniqueHunterId = uniqueHunterId_field:get_data(OtherPlayerInfo);
						if uniqueHunterId and not isInBlockList_method:call(GoodRelationshipHud, uniqueHunterId) then
							OtherPlayerInfo:set_field("_good", true);
							set_Item_method:call(OtherPlayerInfos, i, OtherPlayerInfo);
							isChanged = true;
						end
					end
				end
				if isChanged then
					GoodRelationshipHud:set_field("_OtherPlayerInfos", OtherPlayerInfos);
				end
				sendGoodReady = true;
			end
		end
	end
	GoodRelationshipHud = nil;
end

local function sendGood(retval)
	if sendGoodReady then
		sendGoodReady = nil;
		return Constants.TRUE_POINTER;
	end
	return retval;
end

Constants.SDK.hook(GoodRelationship_type_def:get_method("doOpen"), PreHook_doOpen, PostHook_doOpen);
Constants.SDK.hook(GoodRelationship_type_def:get_method("updatePlayerInfo"), nil, PostHook_updatePlayerInfo);
Constants.SDK.hook(Constants.type_definitions.StmGuiInput_type_def:get_method("isOperationOn(snow.StmInputManager.UI_INPUT, snow.StmInputManager.UI_INPUT)"), nil, sendGood);