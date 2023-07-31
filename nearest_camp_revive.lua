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
local get_FastTravelPointList_method = sdk.find_type_definition("snow.stage.StagePointManager"):get_method("get_FastTravelPointList");

local FastTravelPointList_type_def = get_FastTravelPointList_method:get_return_type();
local FastTravelPointList_get_Count_method = FastTravelPointList_type_def:get_method("get_Count");
local FastTravelPointList_get_Item_method = FastTravelPointList_type_def:get_method("get_Item(System.Int32)");

local get_Points_method = FastTravelPointList_get_Item_method:get_return_type():get_method("get_Points");

local Points_get_Item_method = get_Points_method:get_return_type():get_method("get_Item(System.Int32)");
--
local StageManager_type_def = sdk.find_type_definition("snow.stage.StageManager");
local setPlWarpInfo_method = StageManager_type_def:get_method("setPlWarpInfo(via.vec3, System.Single, snow.stage.StageManager.AreaMoveQuest)");

local AreaMoveQuest_Die = sdk.find_type_definition("snow.stage.StageManager.AreaMoveQuest"):get_field("Die"):get_data(nil);
--
local skipCreateNeko = false;
local skipWarpNeko = false;
local reviveCamp = nil;

local function PreHook_startToPlayPlayerDieMusic()
    local QuestManager = sdk.get_managed_singleton("snow.QuestManager");
    if Constants.getDeathNum(QuestManager) < Constants.getQuestLife(QuestManager) then
        local questMapNo = Constants.getQuestMapNo(QuestManager);

        for _, campMapNo in pairs(Constants.QuestMapList) do
            if questMapNo == campMapNo then
                local nearestDistance = nil;

                local currentPos = get_Position_method:call(GetTransform_method:call(sdk.get_managed_singleton("snow.CameraManager"), GameObjectType_MasterPlayer));
                local FastTravelPointList = get_FastTravelPointList_method:call(sdk.get_managed_singleton("snow.stage.StagePointManager"));

                for i = 0, FastTravelPointList_get_Count_method:call(FastTravelPointList) - 1, 1 do
                    local Point = Points_get_Item_method:call(get_Points_method:call(FastTravelPointList_get_Item_method:call(FastTravelPointList, i)), 0);
                    local distance = calcDistance_method:call(nil, currentPos, Point);
                    if i == 0 or (distance < nearestDistance) then
                        nearestDistance = distance;
                        skipCreateNeko = true;
                        skipWarpNeko = true;
                        reviveCamp = Point;
                    end
                end

                break;
            end
        end
    end
end

local function PreHook_setPlWarpInfo_Nekotaku(args)
    if skipWarpNeko == true then
        skipWarpNeko = false;

        if reviveCamp ~= nil then
            setPlWarpInfo_method:call(sdk.to_managed_object(args[2]) or sdk.get_managed_singleton("snow.stage.StageManager"), reviveCamp, 0.0, AreaMoveQuest_Die);
            return sdk.PreHookResult.SKIP_ORIGINAL;
        end
    end
end

local function PreHook_createNekotaku(args)
    if skipCreateNeko == true then
        skipCreateNeko = false;

        if reviveCamp ~= nil then
            createNekotaku_method:call(sdk.to_managed_object(args[2]) or sdk.get_managed_singleton("snow.NekotakuManager"), Constants.to_byte(args[3]), reviveCamp, sdk.to_float(args[5]));
            reviveCamp = nil;
            return sdk.PreHookResult.SKIP_ORIGINAL;
        end
    end
end

sdk.hook(sdk.find_type_definition("snow.wwise.WwiseMusicManager"):get_method("startToPlayPlayerDieMusic"), PreHook_startToPlayPlayerDieMusic);
sdk.hook(StageManager_type_def:get_method("setPlWarpInfo_Nekotaku"), PreHook_setPlWarpInfo_Nekotaku);
sdk.hook(createNekotaku_method, PreHook_createNekotaku);