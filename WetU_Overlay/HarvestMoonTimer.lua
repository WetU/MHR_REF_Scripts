local getMasterPlayerIndex_method = sdk.find_type_definition("snow.enemy.EnemyUtility"):get_method("getMasterPlayerIndex");
--
local LongSwordShell010_type_def = sdk.find_type_definition("snow.shell.LongSwordShellManager"):get_method("getMaseterLongSwordShell010s(snow.player.PlayerIndex)"):get_return_type():get_method("get_Item(System.Int32)"):get_return_type();
local update_method = LongSwordShell010_type_def:get_method("update");
local onDestroy_method = LongSwordShell010_type_def:get_method("onDestroy");
local lifeTimer_field = LongSwordShell010_type_def:get_field("_lifeTimer");
local CircleType_field = LongSwordShell010_type_def:get_field("_CircleType");

local get_OwnerId_method = LongSwordShell010_type_def:get_parent_type():get_method("get_OwnerId");

local HarvestMoonCircleType_OutSide = CircleType_field:get_type():get_field("Outside"):get_data(nil);
--
local this = {
    CircleTimer = nil
};
--
local function Terminate()
    this.CircleTimer = nil;
end

local function UpdateHarvestMoonTimer(longSwordShell010)
    this.CircleTimer = string.format("원월 타이머: %.f초", lifeTimer_field:get_data(longSwordShell010));
end

local function PreHook_update(args)
    UpdateHarvestMoonTimer(sdk.to_managed_object(args[2]));
end

local LongSwordShell010 = nil;
local function PreHook(args)
    LongSwordShell010 = sdk.to_managed_object(args[2]);
end
local function PostHook()
    if get_OwnerId_method:call(LongSwordShell010) == getMasterPlayerIndex_method:call(nil) and CircleType_field:get_data(LongSwordShell010) == HarvestMoonCircleType_OutSide then
        UpdateHarvestMoonTimer(LongSwordShell010);
        sdk.hook_vtable(LongSwordShell010, update_method, PreHook_update);
        sdk.hook_vtable(LongSwordShell010, onDestroy_method, nil, Terminate);
    end

    LongSwordShell010 = nil;
end

function this.init()
    sdk.hook(LongSwordShell010_type_def:get_method("start"), PreHook, PostHook);
end

return this;