local Constants = require("Constants.Constants");
if Constants == nil then
	return;
end
--
local createNekotaku_method = Constants.SDK.find_type_definition("snow.NekotakuManager"):get_method("CreateNekotaku(snow.player.PlayerIndex, via.vec3, System.Single)");
--
local StagePointManager_type_def = Constants.SDK.find_type_definition("snow.stage.StagePointManager");
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
local StageManager_type_def = Constants.SDK.find_type_definition("snow.stage.StageManager");
local setPlWarpInfo_method = StageManager_type_def:get_method("setPlWarpInfo(via.vec3, System.Single, snow.stage.StageManager.AreaMoveQuest)");
--
local AreaMoveQuest_Die = Constants.SDK.find_type_definition("snow.stage.StageManager.AreaMoveQuest"):get_field("Die"):get_data(nil);
local campList = {};

for mapName, mapNo in Constants.LUA.pairs(Constants.QuestMapList) do
    local campPosition = nil;

    if mapName == "Shrine Ruins" then
        campPosition = {
            Constants.VECTOR3f.new(236.707, 174.37, -510.568)
        };

    elseif mapName == "Sandy Plains" then
        campPosition = {
            Constants.VECTOR3f.new(-117.699, -45.653, -233.201),
            Constants.VECTOR3f.new(116.07, -63.316, -428.018)
        };

    elseif mapName == "Flooded Forest" then
        campPosition = {
            Constants.VECTOR3f.new(207.968, 90.447, 46.081)
        };

    elseif mapName == "Frost Islands" then
        campPosition = {
            Constants.VECTOR3f.new(-94.171, 2.744, -371.947),
            Constants.VECTOR3f.new(103.986, 26, -496.863)
        };

    elseif mapName == "Lava Caverns" then
        campPosition = {
            Constants.VECTOR3f.new(244.252, 147.122, -537.940),
            Constants.VECTOR3f.new(-40.000, 81.136, -429.201)
        };

    elseif mapName == "Jungle" then
        campPosition = {
            Constants.VECTOR3f.new(3.854, 32.094, -147.152)
        };

    elseif mapName == "Citadel" then
        campPosition = {
            Constants.VECTOR3f.new(107.230, 94.988, -254.308)
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

local function getFastTravelPt(stagePointManager, index)
    if index >= 0 then
        local FastTravelPointList = get_FastTravelPointList_method:call(stagePointManager);
        if FastTravelPointList ~= nil then
            local count = FastTravelPointList_get_Count_method:call(FastTravelPointList);
            if count ~= nil and index < count then
                local FastTravelPoint = FastTravelPointList_get_Item_method:call(FastTravelPointList, index);
                if FastTravelPoint ~= nil then
                    local Points = get_Points_method:call(FastTravelPoint);
                    if Points ~= nil then
                        return Points_get_Item_method:call(Points, 0);
                    end
                end
            end
        end
    end
    return nil;
end

local function findNearestCamp(stagePointManager, camps, nekoTakuPos)
    local camps_count = TentPositionList_get_Count_method:call(camps);
    if camps_count == nil then
        return;
    end

    local currentPos = Constants.getCurrentPosition();
    if currentPos == nil then
        return;
    end

    local nearestCamp = nil;
    local nearestDistance = nil;
    local nearestCampIndex = nil;

    for i = 0, camps_count - 1, 1 do
        local camp = TentPositionList_get_Item_method:call(camps, i);
        if camp ~= nil then
            local camp_x = camp.x;
            local distance = ((currentPos.x - camp_x) ^ 2 + (currentPos.z - camp.z) ^ 2) ^ 0.5;
            if (i == 0) or ((nearestDistance ~= nil and distance < nearestDistance) and camp_x ~= 0.0) then
                nearestCamp = camp;
                nearestDistance = distance;
                nearestCampIndex = i;
            end
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
        reviveCamp = Constants.VECTOR3f.new(fastTravelPt.x, fastTravelPt.y, fastTravelPt.z);
        nekoTaku = nekoTakuPos[nearestCampIndex];
        if nekoTaku == nil and reviveCamp ~= nil then
            nekoTaku = reviveCamp;
        end
    end
end
--
local function PreHook_startToPlayPlayerDieMusic()
    local StagePointManager = Constants.SDK.get_managed_singleton("snow.stage.StagePointManager");
    if StagePointManager == nil then
        return;
    end

    local mapNo = Constants.getQuestMapNo(nil);
    if mapNo == nil then
        return;
    end

    local camps = TentPositionList_field:get_data(StagePointManager);
    if camps == nil then
        return;
    end

    local nekoTakuItem = campList[mapNo];
    if nekoTakuItem == nil then
        return;
    end

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

    local NekotakuManager = Constants.SDK.to_managed_object(args[2]);
    if NekotakuManager == nil then
        return;
    end

    createNekotaku_method:call(NekotakuManager, Constants.to_byte(args[3]), nekoTaku, Constants.SDK.to_float(args[5]));
    return Constants.SDK.SKIP_ORIGINAL;
end

local function PreHook_setPlWarpInfo_Nekotaku(args)
    if skipWarpNeko == false then
        return;
    end

    skipWarpNeko = false;
    if reviveCamp == nil then
        return;
    end

    local StageManager = Constants.SDK.to_managed_object(args[2]);
    if StageManager == nil then
        return;
    end

    setPlWarpInfo_method:call(StageManager, reviveCamp, 0.0, AreaMoveQuest_Die);
    return Constants.SDK.SKIP_ORIGINAL;
end

Constants.SDK.hook(Constants.SDK.find_type_definition("snow.wwise.WwiseMusicManager"):get_method("startToPlayPlayerDieMusic"), PreHook_startToPlayPlayerDieMusic);
Constants.SDK.hook(createNekotaku_method, PreHook_createNekotaku);
Constants.SDK.hook(StageManager_type_def:get_method("setPlWarpInfo_Nekotaku"), PreHook_setPlWarpInfo_Nekotaku);