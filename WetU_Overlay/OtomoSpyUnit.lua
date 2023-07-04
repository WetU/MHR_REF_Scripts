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

local GuiOtomoSpyUnitReturn_type_def = Constants.SDK.find_type_definition("snow.gui.fsm.otomospy.GuiOtomoSpyUnitReturn");
--
local OtomoSpyStr = {
    NotActive = "활동 없음",
    Step = "조사 단계: %d / 5"
};

local function TerminateOtomoSpyUnit()
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
        TerminateOtomoSpyUnit();
    else
        get_currentStepCount();
    end
end

local GuiOtomoSpyUnitReturn = nil;
local function PreHook_openReturnGui(args)
    local GuiOtomoSpyUnitReturn = Constants.SDK.to_managed_object(args[2]);
end
local function PostHook_openReturnGui()
    if GuiOtomoSpyUnitReturn ~= nil then
        GuiOtomoSpyUnitReturn:set_field("skipFlag", true);
    end
    GuiOtomoSpyUnitReturn = nil;
end

local function PostHook_closeReturnGui()
    this.currentStep = OtomoSpyStr.NotActive;
end

function this.init()
    if Constants.checkGameStatus(Constants.GameStatusType.Village) == true then
        get_currentStepCount();
    end
    Constants.SDK.hook(OtomoSpyUnitManager_type_def:get_method("dispatch"), nil, get_currentStepCount);
    Constants.SDK.hook(GuiOtomoSpyUnitMainControll_type_def:get_method("doOpen"), setBoostItem);
    Constants.SDK.hook(Constants.type_definitions.QuestManager_type_def:get_method("onChangedGameStatus(snow.SnowGameManager.StatusType)"), onChangedGameStatus);
    Constants.SDK.hook(GuiOtomoSpyUnitReturn_type_def:get_method("setOpenGui"), PreHook_openReturnGui, PostHook_openReturnGui);
    Constants.SDK.hook(GuiOtomoSpyUnitReturn_type_def:get_method("setCloseGui"), nil, PostHook_closeReturnGui);
end
--
return this;