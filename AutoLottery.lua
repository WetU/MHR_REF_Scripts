local Constants = _G.require("Constants.Constants");
--
local find_type_definition = Constants.sdk.find_type_definition;
local get_managed_singleton = Constants.sdk.get_managed_singleton;
local to_managed_object = Constants.sdk.to_managed_object;
local hook = Constants.sdk.hook;
local hook_vtable = Constants.sdk.hook_vtable;

local TRUE_POINTER = Constants.TRUE_POINTER;

local SendMessage = Constants.SendMessage;
--
local type_definitions = Constants.type_definitions;
local StmGuiInput_type_def = type_definitions.StmGuiInput_type_def;

local checkLotEventStatus_method = type_definitions.FacilityDataManager_type_def:get_method("checkLotEventStatus"); -- static
--
local GuiItemShopFsmManager_type_def = find_type_definition("snow.gui.fsm.itemshop.GuiItemShopFsmManager");
local get_ItemShopState_method = GuiItemShopFsmManager_type_def:get_method("get_ItemShopState");
local get_TopMenuCursor_method = GuiItemShopFsmManager_type_def:get_method("get_TopMenuCursor");
local get_TopSubMenuCursor_method = GuiItemShopFsmManager_type_def:get_method("get_TopSubMenuCursor");

local MenuCursor_set_index_method = get_TopMenuCursor_method:get_return_type():get_method("set_index(System.Int32)");
--
local GuiItemShopFsmTopMenuAction_type_def = find_type_definition("snow.gui.fsm.itemshop.GuiItemShopFsmTopMenuAction");
local TopMenu_update_method = GuiItemShopFsmTopMenuAction_type_def:get_method("update(via.behaviortree.ActionArg)");
local decideTopMenu_method = GuiItemShopFsmTopMenuAction_type_def:get_method("decideTopMenu");
--
local GuiItemShopFsmTopSubMenuAction_type_def = find_type_definition("snow.gui.fsm.itemshop.GuiItemShopFsmTopSubMenuAction");
local SubMenu_update_method = GuiItemShopFsmTopSubMenuAction_type_def:get_method("update(via.behaviortree.ActionArg)");
local decideSubMenu_method = GuiItemShopFsmTopSubMenuAction_type_def:get_method("decideSubMenu");
--
local GuiItemShopFsmLotMenuResultSelectAction_type_def = find_type_definition("snow.gui.fsm.itemshop.GuiItemShopFsmLotMenuResultSelectAction");
local LotResult_update_method = GuiItemShopFsmLotMenuResultSelectAction_type_def:get_method("update(via.behaviortree.ActionArg)");
--
local get_refGuiItemShopLotMenu_method = type_definitions.GuiManager_type_def:get_method("get_refGuiItemShopLotMenu");

local GuiItemShopLotMenu_type_def = get_refGuiItemShopLotMenu_method:get_return_type();
local get__LotResultCursor_method = GuiItemShopLotMenu_type_def:get_method("get__LotResultCursor");

local LotResultCursor_set_index_method = get__LotResultCursor_method:get_return_type():get_method("set_index(via.vec2)");
--
local LotStates = {
    checkLotEvent = 0,
    setTopMenu = 1,
    setSubMenu = 2,
    confirmYN = 3,
    readyLotAnim = 4,
    LotAnim = 5,
    onLotResult = 6,
    setResultCursor = 7,
    receivePrizes = 8,
    noTicketandMoney = 100
};

local All_Receive_Button_Index = Constants.Vector2f.new(0.0, 1.0);
--
local LotState = nil;
local LotEventStatus = nil;

local GuiItemShopFsmTopMenuAction = nil;
local function PreHook_TopMenuStart(args)
    if LotState == nil then
        LotState = LotStates.checkLotEvent;
        LotEventStatus = checkLotEventStatus_method:call(nil);
        if LotEventStatus >= 0 and LotEventStatus <= 2 then
            GuiItemShopFsmTopMenuAction = to_managed_object(args[2]);
        else
            LotState = LotStates.noTicketandMoney;
            SendMessage("추첨권과 소지금이 없습니다!");
            LotEventStatus = nil;
        end
    end
end
local function PostHook_TopMenuStart()
    if GuiItemShopFsmTopMenuAction ~= nil then
        hook_vtable(GuiItemShopFsmTopMenuAction, TopMenu_update_method, function(args)
            if LotState == LotStates.checkLotEvent then
                MenuCursor_set_index_method:call(get_TopMenuCursor_method:call(get_managed_singleton("snow.gui.fsm.itemshop.GuiItemShopFsmManager")), 2);
                decideTopMenu_method:call(to_managed_object(args[2]));
                LotState = LotStates.setTopMenu;
            end
        end);
        GuiItemShopFsmTopMenuAction = nil;
    end
end
hook(GuiItemShopFsmTopMenuAction_type_def:get_method("start(via.behaviortree.ActionArg)"), PreHook_TopMenuStart, PostHook_TopMenuStart);

local GuiItemShopFsmTopSubMenuAction = nil;
local function PreHook_TopSubMenuStart(args)
    if LotState == LotStates.setTopMenu then
        GuiItemShopFsmTopSubMenuAction = to_managed_object(args[2]);
    end
end
local function PostHook_TopSubMenuStart()
    if GuiItemShopFsmTopSubMenuAction ~= nil then
        hook_vtable(GuiItemShopFsmTopSubMenuAction, SubMenu_update_method, function(args)
            if LotState == LotStates.setTopMenu then
                MenuCursor_set_index_method:call(get_TopSubMenuCursor_method:call(get_managed_singleton("snow.gui.fsm.itemshop.GuiItemShopFsmManager")), LotEventStatus == 2 and 0 or 1);
                decideSubMenu_method:call(to_managed_object(args[2]));
                LotState = LotStates.setSubMenu;
                LotEventStatus = nil;
            end
        end);
        GuiItemShopFsmTopSubMenuAction = nil;
    end
end
hook(GuiItemShopFsmTopSubMenuAction_type_def:get_method("start(via.behaviortree.ActionArg)"), PreHook_TopSubMenuStart, PostHook_TopSubMenuStart);

local function PostHook_LotYN_Start()
    if LotState == LotStates.setSubMenu then
        LotState = LotStates.confirmYN;
    end
end
hook(find_type_definition("snow.gui.fsm.itemshop.GuiItemShopLotYNfsmAction"):get_method("setYNInfoWindowMessage"), nil, PostHook_LotYN_Start);

local function PostHook_initBallState()
    if LotState == LotStates.readyLotAnim then
        LotState = LotStates.LotAnim;
    end
end
hook(GuiItemShopLotMenu_type_def:get_method("initBallState"), nil, PostHook_initBallState);

local GuiItemShopFsmLotMenuResultSelectAction = nil;
local function PreHook_LotResultStart(args)
    if LotState == LotStates.LotAnim then
        LotState = LotStates.onLotResult;
        GuiItemShopFsmLotMenuResultSelectAction = to_managed_object(args[2]);
    end
end
local function PostHook_LotResultStart()
    if GuiItemShopFsmLotMenuResultSelectAction ~= nil then
        hook_vtable(GuiItemShopFsmLotMenuResultSelectAction, LotResult_update_method, nil, function()
            if LotState == LotStates.onLotResult then
                LotResultCursor_set_index_method:call(get__LotResultCursor_method:call(get_refGuiItemShopLotMenu_method:call(Constants:get_GuiManager())), All_Receive_Button_Index);
                LotState = LotStates.setResultCursor;
            end
        end);
        GuiItemShopFsmLotMenuResultSelectAction = nil;
    end
end
hook(GuiItemShopFsmLotMenuResultSelectAction_type_def:get_method("start(via.behaviortree.ActionArg)"), PreHook_LotResultStart, PostHook_LotResultStart);

local function PreHook_closeLotResultPanel(args)
    if LotState == LotStates.setResultCursor then
        LotState = LotStates.receivePrizes;
    end
end
hook(GuiItemShopLotMenu_type_def:get_method("closeLotResultPanel"), PreHook_closeLotResultPanel);

local function PreHook_closeItemShop(args)
    LotState = nil;
end
hook(GuiItemShopFsmManager_type_def:get_method("closeItemShop"), PreHook_closeItemShop);

local function decideFunc(retval)
    if LotState == LotStates.confirmYN then
        LotState = LotStates.readyLotAnim;
        return TRUE_POINTER;
    end

    return (LotState == LotStates.LotAnim or LotState == LotStates.setResultCursor) and TRUE_POINTER or retval;
end
hook(StmGuiInput_type_def:get_method("getDecideButtonTrg(snow.StmInputConfig.KeyConfigType, System.Boolean)"), nil, decideFunc);

local function cancelFunc(retval)
    return (LotState == LotStates.receivePrizes and get_ItemShopState_method:call(get_managed_singleton("snow.gui.fsm.itemshop.GuiItemShopFsmManager")) == 0) and TRUE_POINTER or retval;
end
hook(StmGuiInput_type_def:get_method("getCancelButtonTrg(snow.StmInputConfig.KeyConfigType, System.Boolean)"), nil, cancelFunc);