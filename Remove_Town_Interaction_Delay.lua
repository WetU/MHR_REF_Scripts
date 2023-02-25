local sdk = sdk;
local sdk_find_type_definition = sdk.find_type_definition;
local sdk_hook = sdk.hook;
local sdk_to_int64 = sdk.to_int64;
local sdk_get_managed_singleton = sdk.get_managed_singleton;
local sdk_SKIP_ORIGINAL = sdk.PreHookResult.SKIP_ORIGINAL;
local sdk_CALL_ORIGINAL = sdk.PreHookResult.CALL_ORIGINAL;

local QuestManager = nil;
local questStatus_field = sdk_find_type_definition("snow.QuestManager"):get_field("_QuestStatus");
local changeAllMarkerEnable_method = sdk_find_type_definition("snow.access.ObjectAccessManager"):get_method("changeAllMarkerEnable");

sdk_hook(changeAllMarkerEnable_method, function(args)
	if (sdk_to_int64(args[3]) & 1) ~= 1 then
		if not QuestManager or QuestManager:get_reference_count() <= 1 then
			QuestManager = sdk_get_managed_singleton("snow.QuestManager")
		end
		if questStatus_field:get_data(QuestManager) == 0 then
			return sdk_SKIP_ORIGINAL;
		end
	end
	return sdk_CALL_ORIGINAL;
end);