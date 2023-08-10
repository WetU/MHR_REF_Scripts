local Constants = _G.require("Constants.Constants");

local string_format = Constants.lua.string_format;

local find_type_definition = Constants.sdk.find_type_definition;
local to_managed_object = Constants.sdk.to_managed_object;
local hook = Constants.sdk.hook;
local hook_vtable = Constants.sdk.hook_vtable;
--
local getMasterPlayerIndex_method = Constants.type_definitions.EnemyUtility_type_def:get_method("getMasterPlayerIndex"); -- static
--
local LongSwordShell010_type_def = find_type_definition("snow.shell.LongSwordShell010");
local update_method = LongSwordShell010_type_def:get_method("update");
local onDestroy_method = LongSwordShell010_type_def:get_method("onDestroy");
local lifeTimer_field = LongSwordShell010_type_def:get_field("_lifeTimer");
local CircleType_field = LongSwordShell010_type_def:get_field("_CircleType");

local get_OwnerId_method = LongSwordShell010_type_def:get_parent_type():get_method("get_OwnerId");

local HarvestMoonCircleType_OutSide = CircleType_field:get_type():get_field("Outside"):get_data(nil);
--
local this = {
	init = true,
	CircleTimer = nil
};
--
local function Terminate()
	this.CircleTimer = nil;
end

local function UpdateHarvestMoonTimer(longSwordShell010)
	this.CircleTimer = string_format("원월 타이머: %.f초", lifeTimer_field:get_data(longSwordShell010));
end

local function PreHook_update(args)
	UpdateHarvestMoonTimer(to_managed_object(args[2]));
end

local PreHook = nil;
local PostHook = nil;
do
	local LongSwordShell010 = nil;
	PreHook = function(args)
		LongSwordShell010 = to_managed_object(args[2]);
	end
	PostHook = function()
		if CircleType_field:get_data(LongSwordShell010) == HarvestMoonCircleType_OutSide and get_OwnerId_method:call(LongSwordShell010) == getMasterPlayerIndex_method:call(nil) then
			UpdateHarvestMoonTimer(LongSwordShell010);
			hook_vtable(LongSwordShell010, update_method, PreHook_update);
			hook_vtable(LongSwordShell010, onDestroy_method, nil, Terminate);
		end

		LongSwordShell010 = nil;
	end
end

local function init()
	hook(LongSwordShell010_type_def:get_method("start"), PreHook, PostHook);
end

this.init = init;
--
return this;