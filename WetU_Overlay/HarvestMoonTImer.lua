local require = require;
local Constants = require("Constants.Constants");
if not Constants then
	return;
end
--
local LongSwordShell010_type_def = Constants.SDK.find_type_definition("snow.shell.LongSwordShellManager"):get_method("getMaseterLongSwordShell010s(snow.player.PlayerIndex)"):get_return_type():get_method("get_Item(System.Int32)"):get_return_type();
local update_method = LongSwordShell010_type_def:get_method("update");
local onDestroy_method = LongSwordShell010_type_def:get_method("onDestroy");
local lifeTimer_field = LongSwordShell010_type_def:get_field("_lifeTimer");
local CircleType_field = LongSwordShell010_type_def:get_field("_CircleType");

local get_OwnerId_method = Constants.SDK.find_type_definition("snow.shell.PlayerShellBase"):get_method("get_OwnerId"); -- retval

local HarvestMoonCircleType_OutSide = CircleType_field:get_type():get_field("Outside"):get_data(nil);
--
local this = {
    CircleTimer = nil
};
--
local LongSwordShell010 = nil;
local HarvestMoonTimer_String = "원월 타이머: %.f초";

local function UpdateHarvestMoonTimer()
    local lifeTimer = lifeTimer_field:get_data(LongSwordShell010);
    this.CircleTimer = lifeTimer ~= nil and Constants.LUA.string_format(HarvestMoonTimer_String, lifeTimer) or nil;
end

function this.TerminateHarvestMoon()
    this.CircleTimer = nil;
    LongSwordShell010 = nil;
end

Constants.SDK.hook(LongSwordShell010_type_def:get_method("start"), function(args)
    LongSwordShell010 = Constants.SDK.to_managed_object(args[2]);
    if Constants.MasterPlayerIndex == nil then
        Constants.GetMasterPlayerId(nil);
    end
end, function()
    if LongSwordShell010 and get_OwnerId_method:call(LongSwordShell010) == Constants.MasterPlayerIndex and CircleType_field:get_data(LongSwordShell010) == HarvestMoonCircleType_OutSide then
        UpdateHarvestMoonTimer();
        Constants.SDK.hook_vtable(LongSwordShell010, update_method, nil, UpdateHarvestMoonTimer);
        Constants.SDK.hook_vtable(LongSwordShell010, onDestroy_method, nil, this.TerminateHarvestMoon);
    else
        LongSwordShell010 = nil;
    end
end);

return this;