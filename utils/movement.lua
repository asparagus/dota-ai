function Retreat( amount )
    local npcBot = GetBot();
    local assignedLane = npcBot:GetAssignedLane();
    local team = npcBot:GetTeam();
    local towers = GetTowersByLane( team, assignedLane );
    local t1 = towers[1]:GetLocation();

    local home = GetShopLocation( team, SHOP_HOME );
    local currentLocation = npcBot:GetLocation();
    local delta = ( t1 - currentLocation ) * amount / GetUnitToLocationDistance( npcBot, t1 );
    npcBot:Action_MoveToLocation( currentLocation + delta );
end
