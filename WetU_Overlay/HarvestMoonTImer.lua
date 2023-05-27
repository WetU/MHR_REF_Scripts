local require = require;
local Constants = require("Constants.Constants");
if not Constants then
	return;
end
--
local LongSwordShell010_type_def = Constants.SDK.find_type_definition("snow.shell.LongSwordShellManager"):get_method("getMaseterLongSwordShell010s(snow.player.PlayerIndex)"):get_return_type():get_method("get_Item(System.Int32)"):get_return_type();
local lifeTimer_field = LongSwordShell010_type_def:get_field("_lifeTimer");
local CircleType_field = LongSwordShell010_type_def:get_field("_CircleType");

local get_OwnerId_method = Constants.SDK.find_type_definition("snow.shell.PlayerShellBase"):get_method("get_OwnerId"); -- retval

local HarvestMoonCircleType_OutSide = CircleType_field:get_type():get_field("Outside"):get_data(nil);
--
local this = {
    CircleTimer = nil
};

local HarvestMoonTimer_String = "원월 타이머: %.f초";

local function getHarvestMoonTimer(shellObj)
    if get_OwnerId_method:call(shellObj) == Constants.MasterPlayerIndex then
        if CircleType_field:get_data(shellObj) == HarvestMoonCircleType_OutSide then
            local lifeTimer = lifeTimer_field:get_data(shellObj);
            this.CircleTimer = lifeTimer ~= nil and Constants.LUA.string_format(HarvestMoonTimer_String, lifeTimer) or nil;
        end
    end
end

local LongSwordShell010_start = nil;
Constants.SDK.hook(LongSwordShell010_type_def:get_method("start"), function(args)
    LongSwordShell010_start = Constants.SDK.to_managed_object(args[2]);
    if Constants.MasterPlayerIndex == nil then
        Constants.GetMasterPlayerId(nil);
    end
end, function()
    if LongSwordShell010_start then
        getHarvestMoonTimer(LongSwordShell010_start);
    end
    LongSwordShell010_start = nil;
end);

local LongSwordShell010_update = nil;
Constants.SDK.hook(LongSwordShell010_type_def:get_method("update"), function(args)
    LongSwordShell010_update = Constants.SDK.to_managed_object(args[2]);
    if Constants.MasterPlayerIndex == nil then
        Constants.GetMasterPlayerId(nil);
    end
end, function()
    if LongSwordShell010_update then
        getHarvestMoonTimer(LongSwordShell010_update);
    end
    LongSwordShell010_update = nil;
end);

local LongSwordShell010_onDestroy = nil;
Constants.SDK.hook(LongSwordShell010_type_def:get_method("onDestroy"), function(args)
    LongSwordShell010_onDestroy = Constants.SDK.to_managed_object(args[2]);
    if Constants.MasterPlayerIndex == nil then
        Constants.GetMasterPlayerId(nil);
    end
    if LongSwordShell010_onDestroy and (get_OwnerId_method:call(LongSwordShell010_onDestroy) ~= Constants.MasterPlayerIndex) then
        LongSwordShell010_onDestroy = nil;
    end
end, function()
    if LongSwordShell010_onDestroy and CircleType_field:get_data(LongSwordShell010_onDestroy) == HarvestMoonCircleType_OutSide then
        this.CircleTimer = nil;
    end
    LongSwordShell010_onDestroy = nil;
end);

return this;