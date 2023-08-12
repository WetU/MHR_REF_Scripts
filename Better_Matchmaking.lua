local Constants = _G.require("Constants.Constants");

local find_type_definition = Constants.sdk.find_type_definition;
local to_managed_object = Constants.sdk.to_managed_object;
local get_managed_singleton = Constants.sdk.get_managed_singleton;
local hook = Constants.sdk.hook;
local to_int64 = Constants.sdk.to_int64;
local to_valuetype = Constants.sdk.to_valuetype;
local SKIP_ORIGINAL = Constants.sdk.SKIP_ORIGINAL;
local CALL_ORIGINAL = Constants.sdk.CALL_ORIGINAL;

local SendMessage = Constants.SendMessage;
local SKIP_ORIGINAL_func = Constants.SKIP_ORIGINAL_func;
local to_bool = Constants.to_bool;

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
local quest_types = {
	"regular",
	"random",
	"rampage",
	"random_master_rank",
	"random_anomaly",
	"anomaly_investigation"
};
--
local isSearching = false;
local quest_vars = nil;
local skip_next_hook = nil;

local function prehook_on_timeout(args)
	if quest_vars ~= nil and to_int64(args[3]) == 2 then
		local session_manager = to_managed_object(args[2]) or get_managed_singleton("snow.SnowSessionManager");

		local questType = quest_vars.quest_type;
		skip_next_hook = questType;
		if questType == quest_types[1] then
			req_matchmaking_method:call(session_manager, quest_vars.quest_id);

		elseif questType == quest_types[2] then
			req_matchmaking_random_method:call(session_manager, quest_vars.my_hunter_rank);

		elseif questType == quest_types[3] then
			req_matchmaking_hyakuryu_method:call(session_manager, quest_vars.difficulty, quest_vars.quest_level, quest_vars.target_enemy);

		elseif questType == quest_types[4] then
			req_matchmaking_random_master_rank_method:call(session_manager, quest_vars.my_hunter_rank, quest_vars.my_master_rank);

		elseif questType == quest_types[5] then
			req_matchmaking_random_mystery_method:call(session_manager, quest_vars.my_hunter_rank, quest_vars.my_master_rank, quest_vars.anomaly_research_level);

		elseif questType == quest_types[6] then
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
	local regular = quest_types[1];

	if skip_next_hook == regular then
		skip_next_hook = nil;
		return;
	end

	quest_vars = {
		quest_type = regular,
		quest_id = to_int64(args[3])
	};
end
--snow.SnowSessionManager.reqMatchmakingAutoJoinSession
--	System.UInt32 						questID
hook(req_matchmaking_method, prehook_req_matchmaking);

local function prehook_req_matchmaking_random(args)
	local random = quest_types[2];

	if skip_next_hook == random then
		skip_next_hook = nil;
		return;
	end

	quest_vars = {
		quest_type = random,
		my_hunter_rank = to_int64(args[3])
	};
end
--snow.SnowSessionManager.reqMatchmakingAutoJoinSessionRandom
--	System.UInt32 						myHunterRank
hook(req_matchmaking_random_method, prehook_req_matchmaking_random);

local function prehook_req_matchmaking_hyakuryu(args)
	local rampage = quest_types[3];

	if skip_next_hook == rampage then
		skip_next_hook = nil;
		return;
	end

	quest_vars = {
		quest_type = rampage,
		difficulty = to_int64(args[3]),
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
	local random_master_rank = quest_types[4];

	if skip_next_hook == random_master_rank then
		skip_next_hook = nil;
		return;
	end

	quest_vars = {
		quest_type = random_master_rank,
		my_hunter_rank = to_int64(args[3]),
		my_master_rank = to_int64(args[4])
	};
end
--snow.SnowSessionManager.reqMatchmakingAutoJoinSessionRandomMasterRank
--	System.UInt32 						myHunterRank
--	System.UInt32						myMasterRank
hook(req_matchmaking_random_master_rank_method, prehook_req_matchmaking_random_master_rank);

local function prehook_req_matchmaking_random_mystery(args)
	local random_anomaly = quest_types[5];

	if skip_next_hook == random_anomaly then
		skip_next_hook = nil;
		return;
	end

	quest_vars = {
		quest_type = random_anomaly,
		my_hunter_rank = to_int64(args[3]),
		my_master_rank = to_int64(args[4]),
		anomaly_research_level = to_int64(args[5])
	};
end
--snow.SnowSessionManager.reqMatchmakingAutoJoinSessionRandomMystery
--	System.UInt32 						myHunterRank
--	System.UInt32						myMasterRank
--	System.UInt32						mysteryResearchLevel
hook(req_matchmaking_random_mystery_method, prehook_req_matchmaking_random_mystery);

local function prehook_req_matchmaking_random_mystery_quest(args)
	local anomaly_investigation = quest_types[6];

	if skip_next_hook == anomaly_investigation then
		skip_next_hook = nil;
		return;
	end

	quest_vars = {
		quest_type = anomaly_investigation,
		min_level = to_int64(args[3]),
		max_level = to_int64(args[4]),
		party_limit = to_int64(args[5]),
		enemy_id = to_valuetype(args[6], nullable_uint32_type_def),
		reward_item = to_int64(args[7]) or 67108864,
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
local function PreHook_setOpenNetworkErrorWindowSelection()
	return checkGameStatus(2) == true and SKIP_ORIGINAL or CALL_ORIGINAL;
end
hook(Constants.type_definitions.GuiManager_type_def:get_method("setOpenNetworkErrorWindowSelection(System.Guid, System.Boolean, System.String, System.Boolean)"), PreHook_setOpenNetworkErrorWindowSelection);