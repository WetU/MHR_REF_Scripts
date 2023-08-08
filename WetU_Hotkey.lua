local Constants = _G.require("Constants.Constants");

local find_type_definition = Constants.sdk.find_type_definition;
local to_managed_object = Constants.sdk.to_managed_object;
local get_managed_singleton = Constants.sdk.get_managed_singleton;
local hook = Constants.sdk.hook;

local TRUE_POINTER = Constants.TRUE_POINTER;

local checkKeyTrg = Constants.checkKeyTrg;
local F5 = Constants.Keys.F5;
local F6 = Constants.Keys.F6;
local F8 = Constants.Keys.F8;

local getPlayerData = Constants.getPlayerData;
local get_VillagePoint = Constants.get_VillagePoint;
local getMealTicketCount = Constants.getMealTicketCount;
local setMealTicket = Constants.setMealTicket;
local DangoLogStart = Constants.DangoLogStart;

local to_bool = Constants.to_bool;

-- in Village hotkeys
local VillageAreaManager_type_def = Constants.type_definitions.VillageAreaManager_type_def;
local fastTravel_method = VillageAreaManager_type_def:get_method("fastTravel(snow.stage.StageDef.VillageFastTravelType)");

local VillageFastTravelType_type_def = find_type_definition("snow.stage.StageDef.VillageFastTravelType");
local ELGADO_CHICHE = VillageFastTravelType_type_def:get_field("v02a06_00"):get_data(nil);
local ELGADO_KITCHEN = VillageFastTravelType_type_def:get_field("v02a06_01"):get_data(nil);
--
local get_Kitchen_method = Constants.type_definitions.FacilityDataManager_type_def:get_method("get_Kitchen");

local get_MealFunc_method = get_Kitchen_method:get_return_type():get_method("get_MealFunc");

local MealFunc_type_def = Constants.type_definitions.MealFunc_type_def;
local checkAvailableMealSystem_method = MealFunc_type_def:get_method("checkAvailableMealSystem");
local setWaitTimer_method = MealFunc_type_def:get_method("setWaitTimer");
local getHandMoneyCost_method = MealFunc_type_def:get_method("getHandMoneyCost");
local getVillagePointCost_method = MealFunc_type_def:get_method("getVillagePointCost");
local get_FacilityLv_method = MealFunc_type_def:get_method("get_FacilityLv");
local getVitalBuff_method = MealFunc_type_def:get_method("getVitalBuff(System.UInt32)");
local getStaminaBuff_method = MealFunc_type_def:get_method("getStaminaBuff(System.UInt32)");
local order_method = MealFunc_type_def:get_method("order(snow.facility.MealOrderData, snow.facility.kitchen.MealFunc.PaymentTypes, System.UInt32)");
local get_MySetDataList_method = MealFunc_type_def:get_method("get_MySetDataList");
local get_DailyDango_method = MealFunc_type_def:get_method("get_DailyDango");
local resetDailyDango_method = MealFunc_type_def:get_method("resetDailyDango");

local MySetDataList_get_Item_method = get_MySetDataList_method:get_return_type():get_method("get_Item(System.Int32)");
--
local getHandMoney_method = Constants.type_definitions.DataManager_type_def:get_method("getHandMoney");

local isEnough_method = getHandMoney_method:get_return_type():get_method("isEnough(System.UInt32)");
--
local getMasterPlayer_method = find_type_definition("snow.npc.NpcUtility"):get_method("getMasterPlayer"); -- static

local get_PlayerSkillList_method = Constants.type_definitions.PlayerBase_type_def:get_method("get_PlayerSkillList");

local get_KitchenSkillData_method = get_PlayerSkillList_method:get_return_type():get_method("get_KitchenSkillData");
--
local DangoLogParam_type_def = find_type_definition("snow.gui.GuiDangoLog.DangoLogParam");
local setStatusParam_method = DangoLogParam_type_def:get_method("setStatusParam(snow.gui.GuiDangoLog.DangoLogParam.DangoLogStatusItemType, System.UInt32)");
--
local DangoLogStatusItemType_type_def = find_type_definition("snow.gui.GuiDangoLog.DangoLogParam.DangoLogStatusItemType");
local DangoLogStatusItemType = {
    Vital = DangoLogStatusItemType_type_def:get_field("Vital"):get_data(nil),
    Stamina = DangoLogStatusItemType_type_def:get_field("Stamina"):get_data(nil)
};

local DailyDango_type_def = get_DailyDango_method:get_return_type();
local DailyDango = {
    [DailyDango_type_def:get_field("Dango_035"):get_data(nil)] = true,  -- 보수금 보험
    [DailyDango_type_def:get_field("Dango_041"):get_data(nil)] = true,  -- 환산술
    [DailyDango_type_def:get_field("Dango_042"):get_data(nil)] = true,  -- 금전운
    [DailyDango_type_def:get_field("Dango_045"):get_data(nil)] = true,  -- 행운술
    [DailyDango_type_def:get_field("Dango_046"):get_data(nil)] = true   -- 격운술
};

local PaymentTypes_type_def = find_type_definition("snow.facility.kitchen.MealFunc.PaymentTypes");
local PaymentTypes = {
    Money = PaymentTypes_type_def:get_field("Money"):get_data(nil),
    VillagePoint = PaymentTypes_type_def:get_field("VillagePoint"):get_data(nil)
};
--
local isOrdering = false;

local function makeDangoLogParam(mealFunc, facilityLv, masterPlayerBase)
    local DangoLogParam = DangoLogParam_type_def:create_instance();
    setStatusParam_method:call(DangoLogParam, DangoLogStatusItemType.Vital, getVitalBuff_method:call(mealFunc, facilityLv));
    setStatusParam_method:call(DangoLogParam, DangoLogStatusItemType.Stamina, getStaminaBuff_method:call(mealFunc, facilityLv));
    DangoLogParam:set_field("_SkillDataList", get_KitchenSkillData_method:call(get_PlayerSkillList_method:call(masterPlayerBase)));
    return DangoLogParam;
end

local function village_Body(villageAreaManager)
    if checkKeyTrg(F5) == true or checkKeyTrg(F6) == true then
        local fastTravelType = checkKeyTrg(F5) == true and ELGADO_CHICHE
            or checkKeyTrg(F6) == true and ELGADO_KITCHEN
            or nil;

        if fastTravelType ~= nil then
            fastTravel_method:call(villageAreaManager, fastTravelType);
        end

    elseif checkKeyTrg(F8) == true then
        local MealFunc = get_MealFunc_method:call(get_Kitchen_method:call(get_managed_singleton("snow.data.FacilityDataManager")));

        if checkAvailableMealSystem_method:call(MealFunc) == true then
            local paymentType = isEnough_method:call(getHandMoney_method:call(get_managed_singleton("snow.data.DataManager")), getHandMoneyCost_method:call(MealFunc)) == true and PaymentTypes.Money
                or get_VillagePoint() >= getVillagePointCost_method:call(MealFunc) and PaymentTypes.VillagePoint
                or nil;

            if paymentType ~= nil then
                resetDailyDango_method:call(MealFunc);
                local FacilityLv = get_FacilityLv_method:call(MealFunc);
                setMealTicket(MealFunc, getMealTicketCount() > 0);

                isOrdering = true;
                order_method:call(MealFunc, MySetDataList_get_Item_method:call(get_MySetDataList_method:call(MealFunc), DailyDango[get_DailyDango_method:call(MealFunc)] == true and 0 or 1), paymentType, FacilityLv);
                isOrdering = false;

                local MasterPlayerBase = getMasterPlayer_method:call(nil);
                local MasterPlayerData = getPlayerData(MasterPlayerBase);
                MasterPlayerData:set_field("_vitalMax", MasterPlayerData:get_field("_vitalMax") + 50);
                MasterPlayerData:set_field("_staminaMax", MasterPlayerData:get_field("_staminaMax") + 1500.0);

                setWaitTimer_method:call(MealFunc);
                DangoLogStart(makeDangoLogParam(MealFunc, FacilityLv, MasterPlayerBase));
            end
        end
    end
end

local VillageAreaManager = nil;
local function PreHook_villageUpdate(args)
    VillageAreaManager = to_managed_object(args[2]) or get_managed_singleton("snow.VillageAreaManager");
    village_Body(VillageAreaManager);
end
local function PostHook_villageUpdate()
    village_Body(VillageAreaManager);
    VillageAreaManager = nil;
end
hook(VillageAreaManager_type_def:get_method("update"), PreHook_villageUpdate, PostHook_villageUpdate);

local function PostHook_canOrder(retval)
    if to_bool(retval) ~= true and isOrdering == true then
        return TRUE_POINTER;
    end

    return retval;
end
hook(MySetDataList_get_Item_method:get_return_type():get_method("canOrder"), nil, PostHook_canOrder);

-- Reset Quest hotkey
local QuestManager_type_def = Constants.type_definitions.QuestManager_type_def;
local notifyReset_method = QuestManager_type_def:get_method("notifyReset");

local function reset_Body(questManager)
    if checkKeyTrg(F5) == true then
		notifyReset_method:call(questManager);
	end
end

local QuestManager = nil;
local function PreHook_updateNormalQuest(args)
    QuestManager = to_managed_object(args[2]) or get_managed_singleton("snow.QuestManager");
	reset_Body(QuestManager);
end
local function PostHook_updateNormalQuest()
    reset_Body(QuestManager);
    QuestManager = nil;
end
hook(QuestManager_type_def:get_method("updateNormalQuest"), PreHook_updateNormalQuest, PostHook_updateNormalQuest);