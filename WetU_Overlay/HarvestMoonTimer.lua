local Constants = _G.require("Constants.Constants");

local string_format = Constants.lua.string_format;

local to_managed_object = Constants.sdk.to_managed_object;
local hook_vtable = Constants.sdk.hook_vtable;

local getArrayCount = Constants.getArrayCount;
local getArrayItem = Constants.getArrayItem;
--
local getMasterPlayerIndex_method = Constants.type_definitions.EnemyUtility_type_def:get_method("getMasterPlayerIndex"); -- static
--
local LongSwordShell010_type_def = Constants.sdk.find_type_definition("snow.shell.LongSwordShell010");
local update_method = LongSwordShell010_type_def:get_method("update");
local onDestroy_method = LongSwordShell010_type_def:get_method("onDestroy");
local lifeTimer_field = LongSwordShell010_type_def:get_field("_lifeTimer");
local CircleType_field = LongSwordShell010_type_def:get_field("_CircleType");
local IsWarning_field = LongSwordShell010_type_def:get_field("_IsWarning");

local get_OwnerId_method = LongSwordShell010_type_def:get_parent_type():get_method("get_OwnerId");
--
local this = {
	init = true,
	CircleTimer = nil,
	IsWarning = false
};
--
local LongSwordShell010 = nil;

local function Terminate()
	this.CircleTimer = nil;
	LongSwordShell010 = nil;
end

local function UpdateHarvestMoonTimer()
	this.CircleTimer = string_format("원월 타이머: %.f초", lifeTimer_field:get_data(LongSwordShell010));
	this.IsWarning = IsWarning_field:get_data(LongSwordShell010);
end

local function PostHook_update()
	UpdateHarvestMoonTimer();
end

local function HarvestMoon_init()
	UpdateHarvestMoonTimer();
	hook_vtable(LongSwordShell010, update_method, nil, PostHook_update);
	hook_vtable(LongSwordShell010, onDestroy_method, nil, Terminate);
end

local function PreHook(args)
	LongSwordShell010 = to_managed_object(args[2]);
end
local function PostHook()
	if CircleType_field:get_data(LongSwordShell010) == 1 and get_OwnerId_method:call(LongSwordShell010) == getMasterPlayerIndex_method:call(nil) then
		HarvestMoon_init();
	end
end

local function init()
	local MasterPlayerIndex = getMasterPlayerIndex_method:call(nil);
	if MasterPlayerIndex ~= nil then
		local LongSwordShellManager = Constants.sdk.get_managed_singleton("snow.shell.LongSwordShellManager");
		if LongSwordShellManager ~= nil then
			local MaseterLongSwordShell010s = LongSwordShellManager:get_type_definition():get_method("getMaseterLongSwordShell010s(snow.player.PlayerIndex)"):call(LongSwordShellManager, MasterPlayerIndex);
			if MaseterLongSwordShell010s ~= nil then
				local count = getArrayCount(MaseterLongSwordShell010s);
				if count > 0 then
					for i = 0, count - 1, 1 do
						local MasterShell010 = getArrayItem(MaseterLongSwordShell010s, i);
						if CircleType_field:get_data(MasterShell010) == 1 then
							LongSwordShell010 = MasterShell010;
							HarvestMoon_init();
							break;
						end
					end
				end
			end
		end
	end

	Constants.sdk.hook(LongSwordShell010_type_def:get_method("start"), PreHook, PostHook);
end

this.init = init;
--
return this;