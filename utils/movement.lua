function Retreat( amount )
    local npcBot = GetBot();
    local team = npcBot:GetTeam();

    local home = GetShopLocation( team, SHOP_HOME );
    local currentLocation = npcBot:GetLocation();
    local delta = ( home - currentLocation ) * amount / npcBot:DistanceFromFountain();
    npcBot:Action_MoveToLocation( currentLocation + delta );
end
