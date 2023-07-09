-- snow.enemy.EnemyBossRandomScaleData.RandomScaleTableData
-- snow.enemy.EnemyZakoCommonData.ZakoRandomScaleData

local config = json.load_file("OnlyCrown.json") or {}
if config.Enabled == nil then
    config.Enabled = true
end
if config.BigCrown == nil then
    config.BigCrown = true
end
if config.SmallCrown == nil then
    config.SmallCrown = true
end

re.on_config_save(function()
    json.dump_file("OnlyCrown.json", config)
end)

---

local function GetEnumMap(enumTypeName)
    local t = sdk.find_type_definition(enumTypeName)
    if not t then return {} end

    local fields = t:get_fields()
    local enum = {}

    for i, field in ipairs(fields) do
        if field:is_static() then
            local name = field:get_name()
            local raw_value = field:get_data(nil)
            enum[raw_value] = name
        end
    end

    return enum
end

local ScaleTypeMap = GetEnumMap("snow.enemy.EnemyDef.BossScaleTblType")

local CacheType = nil
local CacheData = nil
local Cache = {}
sdk.hook(
    sdk.find_type_definition("snow.enemy.EnemyBossRandomScaleData"):get_method("getBossRandomScale(snow.enemy.EnemyDef.BossScaleTblType)"),
    --snow.equip.PlEquipMySetData
    function(args)
        CacheType = nil
        CacheData = nil
        Cache = nil
        if not config.Enabled then
            return
        end
        if not (config.BigCrown or config.SmallCrown) then
            return
        end
        local data = sdk.to_managed_object(args[2])
        CacheData = data

        local type = sdk.to_int64(args[3])
        log.debug("args: " .. type .. " - " .. ScaleTypeMap[type])
        local searchType = ScaleTypeMap[type]
        local list = data:get_field("_RandomScaleTableDataList")
        if list then
            local list = list:get_elements()
            if list then
                for i = 1, #list do 
                    local data = list[i]
                    if data then
                        local type = data:get_field("_Type")
                        if ScaleTypeMap[type] == searchType then
                            log.debug("Type: " .. ScaleTypeMap[type])
                            local rates = data:get_field("_ScaleAndRateData")

                            if rates then
                                local rates = rates:get_elements()

                                CacheType = type
                                Cache = {}
                                for j = 1, #rates do
                                    local scale = rates[j]:get_field("_Scale")
                                    local rate = rates[j]:get_field("_Rate")
                                    Cache[j] = rate

                                    log.debug("  Scale: " .. scale .. " - " .. rate)
                                    -- Simply assumes lower-to-higher
                                    if j == 1 then
                                        if config.SmallCrown and config.BigCrown then
                                            rates[j]:set_field("_Rate", 50)
                                        elseif config.SmallCrown then
                                            rates[j]:set_field("_Rate", 100)
                                        else
                                            rates[j]:set_field("_Rate", 0)
                                        end
                                    elseif j == #rates then
                                        if config.SmallCrown and config.BigCrown then
                                            rates[j]:set_field("_Rate", 50)
                                        elseif config.BigCrown then
                                            rates[j]:set_field("_Rate", 100)
                                        else
                                            rates[j]:set_field("_Rate", 0)
                                        end
                                    else
                                        rates[j]:set_field("_Rate", 0)
                                    end
                                end
                            end
                            break
                        end
                    end
                end
            else
                log.debug("converted list is emtpy")
            end
        else
            log.debug("base list is empty")
        end
    end,
    function (ret)
        if not config.Enabled then
            return ret
        end
        if not (config.BigCrown or config.SmallCrown) then
            return
        end
        -- ret is System.Single
        log.debug("ret: " .. sdk.to_float(ret))

        if CacheType ~= nil and CacheData ~= nil and Cache ~= nil then
            local list = CacheData:get_field("_RandomScaleTableDataList")
            if list then
                local list = list:get_elements()
                if list then
                    for i = 1, #list do 
                        local data = list[i]
                        if data then
                            local type = data:get_field("_Type")
                            if type == CacheType then
                                log.debug("Type: " .. ScaleTypeMap[type])
                                local rates = data:get_field("_ScaleAndRateData")

                                if rates then
                                    local rates = rates:get_elements()

                                    log.debug("After-Type: " .. ScaleTypeMap[CacheType])
                                    for j = 1, #rates do
                                        local scale = rates[j]:get_field("_Scale")
                                        local rate = rates[j]:get_field("_Rate")

                                        log.debug("  After-Scale: " .. scale .. " - " .. rate)
                                        rates[j]:set_field("_Rate", Cache[j])
                                    end
                                end

                                break
                            end
                        end
                    end
                end
            end
        end
        -- local val = sdk.create_instance("System.Single"):add_ref()
        -- val:set_field("mValue", true)
        -- ret = sdk.to_ptr(0.96)
        return ret
    end
)

-- CreateEmTypesBoss
-- CreateEmTypeIndexBoss
-- local EnemyManager = sdk.find_type_definition("snow.enemy.EnemyManager");

re.on_draw_ui(function()
    if imgui.tree_node("CrownOnly") then
        -- local data = EnemyManager:call("getBossRandomScale")
        _, config.Enabled = imgui.checkbox("Enabled", config.Enabled)
        imgui.text("If both options are false, the mod is disabled.")
        _, config.BigCrown = imgui.checkbox("BigCrown", config.BigCrown)
        _, config.SmallCrown = imgui.checkbox("SmallCrown", config.SmallCrown)
        imgui.tree_pop();
    end
end)
