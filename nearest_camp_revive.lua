local Constants = require("Constants.Constants");
if not Constants then
	return;
end

local settings = Constants.JSON.load_file("Nearest_camp_revive.json") or {enable = true};
if settings.enable == nil then
    settings.enable = true
end
--
local get_CurrentMapNo_method = Constants.SDK.find_type_definition("snow.QuestMapManager"):get_method("get_CurrentMapNo"); -- retval
local createNekotaku_method = Constants.SDK.find_type_definition("snow.NekotakuManager"):get_method("CreateNekotaku(snow.player.PlayerIndex, via.vec3, System.Single)");
local GetTransform_method = Constants.type_definitions.CameraManager_type_def:get_method("GetTransform(snow.CameraManager.GameObjectType)");

local get_Position_method = GetTransform_method:get_return_type():get_method("get_Position");

local stagePointManager_type_def = Constants.SDK.find_type_definition("snow.stage.StagePointManager");
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

local stageManager_type_def = Constants.SDK.find_type_definition("snow.stage.StageManager");
local setPlWarpInfo_method = stageManager_type_def:get_method("setPlWarpInfo(via.vec3, System.Single, snow.stage.StageManager.AreaMoveQuest)");

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
    if QuestMapManager then
        local CurrentMapNo = get_CurrentMapNo_method:call(QuestMapManager);
        if CurrentMapNo ~= nil then
            return CurrentMapNo;
        end
    end
    return nil;
end

local function getCurrentPosition()
    local CameraManager = Constants.SDK.get_managed_singleton("snow.CameraManager");
    if CameraManager then
        local Transform = GetTransform_method:call(CameraManager, GameObjectType_MasterPlayer);
        if Transform then
            local Position = get_Position_method:call(Transform);
            if Position then
                return Position;
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
        if count > 0 and (index >= 0 and index <= count - 1) then
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
                    reviveCamp = Constants.VECTOR3f.new(fastTravelPt.x, fastTravelPt.y, fastTravelPt.z);
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
    Constants.JSON.dump_file("Nearest_camp_revive.json", settings);
end

Constants.RE.on_draw_ui(function()
    local changed = false;
	if Constants.IMGUI.tree_node("Nearest Camp Revive") then
		changed, settings.enable = Constants.IMGUI.checkbox("Enabled", settings.enable);
        if changed then
            SaveSettings();
        end
		Constants.IMGUI.tree_pop();
	end
end);

Constants.RE.on_config_save(SaveSettings);

Constants.SDK.hook(Constants.SDK.find_type_definition("snow.wwise.WwiseMusicManager"):get_method("startToPlayPlayerDieMusic"), function()
    if settings.enable then
        local StagePointManager = Constants.SDK.get_managed_singleton("snow.stage.StagePointManager");
        local mapNo = getCurrentMapNo();
        if StagePointManager and mapNo ~= nil then
            local camps = getCampList(StagePointManager);
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
end);

Constants.SDK.hook(createNekotaku_method, function(args)
    if skipCreateNeko then
        skipCreateNeko = false;
        if nekoTaku ~= nil then
            local NekotakuManager = Constants.SDK.to_managed_object(args[2]);
            local PlIndex = Constants.SDK.to_int64(args[3]) & 0xFFFFFFFF;
            local AngleY = Constants.SDK.to_float(args[5]);
            if NekotakuManager and PlIndex ~= nil and AngleY ~= nil then
                createNekotaku_method:call(NekotakuManager, PlIndex, nekoTaku, AngleY);
                return Constants.SDK.SKIP_ORIGINAL;
            end
        end
    end
end);

Constants.SDK.hook(stageManager_type_def:get_method("setPlWarpInfo_Nekotaku"), function(args)
    if skipWarpNeko then
        skipWarpNeko = false;
        if reviveCamp ~= nil then
            local StageManager = Constants.SDK.to_managed_object(args[2]);
            if StageManager then
                setPlWarpInfo_method:call(StageManager, reviveCamp, 0.0, AreaMoveQuest_Die);
                return Constants.SDK.SKIP_ORIGINAL;
            end
        end
    end
end);