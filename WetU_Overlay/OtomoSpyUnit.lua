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
--
local OtomoSpyStr = {
    NotActive = "활동 없음",
    Step = "조사 단계: %d / 5"
};

local function Terminate()
    this.currentStep = nil;
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

local function setBoostItem(args)
    local GuiOtomoSpyUnitMainControll = Constants.SDK.to_managed_object(args[2]);
    if GuiOtomoSpyUnitMainControll ~= nil then
        setBoostItem_method:call(GuiOtomoSpyUnitMainControll);
    end
end

local function onChangedGameStatus(args)
    if (Constants.SDK.to_int64(args[3]) & 0xFFFFFFFF) ~= Constants.GameStatusType.Village then
        Terminate();
    else
        get_currentStepCount();
    end
end

local function PostHook_endOtomoSpyUnitReturn()
    this.currentStep = OtomoSpyStr.NotActive;
end

function this.init()
    if Constants.checkGameStatus(Constants.GameStatusType.Village) == true then
        get_currentStepCount();
    end
    Constants.SDK.hook(OtomoSpyUnitManager_type_def:get_method("dispatch"), nil, get_currentStepCount);
    Constants.SDK.hook(GuiOtomoSpyUnitMainControll_type_def:get_method("doOpen"), setBoostItem);
    Constants.SDK.hook(Constants.type_definitions.QuestManager_type_def:get_method("onChangedGameStatus(snow.SnowGameManager.StatusType)"), onChangedGameStatus);
    Constants.SDK.hook(Constants.SDK.find_type_definition("snow.gui.fsm.otomospy.GuiOtomoSpyUnitReturn"):get_method("endOtomoSpyUnitReturn"), nil, PostHook_endOtomoSpyUnitReturn);
end
--
return this;