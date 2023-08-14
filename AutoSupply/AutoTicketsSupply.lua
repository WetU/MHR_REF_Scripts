local Constants = _G.require("Constants.Constants");

local hook = Constants.sdk.hook;
local find_type_definition = Constants.sdk.find_type_definition;
local to_managed_object = Constants.sdk.to_managed_object;

local TRUE_POINTER = Constants.TRUE_POINTER;
local FALSE_POINTER = Constants.FALSE_POINTER;

local to_bool = Constants.to_bool;
--
local GoodReward_supplyReward_method = find_type_definition("snow.progress.ProgressGoodRewardManager"):get_method("supplyReward");
--
local Otomo_supply_method = find_type_definition("snow.progress.ProgressOtomoTicketManager"):get_method("supply");
--
local Ticket_supply_method = find_type_definition("snow.progress.ProgressTicketSupplyManager"):get_method("supply(snow.progress.ProgressTicketSupplyManager.TicketType)");
--
--[[local ProgressEc019UnlockItemManager_type_def = find_type_definition("snow.progress.ProgressEc019UnlockItemManager");
local Ec019_supply_method = ProgressEc019UnlockItemManager_type_def:get_method("supply");
local Ec019_supplyMR_method = ProgressEc019UnlockItemManager_type_def:get_method("supplyMR");
--
local SwitchAction_supply_method = find_type_definition("snow.progress.ProgressSwitchActionSupplyManager"):get_method("supply");
--
local Note_supply_method = find_type_definition("snow.progress.ProgressNoteRewardManager"):get_method("supply");]]
--
local get_BbqFunc_method = Constants.type_definitions.KitchenFacility_type_def:get_method("get_BbqFunc");

local outputTicket_method = get_BbqFunc_method:get_return_type():get_method("outputTicket");
--
local FacilityDataManager_type_def = Constants.type_definitions.FacilityDataManager_type_def;
local getMysteryLaboFacility_method = FacilityDataManager_type_def:get_method("getMysteryLaboFacility");

local get_LaboReward_method = getMysteryLaboFacility_method:get_return_type():get_method("get_LaboReward");

local get_IsClear_method = get_LaboReward_method:get_return_type():get_method("get_IsClear");
--
local getCommercialStuffFacility_method = FacilityDataManager_type_def:get_method("getCommercialStuffFacility");

local CommercialStuffFacility_type_def = getCommercialStuffFacility_method:get_return_type();
local get_CommercialStuffID_method = CommercialStuffFacility_type_def:get_method("get_CommercialStuffID");
local get_CanObtainlItem_method = CommercialStuffFacility_type_def:get_method("get_CanObtainlItem");
--
local NpcTalkMessageCtrl_type_def = find_type_definition("snow.npc.NpcTalkMessageCtrl");
local get_NpcId_method = NpcTalkMessageCtrl_type_def:get_method("get_NpcId");
local resetTalkDispName_method = NpcTalkMessageCtrl_type_def:get_method("resetTalkDispName");
local set_DetermineSpeechBalloonMessage_method = NpcTalkMessageCtrl_type_def:get_method("set_DetermineSpeechBalloonMessage(System.String)");
local set_SpeechBalloonAttr_method = NpcTalkMessageCtrl_type_def:get_method("set_SpeechBalloonAttr(snow.npc.TalkAttribute)");
local talkAction2_CommercialStuffItem_method = NpcTalkMessageCtrl_type_def:get_method("talkAction2_CommercialStuffItem(snow.NpcDefine.NpcID, snow.npc.TalkAction2Param, System.UInt32)");
local talkAction2_SupplyMysteryResearchRequestReward_method = NpcTalkMessageCtrl_type_def:get_method("talkAction2_SupplyMysteryResearchRequestReward(snow.NpcDefine.NpcID, snow.npc.TalkAction2Param, System.UInt32)");
--
local Reward_Ids_field = find_type_definition("snow.gui.GuiRewardDialog"):get_field("Reward_Ids");
local get_Item_method = Reward_Ids_field:get_type():get_method("get_Item(System.Int32)");
--
local MysteryResearchRequestEnd = nil;
local CommercialStuff = nil;

local function get_CanObtainCommercialStuff()
	if CommercialStuff ~= nil then
		local result = CommercialStuff;
		CommercialStuff = nil;
		return result;
	end

	local CommercialStuffFacility = getCommercialStuffFacility_method:call(Constants:get_FacilityDataManager());
	return get_CanObtainlItem_method:call(CommercialStuffFacility) == true and get_CommercialStuffID_method:call(CommercialStuffFacility) ~= 0 or nil;
end

local function get_IsMysteryResearchRequestClear()
	if MysteryResearchRequestEnd ~= nil then
		local result = MysteryResearchRequestEnd;
		MysteryResearchRequestEnd = nil;
		return result;
	end

	return get_IsClear_method:call(get_LaboReward_method:call(getMysteryLaboFacility_method:call(Constants:get_FacilityDataManager())));
end
--
local CommercialNpcTalkMessageCtrl = nil;
local MysteryLaboNpcTalkMessageCtrl = nil;
local isOpenMysteryResearchReward = false;

local NpcTalkMessageCtrl = nil;
local function PreHook_getTalkTarget(args)
	NpcTalkMessageCtrl = to_managed_object(args[2]);
end
local function PostHook_getTalkTarget()
	local NpcId = get_NpcId_method:call(NpcTalkMessageCtrl);
	if NpcId == 106 and get_CanObtainCommercialStuff() == true then
		CommercialNpcTalkMessageCtrl = NpcTalkMessageCtrl;
	elseif NpcId == 78 and get_IsMysteryResearchRequestClear() == true then
		MysteryLaboNpcTalkMessageCtrl = NpcTalkMessageCtrl;
	end

	NpcTalkMessageCtrl = nil;
end

local function talkHandler()
	if CommercialNpcTalkMessageCtrl ~= nil and talkAction2_CommercialStuffItem_method:call(CommercialNpcTalkMessageCtrl, 106, 0, 0) == true then
		CommercialNpcTalkMessageCtrl = nil;
	end

	if MysteryLaboNpcTalkMessageCtrl ~= nil and talkAction2_SupplyMysteryResearchRequestReward_method:call(MysteryLaboNpcTalkMessageCtrl, 78, 0, 0) == true then
		resetTalkDispName_method:call(MysteryLaboNpcTalkMessageCtrl);
		set_DetermineSpeechBalloonMessage_method:call(MysteryLaboNpcTalkMessageCtrl, nil);
		set_SpeechBalloonAttr_method:call(MysteryLaboNpcTalkMessageCtrl, 0);
		MysteryLaboNpcTalkMessageCtrl = nil;
		isOpenMysteryResearchReward = true;
	end
end
--
local function PostHook_checkPickItem_V02Ticket(retval)
	if to_bool(retval) == true then
		Ticket_supply_method:call(Constants:get_ProgressTicketSupplyManager(), 2);
		return FALSE_POINTER;
	end

	return retval;
end
local function PostHook_checkPickItem_MysteryTicket(retval)
	if to_bool(retval) == true then
		Ticket_supply_method:call(Constants:get_ProgressTicketSupplyManager(), 3);
		return FALSE_POINTER;
	end

	return retval;
end
--[[local function PostHook_checkPickItem_VillageTicket(retval)
	if to_bool(retval) == true then
		Ticket_supply_method:call(Constants:get_ProgressTicketSupplyManager(), 0);
		return FALSE_POINTER;
	end

	return retval;
end
local function PostHook_checkPickItem_GuildTicket(retval)
	if to_bool(retval) == true then
		Ticket_supply_method:call(Constants:get_ProgressTicketSupplyManager(), 1);
		return FALSE_POINTER;
	end

	return retval;
end]]

local function PostHook_checkSupplyItem_OtomoTicket(retval)
	if to_bool(retval) == true then
		Otomo_supply_method:call(Constants:get_ProgressOtomoTicketManager());
		return FALSE_POINTER;
	end

	return retval;
end

--[[local function PostHook_checkSupplyItem_Ec019(retval)
	if to_bool(retval) == true then
		Ec019_supply_method:call(Constants:get_ProgressEc019UnlockItemManager());
		return FALSE_POINTER;
	end

	return retval;
end
local function PostHook_checkSupplyItem_Ec019MR(retval)
	if to_bool(retval) == true then
		Ec019_supplyMR_method:call(Constants:get_ProgressEc019UnlockItemManager());
		return FALSE_POINTER;
	end

	return retval;
end]]

--[[local function PostHook_checkSwitchAction_EnableSupply_Smithy(retval)
	if to_bool(retval) == true then
		SwitchAction_supply_method:call(Constants:get_ProgressSwitchActionSupplyManager());
		return FALSE_POINTER;
	end

	return retval;
end]]

local function PostHook_checkSupplyItem_GoodReward(retval)
	if to_bool(retval) == true then
		GoodReward_supplyReward_method:call(Constants:get_ProgressGoodRewardManager());
		return FALSE_POINTER;
	end

	return retval;
end

local function PostHook_checkSupplyItem_BBQReward(retval)
	if to_bool(retval) == true then
		outputTicket_method:call(get_BbqFunc_method:call(Constants:get_KitchenFacility()));
		return FALSE_POINTER;
	end

	return retval;
end

--[[local function getNoteReward(retval)
	if to_bool(retval) == true then
		Note_supply_method:call(Constants:get_ProgressNoteRewardManager());
		return FALSE_POINTER;
	end

	return retval;
end]]

local function PostHook_checkMysteryResearchRequestEnd(retval)
	if MysteryLaboNpcTalkMessageCtrl ~= nil and talkAction2_SupplyMysteryResearchRequestReward_method:call(MysteryLaboNpcTalkMessageCtrl, 78, 0, 0) == true then
		MysteryResearchRequestEnd = false;
		MysteryLaboNpcTalkMessageCtrl = nil;
		isOpenMysteryResearchReward = true;
		return FALSE_POINTER;
	end

	MysteryResearchRequestEnd = to_bool(retval);
	return retval;
end

local function PostHook_checkCommercialStuff(retval)
	CommercialStuff = to_bool(retval);
	return retval;
end

local function closeRewardDialog(retval)
	if isOpenMysteryResearchReward == true then
		isOpenMysteryResearchReward = false;
		return TRUE_POINTER;
	end

	return retval;
end

local function init()
	hook(NpcTalkMessageCtrl_type_def:get_method("start"), PreHook_getTalkTarget, PostHook_getTalkTarget);
	hook(NpcTalkMessageCtrl_type_def:get_method("onLoad"), PreHook_getTalkTarget, PostHook_getTalkTarget);
	hook(NpcTalkMessageCtrl_type_def:get_method("checkPickItem_V02Ticket(snow.npc.message.define.NpcMessageTalkTag)"), nil, PostHook_checkPickItem_V02Ticket);
	hook(NpcTalkMessageCtrl_type_def:get_method("checkPickItem_MysteryTicket(snow.npc.message.define.NpcMessageTalkTag)"), nil, PostHook_checkPickItem_MysteryTicket);
	--hook(NpcTalkMessageCtrl_type_def:get_method("checkPickItem_VillageTicket(snow.npc.message.define.NpcMessageTalkTag)"), nil, PostHook_checkPickItem_VillageTicket);
	--hook(NpcTalkMessageCtrl_type_def:get_method("checkPickItem_GuildTicket(snow.npc.message.define.NpcMessageTalkTag)"), nil, PostHook_checkPickItem_GuildTicket);
	hook(NpcTalkMessageCtrl_type_def:get_method("checkSupplyItem_OtomoTicket(snow.npc.message.define.NpcMessageTalkTag)"), nil, PostHook_checkSupplyItem_OtomoTicket);
	--hook(NpcTalkMessageCtrl_type_def:get_method("checkSupplyItem_Ec019(snow.npc.message.define.NpcMessageTalkTag)"), nil, PostHook_checkSupplyItem_Ec019);
	--hook(NpcTalkMessageCtrl_type_def:get_method("checkSupplyItem_Ec019MR(snow.npc.message.define.NpcMessageTalkTag)"), nil, PostHook_checkSupplyItem_Ec019MR);
	--hook(NpcTalkMessageCtrl_type_def:get_method("checkSwitchAction_EnableSupply_Smithy(snow.npc.message.define.NpcMessageTalkTag)"), nil, PostHook_checkSwitchAction_EnableSupply_Smithy);
	hook(NpcTalkMessageCtrl_type_def:get_method("checkSupplyItem_GoodReward(snow.npc.message.define.NpcMessageTalkTag)"), nil, PostHook_checkSupplyItem_GoodReward);
	hook(NpcTalkMessageCtrl_type_def:get_method("checkSupplyItem_BBQReward(snow.npc.message.define.NpcMessageTalkTag)"), nil, PostHook_checkSupplyItem_BBQReward);
	--hook(NpcTalkMessageCtrl_type_def:get_method("checkNoteReward_SupplyAnyOrnament(snow.npc.message.define.NpcMessageTalkTag)"), nil, getNoteReward);
	--hook(NpcTalkMessageCtrl_type_def:get_method("checkNoteReward_SupplyAnyOrnament_MR(snow.npc.message.define.NpcMessageTalkTag)"), nil, getNoteReward);
	hook(NpcTalkMessageCtrl_type_def:get_method("checkMysteryResearchRequestEnd(snow.npc.message.define.NpcMessageTalkTag)"), nil, PostHook_checkMysteryResearchRequestEnd);
	hook(NpcTalkMessageCtrl_type_def:get_method("checkCommercialStuff(snow.npc.message.define.NpcMessageTalkTag)"), nil, PostHook_checkCommercialStuff);
	hook(Constants.type_definitions.StmGuiInput_type_def:get_method("getDecideButtonTrg(snow.StmInputConfig.KeyConfigType, System.Boolean)"), nil, closeRewardDialog);
end
--
local this = {
	init = init,
	talkHandler = talkHandler
};
--
return this;