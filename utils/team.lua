function GetHeroesByLane()
    local heroes_by_lane = {};
    local alliedHeroes = GetUnitList( UNIT_LIST_ALLIED_HEROES );
    for _, hero in pairs( alliedHeroes ) do
        local assignedLane = hero:GetAssignedLane();
        if ( heroes_by_lane[assignedLane] == nil ) then
            heroes_by_lane[assignedLane] = {};
        end
        table.insert( heroes_by_lane[assignedLane], hero );
    end

    return heroes_by_lane;
end