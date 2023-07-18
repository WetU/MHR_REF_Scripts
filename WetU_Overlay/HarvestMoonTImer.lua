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

local get_OwnerId_method = LongSwordShell010_type_def:get_parent_type():get_method("get_OwnerId");

local HarvestMoonCircleType_OutSide = CircleType_field:get_type():get_field("Outside"):get_data(nil);
--
local this = {CircleTimer = nil};
--
local function Terminate()
    this.CircleTimer = nil;
end

local function UpdateHarvestMoonTimer(longSwordShell010)
    local lifeTimer = lifeTimer_field:get_data(longSwordShell010);
    if lifeTimer == nil then
        Terminate();
        return;
    end
    this.CircleTimer = Constants.LUA.string_format("원월 타이머: %.f초", lifeTimer);
end

local function PreHook_update(args)
    local LongSwordShell010 = Constants.SDK.to_managed_object(args[2]);
    if LongSwordShell010 == nil then
        Terminate();
        return;
    end
    UpdateHarvestMoonTimer(LongSwordShell010);
end

local LongSwordShell010 = nil;
local function PreHook(args)
    LongSwordShell010 = Constants.SDK.to_managed_object(args[2]);
    if Constants.MasterPlayerIndex == nil then
        Constants.GetMasterPlayerId(nil);
    end
end
local function PostHook()
    if LongSwordShell010 == nil then
        return;
    end

    if get_OwnerId_method:call(LongSwordShell010) == Constants.MasterPlayerIndex and CircleType_field:get_data(LongSwordShell010) == HarvestMoonCircleType_OutSide then
        UpdateHarvestMoonTimer(LongSwordShell010);
        Constants.SDK.hook_vtable(LongSwordShell010, update_method, PreHook_update);
        Constants.SDK.hook_vtable(LongSwordShell010, onDestroy_method, nil, Terminate);
    end

    LongSwordShell010 = nil;
end

function this.init()
    Constants.SDK.hook(LongSwordShell010_type_def:get_method("start"), PreHook, PostHook);
end

return this;