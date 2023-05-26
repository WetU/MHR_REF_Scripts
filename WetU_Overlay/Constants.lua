local sdk = sdk;

local getMasterPlayerID_method = sdk.find_type_definition("snow.player.PlayerManager"):get_method("getMasterPlayerID"); 

local this = {
    MasterPlayerIndex = nil;
};

function this.getMasterPlayerId()
    this.MasterPlayerIndex = getMasterPlayerID_method:call(sdk.get_managed_singleton("snow.player.PlayerManager"));
end

return this;