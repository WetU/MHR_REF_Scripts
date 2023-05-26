local json = json;

local Vector3f = Vector3f;
local Vector3f_new = Vector3f.new;

local sdk = sdk;
local sdk_call_native_func = sdk.call_native_func;
local sdk_find_type_definition = sdk.find_type_definition;
local sdk_get_managed_singleton = sdk.get_managed_singleton;
local sdk_to_managed_object = sdk.to_managed_object;
local sdk_to_float = sdk.to_float;
local sdk_to_int64 = sdk.to_int64;
local sdk_hook = sdk.hook;
local sdk_SKIP_ORIGINAL = sdk.PreHookResult.SKIP_ORIGINAL;

local re = re;

local imgui = imgui;
local imgui_tree_node = imgui.tree_node;
local imgui_checkbox = imgui.checkbox;
local imgui_tree_pop = imgui.tree_pop;

local settings = json.load_file("Nearest_camp_revive.json") or {enable = true};
if settings.enable == nil then
    settings.enable = true
end

local nekoTakuList = {
    [1] = {
        [1] = Vector3f_new(236.707, 174.37, -510.568)
    },
    [2] = {
        [1] = Vector3f_new(-117.699, -45.653, -233.201),
        [2] = Vector3f_new(116.07, -63.316, -428.018)
    },
    [3] = {
        [1] = Vector3f_new(207.968, 90.447, 46.081)
    },
    [4] = {
        [1] = Vector3f_new(-94.171, 2.744, -371.947),
        [2] = Vector3f_new(103.986, 26, -496.863)
    },
    [5] = {
        [1] = Vector3f_new(244.252, 147.122, -537.940),
        [2] = Vector3f_new(-40.000, 81.136, -429.201)
    },
    [12] = {
        [1] = Vector3f_new(3.854, 32.094, -147.152)
    },
    [13] = {
        [1] = Vector3f_new(107.230, 94.988, -254.308)
    }
};
--
local get_CurrentMapNo_method = sdk_find_type_definition("snow.QuestMapManager"):get_method("get_CurrentMapNo"); -- retval
local createNekotaku_method = sdk_find_type_definition("snow.NekotakuManager"):get_method("CreateNekotaku(snow.player.PlayerIndex, via.vec3, System.Single)");

local findMasterPlayer_method = sdk_find_type_definition("snow.player.PlayerManager"):get_method("findMasterPlayer"); -- retval

local get_GameObject_method = findMasterPlayer_method:get_return_type():get_method("get_GameObject");

local GameObject_type_def = get_GameObject_method:get_return_type();

local Transform_type_def = sdk_find_type_definition("via.Transform");

local stagePointManager_type_def = sdk_find_type_definition("snow.stage.StagePointManager");
local get_FastTravelPointList_method = stagePointManager_type_def:get_method("get_FastTravelPointList"); -- retval
local tentPositionList_field = stagePointManager_type_def:get_field("_TentPositionList");

local fastTravelPointList_type_def = get_FastTravelPointList_method:get_return_type();
local fastTravelPointList_get_Count_method = fastTravelPointList_type_def:get_method("get_Count"); -- retval
local fastTravelPointList_get_Item_method = fastTravelPointList_type_def:get_method("get_Item(System.Int32)"); -- retval

local get_Points_method = fastTravelPointList_get_Item_method:get_return_type():get_method("get_Points"); -- retval

local Points_get_Item_method = get_Points_method:get_return_type():get_method("get_Item(System.Int32)"); -- retval

local tentPositionList_type_def = tentPositionList_field:get_type();
local tentPositionList_get_Count_method = tentPositionList_type_def:get_method("get_Count"); -- retval
local tentPositionList_get_Item_method = tentPositionList_type_def:get_method("get_Item(System.Int32)"); -- retval

local stageManager_type_def = sdk_find_type_definition("snow.stage.StageManager");
local setPlWarpInfo_method = stageManager_type_def:get_method("setPlWarpInfo(via.vec3, System.Single, snow.stage.StageManager.AreaMoveQuest)");

local AreaMoveQuest_Die = sdk_find_type_definition("snow.stage.StageManager.AreaMoveQuest"):get_field("Die"):get_data(nil);
--
local skipCreateNeko = false;
local skipWarpNeko = false;
local reviveCamp = nil;
local nekoTaku = nil;

local function getCurrentMapNo()
    local QuestMapManager = sdk_get_managed_singleton("snow.QuestMapManager");
    if QuestMapManager then
        local CurrentMapNo = get_CurrentMapNo_method:call(QuestMapManager);
        if CurrentMapNo then
            return CurrentMapNo;
        end
    end
    return nil;
end

local function getCurrentPosition()
    local PlayerManager = sdk_get_managed_singleton("snow.player.PlayerManager");
    if PlayerManager then
        local MasterPlayer = findMasterPlayer_method:call(PlayerManager);
        if MasterPlayer then
            local GameObject = get_GameObject_method:call(MasterPlayer);
            if GameObject then
                local Transform = sdk_call_native_func(GameObject, GameObject_type_def, "get_Transform");
                if Transform then
                    local Position = sdk_call_native_func(Transform, Transform_type_def, "get_Position");
                    if Position then
                        return Position;
                    end
                end
            end
        end
    end
    return nil;
end

local function getCampList(stagePointManager)
    local TentPositionList = tentPositionList_field:get_data(stagePointManager);
    if TentPositionList then
        return TentPositionList;
    end
    return nil;
end

local function getFastTravelPt(stagePointManager, index)
    local FastTravelPointList = get_FastTravelPointList_method:call(stagePointManager);
    if FastTravelPointList then
        local count = fastTravelPointList_get_Count_method:call(FastTravelPointList);
        if count > 0 and (index > 0 and index <= count - 1) then
            local FastTravelPoint = fastTravelPointList_get_Item_method:call(FastTravelPointList, index);
            if FastTravelPoint then
                local Points = get_Points_method:call(FastTravelPoint);
                if Points then
                    local Point = Points_get_Item_method:call(Points, 0);
                    if Point then
                        return Point;
                    end
                end
            end
        end
    end
    return nil;
end

local function findNearestCamp(stagePointManager, camps, nekoTakuPos)
    local camps_count = tentPositionList_get_Count_method:call(camps);
    if camps_count > 0 then
        local currentPos = getCurrentPosition();
        if currentPos ~= nil then
            local nearestCamp = nil;
            local nearestDistance = nil;
            local nearestCampIndex = nil;
            for i = 0, camps_count - 1, 1 do
                local camp = tentPositionList_get_Item_method:call(camps, i);
                if camp then
                    local distance = ((currentPos.x - camp.x) ^ 2 + (currentPos.z - camp.z) ^ 2) ^ 0.5;
                    if (i == 0) or ((nearestDistance ~= nil and distance < nearestDistance) and camp.x ~= 0.0) then
                        nearestCamp = camp;
                        nearestDistance = distance;
                        nearestCampIndex = i;
                    end
                end
            end
            if nearestCampIndex ~= nil then
                local fastTravelPt = getFastTravelPt(stagePointManager, nearestCampIndex);
                if not fastTravelPt and nearestCamp ~= nil then
                    fastTravelPt = nearestCamp;
                end
                if nearestCampIndex ~= 0 and fastTravelPt ~= nil then
                    skipCreateNeko = true;
                    skipWarpNeko = true;
                    reviveCamp = Vector3f_new(fastTravelPt.x, fastTravelPt.y, fastTravelPt.z);
                    nekoTaku = nekoTakuPos[nearestCampIndex];
                    if not nekoTaku and reviveCamp ~= nil then
                        nekoTaku = reviveCamp;
                    end
                end
            end
        end
    end
end

local function SaveSettings()
    json.dump_file("Nearest_camp_revive.json", settings);
end

re.on_draw_ui(function()
    local changed = false;
	if imgui_tree_node("Nearest Camp Revive") then
		changed, settings.enable = imgui_checkbox("Enabled", settings.enable);
        if changed then
            SaveSettings();
        end
		imgui_tree_pop();
	end
end);

re.on_config_save(SaveSettings);

sdk_hook(sdk_find_type_definition("snow.wwise.WwiseMusicManager"):get_method("startToPlayPlayerDieMusic"), function()
    if settings.enable then
        local StagePointManager = sdk_get_managed_singleton("snow.stage.StagePointManager");
        local mapNo = getCurrentMapNo();
        if StagePointManager and mapNo ~= nil then
            skipCreateNeko = false;
            skipWarpNeko = false;
            reviveCamp = nil;
            nekoTaku = nil;
            local camps = getCampList(StagePointManager);
            local nekoTakuItem = nekoTakuList[mapNo];
            if camps ~= nil and nekoTakuItem ~= nil then
                findNearestCamp(StagePointManager, camps, nekoTakuItem);
            end
        end
    end
end);

sdk_hook(createNekotaku_method, function(args)
    if skipCreateNeko then
        skipCreateNeko = false;
        local obj = sdk_to_managed_object(args[2]);
        if obj and nekoTaku ~= nil then
            local PlIndex = sdk_to_int64(args[3]) & 0xFFFFFFFF;
            local AngY = sdk_to_float(args[5]);
            if PlIndex ~= nil and AngY ~= nil then
                createNekotaku_method:call(obj, PlIndex, nekoTaku, AngY);
                return sdk_SKIP_ORIGINAL;
            end
        end
    end
end);

sdk_hook(stageManager_type_def:get_method("setPlWarpInfo_Nekotaku"), function(args)
    if skipWarpNeko then
        skipWarpNeko = false;
        local obj = sdk_to_managed_object(args[2]);
        if obj and reviveCamp ~= nil then
            setPlWarpInfo_method:call(obj, reviveCamp, 0.0, AreaMoveQuest_Die);
            return sdk_SKIP_ORIGINAL;
        end
    end
end);