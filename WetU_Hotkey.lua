local Constants = _G.require("Constants.Constants");

local find_type_definition = Constants.sdk.find_type_definition;
local get_managed_singleton = Constants.sdk.get_managed_singleton;
local hook = Constants.sdk.hook;

local TRUE_POINTER = Constants.TRUE_POINTER;

local checkKeyTrg = Constants.checkKeyTrg;
local Keys = Constants.Keys;

local SendMessage = Constants.SendMessage;
local getKitchenFacility = Constants.getKitchenFacility;
local getMasterPlayerBase = Constants.getMasterPlayerBase;
local getPlayerData = Constants.getPlayerData;

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

local MealFunc_type_def = get_MealFunc_method:get_return_type();
local setWaitTimer_method = MealFunc_type_def:get_method("setWaitTimer");
local checkAvailableMealSystem_method = MealFunc_type_def:get_method("checkAvailableMealSystem");
local checkHandMoney_method = MealFunc_type_def:get_method("checkHandMoney");
local checkVillagePoint_method = MealFunc_type_def:get_method("checkVillagePoint");
local setMealTicketFlag_method = MealFunc_type_def:get_method("setMealTicketFlag(System.Boolean)");
local getMealTicketNum_method = MealFunc_type_def:get_method("getMealTicketNum");
local get_FacilityLv_method = MealFunc_type_def:get_method("get_FacilityLv");
local getVitalBuff_method = MealFunc_type_def:get_method("getVitalBuff(System.UInt32)");
local getStaminaBuff_method = MealFunc_type_def:get_method("getStaminaBuff(System.UInt32)");
local addBuff_method = MealFunc_type_def:get_method("addBuff(System.UInt32)");
local order_method = MealFunc_type_def:get_method("order(snow.facility.MealOrderData, snow.facility.kitchen.MealFunc.PaymentTypes, System.UInt32)");
local get_MySetDataList_method = MealFunc_type_def:get_method("get_MySetDataList");
local get_DailyDango_method = MealFunc_type_def:get_method("get_DailyDango");
local resetDailyDango_method = MealFunc_type_def:get_method("resetDailyDango");
--
local GuiManager_type_def = Constants.type_definitions.GuiManager_type_def;
local get_refGuiDangoLog_method = GuiManager_type_def:get_method("get_refGuiDangoLog");
local reqDangoLogStart_method = GuiManager_type_def:get_method("reqDangoLogStart(snow.gui.GuiDangoLog.DangoLogParam, System.Single)");

local updateSkillList_method = get_refGuiDangoLog_method:get_return_type():get_method("updateSkillList(snow.gui.GuiDangoLog.DangoLogParam)");
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
local function makeDangoLogParam(vitalBuff, staminaBuff)
	local DangoLogParam = DangoLogParam_type_def:create_instance();
	setStatusParam_method:call(DangoLogParam, DangoLogStatusItemType[1], vitalBuff);
	setStatusParam_method:call(DangoLogParam, DangoLogStatusItemType[2], staminaBuff);

	local GuiManager = get_managed_singleton("snow.gui.GuiManager");
	updateSkillList_method:call(get_refGuiDangoLog_method:call(GuiManager), DangoLogParam);
	return GuiManager, DangoLogParam;
end

local isOrdering = false;
local function PostHook_villageUpdate()
	if checkKeyTrg(Keys.F5) == true then
		fastTravel_method:call(get_managed_singleton("snow.VillageAreaManager"), VillageFastTravelType.ELGADO_CHICHE);

	elseif checkKeyTrg(Keys.F6) == true then
		fastTravel_method:call(get_managed_singleton("snow.VillageAreaManager"), VillageFastTravelType.ELGADO_KITCHEN);

	elseif checkKeyTrg(Keys.F8) == true then
		local MealFunc = get_MealFunc_method:call(getKitchenFacility());

		if checkAvailableMealSystem_method:call(MealFunc) == true then
			local paymentType = checkHandMoney_method:call(MealFunc) == true and PaymentTypes[1]
				or checkVillagePoint_method:call(MealFunc) == true and PaymentTypes[2]
				or nil;

			if paymentType ~= nil then
				local MealTicketNum = getMealTicketNum_method:call(MealFunc);
				local FacilityLv = get_FacilityLv_method:call(MealFunc);
				local VitalBuff = getVitalBuff_method:call(MealFunc, FacilityLv);
				local StaminaBuff = getStaminaBuff_method:call(MealFunc, FacilityLv);
				resetDailyDango_method:call(MealFunc);
				if MealTicketNum == nil or MealTicketNum <= 0 then
					SendMessage(nil, "식사권이 없습니다!");
					setMealTicketFlag_method:call(MealFunc, false);
				else
					setMealTicketFlag_method:call(MealFunc, true);
				end

				isOrdering = true;
				order_method:call(MealFunc, get_MySetDataList_method:call(MealFunc):get_element(DailyDango[get_DailyDango_method:call(MealFunc)] == true and 0 or 1), paymentType, FacilityLv);
				isOrdering = false;

				local MasterPlayerData = getPlayerData(getMasterPlayerBase());
				MasterPlayerData:set_field("_vitalMax", MasterPlayerData:get_field("_vitalMax") + VitalBuff);
				MasterPlayerData:set_field("_staminaMax", MasterPlayerData:get_field("_staminaMax") + (StaminaBuff * 30.0));
				addBuff_method:call(MealFunc, FacilityLv);

				setWaitTimer_method:call(MealFunc);

				local GuiManager, DangoLogParam = makeDangoLogParam(VitalBuff, StaminaBuff);
				reqDangoLogStart_method:call(GuiManager, DangoLogParam, 5.0);
				DangoLogParam:force_release();
			end
		end
	end
end
hook(VillageAreaManager_type_def:get_method("update"), nil, PostHook_villageUpdate);

local function PostHook_canOrder(retval)
	return isOrdering == true and TRUE_POINTER or retval;
end
hook(find_type_definition("snow.facility.MealOrderData"):get_method("canOrder"), nil, PostHook_canOrder);

-- Reset Quest hotkey
local QuestManager_type_def = Constants.type_definitions.QuestManager_type_def;
local notifyReset_method = QuestManager_type_def:get_method("notifyReset");

local function PostHook_updateNormalQuest()
	if checkKeyTrg(Keys.F5) == true then
		notifyReset_method:call(get_managed_singleton("snow.QuestManager"));
	end
end
hook(QuestManager_type_def:get_method("updateNormalQuest"), nil, PostHook_updateNormalQuest);