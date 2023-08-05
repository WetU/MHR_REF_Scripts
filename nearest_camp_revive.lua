local Constants = _G.require("Constants.Constants");

local ipairs = Constants.lua.ipairs;

local find_type_definition = Constants.sdk.find_type_definition;
local get_managed_singleton = Constants.sdk.get_managed_singleton;
local to_managed_object = Constants.sdk.to_managed_object;
local to_float = Constants.sdk.to_float;
local hook = Constants.sdk.hook;
local SKIP_ORIGINAL = Constants.sdk.SKIP_ORIGINAL;

local Vector3f_new = Constants.Vector3f.new;

local getDeathNum = Constants.getDeathNum;
local getQuestLife = Constants.getQuestLife;
local getQuestMapNo = Constants.getQuestMapNo;
local to_byte = Constants.to_byte;
--
local calcDistance_method = find_type_definition("snow.CharacterMathUtility"):get_method("calcDistance(via.vec3, via.vec3)"); -- static
--
local GetTransform_method = Constants.type_definitions.CameraManager_type_def:get_method("GetTransform(snow.CameraManager.GameObjectType)");
local get_Position_method = GetTransform_method:get_return_type():get_method("get_Position");

local GameObjectType_MasterPlayer = find_type_definition("snow.CameraManager.GameObjectType"):get_field("MasterPlayer"):get_data(nil);
--
local CreateNekotaku_method = find_type_definition("snow.NekotakuManager"):get_method("CreateNekotaku(snow.player.PlayerIndex, via.vec3, System.Single)");
--
local get_FastTravelPointList_method = find_type_definition("snow.stage.StagePointManager"):get_method("get_FastTravelPointList");

local FastTravelPointList_get_Item_method = get_FastTravelPointList_method:get_return_type():get_method("get_Item(System.Int32)");

local get_Points_method = FastTravelPointList_get_Item_method:get_return_type():get_method("get_Points");

local Points_get_Item_method = get_Points_method:get_return_type():get_method("get_Item(System.Int32)");
--
local StageManager_type_def = find_type_definition("snow.stage.StageManager");
local setPlWarpInfo_method = StageManager_type_def:get_method("setPlWarpInfo(via.vec3, System.Single, snow.stage.StageManager.AreaMoveQuest)");

local AreaMoveQuest_Die = find_type_definition("snow.stage.StageManager.AreaMoveQuest"):get_field("Die"):get_data(nil);
--
local QuestMapList = Constants.QuestMapList;
local SubCampRevivalPos = {
    [QuestMapList.ShrineRuins] = {
        Vector3f_new(236.707, 174.37, -510.568)
    },
    [QuestMapList.SandyPlains] = {
        Vector3f_new(-117.699, -45.653, -233.201),
        Vector3f_new(116.07, -63.316, -428.018)
    },
    [QuestMapList.FloodedForest] = {
        Vector3f_new(207.968, 90.447, 46.081)
    },
    [QuestMapList.FrostIslands] = {
        Vector3f_new(-94.171, 2.744, -371.947),
        Vector3f_new(103.986, 26.0, -496.863)
    },
    [QuestMapList.LavaCaverns] = {
        Vector3f_new(244.252, 147.122, -537.940),
        Vector3f_new(-40.000, 81.136, -429.201)
    },
    [QuestMapList.Jungle] = {
        Vector3f_new(3.854, 32.094, -147.152)
    },
    [QuestMapList.Citadel] = {
        Vector3f_new(107.230, 94.988, -254.308)
    }
};
--
local reviveCampPos = nil;

local function PreHook_startToPlayPlayerDieMusic()
    reviveCampPos = nil;

    local QuestManager = get_managed_singleton("snow.QuestManager");

    if getDeathNum(QuestManager) < getQuestLife(QuestManager) then
        local subCamps = SubCampRevivalPos[getQuestMapNo(QuestManager)];

        if subCamps ~= nil then
            local currentPos = get_Position_method:call(GetTransform_method:call(get_managed_singleton("snow.CameraManager"), GameObjectType_MasterPlayer));
            local nearestDistance = calcDistance_method:call(nil, currentPos, Points_get_Item_method:call(get_Points_method:call(FastTravelPointList_get_Item_method:call(get_FastTravelPointList_method:call(get_managed_singleton("snow.stage.StagePointManager")), 0)), 0));

            if #subCamps > 1 then
                for _, subCampPos in ipairs(subCamps) do
                    local distance = calcDistance_method:call(nil, currentPos, subCampPos);

                    if distance < nearestDistance then
                        nearestDistance = distance;
                        reviveCampPos = subCampPos;
                    end
                end
            else
                local subCampPos = subCamps[1];
                if calcDistance_method:call(nil, currentPos, subCampPos) < nearestDistance then
                    reviveCampPos = subCampPos;
                end
            end
        end
    end
end

local function PreHook_setPlWarpInfo_Nekotaku(args)
    if reviveCampPos ~= nil then
        setPlWarpInfo_method:call(to_managed_object(args[2]) or get_managed_singleton("snow.stage.StageManager"), reviveCampPos, 0.0, AreaMoveQuest_Die);
        return SKIP_ORIGINAL;
    end
end

local function PreHook_CreateNekotaku(args)
    if reviveCampPos ~= nil then
        local campPos = reviveCampPos;
        reviveCampPos = nil;
        CreateNekotaku_method:call(to_managed_object(args[2]) or get_managed_singleton("snow.NekotakuManager"), to_byte(args[3]), campPos, to_float(args[5]));
        return SKIP_ORIGINAL;
    end
end

hook(find_type_definition("snow.wwise.WwiseMusicManager"):get_method("startToPlayPlayerDieMusic"), PreHook_startToPlayPlayerDieMusic);
hook(StageManager_type_def:get_method("setPlWarpInfo_Nekotaku"), PreHook_setPlWarpInfo_Nekotaku);
hook(CreateNekotaku_method, PreHook_CreateNekotaku);