local json = json;
local json_load_file = json.load_file;
local json_dump_file = json.dump_file;

local re = re;
local re_on_config_save = re.on_config_save;
local re_on_draw_ui = re.on_draw_ui;
local re_on_frame = re.on_frame;

local sdk = sdk;
local sdk_find_type_definition = sdk.find_type_definition;
local sdk_get_managed_singleton = sdk.get_managed_singleton;
local sdk_to_managed_object = sdk.to_managed_object;
local sdk_to_ptr = sdk.to_ptr;
local sdk_hook = sdk.hook;

local imgui = imgui;
local imgui_tree_node = imgui.tree_node;
local imgui_checkbox = imgui.checkbox;
local imgui_combo = imgui.combo;
local imgui_slider_int = imgui.slider_int;
local imgui_button = imgui.button;
local imgui_tree_pop = imgui.tree_pop;

local table = table;
local table_insert = table.insert;

local math = math;
local math_floor = math.floor;

local pairs = pairs;
local tonumber = tonumber;

local config = nil;

local function Reset()
    config = {
        ["Enable"] = true,
        ["Weakness"] = "Orange",
        ["MindEye"] = "Large Gray",
        ["Neither"] = "White",
        ["IgnoreMeat"] = "Red",
        ["BuddyAttack"] = "Hide",
        ["WeaknessAndElement"] = "Orange",
        ["MindEyeAndElement"] = "Large Gray",
        ["NeitherAndElement"] = "White",
        ["CriticalDisplay"] = false,
        ["PhysicalDisplay"] = false,
        ["ElementDisplay"] = false,
        ["ElementExploitSkillDisplay"] = false,
        ["ElementExploitRampageDecoDisplay"] = false,
        ["DisplayTime"] = 20,
        ["FontType"] = 0,
        ["ElementActivationValue"] = 100
    };
end

local function SaveConfig()
    json_dump_file("HardOrSoft.json", config);
end

local loadConfig = json_load_file("HardOrSoft.json");
if loadConfig then
    config = loadConfig;
else
    Reset();
    SaveConfig();
end

local temp = nil;
local preDmg = {};
local elementExploit = 0;
local lastShowTimer = 0;
local color = {"Hide", "White", "Orange", "Large Orange", "Gray", "Red", "Large Gray"};

local function FindIndex (table, value, nullable)
	for i = 1, #table do
		if table[i] == value then
			return i;
		end
	end
	if not nullable then
		return 1;
	end
    return nil;
end

re_on_config_save(SaveConfig);

local get_UpTimeSecond_method = sdk_find_type_definition("via.Application"):get_method("get_UpTimeSecond");

local afterCalcDamage_DamageSide_method = sdk_find_type_definition("snow.enemy.EnemyCharacterBase"):get_method("afterCalcDamage_DamageSide(snow.hit.DamageFlowInfoBase, snow.DamageReceiver.HitInfo)");
local getHitUIColorType_method = sdk_find_type_definition("snow.enemy.EnemyUtility"):get_method("getHitUIColorType(snow.hit.EnemyCalcDamageInfo.AfterCalcInfo_DamageSide)");

local GuiDamageDisp_NumDisp_type_def = sdk_find_type_definition("snow.gui.GuiDamageDisp.NumDisp");
local excute_method = GuiDamageDisp_NumDisp_type_def:get_method("execute");
local isExecute_method = GuiDamageDisp_NumDisp_type_def:get_method("isExecute");
local DispType_field = GuiDamageDisp_NumDisp_type_def:get_field("DispType");
local DamageText_field = GuiDamageDisp_NumDisp_type_def:get_field("_DamageText");

local DamageText_type_def = DamageText_field:get_type();
local get_Message_method = DamageText_type_def:get_method("get_Message");
local set_Message_method = DamageText_type_def:get_method("set_Message(System.String)");
local set_FontSlot_method = DamageText_type_def:get_method("set_FontSlot(via.gui.FontSlot)");

local AfterCalcInfo_DamageSide_type_def = sdk_find_type_definition("snow.hit.EnemyCalcDamageInfo.AfterCalcInfo_DamageSide");
local get_AttackerID_method = AfterCalcInfo_DamageSide_type_def:get_method("get_AttackerID");
local get_DamageAttackerType_method = AfterCalcInfo_DamageSide_type_def:get_method("get_DamageAttackerType");
local get_TotalDamage_method = AfterCalcInfo_DamageSide_type_def:get_method("get_TotalDamage");
local get_PhysicalDamage_method = AfterCalcInfo_DamageSide_type_def:get_method("get_PhysicalDamage");
local get_ElementDamage_method = AfterCalcInfo_DamageSide_type_def:get_method("get_ElementDamage");
local get_CriticalResult_method = AfterCalcInfo_DamageSide_type_def:get_method("get_CriticalResult");
local CalcParam_field = AfterCalcInfo_DamageSide_type_def:get_field("_CalcParam");

local CalcParam_type_def = CalcParam_field:get_type();
local get_OwnerType_method = CalcParam_type_def:get_method("get_OwnerType");
local get_CalcType_method = CalcParam_type_def:get_method("get_CalcType");
local get_ElementMeatAdjustRate_method = CalcParam_type_def:get_method("get_ElementMeatAdjustRate");
local get_PhysicalMeatAdjustRate_method = CalcParam_type_def:get_method("get_PhysicalMeatAdjustRate");

local findMasterPlayer_method = sdk_find_type_definition("snow.player.PlayerManager"):get_method("findMasterPlayer");

local getPlayerIndex_method = findMasterPlayer_method:get_return_type():get_method("getPlayerIndex");

local DamageAttackerType = {
    PlayerWeapon = 0,
    BarrelBombLarge = 1,
    Makimushi = 2,
    Nitro = 3,
    OnibiMine = 4,
    BallistaHate = 5,
    CaptureSmokeBomb = 6,
    CaptureBullet = 7,
    BarrelBombSmall = 8,
    Kunai = 9,
    WaterBeetle = 10,
    DetonationGrenade = 11,
    Kabutowari = 12,
    FlashBoll = 13,
    Em058BallistaOneShotBinder = 14,
    Em058CannonKantsu = 15,
    HmBallista = 16,
    HmCannon = 17,
    HmGatling = 18,
    HmTrap = 19,
    HmNpc = 20,
    HmFlameThrower = 21,
    HmDragnator = 22,
    Otomo = 23,
    OtAirouShell014 = 24,
    OtAirouShell102 = 25,
    Fg005 = 26,
    EcBatExplode = 27,
    EcWallTrapBugExplode = 28,
    EcPiranha = 29,
    EcFlash = 30,
    EcSandWallShooter = 31,
    EcForestWallShooter = 32,
    EcSwampLeech = 33,
    EcPenetrateFish = 34,
    Max = 35,
    Invalid = 36
};

local DamageFlowOwnerType = {
    Invalid = -1,
    Props = 0,
    Enemy = 1,
    EnemyShell = 2,
    Player = 3,
    PlayerShell = 4,
    Otomo = 5,
    OtomoShell = 6,
    Creature = 7,
    CreatureShell = 8
};

local DamageCalcType = {
    Slash = 0,
    Strike = 1,
    Shell = 2,
    IgnoreMeat = 3,
    FriendlyFire = 4,
    Max = 5,
    Invalid = 6
};

local ColorType = {
    White = 0,
    Orange = 1,
    BigOrange = 2,
    Gray = 3,
    Red = 4,
    BigGray = 5
};

local function Conversion()
    temp = {
        ["White"] = sdk_to_ptr(ColorType.White),
        ["Orange"] = sdk_to_ptr(ColorType.Orange),
        ["Weakness"] = sdk_to_ptr(FindIndex(color, config.Weakness, false) - 2),
        ["MindEye"] = sdk_to_ptr(FindIndex(color, config.MindEye, false) - 2),
        ["Neither"] = sdk_to_ptr(FindIndex(color, config.Neither, false) - 2),
        ["IgnoreMeat"] = sdk_to_ptr(FindIndex(color, config.IgnoreMeat, false) - 2),
        ["BuddyAttack"] = sdk_to_ptr(FindIndex(color, config.BuddyAttack, false) - 2),
        ["WeaknessAndElement"] = sdk_to_ptr(FindIndex(color, config.WeaknessAndElement, false) - 2),
        ["MindEyeAndElement"] = sdk_to_ptr(FindIndex(color, config.MindEyeAndElement, false) - 2),
        ["NeitherAndElement"] = sdk_to_ptr(FindIndex(color, config.NeitherAndElement, false) - 2)
    };
end

Conversion();

local function IsPlayerDamageType(dmgtype)
    return dmgtype == DamageAttackerType.PlayerWeapon or dmgtype == DamageAttackerType.DetonationGrenade or dmgtype == DamageAttackerType.Kabutowari or false;
end

sdk_hook(afterCalcDamage_DamageSide_method, function(args)
    if config.Enable then
        local PlayerManager = sdk_get_managed_singleton("snow.player.PlayerManager");
        if PlayerManager then
            local MasterPlayer = findMasterPlayer_method:call(PlayerManager);
            if MasterPlayer then
                local masterIdx = getPlayerIndex_method:call(MasterPlayer);
                local dmgInfo = sdk_to_managed_object(args[3]);
                if masterIdx ~= nil and dmgInfo and get_AttackerID_method(dmgInfo) == masterIdx and IsPlayerDamageType(get_DamageAttackerType_method:call(dmgInfo)) then
                    table_insert(preDmg, {
                        ["dmg"] = get_TotalDamage_method:call(dmgInfo),
                        ["physical"] = get_PhysicalDamage_method:call(dmgInfo),
                        ["element"] = get_ElementDamage_method:call(dmgInfo),
                        ["critical"] = get_CriticalResult_method:call(dmgInfo),
                        ["find"] = 0
                    });
                    lastShowTimer = get_UpTimeSecond_method:call(nil);
                end
            end
        end
    end
end);

sdk_hook(excute_method, function(args)
    if config.Enable then
        local tmp = sdk_to_managed_object(args[2]);
        if tmp and DispType_field:get_data(tmp) ~= ColorType.Gray and isExecute_method:call(tmp) then
            local text = DamageText_field:get_data(tmp);
            local font = (config.FontType == 5 and 7) or (config.FontType == 6 and 11) or config.FontType;
            if text and font then
                set_FontSlot_method:call(text, font);
                tmp:set_field("waitFrame", config.DisplayTime);
                local dmg = tonumber(get_Message_method:call(text));
                if dmg then
                    for _, v in pairs(preDmg) do
                        if v.find < 2 then
                            if v.dmg == dmg then
                                v.find = v.find + 1;
                                local msg = dmg;
                                if config.CriticalDisplay then
                                    if v.critical == 1 then
                                        msg = msg .. "!";
                                    elseif v.critical == 2 then
                                        msg = msg .. "?";
                                    end
                                end
                                if v.element ~= 0 then
                                    if config.PhysicalDisplay or config.ElementDisplay then
                                        msg = msg .. " (";
                                        if config.PhysicalDisplay then
                                            msg = msg .. math_floor(v.physical);
                                            if config.ElementDisplay then
                                                msg = msg .. ",";
                                            end
                                        end
                                        if config.ElementDisplay then
                                            msg = msg .. math_floor(v.element);
                                        end
                                        msg = msg .. ")";
                                    end
                                end
                                if config.ElementExploitSkillDisplay then
                                    if elementExploit >= 1 then
                                        msg = msg .. "+";
                                    end
                                end
                                if config.ElementExploitRampageDecoDisplay then
                                    if elementExploit == 2 then
                                        msg = msg .. "+";
                                    end
                                end
                                if msg ~= dmg then
                                    set_Message_method:call(text, msg);
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end);

local nextArg = nil;
sdk_hook(getHitUIColorType_method, function(args)
    if config.Enable then
        nextArg = sdk_to_managed_object(args[2]);
    end
end, function()
    if nextArg then
        local calcParam = CalcParam_field:get_data(nextArg);
        nextArg = nil;
        elementExploit = 0;
        if calcParam then
            local ownerType = get_OwnerType_method:call(calcParam);
            local calcType = get_CalcType_method:call(calcParam);
            local elementMeatAdjustRate = get_ElementMeatAdjustRate_method:call(calcParam);
            local physicalMeatAdjustRate = get_PhysicalMeatAdjustRate_method:call(calcParam);

            if elementMeatAdjustRate < 1 then
                if elementMeatAdjustRate >= 0.25 then
                    elementExploit = 2;
                elseif elementMeatAdjustRate >= 0.2 then
                    elementExploit = 1;
                end
            end

            -- Buddy
            if (ownerType == DamageFlowOwnerType.Otomo or ownerType == DamageFlowOwnerType.OtomoShell) and (ownerType ~= DamageFlowOwnerType.Player and ownerType ~= DamageFlowOwnerType.PlayerShell) then
                elementExploit = 0;
                return temp.BuddyAttack;
            end

            -- Blademaster
            if calcType == DamageCalcType.Slash or calcType == DamageCalcType.Strike then
                if physicalMeatAdjustRate > 0.445 then
                    if elementMeatAdjustRate < 1 and elementMeatAdjustRate >= config.ElementActivationValue / 100 then
                        return temp.WeaknessAndElement;
                    end
                    return temp.Weakness;
                end
                if retval == temp.White then
                    if elementMeatAdjustRate < 1 and elementMeatAdjustRate >= config.ElementActivationValue / 100 then
                        return temp.MindEyeAndElement;
                    end
                    return temp.MindEye;
                end
                if elementMeatAdjustRate < 1 and elementMeatAdjustRate >= config.ElementActivationValue / 100 then
                    return temp.NeitherAndElement;
                end
                return temp.Neither;
            end

            -- Gunner
            if calcType == DamageCalcType.Shell then
                if retval == temp.Orange then
                    if elementMeatAdjustRate < 1 and elementMeatAdjustRate >= config.ElementActivationValue / 100 then
                        return temp.WeaknessAndElement;
                    end
                    return temp.Weakness;
                end
                if elementMeatAdjustRate < 1 and elementMeatAdjustRate >= config.ElementActivationValue / 100 then
                    return temp.NeitherAndElement;
                end
                return temp.Neither;
            end

            elementExploit = 0

            --IgnoreMeat
            if calcType == DamageCalcType.IgnoreMeat then
                return temp.IgnoreMeat;
            end
        end
    end
    nextArg = nil;
end);

re_on_draw_ui(function()
    if imgui_tree_node("Hard or Soft") then
        local changed = false;
        local new_value = nil;
        local configChanged = false;
        changed, config.Enable = imgui_checkbox("Enabled", config.Enable);
        if changed then
            configChanged = configChanged or changed;
        end
        
        local weaknessExploitChanged, weaknessExploit_newValue = imgui_combo("Weakness Exploit", FindIndex(color, config.Weakness), color);
        if weaknessExploitChanged then
            config.Weakness = color[weaknessExploit_newValue];
            configChanged = configChanged or changed;
        end

        local mindEyeChanged, mindEye_newValue = imgui_combo("Mind's Eye", FindIndex(color, config.MindEye), color);
        if mindEyeChanged then
            config.MindEye = color[mindEye_newValue];
            configChanged = configChanged or changed;
        end

        local neitherChanged, neither_newValue = imgui_combo("Neither", FindIndex(color, config.Neither), color);
        if neitherChanged then
            config.Neither = color[neither_newValue];
            configChanged = configChanged or changed;
        end

        local ignoreMeatChanged, ignoreMeat_newValue = imgui_combo("Ignore Meat", FindIndex(color, config.IgnoreMeat), color);
        if ignoreMeatChanged then
            config.IgnoreMeat = color[ignoreMeat_newValue];
            configChanged = configChanged or changed;
        end

        local buddyChanged, buddy_newValue = imgui_combo("Buddy Attack", FindIndex(color, config.BuddyAttack), color);
        if buddyChanged then
            config.BuddyAttack = color[buddy_newValue];
            configChanged = configChanged or changed;
        end

        changed, config.CriticalDisplay = imgui_checkbox("Displays Critical", config.CriticalDisplay);
        if changed then
            configChanged = configChanged or changed;
        end

        changed, config.PhysicalDisplay = imgui_checkbox("Displays Physical Damage", config.PhysicalDisplay);
        if changed then
            configChanged = configChanged or changed;
        end

        changed, config.ElementDisplay = imgui_checkbox("Displays Element Damage", config.ElementDisplay);
        if changed then
            configChanged = configChanged or changed;
        end

        changed, config.ElementExploitSkillDisplay = imgui_checkbox("Displays Element Exploit of Skill", config.ElementExploitSkillDisplay);
        if changed then
            configChanged = configChanged or changed;
        end

        changed, config.ElementExploitRampageDecoDisplay = imgui_checkbox("Displays Element Exploit of Rampage Deco", config.ElementExploitRampageDecoDisplay);
        if changed then
            configChanged = configChanged or changed;
        end

        changed, config.FontType = imgui_slider_int("Font Type", config.FontType, 0, 6);
        if changed then
            configChanged = configChanged or changed;
        end

        changed, config.DisplayTime = imgui_slider_int("Display Time", config.DisplayTime, 5, 200);
        if changed then
            configChanged = configChanged or changed;
        end

        local weakandeleChanged, weakandele_newValue = imgui_combo("Weakness And Element", FindIndex(color, config.WeaknessAndElement), color);
        if weakandeleChanged then
            config.WeaknessAndElement = color[weakandele_newValue];
            configChanged = configChanged or changed;
        end

        local mindeyeChanged, mindeye_newValue = imgui_combo("MindEye And Element", FindIndex(color, config.MindEyeAndElement), color);
        if mindeyeChanged then
            config.MindEyeAndElement = color[mindeye_newValue];
            configChanged = configChanged or changed;
        end

        local neitherandeleChanged, neitherandele_newValue = imgui_combo("Neither And Element", FindIndex(color, config.NeitherAndElement), color);
        if neitherandeleChanged then
            config.NeitherAndElement = color[neitherandele_newValue];
            configChanged = configChanged or changed;
        end

        changed, config.ElementActivationValue = imgui_slider_int("Element Activation Value", config.ElementActivationValue, 0, 100);
        if changed then
            configChanged = configChanged or changed;
        end

        if configChanged then
            SaveConfig();
            Conversion();
        end

        if imgui_button("Reset") then
            Reset();
            SaveConfig();
            Conversion();
        end
		imgui_tree_pop();
    end
end);

re_on_frame(function()
	if #preDmg ~= 0 and (get_UpTimeSecond_method:call(nil) - lastShowTimer >= 1) then
		preDmg = {};
        elementExploit = 0;
	end
end);