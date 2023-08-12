local Constants = _G.require("Constants.Constants");

local find_type_definition = Constants.sdk.find_type_definition;
local get_managed_singleton = Constants.sdk.get_managed_singleton;2
--
local ProgressOwlNestManager_type_def = find_type_definition("snow.progress.ProgressOwlNestManager");
local supply_method = ProgressOwlNestManager_type_def:get_method("supply");
local get_SaveData_method = ProgressOwlNestManager_type_def:get_method("get_SaveData");

local ProgressOwlNestSaveData_type_def = get_SaveData_method:get_return_type();
local kamuraStackCount_field = ProgressOwlNestSaveData_type_def:get_field("_StackCount");
local elgadoStackCount_field = ProgressOwlNestSaveData_type_def:get_field("_StackCount2");
--
local VillageAreaManager_type_def = Constants.type_definitions.VillageAreaManager_type_def;
local get__CurrentAreaNo_method = VillageAreaManager_type_def:get_method("get__CurrentAreaNo");
local set__CurrentAreaNo_method = VillageAreaManager_type_def:get_method("set__CurrentAreaNo(snow.stage.StageDef.AreaNoType)");
--
local this = {
	Supply = function()
		local ProgressOwlNestManager = get_managed_singleton("snow.progress.ProgressOwlNestManager");
		local SaveData = get_SaveData_method:call(ProgressOwlNestManager);

		local fullFlag = 0;

		if kamuraStackCount_field:get_data(SaveData) == 5 then
			fullFlag = fullFlag + 1;
		end
		if elgadoStackCount_field:get_data(SaveData) == 5 then
			fullFlag = fullFlag + 2;
		end

		if fullFlag > 0 then
			local VillageAreaManager = get_managed_singleton("snow.VillageAreaManager");
			local savedAreaNo = get__CurrentAreaNo_method:call(VillageAreaManager);

			if fullFlag == 3 then
				if savedAreaNo == 2 or savedAreaNo == 6 then
					supply_method:call(ProgressOwlNestManager);
					set__CurrentAreaNo_method:call(VillageAreaManager, savedAreaNo == 2 and 6 or 2);
					supply_method:call(ProgressOwlNestManager);
					set__CurrentAreaNo_method:call(VillageAreaManager, savedAreaNo);
				else
					set__CurrentAreaNo_method:call(VillageAreaManager, 2);
					supply_method:call(ProgressOwlNestManager);
					set__CurrentAreaNo_method:call(VillageAreaManager, 6);
					supply_method:call(ProgressOwlNestManager);
					set__CurrentAreaNo_method:call(VillageAreaManager, savedAreaNo);
				end

			elseif fullFlag == 2 then
				if savedAreaNo == 6 then
					supply_method:call(ProgressOwlNestManager);
				else
					set__CurrentAreaNo_method:call(VillageAreaManager, 6);
					supply_method:call(ProgressOwlNestManager);
					set__CurrentAreaNo_method:call(VillageAreaManager, savedAreaNo);
				end

			else
				if savedAreaNo == 2 then
					supply_method:call(ProgressOwlNestManager);
				else
					set__CurrentAreaNo_method:call(VillageAreaManager, 2);
					supply_method:call(ProgressOwlNestManager);
					set__CurrentAreaNo_method:call(VillageAreaManager, savedAreaNo);
				end
			end
		end
	end
};
--
return this;