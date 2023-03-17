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
local GuiManager_type_def = sdk_find_type_definition("snow.gui.GuiManager");
local openGoodRelationshipHud_method = GuiManager_type_def:get_method("openGoodRelationshipHud");
local get_refGuiHud_GoodRelationship_method = GuiManager_type_def:get_method("get_refGuiHud_GoodRelationship");

local GoodRelationship_type_def = get_refGuiHud_GoodRelationship_method:get_return_type();
local isInBlockList_method = GoodRelationship_type_def:get_method("isInBlockList(System.Guid)");
local OtherPlayerInfos_field = GoodRelationship_type_def:get_field("_OtherPlayerInfos");
local gaugeAngleMax_field = GoodRelationship_type_def:get_field("_gaugeAngleMax");
local iter_Num = GoodRelationship_type_def:get_field("_OtherPlayerNum"):get_data(nil) - 1;

local OtherPlayerInfos_type_def = OtherPlayerInfos_field:get_type();
local set_Item_method = OtherPlayerInfos_type_def:get_method("set_Item(System.Int32, snow.gui.GuiHud_GoodRelationship.PlInfo)");
local get_Item_method = OtherPlayerInfos_type_def:get_method("get_Item(System.Int32)");

local uniqueHunterId_field = get_Item_method:get_return_type():get_field("_uniqueHunterId");
-- Main Function
sdk_hook(openGoodRelationshipHud_method, function(args)
	if settings.enable then
		local GuiManager = sdk_to_managed_object(args[2]);
		if GuiManager then
			local refGoodRelationship = get_refGuiHud_GoodRelationship_method:call(GuiManager);
			if refGoodRelationship then
				local OtherPlayerInfos = OtherPlayerInfos_field:get_data(refGoodRelationship);
				if OtherPlayerInfos and iter_Num then
					local isChanged = false;
					for i = 0, iter_Num, 1 do
						local OtherPlayerInfo = get_Item_method:call(OtherPlayerInfos, i);
						if not OtherPlayerInfo then
							goto continue;
						end
						local OtherPlayerHunterId = uniqueHunterId_field:get_data(OtherPlayerInfo);
						if not OtherPlayerHunterId or isInBlockList_method:call(refGoodRelationship, OtherPlayerHunterId) then
							goto continue;
						end
						OtherPlayerInfo:set_field("_good", true);
						set_Item_method:call(OtherPlayerInfos, i, OtherPlayerInfo);
						isChanged = true;
						::continue::
					end
					if isChanged then
						refGoodRelationship:set_field("_OtherPlayerInfos", OtherPlayerInfos);
					end
				end
				refGoodRelationship:set_field("_gaugeAngleY", gaugeAngleMax_field:get_data(refGoodRelationship));
				refGoodRelationship:set_field("WaitTime", 0.0);
			end
		end
	end
	return sdk_CALL_ORIGINAL;
end);
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
		imgui_tree_pop();
	else
		if changed then
			save_config();
		end
	end
end);