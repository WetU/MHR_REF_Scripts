local Constants = _G.require("Constants.Constants");
--
local ipairs = Constants.lua.ipairs;

local find_type_definition = Constants.sdk.find_type_definition;
local get_managed_singleton = Constants.sdk.get_managed_singleton;
local to_managed_object = Constants.sdk.to_managed_object;
local hook = Constants.sdk.hook;
local hook_vtable = Constants.sdk.hook_vtable;

local TRUE_POINTER = Constants.TRUE_POINTER;

local findInventoryData = Constants.findInventoryData;
local SendMessage = Constants.SendMessage;
--
local type_definitions = Constants.type_definitions;
local StmGuiInput_type_def = type_definitions.StmGuiInput_type_def;
local checkLotEventStatus_method = type_definitions.FacilityDataManager_type_def:get_method("checkLotEventStatus"); -- static
local reqAddChatItemInfo_method = type_definitions.ChatManager_type_def:get_method("reqAddChatItemInfo(snow.data.ContentsIdSystem.ItemId, System.Int32, snow.gui.ChatManager.ItemMaxType, System.Boolean)");
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
local get_LotResultData_method = GuiItemShopLotMenu_type_def:get_method("get_LotResultData");
local get_ListFukudamaPrize_method = GuiItemShopLotMenu_type_def:get_method("get_ListFukudamaPrize");

local ListFukudamaPrize_type_def = get_ListFukudamaPrize_method:get_return_type();
local Prize_get_Count_method = ListFukudamaPrize_type_def:get_method("get_Count");
local Prize_get_Item_method = ListFukudamaPrize_type_def:get_method("get_Item(System.Int32)");

local FukudamaPrize_type_def = Prize_get_Item_method:get_return_type();
local PrizeItemId_field = FukudamaPrize_type_def:get_field("Item1");
local PrizeItemCount_field = FukudamaPrize_type_def:get_field("Item2");

local LotResultCursor_set_index_method = get__LotResultCursor_method:get_return_type():get_method("set_index(via.vec2)");
--
local ItemInventoryData_type_def = type_definitions.ItemInventoryData_type_def;
local get_ItemId_method = ItemInventoryData_type_def:get_method("get_ItemId");
local get_Count_method = ItemInventoryData_type_def:get_method("get_Count");
local checkSendInventoryStatus_method = ItemInventoryData_type_def:get_method("checkSendInventoryStatus(snow.data.ItemInventoryData, snow.data.InventoryData.InventoryType, System.UInt32)"); -- static
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
    noTicketandMoney = 100,
    unAvail = 101
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
        elseif LotEventStatus == 5 then
            LotState = LotStates.noTicketandMoney;
            SendMessage("추첨권과 소지금이 없습니다!");
            LotEventStatus = nil;
        else
            LotState = LotStates.unAvail;
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
                local GuiItemShopLotMenu = get_refGuiItemShopLotMenu_method:call(Constants:get_GuiManager());
                local ListFukudamaPrize = get_ListFukudamaPrize_method:call(GuiItemShopLotMenu);
                local ChatManager = Constants:get_ChatManager();

                for _, data in ipairs(get_LotResultData_method:call(GuiItemShopLotMenu):get_elements()) do
                    local count = get_Count_method:call(data);
                    reqAddChatItemInfo_method:call(
                        ChatManager,
                        get_ItemId_method:call(data),
                        count,
                        checkSendInventoryStatus_method:call(nil, data, 65536, count) == 0 and 0 or 1,
                        false
                    );
                end

                if ListFukudamaPrize ~= nil then
                    for i = 0, Prize_get_Count_method:call(ListFukudamaPrize) - 1, 1 do
                        local FukudamaPrize = Prize_get_Item_method:call(ListFukudamaPrize, i);
                        local itemId = PrizeItemId_field:get_data(FukudamaPrize);
                        local count = PrizeItemCount_field:get_data(FukudamaPrize);
                        local InventoryData = findInventoryData(1, itemId);
                        reqAddChatItemInfo_method:call(
                            ChatManager,
                            itemId,
                            count,
                            (InventoryData == nil or checkSendInventoryStatus_method:call(nil, InventoryData, 65536, count) == 0) and 0 or 1,
                            false
                        );
                    end
                end

                LotResultCursor_set_index_method:call(get__LotResultCursor_method:call(GuiItemShopLotMenu), All_Receive_Button_Index);
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