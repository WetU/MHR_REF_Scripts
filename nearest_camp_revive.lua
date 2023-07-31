local Constants = require("Constants.Constants");
--
local calcDistance_method = sdk.find_type_definition("snow.CharacterMathUtility"):get_method("calcDistance(via.vec3, via.vec3)"); -- static
--
local GetTransform_method = Constants.type_definitions.CameraManager_type_def:get_method("GetTransform(snow.CameraManager.GameObjectType)");
local get_Position_method = GetTransform_method:get_return_type():get_method("get_Position");

local GameObjectType_MasterPlayer = sdk.find_type_definition("snow.CameraManager.GameObjectType"):get_field("MasterPlayer"):get_data(nil);
--
local CreateNekotaku_method = sdk.find_type_definition("snow.NekotakuManager"):get_method("CreateNekotaku(snow.player.PlayerIndex, via.vec3, System.Single)");
--
local get_FastTravelPointList_method = sdk.find_type_definition("snow.stage.StagePointManager"):get_method("get_FastTravelPointList");

local FastTravelPointList_get_Item_method = get_FastTravelPointList_method:get_return_type():get_method("get_Item(System.Int32)");

local get_Points_method = FastTravelPointList_get_Item_method:get_return_type():get_method("get_Points");

local Points_get_Item_method = get_Points_method:get_return_type():get_method("get_Item(System.Int32)");
--
local StageManager_type_def = sdk.find_type_definition("snow.stage.StageManager");
local setPlWarpInfo_method = StageManager_type_def:get_method("setPlWarpInfo(via.vec3, System.Single, snow.stage.StageManager.AreaMoveQuest)");

local AreaMoveQuest_Die = sdk.find_type_definition("snow.stage.StageManager.AreaMoveQuest"):get_field("Die"):get_data(nil);
--
local SubCampRevivalPos = {
    [Constants.QuestMapList.ShrineRuins] = {
        [1] = Vector3f.new(236.707, 174.37, -510.568)
    },
    [Constants.QuestMapList.SandyPlains] = {
        [1] = Vector3f.new(-117.699, -45.653, -233.201),
        [2] = Vector3f.new(116.07, -63.316, -428.018)
    },
    [Constants.QuestMapList.FloodedForest] = {
        [1] = Vector3f.new(207.968, 90.447, 46.081)
    },
    [Constants.QuestMapList.FrostIslands] = {
        [1] = Vector3f.new(-94.171, 2.744, -371.947),
        [2] = Vector3f.new(103.986, 26.0, -496.863)
    },
    [Constants.QuestMapList.LavaCaverns] = {
        [1] = Vector3f.new(244.252, 147.122, -537.940),
        [2] = Vector3f.new(-40.000, 81.136, -429.201)
    },
    [Constants.QuestMapList.Jungle] = {
        [1] = Vector3f.new(3.854, 32.094, -147.152)
    },
    [Constants.QuestMapList.Citadel] = {
        [1] = Vector3f.new(107.230, 94.988, -254.308)
    }
};
--
local reviveCampPos = nil;

local function PreHook_startToPlayPlayerDieMusic()
    reviveCampPos = nil;

    local QuestManager = sdk.get_managed_singleton("snow.QuestManager");

    if Constants.getDeathNum(QuestManager) < Constants.getQuestLife(QuestManager) then
        local subCamps = SubCampRevivalPos[Constants.getQuestMapNo(QuestManager)];

        if subCamps ~= nil then
            local currentPos = get_Position_method:call(GetTransform_method:call(sdk.get_managed_singleton("snow.CameraManager"), GameObjectType_MasterPlayer));
            local nearestDistance = calcDistance_method:call(nil, currentPos, Points_get_Item_method:call(get_Points_method:call(FastTravelPointList_get_Item_method:call(get_FastTravelPointList_method:call(sdk.get_managed_singleton("snow.stage.StagePointManager")), 0)), 0));

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
        setPlWarpInfo_method:call(sdk.to_managed_object(args[2]) or sdk.get_managed_singleton("snow.stage.StageManager"), reviveCampPos, 0.0, AreaMoveQuest_Die);
        return sdk.PreHookResult.SKIP_ORIGINAL;
    end
end

local function PreHook_createNekotaku(args)
    if reviveCampPos ~= nil then
        local campPos = reviveCampPos;
        reviveCampPos = nil;
        CreateNekotaku_method:call(sdk.to_managed_object(args[2]) or sdk.get_managed_singleton("snow.NekotakuManager"), Constants.to_byte(args[3]), campPos, sdk.to_float(args[5]));
        return sdk.PreHookResult.SKIP_ORIGINAL;
    end
end

sdk.hook(sdk.find_type_definition("snow.wwise.WwiseMusicManager"):get_method("startToPlayPlayerDieMusic"), PreHook_startToPlayPlayerDieMusic);
sdk.hook(StageManager_type_def:get_method("setPlWarpInfo_Nekotaku"), PreHook_setPlWarpInfo_Nekotaku);
sdk.hook(CreateNekotaku_method, PreHook_createNekotaku);