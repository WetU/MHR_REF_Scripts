local Constants = _G.require("Constants.Constants");
--
local find_type_definition = Constants.sdk.find_type_definition;
local to_managed_object = Constants.sdk.to_managed_object;
local hook = Constants.sdk.hook;

local TRUE_POINTER = Constants.TRUE_POINTER;

local SendMessage = Constants.SendMessage;
--
local type_definitions = Constants.type_definitions;
local checkLotEventStatus_method = type_definitions.FacilityDataManager_type_def:get_method("checkLotEventStatus"); -- static

local isSale_method = find_type_definition("snow.data.ItemShopFacility"):get_method("isSale"); -- static
--
local GuiItemShopFsmManager_type_def = find_type_definition("snow.gui.fsm.itemshop.GuiItemShopFsmManager");
local get_TopMenuCursor_method = GuiItemShopFsmManager_type_def:get_method("get_TopMenuCursor");
local get_TopSubMenuCursor_method = GuiItemShopFsmManager_type_def:get_method("get_TopSubMenuCursor");

local MenuCursor_type_def = get_TopMenuCursor_method:get_return_type();
local get_index_method = MenuCursor_type_def:get_method("get_index");
local set_index_method = MenuCursor_type_def:get_method("set_index(System.Int32)");
--
local LotAnimPlaying = false;

local GuiItemShopFsmManager = nil;
local function PreHook_openItemShop(args)
    if isSale_method:call(nil) == true then
        GuiItemShopFsmManager = to_managed_object(args[2]);
    end
end
local function PostHook_openItemShop()
    if GuiItemShopFsmManager ~= nil then
        local LotEventStatus = checkLotEventStatus_method:call(nil);
        if LotEventStatus >= 0 and LotEventStatus <= 2 then
            local TopMenuCursor = get_TopMenuCursor_method:call(GuiItemShopFsmManager);
            if get_index_method:call(TopMenuCursor) ~= 2 then
                set_index_method:call(TopMenuCursor, 2);
            end

            set_index_method:call(get_TopSubMenuCursor_method:call(GuiItemShopFsmManager), LotEventStatus == 2 and 0 or 1);
            LotAnimPlaying = true;
        else
            SendMessage("추첨권과 소지금이 없습니다!");
        end

        GuiItemShopFsmManager = nil;
    end
end
hook(GuiItemShopFsmManager_type_def:get_method("openItemShop"), PreHook_openItemShop, PostHook_openItemShop);

local function PreHook_closeLotResultPanel()
    LotAnimPlaying = false;
end
hook(find_type_definition("snow.gui.GuiItemShopLotMenu"):get_method("closeLotResultPanel"), PreHook_closeLotResultPanel);

local function decideFunc(retval)
    if LotAnimPlaying == true then
        return TRUE_POINTER;
    end

    return retval;
end
hook(type_definitions.StmGuiInput_type_def:get_method("getDecideButtonTrg(snow.StmInputConfig.KeyConfigType, System.Boolean)"), nil, decideFunc);