local this = {};

local utils;
local config;

local sdk = sdk;
local sdk_find_type_definition = sdk.find_type_definition;
local sdk_get_managed_singleton = sdk.get_managed_singleton;
local sdk_to_int64 = sdk.to_int64;
local sdk_hook = sdk.hook;
local sdk_SKIP_ORIGINAL = sdk.PreHookResult.SKIP_ORIGINAL;
local sdk_CALL_ORIGINAL = sdk.PreHookResult.CALL_ORIGINAL;

local os = os;
local os_clock = os.clock;

local ValueType = ValueType;
local ValueType_new = ValueType.new;

local require = require;

local quest_types = {
	invalid = {},
	regular = {
		quest_id = 0
	},
	random = {
		my_hunter_rank = 0
	},
	rampage = {
		difficulty = 0,
		quest_level = {
			value = 0,
			has_value = false
		},
		target_enemy = {
			value = 0,
			has_value = false
		}
	},
	random_master_rank = {
		my_hunter_rank = 0,
		my_master_rank = 0
	},

	random_anomaly = {
		my_hunter_rank = 0,
		my_master_rank = 0,
		anomaly_reserach_level = 0
	},
	anomaly_investigation = {
		min_level = 1,
		max_level = 1,
		party_limit = 4,
		enemy_id = {
			value = 0,
			has_value = false
		},
		reward_item = 67108864,
		is_special_random_mystery = false
	}
};

local quest_type = quest_types.invalid;
local skip_next_hook = false;

local session_manager_type_def = sdk_find_type_definition("snow.SnowSessionManager");
local on_timeout_matchmaking_method = session_manager_type_def:get_method("funcOnTimeoutMatchmaking(snow.network.session.SessionAttr)");
local make_error_code_method = session_manager_type_def:get_method("makeErrorCode(via.network.Error)");

local req_matchmaking_method = session_manager_type_def:get_method("reqMatchmakingAutoJoinSession(System.UInt32)");
local req_matchmaking_random_method = session_manager_type_def:get_method("reqMatchmakingAutoJoinSessionRandom(System.UInt32)");
local req_matchmaking_hyakuryu_method = session_manager_type_def:get_method("reqMatchmakingAutoJoinSessionHyakuryu(System.UInt32, System.Nullable`1<System.UInt32>, System.Nullable`1<System.UInt32>)");
local req_matchmaking_random_master_rank_method = session_manager_type_def:get_method("reqMatchmakingAutoJoinSessionRandomMasterRank(System.UInt32, System.UInt32)");
local req_matchmaking_random_mystery_method = session_manager_type_def:get_method("reqMatchmakingAutoJoinSessionRandomMystery(System.UInt32, System.UInt32, System.UInt32)");
local req_matchmaking_random_mystery_quest_method = session_manager_type_def:get_method("reqMatchmakingAutoJoinSessionRandomMysteryQuest(System.UInt32, System.UInt32, System.UInt32, System.Nullable`1<System.UInt32>, snow.data.ContentsIdSystem.ItemId, System.Boolean)");

local nullable_uint32_type_def = sdk_find_type_definition("System.Nullable`1<System.UInt32>");
local nullable_uint32_get_value_or_default_method = nullable_uint32_type_def:get_method("GetValueOrDefault");
local nullable_uint32_get_has_value_method = nullable_uint32_type_def:get_method("get_HasValue");
local nullable_uint32_constructor_method = nullable_uint32_type_def:get_method(".ctor(System.UInt32)");

local network_util_type_def = sdk_find_type_definition("snow.network.Util");
local get_re_and_lib_version_method = network_util_type_def:get_method("getReAndLibVersion");
local tostring_error_method = network_util_type_def:get_method("toString_Error(via.network.Error)");

local t0 = 0;

function this.get_search_time()
	return os_clock() - t0;
end

function this.on_post_timeout_matchmaking(retval)
	local timeout_fix_config = config.current_config.timeout_fix;
	if timeout_fix_config.enabled then
		local session_manager = sdk_get_managed_singleton("snow.SnowSessionManager");
		if session_manager then
			if quest_type == quest_types.regular and timeout_fix_config.quest_types.regular then
				skip_next_hook = true;
				req_matchmaking_method:call(session_manager, quest_type.quest_id);
			elseif quest_type == quest_types.random and timeout_fix_config.quest_types.random then
				skip_next_hook = true;
				req_matchmaking_random_method:call(session_manager, quest_type.my_hunter_rank);
			elseif quest_type == quest_types.rampage and timeout_fix_config.quest_types.rampage then
				local quest_level_pointer = ValueType_new(nullable_uint32_type_def);
				local target_enemy_pointer = ValueType_new(nullable_uint32_type_def);

				nullable_uint32_constructor_method:call(quest_level_pointer, quest_type.quest_level.value);
				nullable_uint32_constructor_method:call(target_enemy_pointer, quest_type.target_enemy.value);

				quest_level_pointer:set_field("_HasValue", quest_type.quest_level.has_value);
				target_enemy_pointer:set_field("_HasValue", quest_type.target_enemy.has_value);

				skip_next_hook = true;
				req_matchmaking_hyakuryu_method:call(session_manager, quest_type.difficulty, quest_level_pointer, target_enemy_pointer);
			elseif quest_type == quest_types.random_master_rank and timeout_fix_config.quest_types.random_master_rank then
				skip_next_hook = true;
				req_matchmaking_random_master_rank_method:call(session_manager, quest_type.my_hunter_rank, quest_type.my_master_rank);
			elseif quest_type == quest_types.random_anomaly and timeout_fix_config.quest_types.random_anomaly then
				skip_next_hook = true;
				req_matchmaking_random_mystery_method:call(session_manager, quest_type.my_hunter_rank, quest_type.my_master_rank, quest_type.anomaly_research_level);
			elseif quest_type == quest_types.anomaly_investigation and timeout_fix_config.quest_types.anomaly_investigation then
				local enemy_id_pointer = ValueType_new(nullable_uint32_type_def);
				nullable_uint32_constructor_method:call(enemy_id_pointer, quest_type.enemy_id.value);
				enemy_id_pointer:set_field("_HasValue", quest_type.enemy_id.has_value);
				skip_next_hook = true;
				req_matchmaking_random_mystery_quest_method:call(session_manager,
					quest_type.min_level,
					quest_type.max_level,
					quest_type.party_limit,
					enemy_id_pointer,
					quest_type.reward_item,
					quest_type.is_special_random_mystery
				);
			end
		end
	end
	return retval;
end

function this.on_req_matchmaking(quest_id)
	if skip_next_hook then
		skip_next_hook = false;
		return;
	end
	quest_type = quest_types.regular;
	quest_type.quest_id = quest_id;
end

function this.on_req_matchmaking_random(my_hunter_rank)
	if skip_next_hook then
		skip_next_hook = false;
		return;
	end
	quest_type = quest_types.random;
	quest_type.my_hunter_rank = my_hunter_rank;
end

function this.on_req_matchmaking_rampage(difficulty, quest_level_pointer, target_enemy_pointer)
	if skip_next_hook then
		skip_next_hook = false;
		return;
	end
	quest_type = quest_types.rampage;
	quest_type.difficulty = difficulty;

	local quest_level_pointer_int = sdk_to_int64(quest_level_pointer);
	local target_enemy_pointer_int = sdk_to_int64(target_enemy_pointer);

	quest_type.quest_level.has_value = nullable_uint32_get_has_value_method:call(quest_level_pointer_int);
	quest_type.target_enemy.has_value = nullable_uint32_get_has_value_method:call(target_enemy_pointer_int);

	if quest_type.quest_level.has_value then
		quest_type.quest_level.value = nullable_uint32_get_value_or_default_method:call(quest_level_pointer);
	end

	if quest_type.target_enemy.has_value then
		quest_type.target_enemy.value = nullable_uint32_get_value_or_default_method:call(target_enemy_pointer);
	end
end

function this.on_req_matchmaking_random_master_rank(my_hunter_rank, my_master_rank)
	if skip_next_hook then
		skip_next_hook = false;
		return;
	end
	quest_type = quest_types.random_master_rank;
	quest_type.my_hunter_rank = my_hunter_rank;
	quest_type.my_master_rank = my_master_rank;
end

function this.on_req_matchmaking_random_anomaly(my_hunter_rank, my_master_rank)
	if skip_next_hook then
		skip_next_hook = false;
		return;
	end
	quest_type = quest_types.random_anomaly;
	quest_type.my_hunter_rank = my_hunter_rank;
	quest_type.my_master_rank = my_master_rank;
end

function this.on_req_matchmaking_random_anomaly_quest(min_level, max_level, party_limit, enemy_id_pointer, reward_item, is_special_random_mystery)
	if skip_next_hook then
		skip_next_hook = false;
		return;
	end
	quest_type = quest_types.anomaly_investigation;
	quest_type.min_level = min_level;
	quest_type.max_level = max_level;
	quest_type.party_limit = party_limit;
	quest_type.reward_item = reward_item;
	quest_type.is_special_random_mystery = is_special_random_mystery;

	local enemy_id_pointer_int = sdk_to_int64(enemy_id_pointer);

	quest_type.enemy_id.has_value = nullable_uint32_get_has_value_method:call(enemy_id_pointer);

	if quest_type.enemy_id.has_value then
		quest_type.enemy_id.value = nullable_uint32_get_value_or_default_method:call(enemy_id_pointer);
	end
end

function this.on_req_online()
	if config.current_config.hide_online_warning.enabled then
		return sdk_SKIP_ORIGINAL;
	end
	return sdk_CALL_ORIGINAL;
end

function this.init_module()
	config = require("Better_Matchmaking.config");
	utils = require("Better_Matchmaking.utils");

	--snow.SnowSessionManager.
	--reqMatchmakingAutoJoinSessionRandomMysteryQuest(
	--	System.UInt32 						lvMin
	--	System.UInt32						lvMax
	--	System.UInt32						limit
	--	System.Nullable`1<System.UInt32>	enemyId
	--	snow.data.ContentsIdSystem.ItemId	rewardItem
	--	System.Boolean						isSpecialRandomMystery
	--)
	sdk_hook(on_timeout_matchmaking_method, nil, function(retval)
		this.on_post_timeout_matchmaking();
		return retval;
	end);

	--snow.SnowSessionManager.
	--reqMatchmakingAutoJoinSession(
	--	System.UInt32 						questID
	--)
	sdk_hook(req_matchmaking_method, function(args)
		local quest_id = sdk_to_int64(args[3]) & 0xFFFFFFFF;
		this.on_req_matchmaking(quest_id);
		return sdk_CALL_ORIGINAL;
	end);

	--snow.SnowSessionManager.
	--reqMatchmakingAutoJoinSessionRandom(
	--	System.UInt32 						myHunterRank
	--)
	sdk_hook(req_matchmaking_random_method, function(args)
		local my_hunter_rank = sdk_to_int64(args[3]) & 0xFFFFFFFF;
		this.on_req_matchmaking_random(my_hunter_rank);
		return sdk_CALL_ORIGINAL;
	end);

	--snow.SnowSessionManager.
	--reqMatchmakingAutoJoinSessionHyakuryu(
	--	System.UInt32 						difficulty
	--	System.Nullable`1<System.UInt32>	questLevel
	--	System.Nullable`1<System.UInt32>	targetEnemy
	--)
	sdk_hook(req_matchmaking_hyakuryu_method, function(args)
		local difficulty = sdk_to_int64(args[3]) & 0xFFFFFFFF;
		local quest_level = args[4];
		local target_enemy = args[5];
		this.on_req_matchmaking_rampage(difficulty, quest_level, target_enemy);
		return sdk_CALL_ORIGINAL;
	end);

	--snow.SnowSessionManager.
	--reqMatchmakingAutoJoinSessionRandomMasterRank(
	--	System.UInt32 						myHunterRank
	--	System.UInt32						myMasterRank
	--)
	sdk_hook(req_matchmaking_random_master_rank_method, function(args)
		local my_hunter_rank = sdk_to_int64(args[3]) & 0xFFFFFFFF;
		local my_master_rank = sdk_to_int64(args[4]) & 0xFFFFFFFF;
		this.on_req_matchmaking_random_master_rank(my_hunter_rank, my_master_rank);
		return sdk_CALL_ORIGINAL;
	end);

	--snow.SnowSessionManager.
	--reqMatchmakingAutoJoinSessionRandomMystery(
	--	System.UInt32 						myHunterRank
	--	System.UInt32						myMasterRank
	--	System.UInt32						myMasterRank (it is actually anomaly research level)
	--)
	sdk_hook(req_matchmaking_random_mystery_method, function(args)
		local my_hunter_rank = sdk_to_int64(args[3]) & 0xFFFFFFFF;
		local my_master_rank = sdk_to_int64(args[4]) & 0xFFFFFFFF;
		local anomaly_research_level = sdk_to_int64(args[5]) & 0xFFFFFFFF;
		this.on_req_matchmaking_random_anomaly(my_hunter_rank, my_master_rank, anomaly_research_level);
		return sdk_CALL_ORIGINAL;
	end);

	--snow.SnowSessionManager.
	--reqMatchmakingAutoJoinSessionRandomMysteryQuest(
	--	System.UInt32 						lvMin
	--	System.UInt32						lvMax
	--	System.UInt32						limit
	--	System.Nullable`1<System.UInt32>	enemyId
	--	snow.data.ContentsIdSystem.ItemId	rewardItem
	--	System.Boolean						isSpecialRandomMystery
	--)
	sdk_hook(req_matchmaking_random_mystery_quest_method, function(args)
		local lv_min = sdk_to_int64(args[3]) & 0xFFFFFFFF;
		local lv_max = sdk_to_int64(args[4]) & 0xFFFFFFFF;
		local limit = sdk_to_int64(args[5]) & 0xFFFFFFFF;
		local enemy_id = args[6];
		local reward_item = sdk_to_int64(args[7]) & 0xFFFFFFFF;
		local is_special_random_mystery = (sdk_to_int64(args[8]) & 1) == 1;
		this.on_req_matchmaking_random_anomaly_quest( lv_min, lv_max, limit, enemy_id, reward_item, is_special_random_mystery);
		return sdk_CALL_ORIGINAL;
	end);
end

return this;