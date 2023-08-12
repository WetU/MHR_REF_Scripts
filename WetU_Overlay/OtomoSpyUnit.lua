local Constants = _G.require("Constants.Constants");

local string_format = Constants.lua.string_format;

local to_int64 = Constants.sdk.to_int64;
local find_type_definition = Constants.sdk.find_type_definition;
local get_managed_singleton = Constants.sdk.get_managed_singleton;
local to_managed_object = Constants.sdk.to_managed_object;
local hook = Constants.sdk.hook;

local Vector2f_new = Constants.Vector2f.new;

local TRUE_POINTER = Constants.TRUE_POINTER;
local checkGameStatus = Constants.checkGameStatus;
local Village = Constants.GameStatusType.Village;
--
local this = {
	OtomoSpyUnitManager = nil,

	init = true,
	get_currentStepCount = true,
	currentStep = nil
};
--
local StmGuiInput_type_def = Constants.type_definitions.StmGuiInput_type_def;

local OtomoSpyUnitManager_type_def = find_type_definition("snow.data.OtomoSpyUnitManager");
local get_IsOperating_method = OtomoSpyUnitManager_type_def:get_method("get_IsOperating");
local get_NowStepCount_method = OtomoSpyUnitManager_type_def:get_method("get_NowStepCount");

local GuiOtomoSpyUnitMainControll_type_def = find_type_definition("snow.gui.fsm.otomospy.GuiOtomoSpyUnitMainControll");
local setBoostItem_method = GuiOtomoSpyUnitMainControll_type_def:get_method("setBoostItem");
local updateRewardList_method = GuiOtomoSpyUnitMainControll_type_def:get_method("updateRewardList");
local RewardListCursor_field = GuiOtomoSpyUnitMainControll_type_def:get_field("RewardListCursor");
local spyOpenType_field = GuiOtomoSpyUnitMainControll_type_def:get_field("spyOpenType");

local RewardListCursor_type_def = RewardListCursor_field:get_type();
local get__PageCursor_method = RewardListCursor_type_def:get_method("get__PageCursor");
local get__Index_method = RewardListCursor_type_def:get_method("get__Index");
local set__Index_method = RewardListCursor_type_def:get_method("set__Index(via.vec2)");

local PageCursor_type_def = get__PageCursor_method:get_return_type();
local get_pageNo_method = PageCursor_type_def:get_method("get_pageNo");
local set_pageNo_method = PageCursor_type_def:get_method("set_pageNo(System.Int32)");
local getPageMax_method = PageCursor_type_def:get_method("getPageMax");

local GuiOtomoSpyUnitReturn_type_def = find_type_definition("snow.gui.fsm.otomospy.GuiOtomoSpyUnitReturn");
--
local ItemReceive = 5;
local ReceiveAllButton_Index = Vector2f_new(0.0, 0.0);
--
local isReturnAnimation = false;
local isReceiveReady = false;

function this:getOtomoSpyUnitManager()
	if self.OtomoSpyUnitManager == nil then
		self.OtomoSpyUnitManager = get_managed_singleton("snow.data.OtomoSpyUnitManager");
	end

	return self.OtomoSpyUnitManager;
end

function this:Terminate()
	self.currentStep = nil;
end

local function setBoostItem(args)
	setBoostItem_method:call(to_managed_object(args[2]));
end

local function get_currentStepCount()
	local OtomoSpyUnitManager = this:getOtomoSpyUnitManager();
	local isOperating = get_IsOperating_method:call(OtomoSpyUnitManager);
	this.currentStep = isOperating == true and string_format("조사 단계: %d / 5", get_NowStepCount_method:call(OtomoSpyUnitManager))
		or isOperating == false and "활동 없음"
		or nil;
end

local function skipReturnAnimation()
	isReturnAnimation = true;
end

local function PostHook_getDecideButtonTrg(retval)
	return isReturnAnimation == true and TRUE_POINTER or retval;
end

local function PreHook_endOtomoSpyUnitReturn()
	isReturnAnimation = false;
	this.currentStep = "활동 없음";
end

local function handleReward(args)
	local GuiOtomoSpyUnitMainControll = to_managed_object(args[2]);

	if spyOpenType_field:get_data(GuiOtomoSpyUnitMainControll) == ItemReceive then
		local RewardListCursor = RewardListCursor_field:get_data(GuiOtomoSpyUnitMainControll);

		local PageCursor = get__PageCursor_method:call(RewardListCursor);
		local PageMax = getPageMax_method:call(PageCursor);

		local currentIndex = get__Index_method:call(RewardListCursor);

		local isChanged = false;

		if get_pageNo_method:call(PageCursor) ~= PageMax then
			set_pageNo_method:call(PageCursor, PageMax);
			if isChanged == false then
				isChanged = true;
			end
		end

		if currentIndex.x ~= 0.0 or currentIndex.y ~= 0.0 then
			set__Index_method:call(RewardListCursor, ReceiveAllButton_Index);
			if isChanged == false then
				isChanged = true;
			end
		end

		if isChanged == true then
			updateRewardList_method:call(GuiOtomoSpyUnitMainControll);
		end

		isReceiveReady = true;
	end
end

local function PostHook_getDecideButtonRep(retval)
	return isReceiveReady == true and TRUE_POINTER or retval;
end

local function PreHook_addAllGameItemtoBox()
	isReceiveReady = false;
end

local function onChangedGameStatus(args)
	if to_int64(args[3]) == Village then
		get_currentStepCount();
	else
		this:Terminate();
	end
end

local function init()
	if checkGameStatus(Village) == true then
		get_currentStepCount();
	end

	hook(GuiOtomoSpyUnitMainControll_type_def:get_method("doOpen"), setBoostItem);
	hook(OtomoSpyUnitManager_type_def:get_method("dispatch"), nil, get_currentStepCount);
	hook(GuiOtomoSpyUnitReturn_type_def:get_method("doOpen"), nil, skipReturnAnimation);
	hook(StmGuiInput_type_def:get_method("getDecideButtonTrg(snow.StmInputConfig.KeyConfigType, System.Boolean)"), nil, PostHook_getDecideButtonTrg);
	hook(GuiOtomoSpyUnitReturn_type_def:get_method("endOtomoSpyUnitReturn"), PreHook_endOtomoSpyUnitReturn);
	hook(GuiOtomoSpyUnitMainControll_type_def:get_method("updateRewardListCursor"), handleReward);
	hook(StmGuiInput_type_def:get_method("getDecideButtonRep(snow.StmInputConfig.KeyConfigType, System.Boolean)"), nil, PostHook_getDecideButtonRep);
	hook(GuiOtomoSpyUnitMainControll_type_def:get_method("addAllGameItemtoBox(System.Boolean)"), PreHook_addAllGameItemtoBox);
	hook(OtomoSpyUnitManager_type_def:get_method("onChangedGameStatus(snow.SnowGameManager.StatusType)"), onChangedGameStatus);
end

this.init = init;
this.get_currentStepCount = get_currentStepCount;
--
return this;