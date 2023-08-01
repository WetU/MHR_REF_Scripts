local Constants = require("Constants.Constants");
--
local this = {
    currentStep = nil
};
--
local OtomoSpyUnitManager_type_def = sdk.find_type_definition("snow.data.OtomoSpyUnitManager");
local get_IsOperating_method = OtomoSpyUnitManager_type_def:get_method("get_IsOperating");
local get_NowStepCount_method = OtomoSpyUnitManager_type_def:get_method("get_NowStepCount");

local GuiOtomoSpyUnitMainControll_type_def = sdk.find_type_definition("snow.gui.fsm.otomospy.GuiOtomoSpyUnitMainControll");
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

local GuiOtomoSpyUnitReturn_type_def = sdk.find_type_definition("snow.gui.fsm.otomospy.GuiOtomoSpyUnitReturn");
--
local ItemReceive = spyOpenType_field:get_type():get_field("ItemReceive"):get_data(nil);
local ReceiveAllButton_Index = Vector2f.new(0.0, 0.0);
--
local isReturnAnimation = false;
local isReceiveReady = false;

local function Terminate()
    this.currentStep = nil;
end

local function setBoostItem(args)
    setBoostItem_method:call(sdk.to_managed_object(args[2]));
end

function this.get_currentStepCount()
    local OtomoSpyUnitManager = sdk.get_managed_singleton("snow.data.OtomoSpyUnitManager");
    if OtomoSpyUnitManager ~= nil then
        local isOperating = get_IsOperating_method:call(OtomoSpyUnitManager);
        if isOperating == true then
            this.currentStep = string.format("조사 단계: %d / 5", get_NowStepCount_method:call(OtomoSpyUnitManager));
            return;
        elseif isOperating == false then
            this.currentStep = "활동 없음";
            return;
        end
    end

    Terminate();
end

local function skipReturnAnimation()
    isReturnAnimation = true;
end

local function PreHook_getDecideButtonTrg()
    return isReturnAnimation == true and sdk.PreHookResult.SKIP_ORIGINAL or sdk.PreHookResult.CALL_ORIGINAL;
end
local function PostHook_getDecideButtonTrg(retval)
    return isReturnAnimation == true and Constants.TRUE_POINTER or retval;
end

local function PreHook_endOtomoSpyUnitReturn()
    isReturnAnimation = false;
    this.currentStep = "활동 없음";
end

local function handleReward(args)
    local GuiOtomoSpyUnitMainControll = sdk.to_managed_object(args[2]);
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

local function PreHook_getDecideButtonRep()
    return isReceiveReady == true and sdk.PreHookResult.SKIP_ORIGINAL or sdk.PreHookResult.CALL_ORIGINAL;
end
local function PostHook_getDecideButtonRep(retval)
    return isReceiveReady == true and Constants.TRUE_POINTER or retval;
end

local function PreHook_addAllGameItemtoBox()
    isReceiveReady = false;
end

local function onChangedGameStatus(args)
    if sdk.to_int64(args[3]) == Constants.GameStatusType.Village then
        this.get_currentStepCount();
    else
        Terminate();
        Constants.isOnVillageStarted = false;
    end
end

function this.init()
    sdk.hook(GuiOtomoSpyUnitMainControll_type_def:get_method("doOpen"), setBoostItem);
    sdk.hook(OtomoSpyUnitManager_type_def:get_method("dispatch"), nil, this.get_currentStepCount);
    sdk.hook(GuiOtomoSpyUnitReturn_type_def:get_method("doOpen"), nil, skipReturnAnimation);
    sdk.hook(Constants.type_definitions.StmGuiInput_type_def:get_method("getDecideButtonTrg(snow.StmInputConfig.KeyConfigType, System.Boolean)"), PreHook_getDecideButtonTrg, PostHook_getDecideButtonTrg);
    sdk.hook(GuiOtomoSpyUnitReturn_type_def:get_method("endOtomoSpyUnitReturn"), PreHook_endOtomoSpyUnitReturn);
    sdk.hook(GuiOtomoSpyUnitMainControll_type_def:get_method("updateRewardListCursor"), handleReward);
    sdk.hook(Constants.type_definitions.StmGuiInput_type_def:get_method("getDecideButtonRep(snow.StmInputConfig.KeyConfigType, System.Boolean)"), PreHook_getDecideButtonRep, PostHook_getDecideButtonRep);
    sdk.hook(GuiOtomoSpyUnitMainControll_type_def:get_method("addAllGameItemtoBox(System.Boolean)"), PreHook_addAllGameItemtoBox);
    sdk.hook(Constants.type_definitions.QuestManager_type_def:get_method("onChangedGameStatus(snow.SnowGameManager.StatusType)"), onChangedGameStatus);
end
--
return this;
