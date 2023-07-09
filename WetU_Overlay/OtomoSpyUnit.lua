local Constants = require("Constants.Constants");
if not Constants then
    return;
end
--
local this = {currentStep = nil};
--
local OtomoSpyUnitManager_type_def = Constants.SDK.find_type_definition("snow.data.OtomoSpyUnitManager");
local get_IsOperating_method = OtomoSpyUnitManager_type_def:get_method("get_IsOperating");
local get_NowStepCount_method = OtomoSpyUnitManager_type_def:get_method("get_NowStepCount");

local GuiOtomoSpyUnitMainControll_type_def = Constants.SDK.find_type_definition("snow.gui.fsm.otomospy.GuiOtomoSpyUnitMainControll");
local setBoostItem_method = GuiOtomoSpyUnitMainControll_type_def:get_method("setBoostItem");
local updateRewardList_method = GuiOtomoSpyUnitMainControll_type_def:get_method("updateRewardList");
local RewardListCursor_field = GuiOtomoSpyUnitMainControll_type_def:get_field("RewardListCursor");

local RewardListCursor_type_def = RewardListCursor_field:get_type();
local setIndex_method = RewardListCursor_type_def:get_method("setIndex(via.vec2)");
local setPageNo_method = RewardListCursor_type_def:get_method("setPageNo(System.Int32)");

local GuiOtomoSpyUnitReturn_type_def = Constants.SDK.find_type_definition("snow.gui.fsm.otomospy.GuiOtomoSpyUnitReturn");
--
local ReceiveAllButton_Index = Constants.VECTOR2f.new(0.0, 0.0);
--
local OtomoSpyStr = {
    NotActive = "활동 없음",
    Step = "조사 단계: %d / 5"
};
--
local isReturnAnimation = false;
local isReceiveReady = false;

local function Terminate()
    this.currentStep = nil;
end

local function setBoostItem(args)
    local GuiOtomoSpyUnitMainControll = Constants.SDK.to_managed_object(args[2]);
    if GuiOtomoSpyUnitMainControll ~= nil then
        setBoostItem_method:call(GuiOtomoSpyUnitMainControll);
    end
end

local function get_currentStepCount()
    local OtomoSpyUnitManager = Constants.SDK.get_managed_singleton("snow.data.OtomoSpyUnitManager");
    if OtomoSpyUnitManager ~= nil then
        if get_IsOperating_method:call(OtomoSpyUnitManager) == true then
            local NowStepCount = get_NowStepCount_method:call(OtomoSpyUnitManager);
            if NowStepCount ~= nil then
                this.currentStep = Constants.LUA.string_format(OtomoSpyStr.Step, NowStepCount);
                return;
            end
        else
            this.currentStep = OtomoSpyStr.NotActive;
            return;
        end
    end
    this.currentStep = nil;
end

local function skipReturnAnimation()
    isReturnAnimation = true;
end

local function PreHook_getDecideButtonTrg()
    if isReturnAnimation == true then
        return Constants.SDK.SKIP_ORIGINAL;
    end
end
local function PostHook_getDecideButtonTrg(retval)
    if isReturnAnimation == true then
        return Constants.TRUE_POINTER;
    end
    return retval;
end

local function PostHook_endOtomoSpyUnitReturn()
    this.currentStep = OtomoSpyStr.NotActive;
    isReturnAnimation = false;
end

local function handleReward(args)
    local GuiOtomoSpyUnitMainControll = Constants.SDK.to_managed_object(args[2]);
    if GuiOtomoSpyUnitMainControll ~= nil then
        local RewardListCursor = RewardListCursor_field:get_data(GuiOtomoSpyUnitMainControll);
        if RewardListCursor ~= nil then
            setPageNo_method:call(RewardListCursor, 5);
            setIndex_method:call(RewardListCursor, ReceiveAllButton_Index);
            updateRewardList_method:call(GuiOtomoSpyUnitMainControll);
            isReceiveReady = true;
        end
    end
end

local function PreHook_getDecideButtonRep()
    if isReceiveReady == true then
        return Constants.SDK.SKIP_ORIGINAL;
    end
end
local function PostHook_getDecideButtonRep(retval)
    if isReceiveReady == true then
        return Constants.TRUE_POINTER;
    end
    return retval;
end

local function PostHook_addAllGameItemtoBox(retval)
    isReceiveReady = false;
    return retval;
end

local function onChangedGameStatus(args)
    if Constants.SDK.to_int64(args[3]) ~= Constants.GameStatusType.Village then
        Terminate();
    else
        get_currentStepCount();
    end
end

function this.init()
    if Constants.checkGameStatus(Constants.GameStatusType.Village) == true then
        get_currentStepCount();
    end
    Constants.SDK.hook(GuiOtomoSpyUnitMainControll_type_def:get_method("doOpen"), setBoostItem);
    Constants.SDK.hook(OtomoSpyUnitManager_type_def:get_method("dispatch"), nil, get_currentStepCount);
    Constants.SDK.hook(GuiOtomoSpyUnitReturn_type_def:get_method("controllSpyUnitAnimation"), nil, skipReturnAnimation);
    Constants.SDK.hook(Constants.type_definitions.StmGuiInput_type_def:get_method("getDecideButtonTrg(snow.StmInputConfig.KeyConfigType, System.Boolean)"), PreHook_getDecideButtonTrg, PostHook_getDecideButtonTrg);
    Constants.SDK.hook(GuiOtomoSpyUnitReturn_type_def:get_method("endOtomoSpyUnitReturn"), nil, PostHook_endOtomoSpyUnitReturn);
    Constants.SDK.hook(GuiOtomoSpyUnitMainControll_type_def:get_method("updateRewardListCursor"), handleReward);
    Constants.SDK.hook(Constants.type_definitions.StmGuiInput_type_def:get_method("getDecideButtonRep(snow.StmInputConfig.KeyConfigType, System.Boolean)"), PreHook_getDecideButtonRep, PostHook_getDecideButtonRep);
    Constants.SDK.hook(GuiOtomoSpyUnitMainControll_type_def:get_method("addAllGameItemtoBox(System.Boolean)"), nil, PostHook_addAllGameItemtoBox);
    Constants.SDK.hook(Constants.type_definitions.QuestManager_type_def:get_method("onChangedGameStatus(snow.SnowGameManager.StatusType)"), onChangedGameStatus);
end
--
return this;