local sdk = sdk;

local PlayerManager_type_def = sdk.find_type_definition("snow.player.PlayerManager");
local findMasterPlayer_method = PlayerManager_type_def:get_method("findMasterPlayer");
local getPlayerIndex_method = findMasterPlayer_method:get_return_type():get_method("getPlayerIndex");

local this = {
    MasterPlayerIndex = nil;
};

function this.getMasterPlayerId()
    this.MasterPlayerIndex = getPlayerIndex_method:call(findMasterPlayer_method:call(sdk.get_managed_singleton("snow.player.PlayerManager")));
end

return this;