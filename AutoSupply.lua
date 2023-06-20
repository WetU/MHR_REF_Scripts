local Constants = require("Constants.Constants");
if not Constants then
    return;
end
--
local Languages = {"en-US", "ko-KR"};

------------- Config Management --------------
local config = Constants.JSON.load_file("AutoSupply.json") or {
    Enabled = true,
    EnableNotification = true,
    EnableCohoot = true,
    EnableGoodReward = true,
    EnableOtomoTicket = true,
    EnableTicket = true,
    EnableArgosy = true,
    DefaultSet = 1,
    WeaponTypeConfig = {},
    EquipLoadoutConfig = {},
    CohootMaxStock = 5,
    Language = "ko-KR"
};
if config.Enabled == nil then
    config.Enabled = true;
end
if config.EnableNotification == nil then
    config.EnableNotification = true;
end
if config.EnableCohoot == nil then
    config.EnableCohoot = true;
end
if config.EnableGoodReward == nil then
    config.EnableGoodReward = true;
end
if config.EnableOtomoTicket == nil then
    config.EnableOtomoTicket = true;
end
if config.EnableTicket == nil then
    config.EnableTicket = true;
end
if config.EnableArgosy == nil then
    config.EnableArgosy = true;
end
if config.DefaultSet == nil then
    config.DefaultSet = 1;
end
if config.WeaponTypeConfig == nil then
    config.WeaponTypeConfig = {};
end
for i = 1, 14, 1 do
    if config.WeaponTypeConfig[i] == nil then
        config.WeaponTypeConfig[i] = -1;
    end
end
if config.EquipLoadoutConfig == nil then
    config.EquipLoadoutConfig = {};
end
for i = 1, 224, 1 do
    if config.EquipLoadoutConfig[i] == nil then
        config.EquipLoadoutConfig[i] = -1;
    end
end
if config.CohootMaxStock == nil then
    config.CohootMaxStock = 5;
end
if config.Language == nil or Constants.FindIndex(Languages, config.Language) == nil then
    config.Language = "ko-KR";
end
--
local findMasterPlayer_method = Constants.type_definitions.PlayerManager_type_def:get_method("findMasterPlayer"); -- retval
local playerWeaponType_field = findMasterPlayer_method:get_return_type():get_field("_playerWeaponType");

local reqAddChatInfomation_method = Constants.SDK.find_type_definition("snow.gui.ChatManager"):get_method("reqAddChatInfomation(System.String, System.UInt32)");

local DataManager_type_def = Constants.SDK.find_type_definition("snow.data.DataManager");
local getItemMySet_method = DataManager_type_def:get_method("get_ItemMySet"); -- static, retval
local trySellGameItem_method = DataManager_type_def:get_method("trySellGameItem(snow.data.ItemInventoryData, System.UInt32)");

local ItemMySet_type_def = getItemMySet_method:get_return_type();
local applyItemMySet_method = ItemMySet_type_def:get_method("applyItemMySet(System.Int32)");
local getData_method = ItemMySet_type_def:get_method("getData(System.Int32)"); -- retval

local PlItemPouchMySetData_type_def = getData_method:get_return_type();
local PlItemPouchMySetData_get_Name_method = PlItemPouchMySetData_type_def:get_method("get_Name"); -- retval
local isEnoughItem_method = PlItemPouchMySetData_type_def:get_method("isEnoughItem"); -- retval
local get_PaletteSetIndex_method = PlItemPouchMySetData_type_def:get_method("get_PaletteSetIndex"); -- retval

local PalleteSetIndex_type_def = get_PaletteSetIndex_method:get_return_type();
local get_HasValue_method = PalleteSetIndex_type_def:get_method("get_HasValue"); -- retval
local get_Value_method = PalleteSetIndex_type_def:get_method("get_Value"); -- retval
local GetValueOrDefault_method = PalleteSetIndex_type_def:get_method("GetValueOrDefault"); -- retval

local PlEquipMySetList_field = Constants.type_definitions.EquipDataManager_type_def:get_field("_PlEquipMySetList");

local PlEquipMySetList_get_Item_method = PlEquipMySetList_field:get_type():get_method("get_Item(System.Int32)");  -- retval

local PlEquipMySetData_type_def = PlEquipMySetList_get_Item_method:get_return_type();
local get_Name_method = PlEquipMySetData_type_def:get_method("get_Name"); -- retval
local get_IsUsing_method = PlEquipMySetData_type_def:get_method("get_IsUsing"); -- retval
local isSamePlEquipPack_method = PlEquipMySetData_type_def:get_method("isSamePlEquipPack"); -- retval
local getWeaponData_method = PlEquipMySetData_type_def:get_method("getWeaponData"); -- retval

local get_PlWeaponType_method = getWeaponData_method:get_return_type():get_method("get_PlWeaponType"); -- retval

local getCustomShortcutSystem_method = Constants.SDK.find_type_definition("snow.data.SystemDataManager"):get_method("getCustomShortcutSystem"); -- static, retval

local CustomShortcutSystem_type_def = getCustomShortcutSystem_method:get_return_type();
local setUsingPaletteIndex_method = CustomShortcutSystem_type_def:get_method("setUsingPaletteIndex(snow.data.CustomShortcutSystem.SycleTypes, System.Int32)");
local getPaletteSetList_method = CustomShortcutSystem_type_def:get_method("getPaletteSetList(snow.data.CustomShortcutSystem.SycleTypes)"); -- retval

local palletteSetData_get_Item_method = getPaletteSetList_method:get_return_type():get_method("get_Item(System.Int32)"); -- retval

local palletteSetData_get_Name_method = palletteSetData_get_Item_method:get_return_type():get_method("get_Name"); -- retval

local SycleTypes_Quest = Constants.SDK.find_type_definition("snow.data.CustomShortcutSystem.SycleTypes"):get_field("Quest"):get_data(nil);
--
local VillagePoint_type_def = Constants.SDK.find_type_definition("snow.data.VillagePoint");
local get_Point_method = VillagePoint_type_def:get_method("get_Point"); -- static, retval
local subPoint_method = VillagePoint_type_def:get_method("subPoint(System.UInt32)"); -- static

local get_TradeFunc_method = Constants.SDK.find_type_definition("snow.facility.TradeCenterFacility"):get_method("get_TradeFunc"); -- retval

local TradeFunc_type_def = get_TradeFunc_method:get_return_type();
local get_TradeOrderList_method = TradeFunc_type_def:get_method("get_TradeOrderList"); -- retval
local getNegotiationData_method = TradeFunc_type_def:get_method("getNegotiationData(snow.facility.tradeCenter.NegotiationTypes)"); -- retval

local TradeOrderList_type_def = get_TradeOrderList_method:get_return_type();
local TradeOrderList_get_Count_method = TradeOrderList_type_def:get_method("get_Count"); -- retval
local TradeOrderList_get_Item_method = TradeOrderList_type_def:get_method("get_Item(System.Int32)"); -- retval

local NegotiationData_type_def = getNegotiationData_method:get_return_type();
local get_Cost_method = NegotiationData_type_def:get_method("get_Cost"); -- retval
local NegotiationData_get_Count_method = NegotiationData_type_def:get_method("get_Count"); -- retval

local TradeOrder_type_def = Constants.SDK.find_type_definition("snow.facility.tradeCenter.TradeOrderData");
local initialize_method = TradeOrder_type_def:get_method("initialize");
local get_InventoryList_method = TradeOrder_type_def:get_method("get_InventoryList"); -- retval
local get_NegotiationCount_method = TradeOrder_type_def:get_method("get_NegotiationCount"); -- retval
local setNegotiationCount_method = TradeOrder_type_def:get_method("setNegotiationCount(System.UInt32)");
local get_NegotiationType_method = TradeOrder_type_def:get_method("get_NegotiationType"); -- retval

local InventoryList_type_def = get_InventoryList_method:get_return_type();
local InventoryList_get_Count_method = InventoryList_type_def:get_method("get_Count"); -- retval
local InventoryList_get_Item_method = InventoryList_type_def:get_method("get_Item(System.Int32)"); -- retval

local Inventory_type_def = InventoryList_get_Item_method:get_return_type();
local isEmpty_method = Inventory_type_def:get_method("isEmpty"); -- retval
local Inventory_get_Count_method = Inventory_type_def:get_method("get_Count"); -- retval
local sendInventory_method = Inventory_type_def:get_method("sendInventory(snow.data.ItemInventoryData, snow.data.ItemInventoryData, System.UInt32)");

local SendInventoryResult_AllSended = sendInventory_method:get_return_type():get_field("AllSended"):get_data(nil);
--
local VillageAreaManager_type_def = Constants.SDK.find_type_definition("snow.VillageAreaManager");
local get__CurrentAreaNo_method = VillageAreaManager_type_def:get_method("get__CurrentAreaNo"); -- retval
local set__CurrentAreaNo_method = VillageAreaManager_type_def:get_method("set__CurrentAreaNo(snow.stage.StageDef.AreaNoType)");

local AreaNoType_type_def = get__CurrentAreaNo_method:get_return_type();
local BUDDY_PLAZA = AreaNoType_type_def:get_field("No02"):get_data(nil);
local OUTPOST = AreaNoType_type_def:get_field("No06"):get_data(nil);
--
local ProgressOwlNestManager_type_def = Constants.SDK.find_type_definition("snow.progress.ProgressOwlNestManager");
local Owl_supply_method = ProgressOwlNestManager_type_def:get_method("supply");
local get_SaveData_method = ProgressOwlNestManager_type_def:get_method("get_SaveData"); -- retval

local progressOwlNestSaveData_type_def = get_SaveData_method:get_return_type();
local kamuraStackCount_field = progressOwlNestSaveData_type_def:get_field("_StackCount");
local elgadoStackCount_field = progressOwlNestSaveData_type_def:get_field("_StackCount2");
--
local ProgressGoodRewardManager_type_def = Constants.SDK.find_type_definition("snow.progress.ProgressGoodRewardManager");
local checkReward_method = ProgressGoodRewardManager_type_def:get_method("checkReward");
local supplyReward_method = ProgressGoodRewardManager_type_def:get_method("supplyReward");
--
local ProgressOtomoTicketManager_type_def = Constants.SDK.find_type_definition("snow.progress.ProgressOtomoTicketManager");
local isSupplyItem_method = ProgressOtomoTicketManager_type_def:get_method("isSupplyItem");
local Otomo_supply_method = ProgressOtomoTicketManager_type_def:get_method("supply");
--
local ProgressTicketSupplyManager_type_def = Constants.SDK.find_type_definition("snow.progress.ProgressTicketSupplyManager");
local isEnableSupply_method = ProgressTicketSupplyManager_type_def:get_method("isEnableSupply(snow.progress.ProgressTicketSupplyManager.TicketType)");
local Ticket_supply_method = ProgressTicketSupplyManager_type_def:get_method("supply(snow.progress.ProgressTicketSupplyManager.TicketType)");

local TicketType_type_def = Constants.SDK.find_type_definition("snow.progress.ProgressTicketSupplyManager.TicketType");
local TicketTypes = {
    Village = TicketType_type_def:get_field("Village"):get_data(nil),
    Hall = TicketType_type_def:get_field("Hall"):get_data(nil),
    V02Ticket = TicketType_type_def:get_field("V02Ticket"):get_data(nil),
    MysteryTicket =TicketType_type_def:get_field("MysteryTicket"):get_data(nil)
};
--
local function SendMessage(text)
    if config.EnableNotification then
        local ChatManager = Constants.SDK.get_managed_singleton("snow.gui.ChatManager");
        if ChatManager then
		    reqAddChatInfomation_method:call(ChatManager, text, 2289944406);
        end
	end
end

local function ApplyItemLoadout(loadoutIndex)
    local DataManager = Constants.SDK.get_managed_singleton("snow.data.DataManager");
    if DataManager then
        local ItemMySet = getItemMySet_method:call(DataManager);
        if ItemMySet then
            return applyItemMySet_method:call(ItemMySet, loadoutIndex);
        end
    end
    return nil;
end

local function GetItemLoadoutName(loadoutIndex)
	local ItemLoadout = getData_method:call(getItemMySet_method:call(nil), loadoutIndex);
	if ItemLoadout then
		return PlItemPouchMySetData_get_Name_method:call(ItemLoadout);
	end
    return nil;
end

----------- Equipment Loadout Managementt ----
local function GetCurrentWeaponType()
    local PlayerManager = Constants.SDK.get_managed_singleton("snow.player.PlayerManager");
    if PlayerManager then
        local MasterPlayer = findMasterPlayer_method:call(PlayerManager);
        if MasterPlayer then
            return playerWeaponType_field:get_data(MasterPlayer);
        end
    end
    return nil;
end

local function GetEquipmentLoadout(equipDataManager, loadoutIndex)
    if not equipDataManager then
        equipDataManager = Constants.SDK.get_managed_singleton("snow.data.EquipDataManager");
    end
    local PlEquipMySetList = PlEquipMySetList_field:get_data(equipDataManager);
    if PlEquipMySetList then
        return PlEquipMySetList_get_Item_method:call(PlEquipMySetList, loadoutIndex);
    end
    return nil;
end

local function GetEquipmentLoadoutWeaponType(loadoutIndex)
	local EquipmentLoadout = GetEquipmentLoadout(nil, loadoutIndex);
	if EquipmentLoadout then
		local WeaponData = getWeaponData_method:call(EquipmentLoadout);
		if WeaponData then
			return get_PlWeaponType_method:call(WeaponData);
		end
	end
    return nil;
end

local function GetEquipmentLoadoutName(equipDataManager, loadoutIndex)
	local EquipmentLoadout = GetEquipmentLoadout(equipDataManager, loadoutIndex);
	if EquipmentLoadout then
		return get_Name_method:call(EquipmentLoadout);
	end
    return nil;
end

local function EquipmentLoadoutIsNotEmpty(loadoutIndex)
	local EquipmentLoadout = GetEquipmentLoadout(nil, loadoutIndex);
	if EquipmentLoadout then
		return get_IsUsing_method:call(EquipmentLoadout);
	end
    return nil;
end

local function EquipmentLoadoutIsEquipped(equipDataManager, loadoutIndex)
	local EquipmentLoadout = GetEquipmentLoadout(equipDataManager, loadoutIndex);
	if EquipmentLoadout then
		return isSamePlEquipPack_method:call(EquipmentLoadout);
	end
    return nil;
end

--------------- Temporary Data ----------------
local lastHitLoadoutIndex = -1;

---------------  Localization  ----------------
local LocalizedStrings = {
    ["en-US"] = {
        WeaponNames = {
            [0] = "Great Sword",
            [1] = "Swtich Axe",
            [2] = "Long Sword",
            [3] = "Light Bowgun",
            [4] = "Heavy Bowgun",
            [5] = "Hammer",
            [6] = "Gunlance",
            [7] = "Lance",
            [8] = "Sword & Shield",
            [9] = "Dual Blades",
            [10] = "Hunting Horn",
            [11] = "Charge Blade",
            [12] = "Insect Glaive",
            [13] = "Bow",
        },
        UseDefaultItemSet = "Use Default Setting",
        WeaponTypeNotSetUseDefault = "%s not set, use default setting %s",
        UseWeaponTypeItemSet = "Use %s setting: %s",

        FromLoadout = "Restock for equipment loadout [<COL YEL>%s</COL>] from item loadout [<COL YEL>%s</COL>]",
        MismatchLoadout = "Current equipment doesn't match any equipment loadout.\n",
        FromWeaponType = "Restock for weapon type [<COL YEL>%s</COL>] from item loadout [<COL YEL>%s</COL>].",
        MismatchWeaponType = "Current equipment doesn't match any equipment loadout, and weapon type [<COL YEL>%s</COL>] has no settings.\n",
        FromDefault = "Restock from default item loadout [<COL YEL>%s</COL>].",
        OutOfStock = "Restock [<COL YEL>%s</COL>] cancelled due to <COL RED>out of stock</COL>.",

        PaletteNilError = "<COL RED>ERROR</COL>: Radial set is nil.",
        PaletteApplied = "Radial set [<COL YEL>%s</COL>] applied.",
        PaletteListEmpty = "Radial set list is empty, skipped."
    },
    ["ko-KR"] = {
        WeaponNames = {
            [0] = "대검",
            [1] = "슬래시액스",
            [2] = "태도",
            [3] = "라이트보우건",
            [4] = "헤비보우건",
            [5] = "해머",
            [6] = "건랜스",
            [7] = "랜스",
            [8] = "한손검",
            [9] = "쌍검",
            [10] = "수렵피리",
            [11] = "차지액스",
            [12] = "조충곤",
            [13] = "활",
        },
        UseDefaultItemSet = "기본 설정 사용",
        WeaponTypeNotSetUseDefault = "%s의 설정이 없으므로,\n기본 설정 %s을(를) 사용합니다\n",
        UseWeaponTypeItemSet = "%s의 설정：%s",

        FromLoadout = "장비 프리셋 [<COL YEL>%s</COL>]의 아이템 프리셋 [<COL YEL>%s</COL>] 적용",
        MismatchLoadout = "현재 장비와 일치하는 프리셋이 없습니다.\n",
        FromWeaponType = "무기 유형 [<COL YEL>%s</COL>]의 아이템 프리셋 [<COL YEL>%s</COL>] 적용",
        MismatchWeaponType = "현재 장비와 일치하는 프리셋이 없습니다\n무기 유형 [<COL YEL>%s</COL>]의 설정이 없습니다.\n",
        FromDefault = "기본 아이템 프리셋 [<COL YEL>%s</COL>] 적용",
        OutOfStock = "아이템 프리셋 [<COL YEL>%s</COL>]의 <COL RED>물품이 부족</COL>하여 적용이 취소되었습니다.",

        PaletteNilError = "<COL RED>오류</COL>：팔레트 미설정",
        PaletteApplied = "팔레트 [<COL YEL>%s</COL>] 적용",
        PaletteListEmpty = "팔레트 설정이 비어있습니다"
    }
};

local function Localized()
    return LocalizedStrings[config.Language];
end

local function GetWeaponName(weaponType)
    if weaponType == nil then
		return "<ERROR>:GetWeaponName failed";
	end
	return Localized().WeaponNames[weaponType];
end

local function UseDefaultItemSet()
    return Localized().UseDefaultItemSet;
end

local function WeaponTypeNotSetUseDefault(weaponName, itemName)
    return Constants.LUA.string_format(Localized().WeaponTypeNotSetUseDefault, weaponName, itemName);
end

local function UseWeaponTypeItemSet(weaponName, itemName)
    return Constants.LUA.string_format(Localized().UseWeaponTypeItemSet, weaponName, itemName);
end

local function FromLoadout(equipName, itemName)
    return Constants.LUA.string_format(Localized().FromLoadout, equipName, itemName);
end

local function FromWeaponType(equipName, itemName, mismatch)
    local msg = "";
    if mismatch then
        msg = Localized().MismatchLoadout;
    end
    return msg .. Constants.LUA.string_format(Localized().FromWeaponType, equipName, itemName);
end

local function FromDefault(itemName, mismatch)
    local msg = "";
    if mismatch then
        msg = Constants.LUA.string_format(Localized().MismatchWeaponType, GetWeaponName(GetCurrentWeaponType()));
    end
    return msg .. Constants.LUA.string_format(Localized().FromDefault, itemName);
end

local function OutOfStock(itemName)
    return Constants.LUA.string_format(Localized().OutOfStock, itemName);
end

local function PaletteNilError()
    return Localized().PaletteNilError;
end

local function PaletteApplied(paletteName)
    return Constants.LUA.string_format(Localized().PaletteApplied, paletteName);
end

local function PaletteListEmpty()
    return Localized().PaletteListEmpty;
end

local function EquipmentChanged()
    return "마지막 장비 프리셋 적용 이후 장비가 변경되었습니다.";
end

---------------      CORE      ----------------
local function GetWeaponTypeItemLoadoutName(weaponType)
    local got = config.WeaponTypeConfig[weaponType + 1];
    if got == nil or got == -1 then
        return UseDefaultItemSet();
    end
    return GetItemLoadoutName(got);
end

local function GetLoadoutItemLoadoutIndex(loadoutIndex)
    local got = config.EquipLoadoutConfig[loadoutIndex + 1];
    if got == nil or got == -1 then
        local weaponType = GetEquipmentLoadoutWeaponType(loadoutIndex);
        got = config.WeaponTypeConfig[weaponType + 1];
        if got == nil or got == -1 then
            return WeaponTypeNotSetUseDefault(GetWeaponName(weaponType), GetItemLoadoutName(config.DefaultSet));
        end
        return UseWeaponTypeItemSet(GetWeaponName(weaponType), GetItemLoadoutName(got));
    end
    return GetItemLoadoutName(got);
end

local function AutoChooseItemLoadout(equipDataManager, expectedLoadoutIndex)
    local cacheHit = false;
    local loadoutMismatch = false;
    if expectedLoadoutIndex then
        cacheHit = true;
        lastHitLoadoutIndex = expectedLoadoutIndex;
        local got = config.EquipLoadoutConfig[expectedLoadoutIndex + 1];
        if got ~= nil and got ~= -1 then
            return got, "Loadout", GetEquipmentLoadoutName(equipDataManager, expectedLoadoutIndex);
        end
    else
		if lastHitLoadoutIndex ~= -1 then
            local cachedLoadoutIndex = lastHitLoadoutIndex;
            if EquipmentLoadoutIsEquipped(equipDataManager, cachedLoadoutIndex) then
                lastHitLoadoutIndex = cachedLoadoutIndex;
                cacheHit = true;
                local got = config.EquipLoadoutConfig[cachedLoadoutIndex + 1];
                if got ~= nil and got ~= -1 then
                    return got, "Loadout", GetEquipmentLoadoutName(equipDataManager, cachedLoadoutIndex);
                end
            end
        end
        if not cacheHit then
            local found = false;
            for i = 1, 224, 1 do
                local loadoutIndex = i - 1;
                if EquipmentLoadoutIsEquipped(equipDataManager, loadoutIndex) then
                    found = true;
                    expectedLoadoutIndex = loadoutIndex;
                    lastHitLoadoutIndex = loadoutIndex;
                    local got = config.EquipLoadoutConfig[i];
                    if got ~= nil and got ~= -1 then
                        return got, "Loadout", GetEquipmentLoadoutName(equipDataManager, loadoutIndex);
                    end
                    break;
                end
            end
            if not found then
                loadoutMismatch = true;
            end
        end
    end
    local weaponType = expectedLoadoutIndex and GetEquipmentLoadoutWeaponType(expectedLoadoutIndex) or GetCurrentWeaponType();
    local got = config.WeaponTypeConfig[weaponType + 1];
    if got ~= nil and got ~= -1 then
        return got, "WeaponType", GetWeaponName(weaponType), loadoutMismatch;
    end
    return config.DefaultSet, "Default", "", loadoutMismatch;
end

------------------------
local function Restock(equipDataManager, loadoutIndex)
    local itemLoadoutIndex, matchedType, matchedName, loadoutMismatch = AutoChooseItemLoadout(equipDataManager, loadoutIndex);
    local loadout = getData_method:call(getItemMySet_method:call(nil), itemLoadoutIndex);
    local itemLoadoutName = PlItemPouchMySetData_get_Name_method:call(loadout);
    local msg = "";
    if isEnoughItem_method:call(loadout) then
        ApplyItemLoadout(itemLoadoutIndex);
        msg = matchedType == "Loadout" and FromLoadout(matchedName, itemLoadoutName)
            or matchedType == "WeaponType" and FromWeaponType(matchedName, itemLoadoutName, loadoutMismatch)
            or FromDefault(itemLoadoutName, loadoutMismatch);

        local paletteIndex = get_PaletteSetIndex_method:call(loadout);
        if paletteIndex == nil then
            msg = msg .. "\n" .. PaletteNilError();
        else
            local radialSetIndex = get_HasValue_method:call(paletteIndex) and get_Value_method:call(paletteIndex) or GetValueOrDefault_method:call(paletteIndex);
            if radialSetIndex ~= nil then
                local ShortcutManager = getCustomShortcutSystem_method:call(nil);
                if ShortcutManager then
                    local paletteList = getPaletteSetList_method:call(ShortcutManager, SycleTypes_Quest);
                    if paletteList then
                        local palette = palletteSetData_get_Item_method:call(paletteList, radialSetIndex);
                        if palette ~= nil then
                            msg = msg .. "\n" .. PaletteApplied(palletteSetData_get_Name_method:call(palette));
                        end
                    else
                        msg = msg .. "\n" .. PaletteListEmpty();
                    end
                    setUsingPaletteIndex_method:call(ShortcutManager, SycleTypes_Quest, radialSetIndex);
                end
            end
        end
    else
        msg = OutOfStock(itemLoadoutName);
    end
    SendMessage(msg);
end

local function Supply()
    if config.EnableCohootSupply then
        local ProgressOwlNestManager = Constants.SDK.get_managed_singleton("snow.progress.ProgressOwlNestManager");
        if ProgressOwlNestManager then
            local saveData = get_SaveData_method:call(ProgressOwlNestManager);
            if saveData then
                local kamuraStack = kamuraStackCount_field:get_data(saveData);
                local elgadoStack = elgadoStackCount_field:get_data(saveData);

                local tempNum = 0;
                if kamuraStack >= config.CohootMaxStock then
                    tempNum = tempNum + 1;
                end
                if elgadoStack >= config.CohootMaxStock then
                    tempNum = tempNum + 2;
                end

                if tempNum > 0 then
                    local VillageAreaManager = Constants.SDK.get_managed_singleton("snow.VillageAreaManager");
                    if VillageAreaManager then
                        local savedAreaNo = get__CurrentAreaNo_method:call(VillageAreaManager);
                        if tempNum == 1 then
                            if savedAreaNo == BUDDY_PLAZA then
                                Owl_supply_method:call(ProgressOwlNestManager);
                            else
                                set__CurrentAreaNo_method:call(VillageAreaManager, BUDDY_PLAZA);
                                Owl_supply_method:call(ProgressOwlNestManager);
                                set__CurrentAreaNo_method:call(VillageAreaManager, savedAreaNo);
                            end
                        elseif tempNum == 2 then
                            if savedAreaNo == OUTPOST then
                                Owl_supply_method:call(ProgressOwlNestManager);
                            else
                                set__CurrentAreaNo_method:call(VillageAreaManager, OUTPOST);
                                Owl_supply_method:call(ProgressOwlNestManager);
                                set__CurrentAreaNo_method:call(VillageAreaManager, savedAreaNo);
                            end
                        else
                            if savedAreaNo == BUDDY_PLAZA or savedAreaNo == OUTPOST then
                                Owl_supply_method:call(ProgressOwlNestManager);
                                set__CurrentAreaNo_method:call(VillageAreaManager, savedAreaNo == BUDDY_PLAZA and OUTPOST or BUDDY_PLAZA);
                            else
                                set__CurrentAreaNo_method:call(VillageAreaManager, BUDDY_PLAZA);
                                Owl_supply_method:call(ProgressOwlNestManager);
                                set__CurrentAreaNo_method:call(VillageAreaManager, OUTPOST);
                            end
                            Owl_supply_method:call(ProgressOwlNestManager);
                            set__CurrentAreaNo_method:call(VillageAreaManager, savedAreaNo);
                        end
                    end
                end
            end
        end
    end

    if config.EnableGoodReward then
        local ProgressGoodRewardManager = Constants.SDK.get_managed_singleton("snow.progress.ProgressGoodRewardManager");
        if ProgressGoodRewardManager and checkReward_method:call(ProgressGoodRewardManager) then
            supplyReward_method:call(ProgressGoodRewardManager);
        end
    end

    if config.EnableOtomoTicket then
        local ProgressOtomoTicketManager = Constants.SDK.get_managed_singleton("snow.progress.ProgressOtomoTicketManager");
        if ProgressOtomoTicketManager and isSupplyItem_method:call(ProgressOtomoTicketManager) then
            Otomo_supply_method:call(ProgressOtomoTicketManager);
        end
    end

    if config.EnableTicket then
        local ProgressTicketSupplyManager = Constants.SDK.get_managed_singleton("snow.progress.ProgressTicketSupplyManager");
        if ProgressTicketSupplyManager then
            for _, v in pairs(TicketTypes) do
                if isEnableSupply_method:call(ProgressTicketSupplyManager, v) then
                    Ticket_supply_method:call(ProgressTicketSupplyManager, v);
                end
            end
        end
    end
end

local function autoArgosy()
    local TradeCenterFacility = Constants.SDK.get_managed_singleton("snow.facility.TradeCenterFacility");
    local DataManager = Constants.SDK.get_managed_singleton("snow.data.DataManager");
    if TradeCenterFacility and DataManager then
        local tradeFunc = get_TradeFunc_method:call(TradeCenterFacility);
        if tradeFunc then
            local tradeOrderList = get_TradeOrderList_method:call(tradeFunc);
            if tradeOrderList then
                local tradeOrderList_count = TradeOrderList_get_Count_method:call(tradeOrderList);
                if tradeOrderList_count > 0 then
                    local isReceived = false;
                    for i = 0, tradeOrderList_count - 1, 1 do
                        local tradeOrder = TradeOrderList_get_Item_method:call(tradeOrderList, i);
                        if tradeOrder then
                            local negotiationCount = get_NegotiationCount_method:call(tradeOrder);
                            if negotiationCount == 1 then
                                local negotiationData = getNegotiationData_method:call(tradeFunc, get_NegotiationType_method:call(tradeOrder));
                                if negotiationData then
                                    local negotiationCost = get_Cost_method:call(negotiationData);
                                    if negotiationCost ~= nil and get_Point_method:call(nil) >= negotiationCost then
                                        setNegotiationCount_method:call(tradeOrder, negotiationCount + NegotiationData_get_Count_method:call(negotiationData));
                                        subPoint_method:call(nil, negotiationCost);
                                    end
                                end
                            end

                            local inventoryList = get_InventoryList_method:call(tradeOrder);
                            if inventoryList then
                                local inventoryList_count = InventoryList_get_Count_method:call(inventoryList);
                                if inventoryList_count > 0 then
                                    for j = 0, inventoryList_count - 1, 1 do
                                        local inventory = InventoryList_get_Item_method:call(inventoryList, i);
                                        if inventory and not isEmpty_method:call(inventory) then
                                            if sendInventory_method:call(inventory, inventory, inventory, 65536) ~= SendInventoryResult_AllSended then
                                                trySellGameItem_method:call(DataManager, inventory, Inventory_get_Count_method:call(inventory));
                                            end
                                            isReceived = true;
                                        end
                                    end
                                end
                            end

                            initialize_method:call(tradeOrder);
                        end
                    end
                    if isReceived then
                        SendMessage("교역선 아이템을 받았습니다");
                    end
                end
            end
        end
    end
end

local EquipDataManager = nil;
local setIdx = nil;
Constants.SDK.hook(Constants.type_definitions.EquipDataManager_type_def:get_method("applyEquipMySet(System.Int32)"), function(args)
    if config.Enabled then
        EquipDataManager = Constants.SDK.to_managed_object(args[2]);
        setIdx = Constants.SDK.to_int64(args[3]) & 0xFFFFFFFF;
    end
end, function(retval)
    if EquipDataManager then
        if setIdx ~= nil then
            Restock(EquipDataManager, setIdx);
        else
            Restock(EquipDataManager, nil);
        end
    else
        if setIdx ~= nil then
            Restock(nil, setIdx);
        else
            if config.Enabled then
                Restock(nil, nil);
            end
        end
    end
    EquipDataManager = nil;
    setIdx = nil;
    return retval;
end);
Constants.SDK.hook(Constants.SDK.find_type_definition("snow.gui.fsm.camp.GuiCampFsmManager"):get_method("start"), nil, function()
    if config.Enabled then
        Restock(nil, nil);
    end
end);
Constants.SDK.hook(Constants.SDK.find_type_definition("snow.wwise.WwiseChangeSpaceWatcher"):get_method("onVillageStart"), nil, function()
    if config.EnableArgosy then
        autoArgosy();
    end
    if config.Enabled then
        Restock(nil, nil);
    end
    Supply();
end);
----------------------------------------------
local function save_config()
    Constants.JSON.dump_file("AutoSupply.json", config);
end

Constants.RE.on_config_save(save_config);
Constants.RE.on_draw_ui(function()
    if Constants.IMGUI.tree_node("AutoSupply") then
        Constants.IMGUI.push_font(Constants.Font);
        local config_changed = false;
        local changed = false;
        config_changed, config.Enabled = Constants.IMGUI.checkbox("Enabled", config.Enabled);
        changed, config.EnableNotification = Constants.IMGUI.checkbox("EnableNotification", config.EnableNotification);
        config_changed = config_changed or changed;
        changed, config.EnableCohoot = Constants.IMGUI.checkbox("EnableCohootSupply", config.EnableCohoot);
        config_changed = config_changed or changed;
        changed, config.EnableGoodReward = Constants.IMGUI.checkbox("EnableGoodRewardSupply", config.EnableGoodReward);
        config_changed = config_changed or changed;
        changed, config.EnableOtomoTicket = Constants.IMGUI.checkbox("EnableOtomoTicketSupply", config.EnableOtomoTicket);
        config_changed = config_changed or changed;
        changed, config.EnableTicket = Constants.IMGUI.checkbox("EnableTicketSupply", config.EnableTicket);
        config_changed = config_changed or changed;
        changed, config.EnableArgosy = Constants.IMGUI.checkbox("EnableArgosy", config.EnableArgosy);
        config_changed = config_changed or changed;

        local langChanged, new_langIdx = Constants.IMGUI.combo("Language", Constants.FindIndex(Languages, config.Language), Languages);
        config_changed = config_changed or langChanged;
        if langChanged then
            config.Language = Languages[new_langIdx];
        end

        changed, config.DefaultSet = Constants.IMGUI.slider_int("Default ItemSet", config.DefaultSet, 0, 39, GetItemLoadoutName(config.DefaultSet));
        config_changed = config_changed or changed;

        if Constants.IMGUI.tree_node("WeaponType") then
            for i = 1, 14, 1 do
                local weaponType = i - 1;
                changed, config.WeaponTypeConfig[i] = Constants.IMGUI.slider_int(GetWeaponName(weaponType), config.WeaponTypeConfig[i], -1, 39, GetWeaponTypeItemLoadoutName(weaponType));
                config_changed = config_changed or changed;
            end
            Constants.IMGUI.tree_pop();
        end

        if Constants.IMGUI.tree_node("Loadout") then
            for i = 1, 224, 1 do
                local loadoutIndex = i - 1;
                local name = GetEquipmentLoadoutName(nil, loadoutIndex);
                if name and EquipmentLoadoutIsNotEmpty(loadoutIndex) then
                    local msg = "";
                    if EquipmentLoadoutIsEquipped(nil, loadoutIndex) then 
                        msg = " (현재)";
                    end
                    changed, config.EquipLoadoutConfig[i] = Constants.IMGUI.slider_int(name .. msg, config.EquipLoadoutConfig[i], -1, 39, GetLoadoutItemLoadoutIndex(loadoutIndex));
                    config_changed = config_changed or changed;
                end
            end
            Constants.IMGUI.tree_pop();
        end

        if Constants.IMGUI.tree_node("Auto cohoot nest") then
            changed, config.CohootMaxStock = Constants.IMGUI.slider_int("Maximum stock", config.CohootMaxStock, 1, 5);
            config_changed = config_changed or changed;
            Constants.IMGUI.tree_pop();
        end
        if config_changed then
            save_config();
        end
        Constants.IMGUI.pop_font();
        Constants.IMGUI.tree_pop();
    end
end);