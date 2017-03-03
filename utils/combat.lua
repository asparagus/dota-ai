CREEP_AGGRO_RANGE = 500;
HERO_AGGRO_RANGE = 800;
TOWER_AGGRO_RANGE = 800;

-- Compute the damage dealt by enemies over a given interval to a hero fighting at the given location
function NearbyEnemyDamage( hero, location, interval )
    local delta = GetUnitToLocationDistance( hero, location );
    -- Enemies that will be attacking the hero
    local creeps = hero:GetNearbyCreeps( CREEP_AGGRO_RANGE + delta, true );
    local heroes = hero:GetNearbyHeroes( HERO_AGGRO_RANGE + delta, true, BOT_MODE_NONE );
    local towers = hero:GetNearbyTowers( TOWER_AGGRO_RANGE + delta, true );

    -- Sum the damage for all sources
    local totalDamage = 0;
    if ( #creeps > 0 ) then
        for _, creep in pairs( creeps ) do
            if ( GetUnitToLocationDistance( creep, location ) <= CREEP_AGGRO_RANGE ) then
                totalDamage = totalDamage + creep:GetEstimatedDamageToTarget( true, hero, interval, DAMAGE_TYPE_ALL);
            end
        end
    end
    if ( #heroes > 0 ) then
        for _, other_hero in pairs( heroes ) do
            if ( GetUnitToLocationDistance( other_hero, location ) <= HERO_AGGRO_RANGE ) then
                totalDamage = totalDamage + other_hero:GetEstimatedDamageToTarget( true, hero, interval, DAMAGE_TYPE_ALL );
            end
        end
    end
    if ( #towers > 0 ) then
        for _, tower in pairs( towers ) do
            if ( GetUnitToLocationDistance( tower, location ) <= TOWER_AGGRO_RANGE ) then
                totalDamage = totalDamage + tower:GetEstimatedDamageToTarget( true, hero, interval, DAMAGE_TYPE_ALL );
            end
        end
    end

    return totalDamage;
end

function ShouldTrade( enemy )
    local npcBot = GetBot();
    local location = enemy:GetLocation();

    local fightLength = 3; -- Pretend an engagement will last 3 seconds -
    local totalEnemyDamage = NearbyEnemyDamage( npcBot, location, fightLength );
    local totalAlliedDamage = (
        NearbyEnemyDamage( enemy, location, fightLength ) +
        npcBot:GetEstimatedDamageToTarget( true, enemy, fightLength, DAMAGE_TYPE_ALL ));

    -- The trade is advantageous if the % damage dealt is greater than the received.
    -- Additional condition: Do not die
    if totalEnemyDamage > npcBot:GetHealth() then
        print( "Trade would result in death" );
        return false;
    end

    local result = totalAlliedDamage / enemy:GetHealth() > totalEnemyDamage / npcBot:GetHealth();
    if ( result ) then
        print( "Trade is favorable: " .. totalAlliedDamage .. " v/s " .. totalEnemyDamage );
        return true;
    else
        print( "Trade is unfavorable: " .. totalAlliedDamage .. " v/s " .. totalEnemyDamage );
        return false;
    end
end

function ChooseTarget( nearbyEnemies )
    local npcBot = GetBot();
    local target = nil;
    local targetValue = 0;
    for _, npcEnemy in pairs( nearbyEnemies ) do
        local value = npcEnemy:GetEstimatedDamageToTarget( true, npcBot, 3.0, DAMAGE_TYPE_ALL );
        local relativeHealth = npcEnemy:GetHealth() / npcBot:GetEstimatedDamageToTarget( true, npcEnemy, 3.0, DAMAGE_TYPE_ALL );

        if ( value > targetValue ) then
            targetValue = value;
            target = npcEnemy;
        end
    end

    return target;
end

function TakeOffAggro()
    print("Taking off aggro");
    local npcBot = GetBot();
    local team = npcBot:GetTeam();
    local closestUnit = nil;
    local closestUnitDistance = 1000;
    local nearbyAlliedCreeps = npcBot:GetNearbyCreeps( closestUnitDistance, false );
    local nearbyAlliedHeroes = npcBot:GetNearbyHeroes( closestUnitDistance, false, BOT_MODE_NONE );
    if ( #nearbyAlliedCreeps > 0 ) then
        local closestCreep = nearbyAlliedCreeps[1];
        local distance = GetUnitToUnitDistance( npcBot, closestCreep );
        if ( distance < closestUnitDistance ) then
            closestUnitDistance = distance;
            closestUnit = closestCreep;
        end
    end

    if ( #nearbyAlliedHeroes > 0 ) then
        local closestHero = nearbyAlliedHeroes[1];
        local distance = GetUnitToUnitDistance( npcBot, closestHero );
        if ( distance < closestUnitDistance ) then
            closestUnitDistance = distance;
            closestUnit = closestHero;
        end
    end

    local team = npcBot:GetTeam();
    local ancient = GetAncient(team);
    local ancientDistance = GetUnitToUnitDistance( npcBot, ancient );
    local location = npcBot:GetLocation();
    -- Move towards the ancient
    local delta = ( ancient:GetLocation() - location ) / ancientDistance * 200;

    if ( closestUnit ) then
        npcBot:Action_AttackUnit( closestUnit, true );
        npcBot:ActionQueue_MoveToLocation( location + delta );
    else
        npcBot:ActionQueue_MoveToLocation( location + delta );
    end
end