local Constants = require("Constants.Constants");
-- Region lock fix
local session_steam_type_def = sdk.find_type_definition("via.network.SessionSteam");
local setLobbyDistanceFilter_method = session_steam_type_def:get_method("setLobbyDistanceFilter(System.UInt32)");
--
local function on_set_is_invisible(args)
	setLobbyDistanceFilter_method:call(sdk.to_managed_object(args[1]), 3);
end
sdk.hook(session_steam_type_def:get_method("setIsInvisible(System.Boolean)"), on_set_is_invisible);

-- timeout fix
local session_manager_type_def = sdk.find_type_definition("snow.SnowSessionManager");
local req_matchmaking_method = session_manager_type_def:get_method("reqMatchmakingAutoJoinSession(System.UInt32)");
local req_matchmaking_random_method = session_manager_type_def:get_method("reqMatchmakingAutoJoinSessionRandom(System.UInt32)");
local req_matchmaking_hyakuryu_method = session_manager_type_def:get_method("reqMatchmakingAutoJoinSessionHyakuryu(System.UInt32, System.Nullable`1<System.UInt32>, System.Nullable`1<System.UInt32>)");
local req_matchmaking_random_master_rank_method = session_manager_type_def:get_method("reqMatchmakingAutoJoinSessionRandomMasterRank(System.UInt32, System.UInt32)");
local req_matchmaking_random_mystery_method = session_manager_type_def:get_method("reqMatchmakingAutoJoinSessionRandomMystery(System.UInt32, System.UInt32, System.UInt32)");
local req_matchmaking_random_mystery_quest_method = session_manager_type_def:get_method("reqMatchmakingAutoJoinSessionRandomMysteryQuest(System.UInt32, System.UInt32, System.UInt32, System.Nullable`1<System.UInt32>, snow.data.ContentsIdSystem.ItemId, System.Boolean)");

local nullable_uint32_type_def = sdk.find_type_definition("System.Nullable`1<System.UInt32>");
local nullable_uint32_constructor_method = nullable_uint32_type_def:get_method(".ctor(System.UInt32)");
local nullable_uint32_get_has_value_method = nullable_uint32_type_def:get_method("get_HasValue");
local nullable_uint32_get_value_method = nullable_uint32_type_def:get_method("get_Value");
--
local SessionAttr_Quest = sdk.find_type_definition("snow.network.session.SessionAttr"):get_field("Quest"):get_data(nil);
--
local quest_types = {
	regular = 1,
	random = 2,
	rampage = 3,
	random_master_rank = 4,
	random_anomaly = 5,
	anomaly_investigation = 6
};

local I_Unclassified_None = Constants.type_definitions.ItemId_type_def:get_field("I_Unclassified_None"):get_data(nil);
--
local isSearching = false;
local quest_type = nil;
local quest_vars = nil;
local skip_next_hook = nil;

local function prehook_on_timeout(args)
	if quest_type ~= nil and quest_vars ~= nil and sdk.to_int64(args[3]) == SessionAttr_Quest then
		local session_manager = sdk.to_managed_object(args[2]) or sdk.get_managed_singleton("snow.SnowSessionManager");

		if quest_type == quest_types.regular then
			skip_next_hook = quest_types.regular;
			req_matchmaking_method:call(session_manager, quest_vars.quest_id);

		elseif quest_type == quest_types.random then
			skip_next_hook = quest_types.random;
			req_matchmaking_random_method:call(session_manager, quest_vars.my_hunter_rank);

		elseif quest_type == quest_types.rampage then
			skip_next_hook = quest_types.rampage;

			local quest_level_pointer = ValueType.new(nullable_uint32_type_def);
			nullable_uint32_constructor_method:call(quest_level_pointer, quest_vars.quest_level.value);
			quest_level_pointer:set_field("_HasValue", quest_vars.quest_level.has_value);

			local target_enemy_pointer = ValueType.new(nullable_uint32_type_def);
			nullable_uint32_constructor_method:call(target_enemy_pointer, quest_vars.target_enemy.value);
			target_enemy_pointer:set_field("_HasValue", quest_vars.target_enemy.has_value);

			req_matchmaking_hyakuryu_method:call(session_manager, quest_vars.difficulty, quest_level_pointer, target_enemy_pointer);

		elseif quest_type == quest_types.random_master_rank then
			skip_next_hook = quest_types.random_master_rank;
			req_matchmaking_random_master_rank_method:call(session_manager, quest_vars.my_hunter_rank, quest_vars.my_master_rank);

		elseif quest_type == quest_types.random_anomaly then
			skip_next_hook = quest_types.random_anomaly;
			req_matchmaking_random_mystery_method:call(session_manager, quest_vars.my_hunter_rank, quest_vars.my_master_rank, quest_vars.anomaly_research_level);

		elseif quest_type == quest_types.anomaly_investigation then
			skip_next_hook = quest_types.anomaly_investigation;

			local enemy_id_pointer = ValueType.new(nullable_uint32_type_def);
			nullable_uint32_constructor_method:call(enemy_id_pointer, quest_vars.enemy_id.value);
			enemy_id_pointer:set_field("_HasValue", quest_vars.enemy_id.has_value);

			req_matchmaking_random_mystery_quest_method:call(
				session_manager,
				quest_vars.min_level,
				quest_vars.max_level,
				quest_vars.party_limit,
				enemy_id_pointer,
				quest_vars.reward_item,
				quest_vars.is_special_random_mystery
			);
		end

		return sdk.PreHookResult.SKIP_ORIGINAL;
	end
end
sdk.hook(session_manager_type_def:get_method("funcOnTimeoutMatchmaking(snow.network.session.SessionAttr)"), prehook_on_timeout);

local function prehook_req_matchmaking(args)
	if skip_next_hook == quest_types.regular then
		skip_next_hook = nil;
		return;
	end

	quest_type = quest_types.regular;
	quest_vars = {
		quest_id = Constants.to_uint(args[3])
	};
end
--snow.SnowSessionManager.reqMatchmakingAutoJoinSession
--	System.UInt32 						questID
sdk.hook(req_matchmaking_method, prehook_req_matchmaking);

local function prehook_req_matchmaking_random(args)
	if skip_next_hook == quest_types.random then
		skip_next_hook = nil;
		return;
	end

	quest_type = quest_types.random;
	quest_vars = {
		my_hunter_rank = Constants.to_uint(args[3])
	};
end
--snow.SnowSessionManager.reqMatchmakingAutoJoinSessionRandom
--	System.UInt32 						myHunterRank
sdk.hook(req_matchmaking_random_method, prehook_req_matchmaking_random);

local function prehook_req_matchmaking_hyakuryu(args)
	if skip_next_hook == quest_types.rampage then
		skip_next_hook = nil;
		return;
	end

	local quest_level_has_value = nullable_uint32_get_has_value_method:call(sdk.to_int64(args[4]));
	local target_enemy_has_value = nullable_uint32_get_has_value_method:call(sdk.to_int64(args[5]));

	quest_type = quest_types.rampage;
	quest_vars = {
		difficulty = Constants.to_uint(args[3]),
		quest_level = {
			has_value = quest_level_has_value,
			value = quest_level_has_value == true and nullable_uint32_get_value_method:call(args[4]) or nil
		},
		target_enemy = {
			has_value = target_enemy_has_value,
			value = target_enemy_has_value == true and nullable_uint32_get_value_method:call(args[5]) or nil
		}
	};
end
--snow.SnowSessionManager.reqMatchmakingAutoJoinSessionHyakuryu
--	System.UInt32 						difficulty
--	System.Nullable`1<System.UInt32>	questLevel
--	System.Nullable`1<System.UInt32>	targetEnemy
sdk.hook(req_matchmaking_hyakuryu_method, prehook_req_matchmaking_hyakuryu);

local function prehook_req_matchmaking_random_master_rank(args)
	if skip_next_hook == quest_types.random_master_rank then
		skip_next_hook = nil;
		return;
	end

	quest_type = quest_types.random_master_rank;
	quest_vars = {
		my_hunter_rank = Constants.to_uint(args[3]),
		my_master_rank = Constants.to_uint(args[4])
	};
end
--snow.SnowSessionManager.reqMatchmakingAutoJoinSessionRandomMasterRank
--	System.UInt32 						myHunterRank
--	System.UInt32						myMasterRank
sdk.hook(req_matchmaking_random_master_rank_method, prehook_req_matchmaking_random_master_rank);

local function prehook_req_matchmaking_random_mystery(args)
	if skip_next_hook == quest_types.random_anomaly then
		skip_next_hook = nil;
		return;
	end

	quest_type = quest_types.random_anomaly;
	quest_vars = {
		my_hunter_rank = Constants.to_uint(args[3]),
		my_master_rank = Constants.to_uint(args[4]),
		anomaly_research_level = Constants.to_uint(args[5])
	};
end
--snow.SnowSessionManager.reqMatchmakingAutoJoinSessionRandomMystery
--	System.UInt32 						myHunterRank
--	System.UInt32						myMasterRank
--	System.UInt32						mysteryResearchLevel
sdk.hook(req_matchmaking_random_mystery_method, prehook_req_matchmaking_random_mystery);

local function prehook_req_matchmaking_random_mystery_quest(args)
	if skip_next_hook == quest_types.anomaly_investigation then
		skip_next_hook = nil;
		return;
	end

	local enemy_id_has_value = nullable_uint32_get_has_value_method:call(sdk.to_int64(args[6]));

	quest_type = quest_types.anomaly_investigation;
	quest_vars = {
		min_level = Constants.to_uint(args[3]),
		max_level = Constants.to_uint(args[4]),
		party_limit = Constants.to_uint(args[5]),
		enemy_id = {
			has_value = enemy_id_has_value,
			value = enemy_id_has_value == true and nullable_uint32_get_value_method:call(args[6]) or nil
		},
		reward_item = Constants.to_uint(args[7]) or I_Unclassified_None,
		is_special_random_mystery = Constants.to_bool(args[8])
	};
end
--snow.SnowSessionManager.reqMatchmakingAutoJoinSessionRandomMysteryQuest
--	System.UInt32 						lvMin
--	System.UInt32						lvMax
--	System.UInt32						limit
--	System.Nullable`1<System.UInt32>	enemyId
--	snow.data.ContentsIdSystem.ItemId	rewardItem
--	System.Boolean						isSpecialRandomMystery
sdk.hook(req_matchmaking_random_mystery_quest_method, prehook_req_matchmaking_random_mystery_quest);

local function onStartSearch()
	isSearching = true;
end
sdk.hook(session_manager_type_def:get_method("routineMatchmakingAutoJoinSession"), nil, onStartSearch);

local function clearVars()
	isSearching = false;
	quest_type = nil;
	quest_vars = nil;
	skip_next_hook = nil;
end

local function onCancelSearch(retval)
	if isSearching == true and Constants.to_bool(retval) == true then
		clearVars();
	end

	return retval;
end
sdk.hook(Constants.type_definitions.StmGuiInput_type_def:get_method("getCancelButtonTrg(snow.StmInputConfig.KeyConfigType, System.Boolean)"), nil, onCancelSearch);
sdk.hook(session_manager_type_def:get_method("funcOnJoinMemberByMatchmaking(snow.network.session.SessionAttr, System.Int32)"), clearVars);
sdk.hook(session_manager_type_def:get_method("funcOnOccuredMatchmakingFatalError(snow.network.session.SessionAttr)"), clearVars);
sdk.hook(session_manager_type_def:get_method("funcOnRejectedMatchmaking(snow.network.session.SessionAttr)"), clearVars);

-- misc fixes
local function PreHook_setOpenNetworkErrorWindowSelection()
	return Constants.checkGameStatus(Constants.GameStatusType.Quest) == true and sdk.PreHookResult.SKIP_ORIGINAL or sdk.PreHookResult.CALL_ORIGINAL;
end

sdk.hook(Constants.type_definitions.GuiManager_type_def:get_method("setOpenNetworkErrorWindowSelection(System.Guid, System.Boolean, System.String, System.Boolean)"), PreHook_setOpenNetworkErrorWindowSelection);
sdk.hook(session_manager_type_def:get_method("reqOnlineWarning"), Constants.SKIP_ORIGINAL);
--
local function onKicked()
	Constants.SendMessage(nil, "세션에서 추방당했습니다");
end
sdk.hook(session_manager_type_def:get_method("funcOnKicked(snow.network.session.SessionAttr)"), nil, onKicked);