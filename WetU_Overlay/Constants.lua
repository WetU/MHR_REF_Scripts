local sdk = sdk;

local findMasterPlayer_method = sdk.find_type_definition("snow.player.PlayerManager"):get_method("findMasterPlayer");
local getPlayerIndex_method = findMasterPlayer_method:get_return_type():get_method("getPlayerIndex");

local this = {
    MasterPlayerIndex = nil;
};

function this.getMasterPlayerId()
    this.MasterPlayerIndex = getPlayerIndex_method:call(findMasterPlayer_method:call(sdk.get_managed_singleton("snow.player.PlayerManager")));
end

return this;