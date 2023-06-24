local require = require;
local Constants = require("Constants.Constants");
local Config = require("AutoSupply.Config");
local AutoArgosy = require("AutoSupply.AutoArgosy");
local CohootSupply = require("AutoSupply.AutoCohootSupply");
local InventorySupply = require("AutoSupply.AutoInventorySupply");

if not Constants
or not Config
or not AutoArgosy
or not CohootSupply
or not InventorySupply then
    return;
end

local settings = Config.config;
--
local reqAddChatInfomation_method = Constants.SDK.find_type_definition("snow.gui.ChatManager"):get_method("reqAddChatInfomation(System.String, System.UInt32)");
--
local function SendMessage(text)
    if settings.EnableNotification then
        local ChatManager = Constants.SDK.get_managed_singleton("snow.gui.ChatManager");
        if ChatManager then
		    reqAddChatInfomation_method:call(ChatManager, text, 2289944406);
        end
	end
end

local EquipDataManager = nil;
local setIdx = nil;
Constants.SDK.hook(Constants.type_definitions.EquipDataManager_type_def:get_method("applyEquipMySet(System.Int32)"), function(args)
    if settings.Enabled then
        EquipDataManager = Constants.SDK.to_managed_object(args[2]);
        setIdx = Constants.SDK.to_int64(args[3]) & 0xFFFFFFFF;
    end
end, function(retval)
    if EquipDataManager and setIdx ~= nil then
        local msg = InventorySupply.Restock(EquipDataManager, setIdx);
        SendMessage(msg);
    end
    EquipDataManager = nil;
    setIdx = nil;
    return retval;
end);

Constants.SDK.hook(Constants.SDK.find_type_definition("snow.gui.fsm.camp.GuiCampFsmManager"):get_method("start"), nil, function()
    if settings.Enabled then
        local msg = InventorySupply.Restock(nil, nil);
        SendMessage(msg);
    end
end);

Constants.SDK.hook(Constants.SDK.find_type_definition("snow.wwise.WwiseChangeSpaceWatcher"):get_method("onVillageStart"), nil, function()
    if settings.EnableArgosy then
        local isReceived = AutoArgosy.autoArgosy();
        if isReceived then
            SendMessage("교역선 아이템을 받았습니다");
        end
    end
    if settings.Enabled then
        local msg = InventorySupply.Restock(nil, nil);
        SendMessage(msg);
    end
    if settings.EnableCohootSupply then
        CohootSupply.SupplyCohoot();
    end
end);
----------------------------------------------
Constants.RE.on_config_save(Config.save_config);
Constants.RE.on_draw_ui(function()
    if Constants.IMGUI.tree_node("AutoSupply") then
        Constants.IMGUI.push_font(Constants.Font);
        local config_changed = false;
        local changed = false;
        config_changed, settings.Enabled = Constants.IMGUI.checkbox("Enabled", settings.Enabled);
        changed, settings.EnableNotification = Constants.IMGUI.checkbox("EnableNotification", settings.EnableNotification);
        config_changed = config_changed or changed;
        changed, settings.EnableCohoot = Constants.IMGUI.checkbox("EnableCohootSupply", settings.EnableCohoot);
        config_changed = config_changed or changed;
        changed, settings.EnableArgosy = Constants.IMGUI.checkbox("EnableArgosy", settings.EnableArgosy);
        config_changed = config_changed or changed;

        local langChanged, new_langIdx = Constants.IMGUI.combo("Language", Constants.FindIndex(Config.Languages, settings.Language), Config.Languages);
        config_changed = config_changed or langChanged;
        if langChanged then
            settings.Language = Config.Languages[new_langIdx];
        end

        changed, settings.DefaultSet = Constants.IMGUI.slider_int("Default ItemSet", settings.DefaultSet, 0, 39, InventorySupply.GetItemLoadoutName(settings.DefaultSet));
        config_changed = config_changed or changed;

        if Constants.IMGUI.tree_node("WeaponType") then
            for i = 1, 14, 1 do
                local weaponType = i - 1;
                changed, settings.WeaponTypeConfig[i] = Constants.IMGUI.slider_int(InventorySupply.GetWeaponName(weaponType), settings.WeaponTypeConfig[i], -1, 39, InventorySupply.GetWeaponTypeItemLoadoutName(weaponType));
                config_changed = config_changed or changed;
            end
            Constants.IMGUI.tree_pop();
        end

        if Constants.IMGUI.tree_node("Loadout") then
            for i = 1, 224, 1 do
                local loadoutIndex = i - 1;
                local name = InventorySupply.GetEquipmentLoadoutName(nil, loadoutIndex);
                if name and InventorySupply.EquipmentLoadoutIsNotEmpty(loadoutIndex) then
                    local msg = "";
                    if InventorySupply.EquipmentLoadoutIsEquipped(nil, loadoutIndex) then 
                        msg = " (현재)";
                    end
                    changed, settings.EquipLoadoutConfig[i] = Constants.IMGUI.slider_int(name .. msg, settings.EquipLoadoutConfig[i], -1, 39, InventorySupply.GetLoadoutItemLoadoutIndex(loadoutIndex));
                    config_changed = config_changed or changed;
                end
            end
            Constants.IMGUI.tree_pop();
        end

        if config_changed then
            Config.save_config();
        end
        Constants.IMGUI.pop_font();
        Constants.IMGUI.tree_pop();
    end
end);