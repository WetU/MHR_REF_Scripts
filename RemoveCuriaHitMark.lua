local Constants = require("Constants.Constants");
if Constants == nil then
    return;
end
--
Constants.SDK.hook(Constants.SDK.find_type_definition("snow.enemy.EnemyCharacterBase"):get_method("requestMysteryCoreHitMark(snow.enemy.EnemyDef.PartsGroup, snow.hit.EnemyCalcDamageInfo.AfterCalcInfo_DamageSide)"), Constants.SKIP_ORIGINAL);