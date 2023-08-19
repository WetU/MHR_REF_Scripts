local Constants = _G.require("Constants.Constants");

local find_type_definition = Constants.sdk.find_type_definition;
local get_managed_singleton = Constants.sdk.get_managed_singleton;
local to_managed_object = Constants.sdk.to_managed_object;
local to_int64 = Constants.sdk.to_int64;
local to_float = Constants.sdk.to_float;
local hook = Constants.sdk.hook;
local SKIP_ORIGINAL = Constants.sdk.SKIP_ORIGINAL;

local Vector3f_new = Constants.Vector3f.new;
--
local calcDistance_method = find_type_definition("snow.CharacterMathUtility"):get_method("calcDistance(via.vec3, via.vec3)"); -- static
--
local GetTransform_method = Constants.type_definitions.CameraManager_type_def:get_method("GetTransform(snow.CameraManager.GameObjectType)");
local get_Position_method = GetTransform_method:get_return_type():get_method("get_Position");
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
	reviveCampPos = nil;
	local subCamps = SubCampRevivalPos[Constants:getQuestMapNo()];

	if subCamps ~= nil and Constants:getDeathNum() < Constants:getQuestLife() then
		local currentPos = get_Position_method:call(GetTransform_method:call(get_managed_singleton("snow.CameraManager"), 1));
		local nearestDistance = calcDistance_method:call(nil, currentPos, Points_get_Item_method:call(get_Points_method:call(FastTravelPointList_get_Item_method:call(get_FastTravelPointList_method:call(get_managed_singleton("snow.stage.StagePointManager")), 0)), 0));
		local subCampCount = #subCamps;
		if subCampCount > 1 then
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
		else
			local subCampPos = subCamps[1];
			if calcDistance_method:call(nil, currentPos, subCampPos) < nearestDistance then
				reviveCampPos = subCampPos;
			end
		end
	end
end

local function PreHook_setPlWarpInfo_Nekotaku(args)
	if reviveCampPos ~= nil then
		setPlWarpInfo_method:call(to_managed_object(args[2]) or get_managed_singleton("snow.stage.StageManager"), reviveCampPos, 0.0, 20);
		return SKIP_ORIGINAL;
	end
end

local function PreHook_CreateNekotaku(args)
	if reviveCampPos ~= nil then
		local campPos = reviveCampPos;
		reviveCampPos = nil;
		CreateNekotaku_method:call(to_managed_object(args[2]) or get_managed_singleton("snow.NekotakuManager"), to_int64(args[3]), campPos, to_float(args[5]));
		return SKIP_ORIGINAL;
	end
end

hook(find_type_definition("snow.wwise.WwiseMusicManager"):get_method("startToPlayPlayerDieMusic"), PreHook_startToPlayPlayerDieMusic);
hook(StageManager_type_def:get_method("setPlWarpInfo_Nekotaku"), PreHook_setPlWarpInfo_Nekotaku);
hook(CreateNekotaku_method, PreHook_CreateNekotaku);