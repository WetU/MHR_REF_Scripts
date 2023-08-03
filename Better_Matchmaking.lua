local require = require;
local Constants = require("Constants.Constants");

local find_type_definition = Constants.sdk.find_type_definition;
local to_managed_object = Constants.sdk.to_managed_object;
local get_managed_singleton = Constants.sdk.get_managed_singleton;
local hook = Constants.sdk.hook;
local to_int64 = Constants.sdk.to_int64;
local to_valuetype = Constants.sdk.to_valuetype;
local SKIP_ORIGINAL = Constants.sdk.SKIP_ORIGINAL;
local CALL_ORIGINAL = Constants.sdk.CALL_ORIGINAL;

local to_uint = Constants.to_uint;
local to_bool = Constants.to_bool;

local ValueType_new = Constants.ValueType.new;

local SendMessage = Constants.SendMessage;

local SKIP_ORIGINAL_func = Constants.SKIP_ORIGINAL;

local checkGameStatus = Constants.checkGameStatus;

-- Region lock fix
local session_steam_type_def = find_type_definition("via.network.SessionSteam");
local setLobbyDistanceFilter_method = session_steam_type_def:get_method("setLobbyDistanceFilter(System.UInt32)");
--
local function on_set_is_invisible(args)
	setLobbyDistanceFilter_method:call(to_managed_object(args[1]), 3);
end
hook(session_steam_type_def:get_method("setIsInvisible(System.Boolean)"), on_set_is_invisible);

-- timeout fix
local session_manager_type_def = find_type_definition("snow.SnowSessionManager");
local req_matchmaking_method = session_manager_type_def:get_method("reqMatchmakingAutoJoinSession(System.UInt32)");
local req_matchmaking_random_method = session_manager_type_def:get_method("reqMatchmakingAutoJoinSessionRandom(System.UInt32)");
local req_matchmaking_hyakuryu_method = session_manager_type_def:get_method("reqMatchmakingAutoJoinSessionHyakuryu(System.UInt32, System.Nullable`1<System.UInt32>, System.Nullable`1<System.UInt32>)");
local req_matchmaking_random_master_rank_method = session_manager_type_def:get_method("reqMatchmakingAutoJoinSessionRandomMasterRank(System.UInt32, System.UInt32)");
local req_matchmaking_random_mystery_method = session_manager_type_def:get_method("reqMatchmakingAutoJoinSessionRandomMystery(System.UInt32, System.UInt32, System.UInt32)");
local req_matchmaking_random_mystery_quest_method = session_manager_type_def:get_method("reqMatchmakingAutoJoinSessionRandomMysteryQuest(System.UInt32, System.UInt32, System.UInt32, System.Nullable`1<System.UInt32>, snow.data.ContentsIdSystem.ItemId, System.Boolean)");

local nullable_uint32_type_def = find_type_definition("System.Nullable`1<System.UInt32>");
--
local SessionAttr_Quest = find_type_definition("snow.network.session.SessionAttr"):get_field("Quest"):get_data(nil);
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
local quest_vars = nil;
local skip_next_hook = nil;

local function prehook_on_timeout(args)
	if quest_vars ~= nil and to_int64(args[3]) == SessionAttr_Quest then
		local session_manager = to_managed_object(args[2]) or get_managed_singleton("snow.SnowSessionManager");

		if quest_vars.quest_type == quest_types.regular then
			skip_next_hook = quest_types.regular;
			req_matchmaking_method:call(session_manager, quest_vars.quest_id);

		elseif quest_vars.quest_type == quest_types.random then
			skip_next_hook = quest_types.random;
			req_matchmaking_random_method:call(session_manager, quest_vars.my_hunter_rank);

		elseif quest_vars.quest_type == quest_types.rampage then
			skip_next_hook = quest_types.rampage;
			req_matchmaking_hyakuryu_method:call(session_manager, quest_vars.difficulty, quest_vars.quest_level, quest_vars.target_enemy);

		elseif quest_vars.quest_type == quest_types.random_master_rank then
			skip_next_hook = quest_types.random_master_rank;
			req_matchmaking_random_master_rank_method:call(session_manager, quest_vars.my_hunter_rank, quest_vars.my_master_rank);

		elseif quest_vars.quest_type == quest_types.random_anomaly then
			skip_next_hook = quest_types.random_anomaly;
			req_matchmaking_random_mystery_method:call(session_manager, quest_vars.my_hunter_rank, quest_vars.my_master_rank, quest_vars.anomaly_research_level);

		elseif quest_vars.quest_type == quest_types.anomaly_investigation then
			skip_next_hook = quest_types.anomaly_investigation;
			req_matchmaking_random_mystery_quest_method:call(
				session_manager,
				quest_vars.min_level,
				quest_vars.max_level,
				quest_vars.party_limit,
				quest_vars.enemy_id,
				quest_vars.reward_item,
				quest_vars.is_special_random_mystery
			);
		end

		return SKIP_ORIGINAL;
	end
end
hook(session_manager_type_def:get_method("funcOnTimeoutMatchmaking(snow.network.session.SessionAttr)"), prehook_on_timeout);

local function prehook_req_matchmaking(args)
	if skip_next_hook == quest_types.regular then
		skip_next_hook = nil;
		return;
	end

	quest_vars = {
		quest_type = quest_types.regular,
		quest_id = to_uint(args[3])
	};
end
--snow.SnowSessionManager.reqMatchmakingAutoJoinSession
--	System.UInt32 						questID
hook(req_matchmaking_method, prehook_req_matchmaking);

local function prehook_req_matchmaking_random(args)
	if skip_next_hook == quest_types.random then
		skip_next_hook = nil;
		return;
	end

	quest_vars = {
		quest_type = quest_types.random,
		my_hunter_rank = to_uint(args[3])
	};
end
--snow.SnowSessionManager.reqMatchmakingAutoJoinSessionRandom
--	System.UInt32 						myHunterRank
hook(req_matchmaking_random_method, prehook_req_matchmaking_random);

local function prehook_req_matchmaking_hyakuryu(args)
	if skip_next_hook == quest_types.rampage then
		skip_next_hook = nil;
		return;
	end

	quest_vars = {
		quest_type = quest_types.rampage,
		difficulty = to_uint(args[3]),
		quest_level = to_valuetype(args[4], nullable_uint32_type_def),
		target_enemy = to_valuetype(args[5], nullable_uint32_type_def)
	};
end
--snow.SnowSessionManager.reqMatchmakingAutoJoinSessionHyakuryu
--	System.UInt32 						difficulty
--	System.Nullable`1<System.UInt32>	questLevel
--	System.Nullable`1<System.UInt32>	targetEnemy
hook(req_matchmaking_hyakuryu_method, prehook_req_matchmaking_hyakuryu);

local function prehook_req_matchmaking_random_master_rank(args)
	if skip_next_hook == quest_types.random_master_rank then
		skip_next_hook = nil;
		return;
	end

	quest_vars = {
		quest_type = quest_types.random_master_rank,
		my_hunter_rank = to_uint(args[3]),
		my_master_rank = to_uint(args[4])
	};
end
--snow.SnowSessionManager.reqMatchmakingAutoJoinSessionRandomMasterRank
--	System.UInt32 						myHunterRank
--	System.UInt32						myMasterRank
hook(req_matchmaking_random_master_rank_method, prehook_req_matchmaking_random_master_rank);

local function prehook_req_matchmaking_random_mystery(args)
	if skip_next_hook == quest_types.random_anomaly then
		skip_next_hook = nil;
		return;
	end

	quest_vars = {
		quest_type = quest_types.random_anomaly,
		my_hunter_rank = to_uint(args[3]),
		my_master_rank = to_uint(args[4]),
		anomaly_research_level = to_uint(args[5])
	};
end
--snow.SnowSessionManager.reqMatchmakingAutoJoinSessionRandomMystery
--	System.UInt32 						myHunterRank
--	System.UInt32						myMasterRank
--	System.UInt32						mysteryResearchLevel
hook(req_matchmaking_random_mystery_method, prehook_req_matchmaking_random_mystery);

local function prehook_req_matchmaking_random_mystery_quest(args)
	if skip_next_hook == quest_types.anomaly_investigation then
		skip_next_hook = nil;
		return;
	end

	quest_vars = {
		quest_type = quest_types.anomaly_investigation,
		min_level = to_uint(args[3]),
		max_level = to_uint(args[4]),
		party_limit = to_uint(args[5]),
		enemy_id = to_valuetype(args[6], nullable_uint32_type_def),
		reward_item = to_uint(args[7]) or I_Unclassified_None,
		is_special_random_mystery = to_bool(args[8])
	};
end
--snow.SnowSessionManager.reqMatchmakingAutoJoinSessionRandomMysteryQuest
--	System.UInt32 						lvMin
--	System.UInt32						lvMax
--	System.UInt32						limit
--	System.Nullable`1<System.UInt32>	enemyId
--	snow.data.ContentsIdSystem.ItemId	rewardItem
--	System.Boolean						isSpecialRandomMystery
hook(req_matchmaking_random_mystery_quest_method, prehook_req_matchmaking_random_mystery_quest);

local function onStartSearch()
	isSearching = true;
end
hook(session_manager_type_def:get_method("routineMatchmakingAutoJoinSession"), nil, onStartSearch);

local function clearVars()
	isSearching = false;
	quest_type = nil;
	quest_vars = nil;
	skip_next_hook = nil;
end

local function onCancelSearch(retval)
	if isSearching == true and to_bool(retval) == true then
		clearVars();
	end

	return retval;
end
hook(Constants.type_definitions.StmGuiInput_type_def:get_method("getCancelButtonTrg(snow.StmInputConfig.KeyConfigType, System.Boolean)"), nil, onCancelSearch);
hook(session_manager_type_def:get_method("funcOnCompletedMatchmaking(snow.network.session.SessionAttr)"), clearVars);
hook(session_manager_type_def:get_method("funcOnOccuredMatchmakingFatalError(snow.network.session.SessionAttr)"), clearVars);
hook(session_manager_type_def:get_method("funcOnRejectedMatchmaking(snow.network.session.SessionAttr)"), clearVars);

local function onKicked()
	SendMessage(nil, "세션에서 추방당했습니다");
end
hook(session_manager_type_def:get_method("funcOnKicked(snow.network.session.SessionAttr)"), nil, onKicked);
hook(session_manager_type_def:get_method("reqOnlineWarning"), SKIP_ORIGINAL_func);

-- misc fixes
local Quest_type = Constants.GameStatusType.Quest;
local function PreHook_setOpenNetworkErrorWindowSelection()
	return checkGameStatus(Quest_type) == true and SKIP_ORIGINAL or CALL_ORIGINAL;
end
hook(Constants.type_definitions.GuiManager_type_def:get_method("setOpenNetworkErrorWindowSelection(System.Guid, System.Boolean, System.String, System.Boolean)"), PreHook_setOpenNetworkErrorWindowSelection);