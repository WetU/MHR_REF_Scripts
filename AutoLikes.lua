-- Initialize
local json = json;
local jsonAvailable = json ~= nil;
local json_load_file = jsonAvailable and json.load_file or nil;
local json_dump_file = jsonAvailable and json.dump_file or nil;

local sdk = sdk;
local sdk_find_type_definition = sdk.find_type_definition;
local sdk_to_managed_object = sdk.to_managed_object;
local sdk_hook = sdk.hook;
local sdk_CALL_ORIGINAL = sdk.PreHookResult.CALL_ORIGINAL;

local re = re;
local re_on_config_save = re.on_config_save;
local re_on_draw_ui = re.on_draw_ui;

local imgui = imgui;
local imgui_tree_node = imgui.tree_node;
local imgui_checkbox = imgui.checkbox;
local imgui_tree_pop = imgui.tree_pop;

local settings = {};

if json_load_file then
	local loadedSettings = json_load_file("AutoLikes.json");
	settings = loadedSettings or {enable = true};
end
if settings.enable == nil then
	settings.enable = true;
end
-- Cache
local GoodRelationship_type_def = sdk_find_type_definition("snow.gui.GuiHud_GoodRelationship");
local doOpen_method = GoodRelationship_type_def:get_method("doOpen");
local isInBlockList_method = GoodRelationship_type_def:get_method("isInBlockList(System.Guid)");
local OtherPlayerInfos_field = GoodRelationship_type_def:get_field("_OtherPlayerInfos");
local gaugeAngleMax_field = GoodRelationship_type_def:get_field("_gaugeAngleMax");

local OtherPlayerInfos_type_def = OtherPlayerInfos_field:get_type();
local get_Count_method = OtherPlayerInfos_type_def:get_method("get_Count");
local set_Item_method = OtherPlayerInfos_type_def:get_method("set_Item(System.Int32, snow.gui.GuiHud_GoodRelationship.PlInfo)");
local get_Item_method = OtherPlayerInfos_type_def:get_method("get_Item(System.Int32)");

local uniqueHunterId_field = get_Item_method:get_return_type():get_field("_uniqueHunterId");
-- Main Function
local GoodRelationshipHud = nil;

local function getGoodRelationshipHud(args)
	if settings.enable then
		GoodRelationshipHud = sdk_to_managed_object(args[2]);
	end
	return sdk_CALL_ORIGINAL;
end

local function SwitchGoodPlayer()
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
						if OtherPlayerHunterId and not isInBlockList_method:call(GoodRelationshipHud, OtherPlayerHunterId) then
							OtherPlayerInfo:set_field("_good", true);
							set_Item_method:call(OtherPlayerInfos, i, OtherPlayerInfo);
							isChanged = true;
						end
					end
				end
				if isChanged then
					GoodRelationshipHud:set_field("_OtherPlayerInfos", OtherPlayerInfos);
				end
			end
		end
		GoodRelationshipHud:set_field("_gaugeAngleY", gaugeAngleMax_field:get_data(GoodRelationshipHud));
		GoodRelationshipHud:set_field("WaitTime", 0.0);
	end
	GoodRelationshipHud = nil;
end

sdk_hook(doOpen_method, getGoodRelationshipHud, SwitchGoodPlayer);
---- re Callbacks ----
local function save_config()
	if json_dump_file then
		json_dump_file("AutoLikes.json", settings);
	end
end

re_on_config_save(save_config);

re_on_draw_ui(function()
	local changed = false;
	if imgui_tree_node("Auto Likes") then
		changed, settings.enable = imgui_checkbox("Enabled", settings.enable);
		if changed then
			save_config();
		end
		imgui_tree_pop();
	end
end);