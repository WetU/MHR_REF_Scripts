local Constants = require("Constants.Constants");
if not Constants then
    return;
end
--
local this = {};
------------- Config Management --------------
this.Languages = {"en-US", "ko-KR"};

local config = Constants.JSON.load_file("AutoSupply.json") or {
    Enabled = true,
    EnableNotification = true,
    EnableCohoot = true,
    EnableArgosy = true,
    DefaultSet = 1,
    WeaponTypeConfig = {},
    EquipLoadoutConfig = {},
    Language = this.Languages[2]
};

if config.Enabled == nil then
    config.Enabled = true;
end
if config.EnableNotification == nil then
    config.EnableNotification = true;
end
if config.EnableCohoot == nil then
    config.EnableCohoot = true;
end
if config.EnableArgosy == nil then
    config.EnableArgosy = true;
end
if config.DefaultSet == nil then
    config.DefaultSet = 1;
end
if config.WeaponTypeConfig == nil then
    config.WeaponTypeConfig = {};
end
for i = 1, 14, 1 do
    if config.WeaponTypeConfig[i] == nil then
        config.WeaponTypeConfig[i] = -1;
    end
end
if config.EquipLoadoutConfig == nil then
    config.EquipLoadoutConfig = {};
end
for i = 1, 224, 1 do
    if config.EquipLoadoutConfig[i] == nil then
        config.EquipLoadoutConfig[i] = -1;
    end
end
if config.Language == nil or Constants.FindIndex(this.Languages, config.Language) == nil then
    config.Language = this.Languages[2];
end

this.config = config;
--
function this.save_config()
    Constants.JSON.dump_file("AutoSupply.json", this.config);
end

return this;
