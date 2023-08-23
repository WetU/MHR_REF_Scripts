local Constants = _G.require("Constants.Constants");

local find_type_definition = Constants.sdk.find_type_definition;
local to_managed_object = Constants.sdk.to_managed_object;
local to_int64 = Constants.sdk.to_int64;
local to_float = Constants.sdk.to_float;
local hook = Constants.sdk.hook;
local SKIP_ORIGINAL = Constants.sdk.SKIP_ORIGINAL;

local Vector3f_new = Constants.Vector3f_new;

local getQuestMapNo = Constants.getQuestMapNo;
local getDeathNum = Constants.getDeathNum;
local getQuestLife = Constants.getQuestLife;
--
local calcDistance_method = find_type_definition("snow.CharacterMathUtility"):get_method("calcDistance(via.vec3, via.vec3)"); -- static
--
local GetTransform_method = find_type_definition("snow.CameraManager"):get_method("GetTransform(snow.CameraManager.GameObjectType)");
local get_Position_method = GetTransform_method:get_return_type():get_method("get_Position");
--
local CreateNekotaku_method = find_type_definition("snow.NekotakuManager"):get_method("CreateNekotaku(snow.player.PlayerIndex, via.vec3, System.Single)");
--
local get_FastTravelPointList_method = find_type_definition("snow.stage.StagePointManager"):get_method("get_FastTravelPointList");

local FastTravelPointList_type_def = get_FastTravelPointList_method:get_return_type();
local FastTravelPointList_mItems_field = FastTravelPointList_type_def:get_field("mItems");
local FastTravelPointList_mSize_field = FastTravelPointList_type_def:get_field("mSize");

local get_Points_method = find_type_definition("snow.stage.StagePointManager.StagePoint"):get_method("get_Points");

local Points_get_Item_method = get_Points_method:get_return_type():get_method("get_Item(System.Int32)");
--
local StageManager_type_def = find_type_definition("snow.stage.StageManager");
local setPlWarpInfo_method = StageManager_type_def:get_method("setPlWarpInfo(via.vec3, System.Single, snow.stage.StageManager.AreaMoveQuest)");
--
local SubCampRevivalPos = {
	[1] = {
		Vector3f_new(236.707, 174.37, -510.568)
	},
	[2] = {
		Vector3f_new(-117.699, -45.653, -233.201),
		Vector3f_new(116.07, -63.316, -428.018)
	},
	[3] = {
		Vector3f_new(207.968, 90.447, 46.081)
	},
	[4] = {
		Vector3f_new(-94.171, 2.744, -371.947),
		Vector3f_new(103.986, 26.0, -496.863)
	},
	[5] = {
		Vector3f_new(244.252, 147.122, -537.940),
		Vector3f_new(-40.000, 81.136, -429.201)
	},
	[12] = {
		Vector3f_new(3.854, 32.094, -147.152)
	},
	[13] = {
		Vector3f_new(107.230, 94.988, -254.308)
	}
};
--
local reviveCampPos = nil;

local function PreHook_startToPlayPlayerDieMusic()
	local subCamps = SubCampRevivalPos[getQuestMapNo()];

	if subCamps ~= nil and getDeathNum() < getQuestLife() then
		local StagePointManager = Constants:get_StagePointManager();
		local FastTravelPointList = get_FastTravelPointList_method:call(StagePointManager);
		local FastTravelPoint_array = FastTravelPointList_mItems_field:get_data(FastTravelPointList);
		local FastTravelPoint_array_size = FastTravelPointList_mSize_field:get_data(FastTravelPointList);
		local FastTravelPoint = FastTravelPoint_array:get_element(0);
		local Points = get_Points_method:call(FastTravelPoint);
		local Point = Points_get_Item_method:call(Points, 0);
		local currentPos = get_Position_method:call(GetTransform_method:call(Constants:get_CameraManager(), 1));
		local nearestDistance = calcDistance_method:call(nil, currentPos, Point);
		local subCampCount = FastTravelPoint_array_size - 1;

		for i = 1, subCampCount, 1 do
			local subCampPos = subCamps[i];

			if i < subCampCount then
				local distance = calcDistance_method:call(nil, currentPos, subCampPos);
				if distance < nearestDistance then
					nearestDistance = distance;
					reviveCampPos = subCampPos;
				end
			else
				if calcDistance_method:call(nil, currentPos, subCampPos) < nearestDistance then
					reviveCampPos = subCampPos;
				end
			end
		end
	end
end

local function PreHook_setPlWarpInfo_Nekotaku(args)
	if reviveCampPos ~= nil then
		setPlWarpInfo_method:call(to_managed_object(args[2]), reviveCampPos, 0.0, 20);
		return SKIP_ORIGINAL;
	end
end

local function PreHook_CreateNekotaku(args)
	if reviveCampPos ~= nil then
		local campPos = reviveCampPos;
		reviveCampPos = nil;
		CreateNekotaku_method:call(to_managed_object(args[2]), to_int64(args[3]), campPos, to_float(args[5]));
		return SKIP_ORIGINAL;
	end
end

hook(find_type_definition("snow.wwise.WwiseMusicManager"):get_method("startToPlayPlayerDieMusic"), PreHook_startToPlayPlayerDieMusic);
hook(StageManager_type_def:get_method("setPlWarpInfo_Nekotaku"), PreHook_setPlWarpInfo_Nekotaku);
hook(CreateNekotaku_method, PreHook_CreateNekotaku);