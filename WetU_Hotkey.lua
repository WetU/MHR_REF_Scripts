local Constants = _G.require("Constants.Constants");

local pairs = Constants.lua.pairs;

local create_managed_array = Constants.sdk.create_managed_array;
local find_type_definition = Constants.sdk.find_type_definition;
local to_managed_object = Constants.sdk.to_managed_object;
local get_managed_singleton = Constants.sdk.get_managed_singleton;
local hook = Constants.sdk.hook;

local TRUE_POINTER = Constants.TRUE_POINTER;

local checkKeyTrg = Constants.checkKeyTrg;
local Keys = Constants.Keys;

local getKitchenFacility = Constants.getKitchenFacility;
local getVillagePoint = Constants.getVillagePoint;
local setMealTicketFlag = Constants.setMealTicketFlag;
local getPlayerData = Constants.getPlayerData;
local reqDangoLogStart = Constants.reqDangoLogStart;

-- in Village hotkeys
local VillageAreaManager_type_def = Constants.type_definitions.VillageAreaManager_type_def;
local fastTravel_method = VillageAreaManager_type_def:get_method("fastTravel(snow.stage.StageDef.VillageFastTravelType)");

local VillageFastTravelType_type_def = find_type_definition("snow.stage.StageDef.VillageFastTravelType");
local VillageFastTravelType = {
    ELGADO_CHICHE = VillageFastTravelType_type_def:get_field("v02a06_00"):get_data(nil),
    ELGADO_KITCHEN = VillageFastTravelType_type_def:get_field("v02a06_01"):get_data(nil)
};
--
local get_MealFunc_method = Constants.type_definitions.KitchenFacility_type_def:get_method("get_MealFunc");

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
--
local getHandMoney_method = Constants.type_definitions.DataManager_type_def:get_method("getHandMoney");

local isEnough_method = getHandMoney_method:get_return_type():get_method("isEnough(System.UInt32)");
--
local getMasterPlayer_method = find_type_definition("snow.npc.NpcUtility"):get_method("getMasterPlayer"); -- static

local get_PlayerSkillList_method = Constants.type_definitions.PlayerBase_type_def:get_method("get_PlayerSkillList");

local get_KitchenSkillData_method = get_PlayerSkillList_method:get_return_type():get_method("get_KitchenSkillData");

local PlayerKitchenSkillData_type_def = find_type_definition("snow.player.PlayerKitchenSkillData");
local SkillId_field = PlayerKitchenSkillData_type_def:get_field("_SkillId");
--
local DangoLogParam_type_def = find_type_definition("snow.gui.GuiDangoLog.DangoLogParam");
local setStatusParam_method = DangoLogParam_type_def:get_method("setStatusParam(snow.gui.GuiDangoLog.DangoLogParam.DangoLogStatusItemType, System.UInt32)");
--
local DangoLogStatusItemType_type_def = find_type_definition("snow.gui.GuiDangoLog.DangoLogParam.DangoLogStatusItemType");
local DangoLogStatusItemType = {
    DangoLogStatusItemType_type_def:get_field("Vital"):get_data(nil),
    DangoLogStatusItemType_type_def:get_field("Stamina"):get_data(nil)
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
    PaymentTypes_type_def:get_field("Money"):get_data(nil),
    PaymentTypes_type_def:get_field("VillagePoint"):get_data(nil)
};
--
local function makeDangoLogParam(mealFunc, facilityLv, masterPlayerBase)
    local DangoLogParam = DangoLogParam_type_def:create_instance();
    setStatusParam_method:call(DangoLogParam, DangoLogStatusItemType[1], getVitalBuff_method:call(mealFunc, facilityLv));
    setStatusParam_method:call(DangoLogParam, DangoLogStatusItemType[2], getStaminaBuff_method:call(mealFunc, facilityLv));
    local kitchenSkillData = get_KitchenSkillData_method:call(get_PlayerSkillList_method:call(masterPlayerBase));

    local skillCopy = {};
    local activeCount = 0;

    for i = 0, kitchenSkillData:get_size() - 1, 1 do
        local skill = kitchenSkillData:get_element(i);
        if SkillId_field:get_data(skill) == 0 then
            break;
        end

        skillCopy[i] = skill;
        activeCount = activeCount + 1;
    end

    local newArray = create_managed_array(PlayerKitchenSkillData_type_def, activeCount);

    for index, activeSkill in pairs(skillCopy) do
        newArray[index] = activeSkill;
    end

    DangoLogParam:set_field("_SkillDataList", newArray);
    return DangoLogParam;
end

local isOrdering = false;
local function PreHook_villageUpdate(args)
    if checkKeyTrg(Keys.F5) == true then
        fastTravel_method:call(to_managed_object(args[2]) or get_managed_singleton("snow.VillageAreaManager"), VillageFastTravelType.ELGADO_CHICHE);

    elseif checkKeyTrg(Keys.F6) == true then
        fastTravel_method:call(to_managed_object(args[2]) or get_managed_singleton("snow.VillageAreaManager"), VillageFastTravelType.ELGADO_KITCHEN);

    elseif checkKeyTrg(Keys.F8) == true then
        local MealFunc = get_MealFunc_method:call(getKitchenFacility());

        if checkAvailableMealSystem_method:call(MealFunc) == true then
            local paymentType = isEnough_method:call(getHandMoney_method:call(get_managed_singleton("snow.data.DataManager")), getHandMoneyCost_method:call(MealFunc)) == true and PaymentTypes[1]
                or getVillagePoint() >= getVillagePointCost_method:call(MealFunc) and PaymentTypes[2]
                or nil;

            if paymentType ~= nil then
                resetDailyDango_method:call(MealFunc);
                local FacilityLv = get_FacilityLv_method:call(MealFunc);
                setMealTicketFlag(MealFunc);

                isOrdering = true;
                order_method:call(MealFunc, get_MySetDataList_method:call(MealFunc):get_element(DailyDango[get_DailyDango_method:call(MealFunc)] == true and 0 or 1), paymentType, FacilityLv);
                isOrdering = false;

                local MasterPlayerBase = getMasterPlayer_method:call(nil);
                local MasterPlayerData = getPlayerData(MasterPlayerBase);
                MasterPlayerData:set_field("_vitalMax", MasterPlayerData:get_field("_vitalMax") + 50);
                MasterPlayerData:set_field("_staminaMax", MasterPlayerData:get_field("_staminaMax") + 1500.0);

                setWaitTimer_method:call(MealFunc);
                reqDangoLogStart(makeDangoLogParam(MealFunc, FacilityLv, MasterPlayerBase));
            end
        end
    end
end
hook(VillageAreaManager_type_def:get_method("update"), PreHook_villageUpdate);

local function PostHook_canOrder(retval)
    return isOrdering == true and TRUE_POINTER or retval;
end
hook(find_type_definition("snow.facility.MealOrderData"):get_method("canOrder"), nil, PostHook_canOrder);

-- Reset Quest hotkey
local QuestManager_type_def = Constants.type_definitions.QuestManager_type_def;
local notifyReset_method = QuestManager_type_def:get_method("notifyReset");

local function PreHook_updateNormalQuest(args)
	if checkKeyTrg(Keys.F5) == true then
		notifyReset_method:call(to_managed_object(args[2]) or get_managed_singleton("snow.QuestManager"));
	end
end
hook(QuestManager_type_def:get_method("updateNormalQuest"), PreHook_updateNormalQuest);