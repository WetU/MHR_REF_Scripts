local require = require;
local Constants = require("Constants.Constants");
if not Constants then
	return;
end

local utils = require("Better_Matchmaking.utils");
-- Config
local SendType = {"Good", "NotGood"};
local config = Constants.JSON.load_file("AutoLikes.json") or {enable = true, sendtype = "Good"};
if config.enable == nil then
	config.enable = true;
end
if config.sendtype == nil then
	config.sendtype = "Good";
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
local sendReady = nil;

local function PreHook_doOpen(args)
	if config.enable then
		GoodRelationshipHud = Constants.SDK.to_managed_object(args[2]);
		sendReady = nil;
	end
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
		if config.sendtype == "Good" then
			local OtherPlayerInfos = OtherPlayerInfos_field:get_data(GoodRelationshipHud);
			if OtherPlayerInfos then
				local isChanged = false;
				for i = 0, PlInfos_get_Count_method:call(OtherPlayerInfos) - 1, 1 do
					local OtherPlayerInfo = PlInfos_get_Item_method:call(OtherPlayerInfos, i);
					if OtherPlayerInfo and PlInfo_Enable_field:get_data(OtherPlayerInfo) then
						OtherPlayerInfo:set_field("_good", true);
						PlInfos_set_Item_method:call(OtherPlayerInfos, i, OtherPlayerInfo);
						isChanged = true;
					end
				end
				if isChanged then
					GoodRelationshipHud:set_field("_OtherPlayerInfos", OtherPlayerInfos);
				end
			end
		end
		sendReady = true;
	end
	GoodRelationshipHud = nil;
end

local function sendGood(retval)
	if sendReady then
		sendReady = nil;
		return Constants.TRUE_POINTER;
	end
	return retval;
end

Constants.SDK.hook(GoodRelationship_type_def:get_method("doOpen"), PreHook_doOpen, PostHook_doOpen);
Constants.SDK.hook(GoodRelationship_type_def:get_method("updatePlayerInfo"), nil, PostHook_updatePlayerInfo);
Constants.SDK.hook(Constants.type_definitions.StmGuiInput_type_def:get_method("isOperationOn(snow.StmInputManager.UI_INPUT, snow.StmInputManager.UI_INPUT)"), nil, sendGood);
--
local function SaveConfig()
	Constants.JSON.dump_file("AutoLikes.json", config);
end

Constants.RE.on_config_save(SaveConfig);
Constants.RE.on_draw_ui(function()
	if Constants.IMGUI.tree_node("AutoLikes") then
		local config_changed = false;
		config_changed, config.enable = Constants.IMGUI.checkbox("Enable", config.enable);
		if config.enable then
			local changed, index = Constants.IMGUI.combo("Send Type", utils.table.find_index(SendType, config.sendtype, false), SendType);
			config_changed = config_changed or changed;
			if changed then
				config.sendtype = SendType[index];
			end
		end
		if config_changed then
			SaveConfig();
			if not config.enable then
				GoodRelationshipHud = nil;
				sendReady = nil;
			end
		end
		Constants.IMGUI.tree_pop();
	end
end);