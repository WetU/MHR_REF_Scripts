local Constants = require("Constants.Constants");
if Constants == nil then
	return;
end
-- Region lock fix
local session_steam_type_def = Constants.SDK.find_type_definition("via.network.SessionSteam");
local setLobbyDistanceFilter_method = session_steam_type_def:get_method("setLobbyDistanceFilter(System.UInt32)");
--
local function on_set_is_invisible(args)
	local session_steam = Constants.SDK.to_managed_object(args[1]);
	if session_steam == nil then
		return;
	end

	setLobbyDistanceFilter_method:call(session_steam, 3);
end
Constants.SDK.hook(session_steam_type_def:get_method("setIsInvisible(System.Boolean)"), on_set_is_invisible);

-- timeout fix
local session_manager_type_def = Constants.SDK.find_type_definition("snow.SnowSessionManager");
local req_matchmaking_method = session_manager_type_def:get_method("reqMatchmakingAutoJoinSession(System.UInt32)");
local req_matchmaking_random_method = session_manager_type_def:get_method("reqMatchmakingAutoJoinSessionRandom(System.UInt32)");
local req_matchmaking_hyakuryu_method = session_manager_type_def:get_method("reqMatchmakingAutoJoinSessionHyakuryu(System.UInt32, System.Nullable`1<System.UInt32>, System.Nullable`1<System.UInt32>)");
local req_matchmaking_random_master_rank_method = session_manager_type_def:get_method("reqMatchmakingAutoJoinSessionRandomMasterRank(System.UInt32, System.UInt32)");
local req_matchmaking_random_mystery_method = session_manager_type_def:get_method("reqMatchmakingAutoJoinSessionRandomMystery(System.UInt32, System.UInt32, System.UInt32)");
local req_matchmaking_random_mystery_quest_method = session_manager_type_def:get_method("reqMatchmakingAutoJoinSessionRandomMysteryQuest(System.UInt32, System.UInt32, System.UInt32, System.Nullable`1<System.UInt32>, snow.data.ContentsIdSystem.ItemId, System.Boolean)");

local nullable_uint32_type_def = Constants.SDK.find_type_definition("System.Nullable`1<System.UInt32>");
local nullable_uint32_constructor_method = nullable_uint32_type_def:get_method(".ctor(System.UInt32)");
local nullable_uint32_get_has_value_method = nullable_uint32_type_def:get_method("get_HasValue");
local nullable_uint32_get_value_method = nullable_uint32_type_def:get_method("get_Value");
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
			value = nil,
			has_value = false
		},
		target_enemy = {
			value = nil,
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
			value = nil,
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
local skip_next_hook = nil;

local session_manager = nil;
local function prehook_on_timeout(args)
	if quest_type == quest_types.invalid then
		return;
	end

	if Constants.SDK.to_int64(args[3]) < SessionAttr_Quest then
		return;
	end

	local session_manager = Constants.SDK.to_managed_object(args[2]);
	if session_manager == nil then
		return;
	end

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

	return Constants.SDK.SKIP_ORIGINAL;
end
Constants.SDK.hook(session_manager_type_def:get_method("funcOnTimeoutMatchmaking(snow.network.session.SessionAttr)"), prehook_on_timeout);

local function prehook_req_matchmaking(args)
	if skip_next_hook == skip_types.regular then
		skip_next_hook = nil;
		return;
	end

	quest_type = quest_types.regular;
	quest_type.quest_id = Constants.to_uint(args[3]);
end
--snow.SnowSessionManager.reqMatchmakingAutoJoinSession
--	System.UInt32 						questID
Constants.SDK.hook(req_matchmaking_method, prehook_req_matchmaking);

local function prehook_req_matchmaking_random(args)
	if skip_next_hook == skip_types.random then
		skip_next_hook = nil;
		return;
	end

	quest_type = quest_types.random;
	quest_type.my_hunter_rank = Constants.to_uint(args[3]);
end
--snow.SnowSessionManager.reqMatchmakingAutoJoinSessionRandom
--	System.UInt32 						myHunterRank
Constants.SDK.hook(req_matchmaking_random_method, prehook_req_matchmaking_random);

local function prehook_req_matchmaking_hyakuryu(args)
	if skip_next_hook == skip_types.rampage then
		skip_next_hook = nil;
		return;
	end

	quest_type = quest_types.rampage;
	quest_type.difficulty = Constants.to_uint(args[3]);

	quest_type.quest_level.has_value = nullable_uint32_get_has_value_method:call(Constants.SDK.to_int64(args[4]));
	quest_type.quest_level.value = quest_type.quest_level.has_value == true and nullable_uint32_get_value_method:call(args[4]) or nil;

	quest_type.target_enemy.has_value = nullable_uint32_get_has_value_method:call(Constants.SDK.to_int64(args[5]));
	quest_type.target_enemy.value = quest_type.target_enemy.has_value == true and nullable_uint32_get_value_method:call(args[5]) or nil;
end
--snow.SnowSessionManager.reqMatchmakingAutoJoinSessionHyakuryu
--	System.UInt32 						difficulty
--	System.Nullable`1<System.UInt32>	questLevel
--	System.Nullable`1<System.UInt32>	targetEnemy
Constants.SDK.hook(req_matchmaking_hyakuryu_method, prehook_req_matchmaking_hyakuryu);

local function prehook_req_matchmaking_random_master_rank(args)
	if skip_next_hook == skip_types.random_master_rank then
		skip_next_hook = nil;
		return;
	end

	quest_type = quest_types.random_master_rank;
	quest_type.my_hunter_rank = Constants.to_uint(args[3]);
	quest_type.my_master_rank = Constants.to_uint(args[4]);
end
--snow.SnowSessionManager.reqMatchmakingAutoJoinSessionRandomMasterRank
--	System.UInt32 						myHunterRank
--	System.UInt32						myMasterRank
Constants.SDK.hook(req_matchmaking_random_master_rank_method, prehook_req_matchmaking_random_master_rank);

local function prehook_req_matchmaking_random_mystery(args)
	if skip_next_hook == skip_types.random_anomaly then
		skip_next_hook = nil;
		return;
	end

	quest_type = quest_types.random_anomaly;
	quest_type.my_hunter_rank = Constants.to_uint(args[3]);
	quest_type.my_master_rank = Constants.to_uint(args[4]);
	quest_type.anomaly_research_level = Constants.to_uint(args[5]);
end
--snow.SnowSessionManager.reqMatchmakingAutoJoinSessionRandomMystery
--	System.UInt32 						myHunterRank
--	System.UInt32						myMasterRank
--	System.UInt32						mysteryResearchLevel
Constants.SDK.hook(req_matchmaking_random_mystery_method, prehook_req_matchmaking_random_mystery);

local function prehook_req_matchmaking_random_mystery_quest(args)
	if skip_next_hook == skip_types.anomaly_investigation then
		skip_next_hook = nil;
		return;
	end

	quest_type = quest_types.anomaly_investigation;
	quest_type.min_level = Constants.to_uint(args[3]);
	quest_type.max_level = Constants.to_uint(args[4]);
	quest_type.party_limit = Constants.to_uint(args[5]);
	quest_type.reward_item = Constants.to_uint(args[7]);
	quest_type.is_special_random_mystery = Constants.to_bool(args[8]);

	quest_type.enemy_id.has_value = nullable_uint32_get_has_value_method:call(Constants.SDK.to_int64(args[6]));
	quest_type.enemy_id.value = quest_type.enemy_id.has_value == true and nullable_uint32_get_value_method:call(args[6]) or nil;
end

--snow.SnowSessionManager.reqMatchmakingAutoJoinSessionRandomMysteryQuest
--	System.UInt32 						lvMin
--	System.UInt32						lvMax
--	System.UInt32						limit
--	System.Nullable`1<System.UInt32>	enemyId
--	snow.data.ContentsIdSystem.ItemId	rewardItem
--	System.Boolean						isSpecialRandomMystery
Constants.SDK.hook(req_matchmaking_random_mystery_quest_method, prehook_req_matchmaking_random_mystery_quest);

-- misc fixes
local function PreHook_setOpenNetworkErrorWindowSelection()
	return Constants.checkGameStatus(Constants.GameStatusType.Quest) == true and Constants.SDK.SKIP_ORIGINAL or Constants.SDK.CALL_ORIGINAL;
end
--
Constants.SDK.hook(Constants.type_definitions.GuiManager_type_def:get_method("setOpenNetworkErrorWindowSelection(System.Guid, System.Boolean, System.String, System.Boolean)"), PreHook_setOpenNetworkErrorWindowSelection);
Constants.SDK.hook(session_manager_type_def:get_method("reqOnlineWarning"), Constants.SKIP_ORIGINAL);