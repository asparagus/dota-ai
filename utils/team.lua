TOWERS_BY_LANE = {};
TOWERS_BY_LANE[LANE_TOP] = { TOWER_TOP_1, TOWER_TOP_2, TOWER_TOP_3 };
TOWERS_BY_LANE[LANE_MID] = { TOWER_MID_1, TOWER_MID_2, TOWER_MID_3 };
TOWERS_BY_LANE[LANE_BOT] = { TOWER_BOT_1, TOWER_BOT_2, TOWER_BOT_3 };

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

function GetTowersByLane( team, lane )
    local towers = {};
    for i, nTower in pairs( TOWERS_BY_LANE[lane] ) do
        towers[i] = GetTower( team, nTower );
    end

    return towers;
end

function GetFarmPriority( hero )
    local heroName = hero:GetUnitName();
    if ( heroName == 'npc_dota_hero_luna' ) then
        return 1;
    elseif ( heroName == 'npc_dota_hero_phantom_assassin' ) then
        return 2;
    elseif ( heroName == 'npc_dota_hero_axe' ) then
        return 3;
    elseif ( heroName == 'npc_dota_hero_warlock' ) then
        return 4;
    elseif ( heroName == 'npc_dota_hero_crystal_maiden' ) then
        return 5;
    end
end
