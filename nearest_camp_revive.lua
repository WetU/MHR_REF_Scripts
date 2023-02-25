local json = json;
local json_dump_file = nil;
local json_load_file = nil;

local Vector3f = Vector3f;
local Vector3f_new = Vector3f.new;

local sdk = sdk;
local sdk_get_managed_singleton = sdk.get_managed_singleton;
local sdk_find_type_definition = sdk.find_type_definition;
local sdk_to_managed_object = sdk.to_managed_object;
local sdk_CALL_ORIGINAL = sdk.PreHookResult.CALL_ORIGINAL;
local sdk_SKIP_ORIGINAL = sdk.PreHookResult.SKIP_ORIGINAL;
local sdk_hook = sdk.hook;

local re = re;
local re_on_draw_ui = re.on_draw_ui;
local re_on_config_save = re.on_config_save;

local imgui = imgui;
local imgui_tree_node = imgui.tree_node;
local imgui_checkbox = imgui.checkbox;
local imgui_tree_pop = imgui.tree_pop;

local settings = {};
local jsonAvailable = json ~= nil;

if jsonAvailable == true then
    json_dump_file = json.dump_file;
    json_load_file = json.load_file;
	local loadedSettings = json_load_file("Nearest_camp_revive.json");
    settings = loadedSettings ~= nil and loadedSettings or {enable = true};
end

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

local QuestMapManager = nil;
local PlayerManager = nil;
local StagePointManager = nil;

local get_CurrentMapNo_method = sdk_find_type_definition("snow.QuestMapManager"):get_method("get_CurrentMapNo");

local get_Position_method = sdk_find_type_definition("via.Transform"):get_method("get_Position");
local get_Transform_method = sdk_find_type_definition("via.GameObject"):get_method("get_Transform");
local get_GameObject_method = sdk_find_type_definition("snow.player.PlayerBase"):get_method("get_GameObject");
local findMasterPlayer_method = sdk_find_type_definition("snow.player.PlayerManager"):get_method("findMasterPlayer");

local stagePointManager_type_def = sdk_find_type_definition("snow.stage.StagePointManager");
local tentPositionList_field = stagePointManager_type_def:get_field("_TentPositionList");
local fastTravelPointList_field = stagePointManager_type_def:get_field("_FastTravelPointList");
local fastTravelPointList_mItems_field = fastTravelPointList_field:get_type():get_field("mItems");

local stageManager_type_def = sdk_find_type_definition("snow.stage.StageManager");
local setPlWarpInfo_method = stageManager_type_def:get_method("setPlWarpInfo(via.vec3, System.Single, snow.stage.StageManager.AreaMoveQuest)");
local setPlWarpInfo_Nekotaku_method = stageManager_type_def:get_method("setPlWarpInfo_Nekotaku");

local pointArray_field = sdk_find_type_definition("snow.stage.StagePointManager.StagePoint"):get_field("_PointArray");
local createNekotaku_method = sdk_find_type_definition("snow.NekotakuManager"):get_method("CreateNekotaku(snow.player.PlayerIndex, via.vec3, System.Single)");
local startToPlayPlayerDieMusic_method = sdk_find_type_definition("snow.wwise.WwiseMusicManager"):get_method("startToPlayPlayerDieMusic");

local skipCreateNeko = false;
local skipWarpNeko = false;
local reviveCamp;
local nekoTaku;

local function getCurrentMapNo()
    if not QuestMapManager or QuestMapManager:get_reference_count() <= 1 then
        QuestMapManager = sdk_get_managed_singleton("snow.QuestMapManager");
    end
    return get_CurrentMapNo_method:call(QuestMapManager);
end

local function getCurrentPosition()
    if not PlayerManager or PlayerManager:get_reference_count() <= 1 then
        PlayerManager = sdk_get_managed_singleton("snow.player.PlayerManager");
    end
    return get_Position_method:call(get_Transform_method:call(get_GameObject_method:call(findMasterPlayer_method:call(PlayerManager))));
end

local function getCampList()
    if not StagePointManager or StagePointManager:get_reference_count() <= 1 then
        StagePointManager = sdk_get_managed_singleton("snow.stage.StagePointManager");
    end
    return tentPositionList_field:get_data(StagePointManager);
end

local function calculateDistance(point1, point2)
    return ((point1.x - point2.x) ^ 2 + (point1.z - point2.z) ^ 2) ^ 0.5;
end

local function getFastTravelPt(index)
    if not StagePointManager or StagePointManager:get_reference_count() <= 1 then
        StagePointManager = sdk_get_managed_singleton("snow.stage.StagePointManager");
    end
    return pointArray_field:get_data(fastTravelPointList_mItems_field:get_data(fastTravelPointList_field:get_data(StagePointManager)):get_element(index)):get_element(0);
end

local function findNearestCamp(camps, nekoTakuPos)
    local nearestCampIndex = nil;
    local nearestDistance = nil;
    local nearestCamp = nil;
    local currentPos = getCurrentPosition();

    for i = 0, camps:get_size(), 1 do
        local camp = camps:get_element(i);
        if camp then
            local distance = calculateDistance(currentPos, camp);
            if i == 0 then
                nearestCamp = camp;
                nearestDistance = distance;
                nearestCampIndex = i;
            end

            if distance < nearestDistance and camp.x ~= 0.0 then
                nearestDistance = distance;
                nearestCamp = camp;
                nearestCampIndex = i;
            end
        end
    end

    local fastTravelPt = getFastTravelPt(nearestCampIndex);

    if not fastTravelPt then
        fastTravelPt = nearestCamp;
    end

    if nearestCampIndex ~= 0 then
        skipCreateNeko = true;
        skipWarpNeko = true;
        reviveCamp = Vector3f_new(fastTravelPt.x, fastTravelPt.y, fastTravelPt.z);
        nekoTaku = nekoTakuPos[nearestCampIndex];
        if not nekoTaku then
            nekoTaku = reviveCamp;
        end
    end
end

local function SaveSettings()
    if jsonAvailable == true then
	    json_dump_file("Nearest_camp_revive.json", settings);
    end
end

re_on_draw_ui(function()
	if imgui_tree_node("Nearest Camp Revive") then
        local changed = false;
		changed, settings.enable = imgui_checkbox("Enabled", settings.enable);
        if changed == true and settings.enable == false then
            QuestMapManager = nil;
            PlayerManager = nil;
            StagePointManager = nil;
        end
		imgui_tree_pop();
	end
end);

re_on_config_save(SaveSettings);

sdk_hook(startToPlayPlayerDieMusic_method, function()
    if not settings.enable then
        return sdk_CALL_ORIGINAL;
    end
    
    local camps = getCampList();
    local mapNo = getCurrentMapNo();
    skipCreateNeko = false;
    skipWarpNeko = false;
    reviveCamp = nil;
    nekoTaku = nil;

    if camps and nekoTakuList[mapNo] then
        findNearestCamp(camps, nekoTakuList[mapNo]);
    end
    return sdk_CALL_ORIGINAL;
end);
sdk_hook(setPlWarpInfo_Nekotaku_method, function(args)
    if skipWarpNeko then
        skipWarpNeko = false;
        local self = sdk_to_managed_object(args[2]);
        setPlWarpInfo_method:call(self, reviveCamp, 0, 20);
        return sdk_SKIP_ORIGINAL;
    end
    return sdk_CALL_ORIGINAL;
end);
sdk_hook(createNekotaku_method, function(args)
    if skipCreateNeko then
        skipCreateNeko = false;
        local self = sdk_to_managed_object(args[2]);
        createNekotaku_method:call(self, args[3], nekoTaku, args[5]);
        return sdk_SKIP_ORIGINAL;
    end
    return sdk_CALL_ORIGINAL;
end);
