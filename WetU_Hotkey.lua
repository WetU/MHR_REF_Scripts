local Constants = _G.require("Constants.Constants");

local math_min = Constants.lua.math_min;

local create_managed_array = Constants.sdk.create_managed_array;
local find_type_definition = Constants.sdk.find_type_definition;
local to_managed_object = Constants.sdk.to_managed_object;
local hook = Constants.sdk.hook;
local hook_vtable = Constants.sdk.hook_vtable;

local TRUE_POINTER = Constants.TRUE_POINTER;

local checkKeyTrg = Constants.checkKeyTrg;
local getVillagePoint = Constants.getVillagePoint;
local subVillagePoint = Constants.subVillagePoint;
local SendMessage = Constants.SendMessage;

-- in Village hotkeys
local VillageAreaManager_type_def = Constants.type_definitions.VillageAreaManager_type_def;
local fastTravel_method = VillageAreaManager_type_def:get_method("fastTravel(snow.stage.StageDef.VillageFastTravelType)");
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
local BbqFunc_type_def = Constants.type_definitions.BbqFunc_type_def;
local get_CanUseFunc_method = BbqFunc_type_def:get_method("get_CanUseFunc");
local get_MealConvertDataList_method = BbqFunc_type_def:get_method("get_MealConvertDataList");
local orderBbq_method = BbqFunc_type_def:get_method("orderBbq(snow.facility.kitchen.BbqConvertData, System.UInt32)");
local isExistOutputTicket_method = BbqFunc_type_def:get_method("isExistOutputTicket");

local MealConvertDataList_get_Item_method = get_MealConvertDataList_method:get_return_type():get_method("get_Item(System.Int32)");

local BbqConvertData_type_def = MealConvertDataList_get_Item_method:get_return_type();
local get_MoneyCost_method = BbqConvertData_type_def:get_method("get_MoneyCost");
local get_PointCost_method = BbqConvertData_type_def:get_method("get_PointCost");
--
local DataShortcut_type_def = Constants.type_definitions.DataShortcut_type_def;
local get_HandMoney_method = DataShortcut_type_def:get_method("get_HandMoney"); -- static
local getMoneyVal_method = DataShortcut_type_def:get_method("getMoneyVal"); -- static
local addItemToBox_method = DataShortcut_type_def:get_method("addItemToBox(snow.data.ContentsIdSystem.ItemId, System.UInt32)"); -- static
--
local getCountOfAll_method = find_type_definition("snow.data.ContentsIdDataManager"):get_method("getCountOfAll(snow.data.ContentsIdSystem.ItemId)");
--
local reqDangoLogStart_method = Constants.type_definitions.GuiManager_type_def:get_method("reqDangoLogStart(snow.gui.GuiDangoLog.DangoLogParam, System.Single)");
--
local DangoLogParam_type_def = find_type_definition("snow.gui.GuiDangoLog.DangoLogParam");
local setStatusParam_method = DangoLogParam_type_def:get_method("setStatusParam(snow.gui.GuiDangoLog.DangoLogParam.DangoLogStatusItemType, System.UInt32)");
--
local PlayerLobbyBase_type_def = find_type_definition("snow.player.PlayerLobbyBase");
local onDestroy_method = PlayerLobbyBase_type_def:get_method("onDestroy");
local Lobby_setKitchenData_method = PlayerLobbyBase_type_def:get_method("setKitchenData");
--
local getMasterPlayerQuestBase_method = find_type_definition("snow.enemy.EnemyUtility"):get_method("getMasterPlayer"); -- static

local Quest_setKitchenData_method = Constants.type_definitions.PlayerQuestBase_type_def:get_method("setKitchenData");
--
local OtomoManager_type_def = find_type_definition("snow.otomo.OtomoManager");
local getMasterFirstOtomo_method = OtomoManager_type_def:get_method("getMasterFirstOtomo");
local getMasterSecondOtomo_method = OtomoManager_type_def:get_method("getMasterSecondOtomo");

local Otomo_setKitchenData_method = getMasterFirstOtomo_method:get_return_type():get_method("setKitchenData");
--
local get_AcitvePlKitchenSkillList_method = find_type_definition("snow.data.SkillDataManager"):get_method("get_AcitvePlKitchenSkillList");

local AcitvePlKitchenSkillList_type_def = get_AcitvePlKitchenSkillList_method:get_return_type();
local get_Count_method = AcitvePlKitchenSkillList_type_def:get_method("get_Count");
local get_Item_method = AcitvePlKitchenSkillList_type_def:get_method("get_Item(System.Int32)");

local PlayerKitchenSkillData_type_def = get_Item_method:get_return_type();
--
local DailyDango = {
	[35] = true,  -- 보수금 보험
	[41] = true,  -- 환산술
	[42] = true,  -- 금전운
	[43] = true,  -- 해체술[소]
	[44] = true,  -- 해체술[대]
	[45] = true,  -- 행운술
	[46] = true   -- 격운술
};
--
local function orderBbq()
	local meatCount = getCountOfAll_method:call(Constants:get_ContentsIdDataManager(), 68157562);
	if meatCount == nil or meatCount <= 0 then
		SendMessage("요리: 날고기가 없습니다!");
		return;
	end

	local BbqFunc = Constants:get_BbqFunc();

	if get_CanUseFunc_method:call(BbqFunc) == true then
		local orderCount = math_min(meatCount, 99);
		local BbqConvertData = MealConvertDataList_get_Item_method:call(get_MealConvertDataList_method:call(BbqFunc), 0);
		local PointCost = get_PointCost_method:call(BbqConvertData) * orderCount;
		local MoneyCost = get_MoneyCost_method:call(BbqConvertData) * orderCount;
		local MoneyVal = getMoneyVal_method:call(nil);
		local paymentType = getVillagePoint() >= PointCost and 1
			or MoneyVal >= MoneyCost and 2
			or nil;

		if paymentType == nil then
			SendMessage("요리: 소지금과 포인트가 부족합니다!");
			return;
		end

		if paymentType == 1 then
			subVillagePoint(PointCost);
		else
			get_HandMoney_method:call(nil):set_field("_Value", MoneyVal - MoneyCost);
			SendMessage("요리: 포인트가 부족합니다!\n소지금을 사용합니다");
		end

		orderBbq_method:call(BbqFunc, BbqConvertData, orderCount);
		addItemToBox_method:call(nil, 68157448, orderCount);
		if isExistOutputTicket_method:call(BbqFunc) == true then
			Constants:outputMealTicket();
		end
	end
end
--
local PlayerLobbyBase = nil;

local function destroyPlayerLobbyBase()
	PlayerLobbyBase = nil;
end

local function getPlayerLobbyBase(args)
	PlayerLobbyBase = to_managed_object(args[2]);
	hook_vtable(PlayerLobbyBase, onDestroy_method, nil, destroyPlayerLobbyBase);
end
hook(PlayerLobbyBase_type_def:get_method("start"), getPlayerLobbyBase);

local function getPlayerLobbyBaseFromUpdate(args)
	if PlayerLobbyBase == nil then
		getPlayerLobbyBase(args);
	end
end
hook(PlayerLobbyBase_type_def:get_method("update"), getPlayerLobbyBaseFromUpdate);

local function applyKitchenBuff(kitchenType)
	if kitchenType == 1 and PlayerLobbyBase ~= nil then
		Lobby_setKitchenData_method:call(PlayerLobbyBase);
	else
		local MasterPlayerQuestBase = getMasterPlayerQuestBase_method:call(nil);
		if MasterPlayerQuestBase ~= nil then
			Quest_setKitchenData_method:call(MasterPlayerQuestBase);
		end
	end

	local OtomoManager = Constants:get_OtomoManager();

	local MasterFirstOtomo = getMasterFirstOtomo_method:call(OtomoManager);
	if MasterFirstOtomo ~= nil then
		Otomo_setKitchenData_method:call(MasterFirstOtomo);
	end

	local MasterSecondOtomo = getMasterSecondOtomo_method:call(OtomoManager);
	if MasterSecondOtomo ~= nil then
		Otomo_setKitchenData_method:call(MasterSecondOtomo);
	end
end

local function makeDangoLogParam(vitalBuff, staminaBuff)
	local DangoLogParam = DangoLogParam_type_def:create_instance();

	local AcitvePlKitchenSkillList = get_AcitvePlKitchenSkillList_method:call(Constants:get_SkillDataManager());
	local AcitvePlKitchenSkill_count = get_Count_method:call(AcitvePlKitchenSkillList);
	local AcitvePlKitchenSkillArray = create_managed_array(PlayerKitchenSkillData_type_def, AcitvePlKitchenSkill_count);

	setStatusParam_method:call(DangoLogParam, 0, vitalBuff);
	setStatusParam_method:call(DangoLogParam, 1, staminaBuff);

	for i = 0, AcitvePlKitchenSkill_count - 1, 1 do
		AcitvePlKitchenSkillArray[i] = get_Item_method:call(AcitvePlKitchenSkillList, i);
	end

	DangoLogParam:set_field("_SkillDataList", AcitvePlKitchenSkillArray);

	return DangoLogParam;
end

local isOrdering = false;
local function orderDango(kitchenType)
	local MealFunc = get_MealFunc_method:call(Constants:get_KitchenFacility());

	if checkAvailableMealSystem_method:call(MealFunc) == true then
		local paymentType = nil;

		if checkHandMoney_method:call(MealFunc) == true then
			paymentType = 0;
		elseif checkVillagePoint_method:call(MealFunc) == true then
			paymentType = 1;
			SendMessage("식사: 소지금이 부족합니다!\n포인트를 사용합니다");
		else
			SendMessage("식사: 소지금과 포인트가 부족합니다!");
			return;
		end

		local MealTicketNum = getMealTicketNum_method:call(MealFunc);

		if MealTicketNum == nil or MealTicketNum <= 0 then
			SendMessage("식사: 식사권이 없습니다!");
			return;
		end

		local FacilityLv = get_FacilityLv_method:call(MealFunc);
		isOrdering = true;
		resetDailyDango_method:call(MealFunc);
		setMealTicketFlag_method:call(MealFunc, true);
		order_method:call(MealFunc, get_MySetDataList_method:call(MealFunc):get_element((kitchenType == 1 and DailyDango[get_DailyDango_method:call(MealFunc)] == true) and 0 or 1), paymentType, FacilityLv);
		isOrdering = false;
		addBuff_method:call(MealFunc, FacilityLv);
		applyKitchenBuff(kitchenType);
		setWaitTimer_method:call(MealFunc);
		reqDangoLogStart_method:call(Constants:get_GuiManager(), makeDangoLogParam(getVitalBuff_method:call(MealFunc, FacilityLv), getStaminaBuff_method:call(MealFunc, FacilityLv)), 5.0);
	end
end
--
local function PostHook_villageUpdate()
	if checkKeyTrg(116) == true then
		fastTravel_method:call(Constants:get_VillageAreaManager(), 8);

	elseif checkKeyTrg(117) == true then
		fastTravel_method:call(Constants:get_VillageAreaManager(), 9);

	elseif checkKeyTrg(118) == true then
		orderBbq();

	elseif checkKeyTrg(119) == true then
		orderDango(1);
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
	if checkKeyTrg(116) == true then
		notifyReset_method:call(Constants:get_QuestManager());

	elseif checkKeyTrg(119) == true then
		orderDango(2);
	end
end
hook(QuestManager_type_def:get_method("updateNormalQuest"), nil, PostHook_updateNormalQuest);