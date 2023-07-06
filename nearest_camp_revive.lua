local Constants = require("Constants.Constants");
if not Constants then
	return;
end
--
local get_CurrentMapNo_method = Constants.SDK.find_type_definition("snow.QuestMapManager"):get_method("get_CurrentMapNo"); -- retval
local createNekotaku_method = Constants.SDK.find_type_definition("snow.NekotakuManager"):get_method("CreateNekotaku(snow.player.PlayerIndex, via.vec3, System.Single)");
local GetTransform_method = Constants.type_definitions.CameraManager_type_def:get_method("GetTransform(snow.CameraManager.GameObjectType)");

local get_Position_method = GetTransform_method:get_return_type():get_method("get_Position");

local StagePointManager_type_def = Constants.SDK.find_type_definition("snow.stage.StagePointManager");
local get_FastTravelPointList_method = StagePointManager_type_def:get_method("get_FastTravelPointList"); -- retval
local TentPositionList_field = StagePointManager_type_def:get_field("_TentPositionList");

local FastTravelPointList_type_def = get_FastTravelPointList_method:get_return_type();
local FastTravelPointList_get_Count_method = FastTravelPointList_type_def:get_method("get_Count"); -- retval
local FastTravelPointList_get_Item_method = FastTravelPointList_type_def:get_method("get_Item(System.Int32)"); -- retval

local get_Points_method = FastTravelPointList_get_Item_method:get_return_type():get_method("get_Points"); -- retval

local Points_get_Item_method = get_Points_method:get_return_type():get_method("get_Item(System.Int32)"); -- retval

local TentPositionList_type_def = TentPositionList_field:get_type();
local TentPositionList_get_Count_method = TentPositionList_type_def:get_method("get_Count"); -- retval
local TentPositionList_get_Item_method = TentPositionList_type_def:get_method("get_Item(System.Int32)"); -- retval

local StageManager_type_def = Constants.SDK.find_type_definition("snow.stage.StageManager");
local get_CurrentWarpFlow_method = StageManager_type_def:get_method("get_CurrentWarpFlow");
local notifyDemoCameraEnd_method = StageManager_type_def:get_method("notifyDemoCameraEnd");
local setPlWarpInfo_method = StageManager_type_def:get_method("setPlWarpInfo(via.vec3, System.Single, snow.stage.StageManager.AreaMoveQuest)");

local WarpFlow_WaitDemo = get_CurrentWarpFlow_method:get_return_type():get_field("WaitDemo"):get_data(nil);
local AreaMoveQuest_Die = Constants.SDK.find_type_definition("snow.stage.StageManager.AreaMoveQuest"):get_field("Die"):get_data(nil);
--
local GameObjectType_MasterPlayer = Constants.SDK.find_type_definition("snow.CameraManager.GameObjectType"):get_field("MasterPlayer"):get_data(nil);
local MapNoType_type_def = get_CurrentMapNo_method:get_return_type();
local nekoTakuList = {
    [MapNoType_type_def:get_field("No01"):get_data(nil)] = { -- 사원 폐허
        [1] = Constants.VECTOR3f.new(236.707, 174.37, -510.568)
    },
    [MapNoType_type_def:get_field("No02"):get_data(nil)] = { -- 모래 평원
        [1] = Constants.VECTOR3f.new(-117.699, -45.653, -233.201),
        [2] = Constants.VECTOR3f.new(116.07, -63.316, -428.018)
    },
    [MapNoType_type_def:get_field("No03"):get_data(nil)] = { -- 수몰된 숲
        [1] = Constants.VECTOR3f.new(207.968, 90.447, 46.081)
    },
    [MapNoType_type_def:get_field("No04"):get_data(nil)] = { -- 한랭 군도
        [1] = Constants.VECTOR3f.new(-94.171, 2.744, -371.947),
        [2] = Constants.VECTOR3f.new(103.986, 26, -496.863)
    },
    [MapNoType_type_def:get_field("No05"):get_data(nil)] = { -- 용암 동굴
        [1] = Constants.VECTOR3f.new(244.252, 147.122, -537.940),
        [2] = Constants.VECTOR3f.new(-40.000, 81.136, -429.201)
    },
    [MapNoType_type_def:get_field("No31"):get_data(nil)] = { -- 밀림
        [1] = Constants.VECTOR3f.new(3.854, 32.094, -147.152)
    },
    [MapNoType_type_def:get_field("No32"):get_data(nil)] = { -- 요새고원
        [1] = Constants.VECTOR3f.new(107.230, 94.988, -254.308)
    }
};
--
local skipCreateNeko = false;
local skipWarpNeko = false;
local reviveCamp = nil;
local nekoTaku = nil;

local function getCurrentMapNo()
    local QuestMapManager = Constants.SDK.get_managed_singleton("snow.QuestMapManager");
    if QuestMapManager ~= nil then
        return get_CurrentMapNo_method:call(QuestMapManager);
    end
    return nil;
end

local function getCurrentPosition()
    local CameraManager = Constants.SDK.get_managed_singleton("snow.CameraManager");
    if CameraManager ~= nil then
        local Transform = GetTransform_method:call(CameraManager, GameObjectType_MasterPlayer);
        if Transform ~= nil then
            return get_Position_method:call(Transform);
        end
    end
    return nil;
end

local function getFastTravelPt(stagePointManager, index)
    local FastTravelPointList = get_FastTravelPointList_method:call(stagePointManager);
    if FastTravelPointList ~= nil then
        local count = FastTravelPointList_get_Count_method:call(FastTravelPointList);
        if count > 0 and (index >= 0 and index <= count - 1) then
            local FastTravelPoint = FastTravelPointList_get_Item_method:call(FastTravelPointList, index);
            if FastTravelPoint ~= nil then
                local Points = get_Points_method:call(FastTravelPoint);
                if Points ~= nil then
                    return Points_get_Item_method:call(Points, 0);
                end
            end
        end
    end
    return nil;
end

local function findNearestCamp(stagePointManager, camps, nekoTakuPos)
    local camps_count = TentPositionList_get_Count_method:call(camps);
    if camps_count > 0 then
        local currentPos = getCurrentPosition();
        if currentPos ~= nil then
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
            if nearestCampIndex ~= nil then
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
        end
    end
end
--
local function PreHook_startToPlayPlayerDieMusic()
    local StagePointManager = Constants.SDK.get_managed_singleton("snow.stage.StagePointManager");
    local mapNo = getCurrentMapNo();
    if StagePointManager ~= nil and mapNo ~= nil then
        local camps = TentPositionList_field:get_data(StagePointManager);
        local nekoTakuItem = nekoTakuList[mapNo];
        if camps ~= nil and nekoTakuItem ~= nil then
            skipCreateNeko = false;
            skipWarpNeko = false;
            reviveCamp = nil;
            nekoTaku = nil;
            findNearestCamp(StagePointManager, camps, nekoTakuItem);
        end
    end
end

local function PreHook_createNekotaku(args)
    if skipCreateNeko == true then
        skipCreateNeko = false;
        if nekoTaku ~= nil then
            local NekotakuManager = Constants.SDK.to_managed_object(args[2]);
            local PlIndex = Constants.SDK.to_int64(args[3]) & 0xFFFFFFFF;
            local AngleY = Constants.SDK.to_float(args[5]);
            if NekotakuManager ~= nil and PlIndex ~= nil and AngleY ~= nil then
                createNekotaku_method:call(NekotakuManager, PlIndex, nekoTaku, AngleY);
                return Constants.SDK.SKIP_ORIGINAL;
            end
        end
    end
end

local function PreHook_setPlWarpInfo_Nekotaku(args)
    if skipWarpNeko == true then
        skipWarpNeko = false;
        if reviveCamp ~= nil then
            local StageManager = Constants.SDK.to_managed_object(args[2]);
            if StageManager ~= nil then
                setPlWarpInfo_method:call(StageManager, reviveCamp, 0.0, AreaMoveQuest_Die);
                return Constants.SDK.SKIP_ORIGINAL;
            end
        end
    end
end

Constants.SDK.hook(Constants.SDK.find_type_definition("snow.wwise.WwiseMusicManager"):get_method("startToPlayPlayerDieMusic"), PreHook_startToPlayPlayerDieMusic);
Constants.SDK.hook(createNekotaku_method, PreHook_createNekotaku);
Constants.SDK.hook(StageManager_type_def:get_method("setPlWarpInfo_Nekotaku"), PreHook_setPlWarpInfo_Nekotaku);

local StageManager_obj = nil;
local function get_Instance(args)
    StageManager_obj = Constants.SDK.to_managed_object(args[2]);
end
local function PostHook_updateWarpFlow()
    if StageManager_obj == nil then
        return;
    end

    if get_CurrentWarpFlow_method:call(StageManager_obj) == WarpFlow_WaitDemo then
        notifyDemoCameraEnd_method:call(StageManager_obj);
    end
    StageManager_obj = nil;
end
Constants.SDK.hook(StageManager_type_def:get_method("updateWarpFlow"), get_Instance, PostHook_updateWarpFlow);