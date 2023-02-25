---------------------------Settings----------------------
local settings = {
	disableKillCam = true; --Disables the hover view of the monster from different angles after killing them
	disableOtherCams = false; --Disables fast travel cutscene cam and end of quest cam (like petting your buddies etc.) slightly glitchy with fast travel camera transitions

	disableUiOnKill = true; --Disables the UI for the slow mo duration on monster kill

	useSlowMo = true; --Enable slow mo for a certain duration of time after the last blow on the monster
	useSlowMoInMP = true; --Whether or not to use slow mo in online quests
	useMotionBlurInSlowMo = false; --ForceAdd heavy motion blur during slowmo
	slowMoSpeed = 0.2; --Slow mo amount in percentage of realtime. 0.2 = 20% speed
	slowMoDuration = 5; --Slow mo duration in seconds
	slowMoRamp = 1.5; --Speed at which it transitions back to normal time after the slow mo duration has elapsed

	activateOnCapture = false; --will trigger slowmo/hide ui when capturing the monster

	--these only work when the script is first initialized and cannot be changed during play without resetting scripts
	--IMPORTANT: also mighttt cause freezes when using Coavins DPS meter or MHR Overlay if you change them
	activateForAllMonsters = false; --will trigger slowmo/hide ui when killing any large monster, not just the final one on quest clear
	activateByAnyPlayer = true; --will trigger slowmo/hide ui when any player kills a monster, otherwise only when you do it 
	activateByEnemies = true; --will trigger slowmo/hide ui when a small monster or your pets kill a large monster, otherwise only when players do it
	
	--keys
	--for keyboard keys you can look up keycodes online with something like a javascript keycode list or demo
	--note that some keys wont work as they are taken by the game or something idk
	padAnimSkipBtn = nil; -- persistent start button on controller, 32768 is probably start button but might be broken for some and cause slowmo not to work
	kbAnimSkipKey = 27; -- persistent escape key. 32 = spacebar
	kbToggleSlowMoKey = nil; --set this to whatever key you want to toggle slowmo
	kbToggleUiKey = nil; --set this to whatever key you want to toggle UI
}
----------------------------------------------------------
local sdk = sdk;
local sdk_find_type_definition = sdk.find_type_definition;
local sdk_get_managed_singleton = sdk.get_managed_singleton;
local sdk_get_native_singleton = sdk.get_native_singleton;
local sdk_call_native_func = sdk.call_native_func;
local sdk_to_int64 = sdk.to_int64;
local sdk_SKIP_ORIGINAL = sdk.PreHookResult.SKIP_ORIGINAL;
local sdk_CALL_ORIGINAL = sdk.PreHookResult.CALL_ORIGINAL;
local sdk_to_managed_object = sdk.to_managed_object;
local sdk_hook = sdk.hook;

local re = re;
local re_on_pre_application_entry = re.on_pre_application_entry;
local re_on_draw_ui = re.on_draw_ui;
local re_on_config_save = re.on_config_save;

local imgui = imgui;
local imgui_tree_node = imgui.tree_node;
local imgui_checkbox = imgui.checkbox;
local imgui_slider_float = imgui.slider_float;
local imgui_tree_pop = imgui.tree_pop;

local json = json;
local json_dump_file = nil;
local json_load_file = nil;

local log = log;
local log_debug = log.debug;

local pcall = pcall;
local ipairs = ipairs;
local type = type;

local jsonAvailable = json ~= nil;
if jsonAvailable == true then
	json_dump_file = json.dump_file;
	json_load_file = json.load_file;
	local loadedSettings = json_load_file("NoKillCam+SlowMo_settings.json");
	settings = loadedSettings ~= nil and loadedSettings or settings;
end

local function SaveSettings()
	if jsonAvailable == true then
		json_dump_file("NoKillCam+SlowMo_settings.json", settings);
	end
end

local hooked = false;
local isSlowMo = false;
local useSlowMoThisTime = false;
local slowMoStartTime = 0;
local curTimeScale = 1.0;
local lastHitPlayerIdx = 0;
local lastHitEnemy = nil;

local isMotionBlur = false;
local prevMotionBlurValue = nil;
local prevMotionBlurEnabled = nil;

local guiManager = nil;
local questManager = nil;
local lobbyManager = nil;
local motionBlur = nil;
local hwKB = nil;
local hwPad = nil;

local GameCamera = nil;
local PadSingleton = nil;
local GameKeyboardSingleton = nil;
local timeManager = nil;

local SceneManager = sdk_get_native_singleton("via.SceneManager");
local SceneManager_type_def = sdk_find_type_definition("via.SceneManager");

local app_type = sdk_find_type_definition("via.Application");
local get_UpTimeSecond_method = app_type:get_method("get_UpTimeSecond");
local get_ElapsedSecond_method = app_type:get_method("get_ElapsedSecond");

local getComponent_method = sdk_find_type_definition("via.GameObject"):get_method("getComponent(System.Type)");
local get_GameObject_method = sdk_find_type_definition("via.Component"):get_method("get_GameObject");

local snowPostEffectParam_type_def = sdk_find_type_definition("snow.SnowPostEffectParam");
local snowMotionBlur_field = snowPostEffectParam_type_def:get_field("_SnowMotionBlur");
local snowMotionBlur_type_def = snowMotionBlur_field:get_type();
local motionBlurEnable_field = snowMotionBlur_type_def:get_field("_Enable");
local exposureFrame_field = snowMotionBlur_type_def:get_field("_ExposureFrame");

local isHyakuryuQuest_method = sdk_find_type_definition("snow.QuestManager"):get_method("isHyakuryuQuest");

local hard_field = sdk_find_type_definition("snow.Pad"):get_field("hard");
local orTrg_method = hard_field:get_type():get_method("orTrg(snow.Pad.Button)");

local hardKeyboard_field = sdk_find_type_definition("snow.GameKeyboard"):get_field("hardKeyboard");
local getTrg_method = hardKeyboard_field:get_type():get_method("getTrg(via.hid.KeyboardKey)");

local lobbyManager_type_def = sdk_find_type_definition("snow.LobbyManager");
local IsQuestOnline_method = lobbyManager_type_def:get_method("IsQuestOnline");
local myselfQuestIndex_field = lobbyManager_type_def:get_field("_myselfQuestIndex");

local enemyType = sdk_find_type_definition("snow.enemy.EnemyCharacterBase");
local get_isBossEnemy = enemyType:get_method("get_isBossEnemy");
local getNowDieInfo_method = enemyType:get_method("getNowDieInfo");
local getAdjustPhysicalDamageRateBySkill_method = enemyType:get_method("getAdjustPhysicalDamageRateBySkill");
local calcDamageCore_method = enemyType:get_method("calcDamageCore");
local questEnemyDie_method = enemyType:get_method("questEnemyDie");

local scene_set_TimeScale_method = sdk_find_type_definition("via.Scene"):get_method("set_TimeScale(System.Single)");
local timeManager_set_TimeScale_method = sdk_find_type_definition("snow.TimeScaleManager"):get_method("set_TimeScale(System.Single)");

local InvisibleAllGUI_field = sdk_find_type_definition("snow.gui.GuiManager"):get_field("InvisibleAllGUI");

local questManager_type_def = sdk_find_type_definition("snow.QuestManager");
local endFlow_field = questManager_type_def:get_field("_EndFlow");
local endCaptureFlag_field = questManager_type_def:get_field("_EndCaptureFlag");

local get_OwnerType_method = sdk_find_type_definition("snow.enemy.EnemyDamageCalcParam"):get_method("get_OwnerType");

local RequestActive_method = sdk_find_type_definition("snow.CameraManager"):get_method("RequestActive");

local function GetMotionBlur()
	if not motionBlur then
		if not GameCamera or GameCamera:get_reference_count() <= 1 then
			GameCamera = sdk_get_managed_singleton("snow.GameCamera");
		end

		if not GameCamera then
			return nil;
		end

		local post = getComponent_method:call(get_GameObject_method:call(GameCamera), snowPostEffectParam_type_def:get_runtime_type());
		if not post then
			return nil;
		end

		motionBlur = snowMotionBlur_field:get_data(post);
	end
	return motionBlur;
end

local function StartMotionBlur()
	local motionBlur = GetMotionBlur();
	if isMotionBlur or not motionBlur then
		return;
	end
	prevMotionBlurEnabled = motionBlurEnable_field:get_data(motionBlur);
	prevMotionBlurValue = exposureFrame_field:get_data(motionBlur);
	motionBlur:set_field("_Enable", true);
	motionBlur:set_field("_ExposureFrame", 100);
	isMotionBlur = true;
end

local function EndMotionBlur()
	local motionBlur = GetMotionBlur();
	if not isMotionBlur or not motionBlur then
		return;
	end
	motionBlur:set_field("_Enable", prevMotionBlurEnabled);
	motionBlur:set_field("_ExposureFrame", prevMotionBlurValue);
	isMotionBlur = false;
end

local function GetMonsterActivateType(isEndQuest)
	if isEndQuest then
		return true;
	elseif settings.activateForAllMonsters then
		if not questManager or questManager:get_reference_count() <= 1 then
			questManager = sdk_get_managed_singleton("snow.QuestManager");
		end
		if questManager ~= nil and isHyakuryuQuest_method:call(questManager) then
			log_debug("Skip isRampage");
			return false;
		else
			return true;
		end
	end

	log_debug("SkipDefault");
	return false;
end

local function GetPadDown(kc)
	-- grabbing the gamepad manager
    if not hwPad then
		if not PadSingleton or PadSingleton:get_reference_count() <= 1 then
			PadSingleton = sdk_get_managed_singleton("snow.Pad");
		end
        hwPad = hard_field:get_data(PadSingleton); -- getting hardware keyboard manager
    end
	return orTrg_method:call(hwPad, kc);
end

local function GetKeyDown(kc)
	-- grabbing the keyboard manager    
    if not hwKB then
		if not GameKeyboardSingleton or GameKeyboardSingleton:get_reference_count() <= 1 then
			GameKeyboardSingleton = sdk_get_managed_singleton("snow.GameKeyboard");
		end
        hwKB = hardKeyboard_field:get_data(GameKeyboardSingleton); -- getting hardware keyboard manager
    end
	--return getTrg:call(hwKB, kc);
	return getTrg_method:call(hwKB, kc);
end

local function GetLobbyManager()
	if not lobbyManager or lobbyManager:get_reference_count() <= 1 then
		lobbyManager = sdk_get_managed_singleton("snow.LobbyManager");
	end
	return lobbyManager;
end

local function GetQuestIsOnline()
	return IsQuestOnline_method:call(GetLobbyManager());
end

local function GetGuiManager()
	if not guiManager or guiManager:get_reference_count() <= 1 then
		guiManager = sdk_get_managed_singleton("snow.gui.GuiManager");
	end
	return guiManager;
end

local function SetInvisibleUI(value)
	if not settings.disableUiOnKill then
		return;
	end
	GetGuiManager():set_field("InvisibleAllGUI", value);
end

local function GetTime()
	return get_UpTimeSecond_method:call(nil);
end

local function GetDeltaTime()
	--no clue why but get_DeltaTime is complete nonsense seemingly whereas get_ElapsedSecond of all things is actual deltatime
	return get_ElapsedSecond_method:call(nil);
end

local function GetShouldUseSlowMo()
	if not settings.useSlowMo then
		log_debug("Skip no slowmo");
		return false;
	end

	if not settings.useSlowMoInMP and GetQuestIsOnline() then
		log_debug("Skip no online slowmo");
		return false;
	end

	return true;
end

local function StartSlowMo()
	log_debug("StartSlowmo");
	useSlowMoThisTime = GetShouldUseSlowMo();
	isSlowMo = true;
	slowMoStartTime = GetTime();
	SetInvisibleUI(true);
end

local function CheckShouldActivate()
	log_debug("CHECK SLOWMO ACTIVATE");
	log_debug("lastHitPlayerIdx: "..lastHitPlayerIdx);

	if GetQuestIsOnline() then
		--myself index is only really valid if online so yknow
		local myIdx = myselfQuestIndex_field:get_data(GetLobbyManager());
		log_debug("MyQuestIdx: "..myIdx);

		if not settings.activateByAnyPlayer then
			if lastHitPlayerIdx ~= myIdx then
				log_debug("Skip wrong player");
				return;
			end
		end
	end

	if not settings.activateOnCapture and lastHitEnemy then
		local dieInfo = nil;
		pcall(function() 
			dieInfo = getNowDieInfo_method:call(lastHitEnemy);
		end);

		log_debug("CAPTURE DIE INFO: ", dieInfo);
		
		-- 2 == capture death
		if dieInfo and dieInfo == 2 then
			log_debug("SkipCapture");
			return;
		end
	end

	if lastHitPlayerIdx < 0 then
		log_debug("skip bad player");
		return;
	end

	StartSlowMo();
end

local function SetTimeScale(value)
	if useSlowMoThisTime then
		if not timeManager or timeManager:get_reference_count() <= 1 then
			timeManager = sdk_get_managed_singleton("snow.TimeScaleManager");
		end
		scene_set_TimeScale_method:call(sdk_call_native_func(SceneManager, SceneManager_type_def, "get_CurrentScene"), value);
		if timeManager ~= nil then
			timeManager_set_TimeScale_method:call(timeManager, value);
		end

		if settings.useMotionBlurInSlowMo and GetMotionBlur() then
			GetMotionBlur():set_field("_ExposureFrame", 100 * (1.0 - value));
		end
	end
end

local function EndSlowMo()
	curTimeScale = 1.0;
	isSlowMo = false;
	SetInvisibleUI(false);
	EndMotionBlur();
end

local function CheckSlowMoSkip()
	return (settings.kbAnimSkipKey and GetKeyDown(settings.kbAnimSkipKey)) or (settings.padAnimSkipBtn and GetPadDown(settings.padAnimSkipBtn));
end

local function HandleSlowMo()
	if settings.kbToggleSlowMoKey and GetKeyDown(settings.kbToggleSlowMoKey) then
		if curTimeScale == 1.0 then
			useSlowMoThisTime = true;
			curTimeScale = settings.slowMoSpeed;
			SetTimeScale(curTimeScale);
		else
			curTimeScale = 1.0;
			SetTimeScale(curTimeScale);
		end
	end

	if settings.kbToggleUiKey and GetKeyDown(settings.kbToggleUiKey) then
		GetGuiManager():set_field("InvisibleAllGUI", not InvisibleAllGUI_field:get_data(GetGuiManager()));
	end

	if not isSlowMo then
		return;
	end

	local curTime = GetTime();
	
	if CheckSlowMoSkip() then
		log_debug("SLOWMO: SKIPPED");
		curTimeScale = 2.0;
		EndSlowMo();
		
		--if we dont make sure this is a float(1.0 instead of 1),
		--for some reason setting timescale to (int)1 actually freezes everything to zero
		--its bizarre especially as i was led to believe that lua used only floats anyway but w/e
		SetTimeScale(1.0);
		return;
	end
	
	if curTimeScale == 1.0 then
		curTimeScale = settings.slowMoSpeed;
		if settings.useMotionBlurInSlowMo then
			StartMotionBlur();
		end
	elseif curTime - slowMoStartTime > settings.slowMoDuration then
		curTimeScale = curTimeScale + settings.slowMoRamp * GetDeltaTime();
		if curTimeScale >= 1.0 then
			EndSlowMo();
		end
	end

	SetTimeScale(curTimeScale);
end

local function PreRequestCamChange(args)
	local type = sdk_to_int64(args[3]) & 0xFFFFFFFF;
	log_debug("Switch cam type: "..type);
	if type == 3 then
		--type 3 == 'demo' camera type
		--somewhat annoyingly this is used for many different cameras, but we'll turn that into a feature anyway
		if not questManager or questManager:get_reference_count() <= 1 then
			questManager = sdk_get_managed_singleton("snow.QuestManager");
			if not questManager then
				return sdk_CALL_ORIGINAL;
			end
		end
		
		local endFlow = endFlow_field:get_data(questManager);
		--idk, this was just the first value i found that actually changes the instant you complete the quest
		local endCapture = endCaptureFlag_field:get_data(questManager);
		
		log_debug("ENDFLOW: "..endFlow);
		log_debug("ENDCAPTURE: "..endCapture);
		
		--endFlow 0 = Start
		--endFlow 1 = WaitEndTimer
		--endFlow 2 = InitCameraDemo		
		--endCapture 0 = Wait
		--endCapture 1 = Request
		--endCapture 2 = CaptureEnd
		if endFlow <= 1 and endCapture == 2 then
			if settings.disableKillCam then				
				return sdk_SKIP_ORIGINAL;
			end
		elseif settings.disableOtherCams then
			return sdk_SKIP_ORIGINAL;
		end
	end
	return sdk_CALL_ORIGINAL;
end

------------------------------------MONSTER DMG AND DEATH LOGIC--------------------------------------------
local function PreDmgCalc(args)
	if settings.activateByEnemies then
		--dont invalidate otomo and enemy attacks if this is on
		return sdk_CALL_ORIGINAL;
	end

	local enemy = sdk_to_managed_object(args[2]);
	if not get_isBossEnemy:call(enemy) then
		return sdk_CALL_ORIGINAL;
	end

	--[[
	"Creature": 7,
	"CreatureShell": 8,
	"Enemy":  1,
	"EnemyShell":  2,
	"Otomo": 5,
	"OtomoShell" 6,
	"Player":  3,
	"PlayerShell": 4,
	"Props"  0,
	]]

	lastHitEnemy = enemy;
	local hitType = get_OwnerType_method:call(sdk_to_managed_object(args[3]));
	if hitType ~= 0 and hitType ~= 3 and hitType ~= 4 then
		--set last hit to negative to invalidate this attack if the monster dies from it
		lastHitPlayerIdx = -1;
		--log.info("invalid attack type: "..hitType);
	else
		lastHitPlayerIdx = 0;
	end
	return sdk_CALL_ORIGINAL;
end

local function PrePlayerAttack(args)
	if settings.activateByAnyPlayer then
		lastHitPlayerIdx = 0;
		return sdk_CALL_ORIGINAL;
	end

	local enemy = sdk_to_managed_object(args[2]);
	if not get_isBossEnemy:call(enemy) then
		return sdk_CALL_ORIGINAL;
	end
	--set the last hit for this monster to the player that hit it
	local pIdx = sdk_to_int64(args[3]);
	lastHitPlayerIdx = pIdx;
	if lastHitPlayerIdx < 0 then
		lastHitPlayerIdx = 0;
	end
	lastHitEnemy = enemy;
	--log.info("player attack idx: "..pIdx);
	return sdk_CALL_ORIGINAL;
end

local dieEnemy = nil;
local function PreDie(args)
	dieEnemy = sdk_to_managed_object(args[2]);
	return sdk_CALL_ORIGINAL;
end

local function PostDie(retval)
	if not dieEnemy then
		return retval;
	end

	if get_isBossEnemy:call(dieEnemy) then
		if getNowDieInfo_method:call(dieEnemy) == 65535 then
			--dont trigger for non death related leavings
			return retval;
		end
		
		local isEndQuest = false;
		if not questManager or questManager:get_reference_count() <= 1 then
			questManager = sdk_get_managed_singleton("snow.QuestManager");
			if not questManager then
				return retval;
			end
		end
		
		local endFlow = endFlow_field:get_data(questManager);
		local endCapture = endCaptureFlag_field:get_data(questManager);
		
		log_debug("DIE ENDFLOW: "..endFlow);
		log_debug("DIE ENDCAPTURE: "..endCapture);
		
		isEndQuest = endCapture >= 2;	
		
		if not settings.activateForAllMonsters and not isEndQuest then
			return retval;
		end
		
		lastHitEnemy = dieEnemy;
		if GetMonsterActivateType(isEndQuest) then
			CheckShouldActivate();
		end
	end

	return retval;
end

local function CheckHook()
	if hooked then
		return;
	end

	sdk_hook(RequestActive_method, PreRequestCamChange);
	sdk_hook(getAdjustPhysicalDamageRateBySkill_method, PrePlayerAttack, nil, true);
	sdk_hook(calcDamageCore_method, PreDmgCalc, nil, true);
	sdk_hook(questEnemyDie_method, PreDie, PostDie, true);

	log_debug("SlowmoHook");
	hooked = true;
end

re_on_pre_application_entry("UpdateBehavior", function()
	CheckHook();
	HandleSlowMo();
end);


-------------------------UI GARBAGE----------------------------------
re_on_draw_ui(function()
    if imgui_tree_node("No Kill-Cam + SlowMo") then
		_, settings.disableKillCam = imgui_checkbox("Disable KillCam", settings.disableKillCam);
		_, settings.disableOtherCams = imgui_checkbox("Disable Other Cams", settings.disableOtherCams);
		_, settings.disableUiOnKill = imgui_checkbox("Disable UI on Kill", settings.disableUiOnKill);
		_, settings.useSlowMo = imgui_checkbox("Use SlowMo", settings.useSlowMo);
		_, settings.useSlowMoInMP = imgui_checkbox("Use SlowMo Online", settings.useSlowMoInMP);
		_, settings.useMotionBlurInSlowMo = imgui_checkbox("Use Motion Blur In SlowMo", settings.useMotionBlurInSlowMo);

		_, settings.slowMoSpeed = imgui_slider_float("SlowMo Speed", settings.slowMoSpeed, 0.01, 1.0);
		_, settings.slowMoDuration = imgui_slider_float("SlowMo Duration", settings.slowMoDuration, 0.1, 15.0);
		_, settings.slowMoRamp = imgui_slider_float("SlowMo Ramp", settings.slowMoRamp, 0.1, 10);

		_, settings.activateForAllMonsters = imgui_checkbox("Activate For All Monsters", settings.activateForAllMonsters);
		_, settings.activateByAnyPlayer = imgui_checkbox("Activate By Any Player", settings.activateByAnyPlayer);
		_, settings.activateByEnemies = imgui_checkbox("Activate by Enemies", settings.activateByEnemies);
		_, settings.activateOnCapture = imgui_checkbox("Activate on Capture", settings.activateOnCapture);

		--[[
		--debug
		changed, hooked = imgui_checkbox("hooked", hooked);
		changed, isSlowMo = imgui_checkbox("isSlowMo", isSlowMo);
		if changed and isSlowMo then
			StartSlowMo();
		end
		
		changed, curTimeScale = imgui_slider_float("curTimeScale", curTimeScale, 0, 1);
		changed, slowMoStartTime = imgui_slider_float("slowMoStartTime", slowMoStartTime, 0, 9999999);

		changed, lastHitPlayerIdx = imgui.slider_int("lastHitPlayerIdx", lastHitPlayerIdx, -1, 3);
		--]]
        imgui_tree_pop();
    end
end);

re_on_config_save(SaveSettings);
