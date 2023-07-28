local Constants = require("Constants.Constants");
--
local calcDistance_method = sdk.find_type_definition("snow.CharacterMathUtility"):get_method("calcDistance(via.vec3, via.vec3)"); -- static
--
local GetTransform_method = Constants.type_definitions.CameraManager_type_def:get_method("GetTransform(snow.CameraManager.GameObjectType)");
local get_Position_method = GetTransform_method:get_return_type():get_method("get_Position");

local GameObjectType_MasterPlayer = sdk.find_type_definition("snow.CameraManager.GameObjectType"):get_field("MasterPlayer"):get_data(nil);
--
local createNekotaku_method = sdk.find_type_definition("snow.NekotakuManager"):get_method("CreateNekotaku(snow.player.PlayerIndex, via.vec3, System.Single)");
--
local StagePointManager_type_def = sdk.find_type_definition("snow.stage.StagePointManager");
local get_FastTravelPointList_method = StagePointManager_type_def:get_method("get_FastTravelPointList");
local TentPositionList_field = StagePointManager_type_def:get_field("_TentPositionList");

local FastTravelPointList_type_def = get_FastTravelPointList_method:get_return_type();
local FastTravelPointList_get_Count_method = FastTravelPointList_type_def:get_method("get_Count");
local FastTravelPointList_get_Item_method = FastTravelPointList_type_def:get_method("get_Item(System.Int32)");

local get_Points_method = FastTravelPointList_get_Item_method:get_return_type():get_method("get_Points");

local Points_get_Item_method = get_Points_method:get_return_type():get_method("get_Item(System.Int32)");

local TentPositionList_type_def = TentPositionList_field:get_type();
local TentPositionList_get_Count_method = TentPositionList_type_def:get_method("get_Count");
local TentPositionList_get_Item_method = TentPositionList_type_def:get_method("get_Item(System.Int32)");
--
local StageManager_type_def = sdk.find_type_definition("snow.stage.StageManager");
local setPlWarpInfo_method = StageManager_type_def:get_method("setPlWarpInfo(via.vec3, System.Single, snow.stage.StageManager.AreaMoveQuest)");
--
local AreaMoveQuest_Die = sdk.find_type_definition("snow.stage.StageManager.AreaMoveQuest"):get_field("Die"):get_data(nil);
local campList = {};

for mapName, mapNo in pairs(Constants.QuestMapList) do
    local campPosition = nil;

    if mapName == "ShrineRuins" then
        campPosition = {
            Vector3f.new(236.707, 174.37, -510.568)
        };

    elseif mapName == "SandyPlains" then
        campPosition = {
            Vector3f.new(-117.699, -45.653, -233.201),
            Vector3f.new(116.07, -63.316, -428.018)
        };

    elseif mapName == "FloodedForest" then
        campPosition = {
            Vector3f.new(207.968, 90.447, 46.081)
        };

    elseif mapName == "FrostIslands" then
        campPosition = {
            Vector3f.new(-94.171, 2.744, -371.947),
            Vector3f.new(103.986, 26, -496.863)
        };

    elseif mapName == "LavaCaverns" then
        campPosition = {
            Vector3f.new(244.252, 147.122, -537.940),
            Vector3f.new(-40.000, 81.136, -429.201)
        };

    elseif mapName == "Jungle" then
        campPosition = {
            Vector3f.new(3.854, 32.094, -147.152)
        };

    elseif mapName == "Citadel" then
        campPosition = {
            Vector3f.new(107.230, 94.988, -254.308)
        };
    end

    if campPosition ~= nil then
        campList[mapNo] = campPosition;
    end
end
--
local skipCreateNeko = false;
local skipWarpNeko = false;
local reviveCamp = nil;
local nekoTaku = nil;

local function getCurrentPosition()
    return get_Position_method:call(GetTransform_method:call(sdk.get_managed_singleton("snow.CameraManager"), GameObjectType_MasterPlayer));
end

local function getFastTravelPt(stagePointManager, index)
    local FastTravelPointList = get_FastTravelPointList_method:call(stagePointManager);
    if index < FastTravelPointList_get_Count_method:call(FastTravelPointList) then
        return Points_get_Item_method:call(get_Points_method:call(FastTravelPointList_get_Item_method:call(FastTravelPointList, index)), 0);
    end

    return nil;
end

local function findNearestCamp(stagePointManager, camps, nekoTakuPos)
    local currentPos = getCurrentPosition();

    local nearestCamp = nil;
    local nearestDistance = nil;
    local nearestCampIndex = nil;

    for i = 0, TentPositionList_get_Count_method:call(camps) - 1, 1 do
        local camp = TentPositionList_get_Item_method:call(camps, i);
        local distance = calcDistance_method:call(nil, currentPos, camp);
        if i == 0 or (distance < nearestDistance and camp.x ~= 0.0) then
            nearestCamp = camp;
            nearestDistance = distance;
            nearestCampIndex = i;
        end
    end

    if nearestCampIndex == nil then
        return;
    end

    local fastTravelPt = getFastTravelPt(stagePointManager, nearestCampIndex);
    if fastTravelPt == nil and nearestCamp ~= nil then
        fastTravelPt = nearestCamp;
    end

    if nearestCampIndex ~= 0 and fastTravelPt ~= nil then
        skipCreateNeko = true;
        skipWarpNeko = true;
        reviveCamp = Vector3f.new(fastTravelPt.x, fastTravelPt.y, fastTravelPt.z);
        nekoTaku = nekoTakuPos[nearestCampIndex];
        if nekoTaku == nil and reviveCamp ~= nil then
            nekoTaku = reviveCamp;
        end
    end
end
--
local function PreHook_startToPlayPlayerDieMusic()
    local nekoTakuItem = campList[Constants.getQuestMapNo(nil)];
    if nekoTakuItem == nil then
        return;
    end

    local StagePointManager = sdk.get_managed_singleton("snow.stage.StagePointManager");
    local camps = TentPositionList_field:get_data(StagePointManager);

    skipCreateNeko = false;
    skipWarpNeko = false;
    reviveCamp = nil;
    nekoTaku = nil;
    findNearestCamp(StagePointManager, camps, nekoTakuItem);
end

local function PreHook_createNekotaku(args)
    if skipCreateNeko == false then
        return;
    end

    skipCreateNeko = false;

    if nekoTaku == nil then
        return;
    end

    createNekotaku_method:call(sdk.to_managed_object(args[2]) or sdk.get_managed_singleton("snow.NekotakuManager"), Constants.to_byte(args[3]), nekoTaku, sdk.to_float(args[5]));
    return sdk.PreHookResult.SKIP_ORIGINAL;
end

local function PreHook_setPlWarpInfo_Nekotaku(args)
    if skipWarpNeko == false then
        return;
    end

    skipWarpNeko = false;

    if reviveCamp == nil then
        return;
    end

    setPlWarpInfo_method:call(sdk.to_managed_object(args[2]) or sdk.get_managed_singleton("snow.stage.StageManager"), reviveCamp, 0.0, AreaMoveQuest_Die);
    return sdk.PreHookResult.SKIP_ORIGINAL;
end

sdk.hook(sdk.find_type_definition("snow.wwise.WwiseMusicManager"):get_method("startToPlayPlayerDieMusic"), PreHook_startToPlayPlayerDieMusic);
sdk.hook(createNekotaku_method, PreHook_createNekotaku);
sdk.hook(StageManager_type_def:get_method("setPlWarpInfo_Nekotaku"), PreHook_setPlWarpInfo_Nekotaku);