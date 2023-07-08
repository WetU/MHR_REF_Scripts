local require = require;
local Constants = require("Constants.Constants");
if not Constants then
	return;
end

local this = {};
local config;
--
local session_manager_type_def = Constants.SDK.find_type_definition("snow.SnowSessionManager");
local req_matchmaking_method = session_manager_type_def:get_method("reqMatchmakingAutoJoinSession(System.UInt32)");
local req_matchmaking_random_method = session_manager_type_def:get_method("reqMatchmakingAutoJoinSessionRandom(System.UInt32)");
local req_matchmaking_hyakuryu_method = session_manager_type_def:get_method("reqMatchmakingAutoJoinSessionHyakuryu(System.UInt32, System.Nullable`1<System.UInt32>, System.Nullable`1<System.UInt32>)");
local req_matchmaking_random_master_rank_method = session_manager_type_def:get_method("reqMatchmakingAutoJoinSessionRandomMasterRank(System.UInt32, System.UInt32)");
local req_matchmaking_random_mystery_method = session_manager_type_def:get_method("reqMatchmakingAutoJoinSessionRandomMystery(System.UInt32, System.UInt32, System.UInt32)");
local req_matchmaking_random_mystery_quest_method = session_manager_type_def:get_method("reqMatchmakingAutoJoinSessionRandomMysteryQuest(System.UInt32, System.UInt32, System.UInt32, System.Nullable`1<System.UInt32>, snow.data.ContentsIdSystem.ItemId, System.Boolean)");

local nullable_uint32_type_def = Constants.SDK.find_type_definition("System.Nullable`1<System.UInt32>");
local nullable_uint32_constructor_method = nullable_uint32_type_def:get_method(".ctor(System.UInt32)");
local nullable_uint32_get_has_value_method = nullable_uint32_type_def:get_method("get_HasValue"); -- retval
local nullable_uint32_get_value_or_default_method = nullable_uint32_type_def:get_method("GetValueOrDefault"); -- retval
--
local SessionAttr_Quest = Constants.SDK.find_type_definition("snow.network.session.SessionAttr"):get_field("Quest"):get_data(nil);
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
local skip_types = {
	regular = 1,
	random = 2,
	rampage = 3,
	random_master_rank = 4,
	random_anomaly = 5,
	anomaly_investigation = 6
};
--
local quest_type = quest_types.invalid;
local skip_next_hook = false;

local session_manager = nil;
local function prehook_on_timeout(args)
	if quest_type ~= quest_types.invalid and Constants.SDK.to_int64(args[3]) >= SessionAttr_Quest then
		session_manager = Constants.SDK.to_managed_object(args[2]);
	end
end
local function posthook_on_timeout()
	if session_manager ~= nil then
		if quest_type == quest_types.regular then
			skip_next_hook = skip_types.regular;
			req_matchmaking_method:call(session_manager, quest_type.quest_id);

		elseif quest_type == quest_types.random then
			skip_next_hook = skip_types.random;
			req_matchmaking_random_method:call(session_manager, quest_type.my_hunter_rank);

		elseif quest_type == quest_types.rampage then
			skip_next_hook = skip_types.rampage;
			local quest_level_pointer = Constants.VALUETYPE.new(nullable_uint32_type_def);
			nullable_uint32_constructor_method:call(quest_level_pointer, quest_type.quest_level.value);
			quest_level_pointer:set_field("_HasValue", quest_type.quest_level.has_value);

			local target_enemy_pointer = Constants.VALUETYPE.new(nullable_uint32_type_def);
			nullable_uint32_constructor_method:call(target_enemy_pointer, quest_type.target_enemy.value);
			target_enemy_pointer:set_field("_HasValue", quest_type.target_enemy.has_value);

			req_matchmaking_hyakuryu_method:call(session_manager, quest_type.difficulty, quest_level_pointer, target_enemy_pointer);

		elseif quest_type == quest_types.random_master_rank then
			skip_next_hook = skip_types.random_master_rank;
			req_matchmaking_random_master_rank_method:call(session_manager, quest_type.my_hunter_rank, quest_type.my_master_rank);

		elseif quest_type == quest_types.random_anomaly then
			skip_next_hook = skip_types.random_anomaly;
			req_matchmaking_random_mystery_method:call(session_manager, quest_type.my_hunter_rank, quest_type.my_master_rank, quest_type.anomaly_research_level);

		elseif quest_type == quest_types.anomaly_investigation then
			skip_next_hook = skip_types.anomaly_investigation;
			local enemy_id_pointer = Constants.VALUETYPE.new(nullable_uint32_type_def);
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
end

local function prehook_req_matchmaking(args)
	if skip_next_hook == skip_types.regular then
		skip_next_hook = nil;
		return;
	end

	if config.current_config.timeout_fix.enabled == true and config.current_config.timeout_fix.quest_types.regular == true then
		quest_type = quest_types.regular;
		quest_type.quest_id = Constants.to_uint(args[3]);
	end
end

local function prehook_req_matchmaking_random(args)
	if skip_next_hook == skip_types.random then
		skip_next_hook = nil;
		return;
	end

	if config.current_config.timeout_fix.enabled == true and config.current_config.timeout_fix.quest_types.random == true then
		quest_type = quest_types.random;
		quest_type.my_hunter_rank = Constants.to_uint(args[3]);
	end
end

local function prehook_req_matchmaking_hyakuryu(args)
	if skip_next_hook == skip_types.rampage then
		skip_next_hook = nil;
		return;
	end

	if config.current_config.timeout_fix.enabled == true and config.current_config.timeout_fix.quest_types.rampage == true then
		quest_type = quest_types.rampage;
		quest_type.difficulty = Constants.to_uint(args[3]);

		local quest_level = Constants.SDK.to_int64(args[4]);
		local target_enemy = Constants.SDK.to_int64(args[5]);

		quest_type.quest_level.has_value = nullable_uint32_get_has_value_method:call(quest_level);
		quest_type.target_enemy.has_value = nullable_uint32_get_has_value_method:call(target_enemy);

		if quest_type.quest_level.has_value == true then
			quest_type.quest_level.value = nullable_uint32_get_value_or_default_method:call(args[4]);
		end

		if quest_type.target_enemy.has_value == true then
			quest_type.target_enemy.value = nullable_uint32_get_value_or_default_method:call(args[5]);
		end
	end
end

local function prehook_req_matchmaking_random_master_rank(args)
	if skip_next_hook == skip_types.random_master_rank then
		skip_next_hook = nil;
		return;
	end

	if config.current_config.timeout_fix.enabled == true and config.current_config.timeout_fix.quest_types.random_master_rank == true then
		quest_type = quest_types.random_master_rank;
		quest_type.my_hunter_rank = Constants.to_uint(args[3]);
		quest_type.my_master_rank = Constants.to_uint(args[4]);
	end
end

local function prehook_req_matchmaking_random_mystery(args)
	if skip_next_hook == skip_types.random_anomaly then
		skip_next_hook = nil;
		return;
	end

	if config.current_config.timeout_fix.enabled == true and config.current_config.timeout_fix.quest_types.random_anomaly == true then
		quest_type = quest_types.random_anomaly;
		quest_type.my_hunter_rank = Constants.to_uint(args[3]);
		quest_type.my_master_rank = Constants.to_uint(args[4]);
		quest_type.anomaly_research_level = Constants.to_uint(args[5]);
	end
end

local function prehook_req_matchmaking_random_mystery_quest(args)
	if skip_next_hook == skip_types.anomaly_investigation then
		skip_next_hook = nil;
		return;
	end

	if config.current_config.timeout_fix.enabled == true and config.current_config.timeout_fix.quest_types.anomaly_investigation == true then
		quest_type = quest_types.anomaly_investigation;
		quest_type.min_level = Constants.to_uint(args[3]);
		quest_type.max_level = Constants.to_uint(args[4]);
		quest_type.party_limit = Constants.to_uint(args[5]);
		quest_type.reward_item = Constants.to_uint(args[7]);
		quest_type.is_special_random_mystery = Constants.to_bool(args[8]);

		local enemy_id = Constants.SDK.to_int64(args[6]);
		quest_type.enemy_id.has_value = nullable_uint32_get_has_value_method:call(enemy_id);
		if quest_type.enemy_id.has_value == true then
			quest_type.enemy_id.value = nullable_uint32_get_value_or_default_method:call(args[6]);
		end
	end
end

local function prehook_reqOnlineWarning()
	if config.current_config.hide_online_warning.enabled == true then
		return Constants.SDK.SKIP_ORIGINAL;
	end
end

function this.init_module()
	config = require("Better_Matchmaking.config");
	Constants.SDK.hook(session_manager_type_def:get_method("funcOnTimeoutMatchmaking(snow.network.session.SessionAttr)"), prehook_on_timeout, posthook_on_timeout);

	--snow.SnowSessionManager.
	--reqMatchmakingAutoJoinSession(
	--	System.UInt32 						questID
	--)
	Constants.SDK.hook(req_matchmaking_method, prehook_req_matchmaking);

	--snow.SnowSessionManager.
	--reqMatchmakingAutoJoinSessionRandom(
	--	System.UInt32 						myHunterRank
	--)
	Constants.SDK.hook(req_matchmaking_random_method, prehook_req_matchmaking_random);

	--snow.SnowSessionManager.
	--reqMatchmakingAutoJoinSessionHyakuryu(
	--	System.UInt32 						difficulty
	--	System.Nullable`1<System.UInt32>	questLevel
	--	System.Nullable`1<System.UInt32>	targetEnemy
	--)
	Constants.SDK.hook(req_matchmaking_hyakuryu_method, prehook_req_matchmaking_hyakuryu);

	--snow.SnowSessionManager.
	--reqMatchmakingAutoJoinSessionRandomMasterRank(
	--	System.UInt32 						myHunterRank
	--	System.UInt32						myMasterRank
	--)
	Constants.SDK.hook(req_matchmaking_random_master_rank_method, prehook_req_matchmaking_random_master_rank);

	--snow.SnowSessionManager.
	--reqMatchmakingAutoJoinSessionRandomMystery(
	--	System.UInt32 						myHunterRank
	--	System.UInt32						myMasterRank
	--	System.UInt32						myMasterRank (it is actually anomaly research level)
	--)
	Constants.SDK.hook(req_matchmaking_random_mystery_method, prehook_req_matchmaking_random_mystery);

	--snow.SnowSessionManager.
	--reqMatchmakingAutoJoinSessionRandomMysteryQuest(
	--	System.UInt32 						lvMin
	--	System.UInt32						lvMax
	--	System.UInt32						limit
	--	System.Nullable`1<System.UInt32>	enemyId
	--	snow.data.ContentsIdSystem.ItemId	rewardItem
	--	System.Boolean						isSpecialRandomMystery
	--)
	Constants.SDK.hook(req_matchmaking_random_mystery_quest_method, prehook_req_matchmaking_random_mystery_quest);
	Constants.SDK.hook(session_manager_type_def:get_method("reqOnlineWarning"), prehook_reqOnlineWarning);
end

return this;