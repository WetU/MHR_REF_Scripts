-- Initialize
local sdk = sdk;

-- Cache
local GoodRelationship_type_def = sdk.find_type_definition("snow.gui.GuiHud_GoodRelationship");
local doOpen_method = GoodRelationship_type_def:get_method("doOpen"); -- virtual
local isInBlockList_method = GoodRelationship_type_def:get_method("isInBlockList(System.Guid)"); -- retval
local OtherPlayerInfos_field = GoodRelationship_type_def:get_field("_OtherPlayerInfos");
local gaugeAngleMax_field = GoodRelationship_type_def:get_field("_gaugeAngleMax");

local gauge_set_Item_method = gaugeAngleMax_field:get_type():get_method("set_Item(System.Int32, System.Single)");

local OtherPlayerInfos_type_def = OtherPlayerInfos_field:get_type();
local get_Count_method = OtherPlayerInfos_type_def:get_method("get_Count"); -- retval
local set_Item_method = OtherPlayerInfos_type_def:get_method("set_Item(System.Int32, snow.gui.GuiHud_GoodRelationship.PlInfo)");
local get_Item_method = OtherPlayerInfos_type_def:get_method("get_Item(System.Int32)"); -- retval

local uniqueHunterId_field = get_Item_method:get_return_type():get_field("_uniqueHunterId");

-- Main Function
local GoodRelationshipHud = nil;
sdk.hook(doOpen_method, function(args)
	GoodRelationshipHud = sdk.to_managed_object(args[2]);
end, function()
	if GoodRelationshipHud then
		local OtherPlayerInfos = OtherPlayerInfos_field:get_data(GoodRelationshipHud);
		if OtherPlayerInfos then
			local count = get_Count_method:call(OtherPlayerInfos);
			if count > 0 then
				local isChanged = false;
				for i = 0, count - 1, 1 do
					local OtherPlayerInfo = get_Item_method:call(OtherPlayerInfos, i);
					if OtherPlayerInfo then
						local OtherPlayerHunterId = uniqueHunterId_field:get_data(OtherPlayerInfo);
						if OtherPlayerHunterId ~= nil and not isInBlockList_method:call(GoodRelationshipHud, OtherPlayerHunterId) then
							OtherPlayerInfo:set_field("_good", true);
							set_Item_method:call(OtherPlayerInfos, i, OtherPlayerInfo);
							if isChanged == false then
								isChanged = true;
							end
						end
					end
				end
				if isChanged then
					GoodRelationshipHud:set_field("_OtherPlayerInfos", OtherPlayerInfos);
				end
			end
		end
		local gaugeAngleMax = gaugeAngleMax_field:get_data(GoodRelationshipHud);
		if gaugeAngleMax then
			gauge_set_Item_method:call(gaugeAngleMax, 1, 0.0);
			GoodRelationshipHud:set_field("_gaugeAngleMax", gaugeAngleMax);
		end
		GoodRelationshipHud:set_field("WaitTime", 0.0);
	end
	GoodRelationshipHud = nil;
end);