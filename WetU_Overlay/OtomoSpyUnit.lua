local Constants = require("Constants.Constants");
if not Constants then
    return;
end
--
local this = {currentStep = nil};
--
local get_CurrentStatus_method = Constants.type_definitions.SnowGameManager_type_def:get_method("get_CurrentStatus");

local OtomoSpyUnitManager_type_def = Constants.SDK.find_type_definition("snow.data.OtomoSpyUnitManager");
local get_IsOperating_method = OtomoSpyUnitManager_type_def:get_method("get_IsOperating");
local get_NowStepCount_method = OtomoSpyUnitManager_type_def:get_method("get_NowStepCount");
local set_IsBoostItemUsing_method = OtomoSpyUnitManager_type_def:get_method("set_IsBoostItemUsing(System.Boolean)");

--local StepCountInRoute = OtomoSpyUnitManager_type_def:get_field("StepCountInRoute"):get_data(nil);
--
function this.TerminateOtomoSpyUnit()
    this.currentStep = nil;
end

function this.get_currentStepCount()
    local OtomoSpyUnitManager = Constants.SDK.get_managed_singleton("snow.data.OtomoSpyUnitManager");
    if OtomoSpyUnitManager ~= nil and get_IsOperating_method:call(OtomoSpyUnitManager) == true then
        this.currentStep = get_NowStepCount_method:call(OtomoSpyUnitManager);
    end
end

function this.init()
    local SnowGameManager = Constants.SDK.get_managed_singleton("snow.SnowGameManager");
    if SnowGameManager ~= nil and get_CurrentStatus_method:call(SnowGameManager) == Constants.GameStatusType_Village then
        this.get_currentStepCount();
    end
    Constants.SDK.hook(OtomoSpyUnitManager_type_def:get_method("dispatch"), nil, this.get_currentStepCount);
    Constants.SDK.hook(Constants.SDK.find_type_definition("snow.gui.fsm.otomospy.GuiOtomoSpyUnitMainControll"):get_method("doOpen"), nil, function()
        local OtomoSpyUnitManager = Constants.SDK.get_managed_singleton("snow.data.OtomoSpyUnitManager");
        if OtomoSpyUnitManager ~= nil then
            set_IsBoostItemUsing_method:call(OtomoSpyUnitManager, true);
        end
    end);
end
--
return this;