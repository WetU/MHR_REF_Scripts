local require = require;

local string = string;
local string_format = string.format;

local sdk = sdk;
local sdk_find_type_definition = sdk.find_type_definition;
local sdk_get_managed_singleton = sdk.get_managed_singleton;
local sdk_to_managed_object = sdk.to_managed_object;
local sdk_to_int64 = sdk.to_int64;
local sdk_hook = sdk.hook;
--
local LongSwordShell010_type_def = sdk_find_type_definition("snow.shell.LongSwordShellManager"):get_method("getMaseterLongSwordShell010s(snow.player.PlayerIndex)"):get_return_type():get_method("get_Item(System.Int32)"):get_return_type();
local lifeTimer_field = LongSwordShell010_type_def:get_field("_lifeTimer");
local CircleType_field = LongSwordShell010_type_def:get_field("_CircleType");

local get_OwnerId_method = sdk_find_type_definition("snow.shell.PlayerShellBase"):get_method("get_OwnerId"); -- retval

local CircleType_type_def = CircleType_field:get_type();
local HarvestMoonCircleType = {
    ["Inside"] = CircleType_type_def:get_field("Inside"):get_data(nil),
    ["Outside"] = CircleType_type_def:get_field("Outside"):get_data(nil)
};
--
local Constants = require("WetU_Overlay.Constants");
--
local this = {
    HarvestMoonTimer_Inside = nil,
    HarvestMoonTimer_Outside = nil
};

local HarvestMoonTimer_String = {
    ["Inside"] = "원월 내부 타이머: %.f초",
    ["Outside"] = "원월 외부 타이머: %.f초"
};

local function getHarvestMoonTimer(shellObj)
    if get_OwnerId_method:call(shellObj) == Constants.MasterPlayerIndex then
        local lifeTimer = lifeTimer_field:get_data(shellObj);
        local CircleType = CircleType_field:get_data(shellObj);
        if CircleType == HarvestMoonCircleType.Inside then
            this.HarvestMoonTimer_Inside = lifeTimer ~= nil and string_format(HarvestMoonTimer_String.Inside, lifeTimer) or nil;
        end
        if CircleType == HarvestMoonCircleType.Outside then
            this.HarvestMoonTimer_Outside = lifeTimer ~= nil and string_format(HarvestMoonTimer_String.Outside, lifeTimer) or nil;
        end
    end
end

local LongSwordShell010_start = nil;
sdk_hook(LongSwordShell010_type_def:get_method("start"), function(args)
    LongSwordShell010_start = sdk_to_managed_object(args[2]);
    if Constants.MasterPlayerIndex == nil then
        Constants.getMasterPlayerId();
    end
end, function()
    if LongSwordShell010_start then
        getHarvestMoonTimer(LongSwordShell010_start);
    end
    LongSwordShell010_start = nil;
end);

local LongSwordShell010_update = nil;
sdk_hook(LongSwordShell010_type_def:get_method("update"), function(args)
    LongSwordShell010_update = sdk_to_managed_object(args[2]);
    if Constants.MasterPlayerIndex == nil then
        Constants.getMasterPlayerId();
    end
end, function()
    if LongSwordShell010_update then
        getHarvestMoonTimer(LongSwordShell010_update);
    end
    LongSwordShell010_update = nil;
end);

local LongSwordShell010_onDestroy = nil;
sdk_hook(LongSwordShell010_type_def:get_method("onDestroy"), function(args)
    LongSwordShell010_onDestroy = sdk_to_managed_object(args[2]);
    if Constants.MasterPlayerIndex == nil then
        Constants.getMasterPlayerId();
    end
    if LongSwordShell010_onDestroy and (get_OwnerId_method:call(LongSwordShell010_onDestroy) ~= Constants.MasterPlayerIndex) then
        LongSwordShell010_onDestroy = nil;
    end
end, function()
    if LongSwordShell010_onDestroy then
        local CircleType = CircleType_field:get_data(LongSwordShell010_onDestroy);
        if CircleType == HarvestMoonCircleType.Inside then
            this.HarvestMoonTimer_Inside = nil;
        end
        if CircleType == HarvestMoonCircleType.Outside then
            this.HarvestMoonTimer_Outside = nil;
        end
    end
    LongSwordShell010_onDestroy = nil;
end);

return this;