CREEP_AGGRO_RANGE = 500;
HERO_AGGRO_RANGE = 800;
TOWER_AGGRO_RANGE = 800;
MAX_RANGE = 1600;


-- Compute the damage dealt by enemies over a given interval to a hero fighting at the given location
function NearbyEnemyDamage( hero, sourceHero, location, interval )
    local delta = GetUnitToLocationDistance( hero, location );

    -- Enemies that will be attacking the hero
    local creeps = sourceHero:GetNearbyCreeps( min( CREEP_AGGRO_RANGE + delta, MAX_RANGE ), hero:GetTeam() == sourceHero:GetTeam() );
    local heroes = sourceHero:GetNearbyHeroes( min( HERO_AGGRO_RANGE + delta, MAX_RANGE ), hero:GetTeam() == sourceHero:GetTeam(), BOT_MODE_NONE );
    local towers = sourceHero:GetNearbyTowers( min( TOWER_AGGRO_RANGE + delta, MAX_RANGE ), hero:GetTeam() == sourceHero:GetTeam() );

    -- Sum the damage for all sources
    local totalDamage = 0;
    if ( creeps ~= nil and #creeps > 0 ) then
        for _, creep in pairs( creeps ) do
            if ( GetUnitToLocationDistance( creep, location ) <= CREEP_AGGRO_RANGE ) then
                totalDamage = totalDamage + creep:GetEstimatedDamageToTarget( true, hero, interval, DAMAGE_TYPE_ALL);
            end
        end
    end
    if ( heroes ~= nil and #heroes > 0 ) then
        for _, other_hero in pairs( heroes ) do
            if ( GetUnitToLocationDistance( other_hero, location ) <= HERO_AGGRO_RANGE ) then
                totalDamage = totalDamage + other_hero:GetEstimatedDamageToTarget( true, hero, interval, DAMAGE_TYPE_ALL );
            end
        end
    end
    if ( towers ~= nil and #towers > 0 ) then
        for _, tower in pairs( towers ) do
            if ( GetUnitToLocationDistance( tower, location ) <= TOWER_AGGRO_RANGE ) then
                totalDamage = totalDamage + tower:GetEstimatedDamageToTarget( true, hero, interval, DAMAGE_TYPE_ALL );
            end
        end
    end

    return totalDamage;
end

function EvaluateTrade( enemy )
    local npcBot = GetBot();
    local location = enemy:GetLocation();

    local fightLength = 3; -- Pretend an engagement will last 3 seconds -
    local totalEnemyDamage = NearbyEnemyDamage( npcBot, enemy, location, fightLength );
    local totalAlliedDamage = (
        NearbyEnemyDamage( enemy, enemy, location, fightLength ) +
        npcBot:GetEstimatedDamageToTarget( true, enemy, fightLength, DAMAGE_TYPE_ALL ));

    -- The trade is advantageous if the % damage dealt is greater than the received.
    -- Additional condition: Do not die
    if totalEnemyDamage > npcBot:GetHealth() then
        -- print( "Trade would result in death" );
        return BOT_ACTION_DESIRE_NONE;
    end

    local enemyRelativeDamageTaken = totalAlliedDamage / enemy:GetHealth();
    local selfRelativeDamageTaken = totalEnemyDamage / npcBot:GetHealth();
    if ( enemyRelativeDamageTaken > selfRelativeDamageTaken ) then
        -- print( "Trade is favorable: " .. totalAlliedDamage .. " v/s " .. totalEnemyDamage );
        return enemyRelativeDamageTaken / ( selfRelativeDamageTaken + enemyRelativeDamageTaken );
    else
        -- print( "Trade is unfavorable: " .. totalAlliedDamage .. " v/s " .. totalEnemyDamage );
        return BOT_ACTION_DESIRE_NONE;
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
    local npcBot = GetBot();
    -- Probably already moving out of aggro range.
    if ( npcBot:GetCurrentActionType() == BOT_ACTION_TYPE_MOVE_TO ) then
        return;
    end

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

function WasRecentlyDamaged( unit, interval )
    return (unit:WasRecentlyDamagedByAnyHero( interval ) or
            unit:WasRecentlyDamagedByCreep( interval ) or
            unit:WasRecentlyDamagedByTower( interval ));
end

function AttackMove()
    local npcBot = GetBot();
    local target = npcBot:GetTarget();
    local attackRange = npcBot:GetAttackRange();

    if ( target ~= nil and target:IsAlive() and npcBot:GetCurrentActionType() ~= BOT_ACTION_TYPE_ATTACK ) then
        -- Expected movement --
        local expectedMovement = target:GetExtrapolatedLocation( 0.2 );
        -- Check if we can attack again --
        if ( npcBot:GetLastAttackTime() >= npcBot:GetSecondsPerAttack() and GetUnitToUnitDistance( target, npcBot ) <= attackRange ) then
            -- Attack once and keep moving.
            print('Hitting');
            npcBot:Action_AttackUnit( target, true );
            npcBot:ActionQueue_MoveToLocation( expectedMovement );
        else
            print('Moving closer');
            npcBot:Action_MoveToLocation( expectedMovement );
        end
    end
end

function ExtrapolateHealth( unit, interval )
    -- Get the health of a unit in the future if all the current units keep attacking it.
    local nearbyCreeps = unit:GetNearbyCreeps( CREEP_AGGRO_RANGE, true );
    local nearbyHeroes = unit:GetNearbyHeroes( MAX_RANGE, true, BOT_MODE_NONE );
    local nearbyTowers = unit:GetNearbyTowers( TOWER_AGGRO_RANGE, true );

    local expectedDamage = 0;
    if ( nearbyCreeps ~= nil ) then
        for _, creep in pairs( nearbyCreeps ) do
            if ( creep:GetAttackTarget() == unit ) then
                expectedDamage = expectedDamage + creep:GetEstimatedDamageToTarget(
                    true, unit, interval, DAMAGE_TYPE_PHYSICAL );
            end
        end
    end

    if ( nearbyHeroes ~= nil ) then
        for _, hero in pairs( nearbyHeroes ) do
            if ( hero:GetAttackTarget() == unit ) then
                expectedDamage = expectedDamage + hero:GetEstimatedDamageToTarget(
                    true, unit, interval, DAMAGE_TYPE_PHYSICAL );
            end
        end
    end

    if ( nearbyTowers ~= nil ) then
        for _, tower in pairs( nearbyTowers ) do
            if ( tower:GetAttackTarget() == unit ) then
                expectedDamage = expectedDamage + tower:GetEstimatedDamageToTarget(
                    true, unit, interval, DAMAGE_TYPE_PHYSICAL );
            end
        end
    end

    return math.max( 0, unit:GetHealth() - expectedDamage );
end
