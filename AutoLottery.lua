local Constants = _G.require("Constants.Constants");
--
local sdk = Constants.sdk;
local type_definitions = Constants.type_definitions;
local TRUE_POINTER = Constants.TRUE_POINTER;

local find_type_definition = sdk.find_type_definition;
local get_managed_singleton = sdk.get_managed_singleton;
local to_managed_object = sdk.to_managed_object;
local hook = sdk.hook;
local hook_vtable = sdk.hook_vtable;
--
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
local GuiManager_type_def = type_definitions.GuiManager_type_def;
local get_refGuiItemShopLotMenu_method = GuiManager_type_def:get_method("get_refGuiItemShopLotMenu");

local GuiItemShopLotMenu_type_def = get_refGuiItemShopLotMenu_method:get_return_type();
local get__LotResultCursor_method = GuiItemShopLotMenu_type_def:get_method("get__LotResultCursor");
local get_LotResultData_method = GuiItemShopLotMenu_type_def:get_method("get_LotResultData");
local get_ListFukudamaPrize_method = GuiItemShopLotMenu_type_def:get_method("get_ListFukudamaPrize");

local LotResultCursor_set_index_method = get__LotResultCursor_method:get_return_type():get_method("set_index(via.vec2)");

local ListFukudamaPrize_type_def = get_ListFukudamaPrize_method:get_return_type();
local ListFukudamaPrize_mItems_field = ListFukudamaPrize_type_def:get_field("mItems");
local ListFukudamaPrize_mSize_field = ListFukudamaPrize_type_def:get_field("mSize");

local FukudamaPrize_type_def = find_type_definition("System.ValueTuple`2<snow.data.ContentsIdSystem.ItemId,System.Int32>");
local PrizeItemId_field = FukudamaPrize_type_def:get_field("Item1");
local PrizeItemCount_field = FukudamaPrize_type_def:get_field("Item2");
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
    fukudamaPrize = 8,
    receivePrizes = 9,
    noTicketandMoney = 100,
    unAvail = 101
};

local All_Receive_Button_Index = Constants.Vector2f_new(0.0, 1.0);
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
            Constants:SendMessage("추첨권과 소지금이 없습니다!");
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

local PrizesData = nil;
local FukudamaPrizeData = nil;
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
                local LotResultDataList = get_LotResultData_method:call(GuiItemShopLotMenu);
                local ListFukudamaPrize = get_ListFukudamaPrize_method:call(GuiItemShopLotMenu);

                if LotResultDataList ~= nil then
                    PrizesData = {
                        ItemId = {},
                        Count = {},
                        SendInventoryStatus = {},
                        Length = LotResultDataList:get_size()
                    };

                    for i = 0, PrizesData.Length - 1, 1 do
                        local data = LotResultDataList:get_element(i);
                        local count = get_Count_method:call(data);
                        PrizesData.ItemId[i + 1] = get_ItemId_method:call(data);
                        PrizesData.Count[i + 1] = count;
                        PrizesData.SendInventoryStatus[i + 1] = checkSendInventoryStatus_method:call(nil, data, 65536, count) == 0 and 0 or 1;
                    end
                end

                if ListFukudamaPrize ~= nil then
                    local ListSize = ListFukudamaPrize_mSize_field:get_data(ListFukudamaPrize);

                    if ListSize > 0 then
                        FukudamaPrizeData = {
                            ItemId = {},
                            Count = {},
                            Length = ListSize
                        };

                        local arrayItems = ListFukudamaPrize_mItems_field:get_data(ListFukudamaPrize);

                        for i = 0, ListSize - 1, 1 do
                            local PrizeData = arrayItems:get_element(i);
                            FukudamaPrizeData.ItemId[i + 1] = PrizeItemId_field:get_data(PrizeData);
                            FukudamaPrizeData.Count[i + 1] = PrizeItemCount_field:get_data(PrizeData);
                        end
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

local function PreHook_openRewardDialog()
    if LotState == LotStates.setResultCursor and FukudamaPrizeData ~= nil then
        LotState = LotStates.fukudamaPrize;
    end
end
local function PostHook_openRewardDialog()
    if LotState == LotStates.fukudamaPrize then
        Constants:closeRewardDialog();
    end
end
hook(GuiManager_type_def:get_method("openRewardDialog(System.Collections.Generic.List`1<System.ValueTuple`2<snow.data.ContentsIdSystem.ItemId,System.Int32>>, System.String)"), PreHook_openRewardDialog, PostHook_openRewardDialog);

local function PreHook_closeLotResultPanel()
    if LotState == LotStates.setResultCursor or LotState == LotStates.fukudamaPrize then
        LotState = LotStates.receivePrizes;
    end
end
hook(GuiItemShopLotMenu_type_def:get_method("closeLotResultPanel"), PreHook_closeLotResultPanel);

local function PreHook_closeItemShop()
    LotState = nil;
end
local function PostHook_closeItemShop()
    if PrizesData ~= nil then
        local ChatManager = Constants:get_ChatManager();

        for i = 1, PrizesData.Length, 1 do
            reqAddChatItemInfo_method:call(
                ChatManager,
                PrizesData.ItemId[i],
                PrizesData.Count[i],
                PrizesData.SendInventoryStatus[i],
                false
            );
        end

        if FukudamaPrizeData ~= nil then
            for i = 1, FukudamaPrizeData.Length, 1 do
                reqAddChatItemInfo_method:call(
                    ChatManager,
                    FukudamaPrizeData.ItemId[i],
                    FukudamaPrizeData.Count[i],
                    0,
                    false
                );
            end

            FukudamaPrizeData = nil;
        end

        PrizesData = nil;
    end
end
hook(GuiItemShopFsmManager_type_def:get_method("closeItemShop"), PreHook_closeItemShop, PostHook_closeItemShop);

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