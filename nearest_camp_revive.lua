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
local getTentPosition_method = StagePointManager_type_def:get_method("getTentPosition(snow.stage.StageDef.CampType)");

local FastTravelPointList_type_def = get_FastTravelPointList_method:get_return_type();
local FastTravelPointList_get_Count_method = FastTravelPointList_type_def:get_method("get_Count");
local FastTravelPointList_get_Item_method = FastTravelPointList_type_def:get_method("get_Item(System.Int32)");

local get_Points_method = FastTravelPointList_get_Item_method:get_return_type():get_method("get_Points");

local Points_get_Item_method = get_Points_method:get_return_type():get_method("get_Item(System.Int32)");

local Nullable_via_vec3_type_def = getTentPosition_method:get_return_type();
local get_HasValue_method = Nullable_via_vec3_type_def:get_method("get_HasValue");
local get_Value_method = Nullable_via_vec3_type_def:get_method("get_Value");
--
local StageManager_type_def = sdk.find_type_definition("snow.stage.StageManager");
local setPlWarpInfo_method = StageManager_type_def:get_method("setPlWarpInfo(via.vec3, System.Single, snow.stage.StageManager.AreaMoveQuest)");
local checkSubCampUnlocked_method = StageManager_type_def:get_method("checkSubCampUnlocked(snow.stage.StageDef.SubCampId)");
--
local CampType_type_def = sdk.find_type_definition("snow.stage.StageDef.CampType");
local CampType = {
    ["BaseCamp"] = CampType_type_def:get_field("BaseCamp"):get_data(nil),
    ["SubCamp1"] = CampType_type_def:get_field("SubCamp1"):get_data(nil),
    ["SubCamp2"] = CampType_type_def:get_field("SubCamp2"):get_data(nil)
};

local AreaMoveQuest_Die = sdk.find_type_definition("snow.stage.StageManager.AreaMoveQuest"):get_field("Die"):get_data(nil);
local SubCampId_type_def = sdk.find_type_definition("snow.stage.StageDef.SubCampId");
local SubCampId = {};
local campList = {};

for mapName, mapNo in pairs(Constants.QuestMapList) do
    local subcampId = nil;
    local campPosition = nil;

    if mapName == "ShrineRuins" then
        subcampId = {
            SubCampId_type_def:get_field("SubCamp_m01_00"):get_data(nil)
        };
        campPosition = {
            Vector3f.new(236.707, 174.37, -510.568)
        };

    elseif mapName == "SandyPlains" then
        subcampId = {
            SubCampId_type_def:get_field("SubCamp_m02_00"):get_data(nil),
            SubCampId_type_def:get_field("SubCamp_m02_01"):get_data(nil)
        };
        campPosition = {
            Vector3f.new(-117.699, -45.653, -233.201),
            Vector3f.new(116.07, -63.316, -428.018)
        };

    elseif mapName == "FloodedForest" then
        subcampId = {
            SubCampId_type_def:get_field("SubCamp_m03_00"):get_data(nil)
        };
        campPosition = {
            Vector3f.new(207.968, 90.447, 46.081)
        };

    elseif mapName == "FrostIslands" then
        subcampId = {
            SubCampId_type_def:get_field("SubCamp_m04_00"):get_data(nil),
            SubCampId_type_def:get_field("SubCamp_m04_01"):get_data(nil)
        };
        campPosition = {
            Vector3f.new(-94.171, 2.744, -371.947),
            Vector3f.new(103.986, 26, -496.863)
        };

    elseif mapName == "LavaCaverns" then
        subcampId = {
            SubCampId_type_def:get_field("SubCamp_m05_00"):get_data(nil),
            SubCampId_type_def:get_field("SubCamp_m05_01"):get_data(nil)
        };
        campPosition = {
            Vector3f.new(244.252, 147.122, -537.940),
            Vector3f.new(-40.000, 81.136, -429.201)
        };

    elseif mapName == "Jungle" then
        subcampId = {
            SubCampId_type_def:get_field("SubCamp_m31_00"):get_data(nil)
        };
        campPosition = {
            Vector3f.new(3.854, 32.094, -147.152)
        };

    elseif mapName == "Citadel" then
        subcampId = {
            SubCampId_type_def:get_field("SubCamp_m32_00"):get_data(nil)
        };
        campPosition = {
            Vector3f.new(107.230, 94.988, -254.308)
        };
    end

    SubCampId[mapNo] = subcampId;
    campList[mapNo] = campPosition;
end
--
local skipCreateNeko = false;
local skipWarpNeko = false;
local reviveCamp = nil;
local nekoTaku = nil;

local function getCurrentPosition()
    return get_Position_method:call(GetTransform_method:call(sdk.get_managed_singleton("snow.CameraManager"), GameObjectType_MasterPlayer));
end

local function getCamps(stagePointManager, mapNo)
    local StageManager = sdk.get_managed_singleton("snow.stage.StageManager");

    local baseCamp = getTentPosition_method:call(stagePointManager, CampType["BaseCamp"]);
    local camps = {
        [1] = get_HasValue_method:call(baseCamp) == true and get_Value_method:call(baseCamp) or nil
    };

    local subcampIds = SubCampId[mapNo];

    for i = 1, #subcampIds, 1 do
        camps[i + 1] = nil;

        if checkSubCampUnlocked_method:call(StageManager, subcampIds[i]) == true then
            local subCamp = getTentPosition_method:call(stagePointManager, CampType["SubCamp" .. tostring(i)]);
            if get_HasValue_method:call(subCamp) == true then
                camps[i + 1] = get_Value_method:call(subCamp);
            end
        end
    end

    return camps;
end

local function getFastTravelPt(stagePointManager, index)
    local FastTravelPointList = get_FastTravelPointList_method:call(stagePointManager);
    if index < FastTravelPointList_get_Count_method:call(FastTravelPointList) then
        return Points_get_Item_method:call(get_Points_method:call(FastTravelPointList_get_Item_method:call(FastTravelPointList, index)), 0);
    end

    return nil;
end

local function findNearestCamp(stagePointManager, camps, nekoTakuPos)
    local nearestCamp = nil;
    local nearestDistance = nil;
    local nearestCampIndex = nil;
    local currentPos = getCurrentPosition();

    for i = 1, #camps, 1 do
        local camp = camps[i];
        if camp ~= nil then
            local distance = calcDistance_method:call(nil, currentPos, camp);
            if i == 1 or (distance < nearestDistance) then
                nearestCamp = camp;
                nearestDistance = distance;
                nearestCampIndex = i - 1;
            end
        end
    end

    if nearestCampIndex == nil or nearestCampIndex == 0 then
        return;
    end

    local fastTravelPt = getFastTravelPt(stagePointManager, nearestCampIndex);

    if fastTravelPt == nil and nearestCamp ~= nil then
        fastTravelPt = nearestCamp;
    end

    if fastTravelPt ~= nil then
        skipCreateNeko = true;
        skipWarpNeko = true;
        reviveCamp = fastTravelPt;
        nekoTaku = nekoTakuPos[nearestCampIndex];
        if nekoTaku == nil and reviveCamp ~= nil then
            nekoTaku = reviveCamp;
        end
    end
end
--
local function PreHook_startToPlayPlayerDieMusic()
    local questMapNo = Constants.getQuestMapNo(nil);
    local nekoTakuItem = campList[questMapNo];
    if nekoTakuItem == nil then
        return;
    end

    local StagePointManager = sdk.get_managed_singleton("snow.stage.StagePointManager");

    skipCreateNeko = false;
    skipWarpNeko = false;
    reviveCamp = nil;
    nekoTaku = nil;
    findNearestCamp(StagePointManager, getCamps(StagePointManager, questMapNo), nekoTakuItem);
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