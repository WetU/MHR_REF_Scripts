local require = require;

local this = {};

local utils;
local config;

local sdk = sdk;
local sdk_find_type_definition = sdk.find_type_definition;
local sdk_to_managed_object = sdk.to_managed_object;
local sdk_to_int64 = sdk.to_int64;
local sdk_hook = sdk.hook;

local ValueType = ValueType;
local ValueType_new = ValueType.new;
--
local session_manager_type_def = sdk_find_type_definition("snow.SnowSessionManager");
local req_matchmaking_method = session_manager_type_def:get_method("reqMatchmakingAutoJoinSession(System.UInt32)");
local req_matchmaking_random_method = session_manager_type_def:get_method("reqMatchmakingAutoJoinSessionRandom(System.UInt32)");
local req_matchmaking_hyakuryu_method = session_manager_type_def:get_method("reqMatchmakingAutoJoinSessionHyakuryu(System.UInt32, System.Nullable`1<System.UInt32>, System.Nullable`1<System.UInt32>)");
local req_matchmaking_random_master_rank_method = session_manager_type_def:get_method("reqMatchmakingAutoJoinSessionRandomMasterRank(System.UInt32, System.UInt32)");
local req_matchmaking_random_mystery_method = session_manager_type_def:get_method("reqMatchmakingAutoJoinSessionRandomMystery(System.UInt32, System.UInt32, System.UInt32)");
local req_matchmaking_random_mystery_quest_method = session_manager_type_def:get_method("reqMatchmakingAutoJoinSessionRandomMysteryQuest(System.UInt32, System.UInt32, System.UInt32, System.Nullable`1<System.UInt32>, snow.data.ContentsIdSystem.ItemId, System.Boolean)");

local nullable_uint32_type_def = sdk_find_type_definition("System.Nullable`1<System.UInt32>");
local nullable_uint32_constructor_method = nullable_uint32_type_def:get_method(".ctor(System.UInt32)");
local nullable_uint32_get_has_value_method = nullable_uint32_type_def:get_method("get_HasValue"); -- retval
local nullable_uint32_get_value_or_default_method = nullable_uint32_type_def:get_method("GetValueOrDefault"); -- retval
--
local SessionAttr_Quest = sdk_find_type_definition("snow.network.session.SessionAttr"):get_field("Quest"):get_data(nil);
--
local quest_types = {
	invalid = nil,
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
--
local quest_type = quest_types.invalid;
local skip_next_hook = quest_types.invalid;

local session_manager = nil;
function this.prehook_on_timeout(args)
	if quest_type ~= quest_types.invalid and (sdk_to_int64(args[3]) & 0xFFFFFFFF) >= SessionAttr_Quest then
		session_manager = sdk_to_managed_object(args[2]);
	end
end

function this.init_module()
	config = require("Better_Matchmaking.config");
	utils = require("Better_Matchmaking.utils");

	sdk_hook(session_manager_type_def:get_method("funcOnTimeoutMatchmaking(snow.network.session.SessionAttr)"), this.prehook_on_timeout, function()
		if session_manager then
			if quest_type == quest_types.regular then
				skip_next_hook = quest_types.regular;
				req_matchmaking_method:call(session_manager, quest_type.quest_id);

			elseif quest_type == quest_types.random then
				skip_next_hook = quest_types.random;
				req_matchmaking_random_method:call(session_manager, quest_type.my_hunter_rank);

			elseif quest_type == quest_types.rampage then
				skip_next_hook = quest_types.rampage;
				local quest_level_pointer = ValueType_new(nullable_uint32_type_def);
				nullable_uint32_constructor_method:call(quest_level_pointer, quest_type.quest_level.value);
				quest_level_pointer:set_field("_HasValue", quest_type.quest_level.has_value);

				local target_enemy_pointer = ValueType_new(nullable_uint32_type_def);
				nullable_uint32_constructor_method:call(target_enemy_pointer, quest_type.target_enemy.value);
				target_enemy_pointer:set_field("_HasValue", quest_type.target_enemy.has_value);

				req_matchmaking_hyakuryu_method:call(session_manager, quest_type.difficulty, quest_level_pointer, target_enemy_pointer);

			elseif quest_type == quest_types.random_master_rank then
				skip_next_hook = quest_types.random_master_rank;
				req_matchmaking_random_master_rank_method:call(session_manager, quest_type.my_hunter_rank, quest_type.my_master_rank);

			elseif quest_type == quest_types.random_anomaly then
				skip_next_hook = quest_types.random_anomaly;
				req_matchmaking_random_mystery_method:call(session_manager, quest_type.my_hunter_rank, quest_type.my_master_rank, quest_type.anomaly_research_level);

			elseif quest_type == quest_types.anomaly_investigation then
				skip_next_hook = quest_types.anomaly_investigation;
				local enemy_id_pointer = ValueType_new(nullable_uint32_type_def);
				nullable_uint32_constructor_method:call(enemy_id_pointer, quest_type.enemy_id.value);
				enemy_id_pointer:set_field("_HasValue", quest_type.enemy_id.has_value);

				req_matchmaking_random_mystery_quest_method:call(
					session_manager,
					quest_type.min_level,
					quest_type.max_level,
					quest_type.party_limit,
					enemy_id_pointer,
					quest_type.reward_item,
					quest_type.is_special_random_mystery
				);
			end
		end
		session_manager = nil;
	end);

	--snow.SnowSessionManager.
	--reqMatchmakingAutoJoinSession(
	--	System.UInt32 						questID
	--)
	sdk_hook(req_matchmaking_method, function(args)
		if config.current_config.timeout_fix.enabled and config.current_config.timeout_fix.quest_types.regular then
			if skip_next_hook == quest_types.regular then
				skip_next_hook = nil;
			else
				quest_type = quest_types.regular;
				quest_type.quest_id = sdk_to_int64(args[3]) & 0xFFFFFFFF;
			end
		end
	end);

	--snow.SnowSessionManager.
	--reqMatchmakingAutoJoinSessionRandom(
	--	System.UInt32 						myHunterRank
	--)
	sdk_hook(req_matchmaking_random_method, function(args)
		if config.current_config.timeout_fix.enabled and config.current_config.timeout_fix.quest_types.random then
			if skip_next_hook == quest_types.random then
				skip_next_hook = nil;
			else
				quest_type = quest_types.random;
				quest_type.my_hunter_rank = sdk_to_int64(args[3]) & 0xFFFFFFFF;
			end
		end
	end);

	--snow.SnowSessionManager.
	--reqMatchmakingAutoJoinSessionHyakuryu(
	--	System.UInt32 						difficulty
	--	System.Nullable`1<System.UInt32>	questLevel
	--	System.Nullable`1<System.UInt32>	targetEnemy
	--)
	sdk_hook(req_matchmaking_hyakuryu_method, function(args)
		if config.current_config.timeout_fix.enabled and config.current_config.timeout_fix.quest_types.rampage then
			if skip_next_hook == quest_types.rampage then
				skip_next_hook = nil;
			else
				quest_type = quest_types.rampage;
				quest_type.difficulty = sdk_to_int64(args[3]) & 0xFFFFFFFF;

				local quest_level = sdk_to_int64(args[4]) & 0xFFFFFFFF;
				local target_enemy = sdk_to_int64(args[5]) & 0xFFFFFFFF;

				quest_type.quest_level.has_value = nullable_uint32_get_has_value_method:call(quest_level);
				quest_type.target_enemy.has_value = nullable_uint32_get_has_value_method:call(target_enemy);

				if quest_type.quest_level.has_value then
					quest_type.quest_level.value = nullable_uint32_get_value_or_default_method:call(args[4]);
				end

				if quest_type.target_enemy.has_value then
					quest_type.target_enemy.value = nullable_uint32_get_value_or_default_method:call(args[5]);
				end
			end
		end
	end);

	--snow.SnowSessionManager.
	--reqMatchmakingAutoJoinSessionRandomMasterRank(
	--	System.UInt32 						myHunterRank
	--	System.UInt32						myMasterRank
	--)
	sdk_hook(req_matchmaking_random_master_rank_method, function(args)
		if config.current_config.timeout_fix.enabled and config.current_config.timeout_fix.quest_types.random_master_rank then
			if skip_next_hook == quest_types.random_master_rank then
				skip_next_hook = nil;
			else
				quest_type = quest_types.random_master_rank;
				quest_type.my_hunter_rank = sdk_to_int64(args[3]) & 0xFFFFFFFF;
				quest_type.my_master_rank = sdk_to_int64(args[4]) & 0xFFFFFFFF;
			end
		end
	end);

	--snow.SnowSessionManager.
	--reqMatchmakingAutoJoinSessionRandomMystery(
	--	System.UInt32 						myHunterRank
	--	System.UInt32						myMasterRank
	--	System.UInt32						myMasterRank (it is actually anomaly research level)
	--)
	sdk_hook(req_matchmaking_random_mystery_method, function(args)
		if config.current_config.timeout_fix.enabled and config.current_config.timeout_fix.quest_types.random_anomaly then
			if skip_next_hook == quest_types.random_anomaly then
				skip_next_hook = nil;
			else
				quest_type = quest_types.random_anomaly;
				quest_type.my_hunter_rank = sdk_to_int64(args[3]) & 0xFFFFFFFF;
				quest_type.my_master_rank = sdk_to_int64(args[4]) & 0xFFFFFFFF;
				quest_type.anomaly_research_level = sdk_to_int64(args[5]) & 0xFFFFFFFF;
			end
		end
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
		if config.current_config.timeout_fix.enabled and config.current_config.timeout_fix.quest_types.anomaly_investigation then
			if skip_next_hook == quest_types.anomaly_investigation then
				skip_next_hook = nil;
			else
				quest_type = quest_types.anomaly_investigation;
				quest_type.min_level = sdk_to_int64(args[3]) & 0xFFFFFFFF;
				quest_type.max_level = sdk_to_int64(args[4]) & 0xFFFFFFFF;
				quest_type.party_limit = sdk_to_int64(args[5]) & 0xFFFFFFFF;
				quest_type.reward_item = sdk_to_int64(args[7]) & 0xFFFFFFFF;
				quest_type.is_special_random_mystery = (sdk_to_int64(args[8]) & 1) == 1;

				local enemy_id = sdk_to_int64(args[6]) & 0xFFFFFFFF;
				quest_type.enemy_id.has_value = nullable_uint32_get_has_value_method:call(enemy_id);
				if quest_type.enemy_id.has_value then
					quest_type.enemy_id.value = nullable_uint32_get_value_or_default_method:call(args[6]);
				end
			end
		end
	end);
end

return this;