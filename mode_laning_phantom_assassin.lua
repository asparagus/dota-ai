require( GetScriptDirectory().."/utils/combat" )
require( GetScriptDirectory().."/utils/movement" )
----------------------------------------------------------------------------------------------------
PULLING = 1;
PUSHING = 2;

function GetDesire()
    if ( DotaTime() < 600 ) then
        return BOT_MODE_DESIRE_LOW;
    else
        return BOT_MODE_DESIRE_NONE;
    end
end

function Think()
    -- Get the most desired action out of the possibilities.
    local utmostDesire = 0;
    local bestAction = nil;
    local bestTarget = nil;
    for i, possibleAction in pairs( PossibleActions ) do
        local desire, target = possibleAction.Desire();
        if ( desire > utmostDesire ) then
            utmostDesire = desire;
            bestAction = possibleAction.Action;
            bestTarget = target;
        end
    end

    -- Execute the action on the chosen target, if any
    if ( utmostDesire > BOT_ACTION_DESIRE_NONE ) then
        if ( bestTarget ) then
            bestAction( bestTarget );
        else
            bestAction();
        end
    end
end

function ConsiderMovingToLane()
    local bot = GetBot();
    local team = GetTeam();
    local assignedLane = bot:GetAssignedLane();
    local laneFrontAmount = GetLaneFrontAmount( team, assignedLane, true );
    local laneFrontLocation = GetLaneFrontLocation( team, assignedLane, laneFrontAmount );
    if ( GetUnitToLocationDistance( bot, laneFrontLocation ) > 800 ) then
        return BOT_ACTION_DESIRE_MODERATE;
    else
        return BOT_ACTION_DESIRE_NONE;
    end
end

-- Block creeps when there are no enemies around
function ConsiderCreepBlock()
    local bot = GetBot();
    local alliedCreeps = bot:GetNearbyLaneCreeps( 1600, false );
    local enemyCreeps = bot:GetNearbyLaneCreeps( 800, true );
    local enemyHeroes = bot:GetNearbyHeroes( 1000, true, BOT_MODE_NONE );
    local enemyTowers = bot:GetNearbyTowers( 1000, true );

    if ( #alliedCreeps > 0 and ( #enemyCreeps + #enemyHeroes + #enemyTowers == 0 ) ) then
        return BOT_ACTION_DESIRE_MODERATE;
    else
        return BOT_ACTION_DESIRE_NONE;
    end
end

function CreepBlock()
    local bot = GetBot();
    local assignedLane = bot:GetAssignedLane();
    local team = bot:GetTeam();

    local laneCreeps = bot:GetNearbyLaneCreeps( 1600, false );
    local ancient = GetAncient(team);
    local ancientDistance = GetUnitToUnitDistance( bot, ancient );
    local firstCreep = nil;
    local firstCreepProgress = 0;

    -- Stay ahead of creeps
    for _, creep in pairs( laneCreeps ) do
        local creepProgress = GetUnitToUnitDistance( creep, ancient );

        -- If any creep has already passed us, give up on him
        if ( creepProgress <= ancientDistance and creepProgress > firstCreepProgress ) then
            firstCreepProgress = creepProgress;
            firstCreep = creep;
        end
    end

    if ( firstCreep ~= nil ) then
        -- Predict the creep's future position and move there to block their way --
        local extrapolatedLocation = firstCreep:GetExtrapolatedLocation( 0.30 );
        bot:Action_MoveToLocation( extrapolatedLocation );
    end
end

function ConsiderApproachingCreeps()
    local bot = GetBot();
    local nDamage = bot:GetAttackDamage();
    local eDamageType = DAMAGE_TYPE_PHYSICAL;
    local attackPoint = bot:GetAttackPoint();
    local attackRange = bot:GetAttackRange();
    local nAcqRange = bot:GetAcquisitionRange();
    local movementSpeed = bot:GetCurrentMovementSpeed();
    local alliedCreeps = bot:GetNearbyLaneCreeps( nAcqRange, false );
    local enemyCreeps = bot:GetNearbyLaneCreeps( nAcqRange, true );

    -- Move closer to dying creeps
    for _, creep in pairs ( enemyCreeps ) do
        local timeToReachCreep = (
            math.max( GetUnitToUnitDistance( bot, creep ) - attackRange, 0 ) /
            bot:GetCurrentMovementSpeed()
        );
        local creepHealth = ExtrapolateHealth( creep, timeToReachCreep + attackPoint );
        if ( creep:GetActualIncomingDamage( nDamage, eDamageType ) >= creepHealth ) then
            return BOT_ACTION_DESIRE_MODERATE, creep;
        end
    end

    -- Move closer to deny creeps
    for _, creep in pairs ( alliedCreeps ) do
        local timeToReachCreep = (
            math.max( GetUnitToUnitDistance( bot, creep ) - attackRange, 0 ) /
            bot:GetCurrentMovementSpeed()
        );
        local creepHealth = ExtrapolateHealth( creep, timeToReachCreep + attackPoint );
        if ( creep:GetActualIncomingDamage( nDamage, eDamageType ) >= creepHealth ) then
            return BOT_ACTION_DESIRE_MODERATE, creep;
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil;
end

function ApproachCreep( creep )
    local bot = GetBot();
    bot:Action_MoveToUnit( creep );
end

function AttackCreep( creep )
    local bot = GetBot();
    bot:Action_AttackUnit( creep, true );
end

function MoveToLocation( location )
    local bot = GetBot();
    bot:Action_MoveToLocation( location );
end

function ConsiderLastHittingCreeps()
    local bot = GetBot();
    local nAcqRange = bot:GetAcquisitionRange();
    local nDamage = bot:GetAttackDamage();
    local attackPoint = bot:GetAttackPoint();
    local eDamageType = DAMAGE_TYPE_PHYSICAL;

    local alliedCreeps = bot:GetNearbyLaneCreeps( nAcqRange, false );
    local enemyCreeps = bot:GetNearbyCreeps( nAcqRange, true );
    for _, creep in pairs( enemyCreeps ) do
        local creepHealth = ExtrapolateHealth( creep, attackPoint );
        -- Check if creep can be last hitted --
        if ( creep:GetActualIncomingDamage( nDamage, eDamageType ) >= creepHealth ) then
            return BOT_ACTION_DESIRE_HIGH, creep;
        end
    end

    for _, creep in pairs( alliedCreeps ) do
        local creepHealth = ExtrapolateHealth( creep, attackPoint );
        -- Check if creep can be denied --
        if ( creep:GetActualIncomingDamage( nDamage, eDamageType ) >= creepHealth ) then
            return BOT_ACTION_DESIRE_HIGH, creep;
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil;
end

function LastHitCreep( creep )
    local bot = GetBot();
    bot:Action_AttackUnit( creep, false );
end

function ConsiderRemovingAggro()
    local bot = GetBot();
    if ( bot:WasRecentlyDamagedByCreep( 1 ) or bot:WasRecentlyDamagedByTower( 1 ) ) then
        return BOT_ACTION_DESIRE_HIGH;
    else
        return BOT_ACTION_DESIRE_NONE;
    end
end

function ConsiderAutoAttackingCreeps()
    local bot = GetBot();
    local assignedLane = bot:GetAssignedLane();

    local nDamage = bot:GetAttackDamage();
    local eDamageType = DAMAGE_TYPE_PHYSICAL;
    local nAcqRange = bot:GetAcquisitionRange();

    local team = bot:GetTeam();
    local opposingTeam = nil;
    if ( team == TEAM_RADIANT ) then
        opposingTeam = TEAM_DIRE;
    else
        opposingTeam = TEAM_RADIANT;
    end

    local laneFront = GetLaneFrontLocation( team, assignedLane, 0 );
    local alliedTower = GetTower( team, TOWER_MID_1 );
    local enemyTower = GetTower( opposingTeam, TOWER_MID_1 );

    local alliedTowerDistance = GetUnitToLocationDistance( alliedTower, laneFront );
    local enemyTowerDistance = GetUnitToLocationDistance( enemyTower, laneFront );
    local delta = alliedTowerDistance - enemyTowerDistance;

    local mode = 0;
    if ( delta > 0 ) then
        mode = PULLING;
    elseif ( delta < -600 ) then
        mode = PUSHING;
    end

    local alliedCreeps = bot:GetNearbyLaneCreeps( nAcqRange, false );
    local enemyCreeps = bot:GetNearbyLaneCreeps( nAcqRange, true );
    if ( mode == PULLING and #alliedCreeps >= #enemyCreeps ) then
        for _, creep in pairs( alliedCreeps ) do
            local creepHealth = creep:GetHealth();
            local attackDamage = creep:GetActualIncomingDamage( nDamage, eDamageType );
            -- Check if creep can be attacked, if so attack once. --
            if ( ( creepHealth / creep:GetMaxHealth() <= 0.5 ) and
                 ( creepHealth > 2 * attackDamage ) ) then
                -- TODO: Attack anyways if the enemy hero is not around
                return BOT_ACTION_DESIRE_MODERATE, creep;
            end
        end
    end

    if ( mode == PUSHING and #alliedCreeps <= #enemyCreeps ) then
        for _, creep in pairs( enemyCreeps ) do
            local creepHealth = creep:GetHealth();
            local attackDamage = creep:GetActualIncomingDamage( nDamage, eDamageType );
            if ( creepHealth > 2 * attackDamage ) then
                -- TODO: Attack anyways if the enemy hero is not around and there are no other attackers
                return BOT_ACTION_DESIRE_MODERATE, creep;
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil;
end

function ConsiderBackingOff()
    local bot = GetBot();
    local location = bot:GetLocation();
    local enemyHeroes = bot:GetNearbyHeroes( 1600, true, BOT_MODE_NONE );

    local delta = 0;
    for _, hero in pairs( enemyHeroes ) do
        local heroRange = hero:GetAttackRange();
        local currentDistance = GetUnitToUnitDistance( bot, hero );
        if ( currentDistance <= heroRange + 150 ) then
            -- We're in attack range of the enemy, retreat.
            -- Always retreat a bit further than needed.
            delta = math.max( heroRange + 150 - currentDistance, delta );
        end
    end

    local fraction = bot:GetHealth() / bot:GetMaxHealth();
    if ( delta > 0 ) then
        if ( fraction < 0.1 ) then
            return BOT_ACTION_DESIRE_ABSOLUTE, delta;
        elseif ( fraction < 0.3 ) then
            return BOT_ACTION_DESIRE_VERY_HIGH, delta;
        elseif ( fraction < 0.5 ) then
            return BOT_ACTION_DESIRE_HIGH, delta;
        else
            return BOT_ACTION_DESIRE_MODERATE, delta;
        end
    else
        return BOT_ACTION_DESIRE_NONE, delta;
    end
end

function StayInLane()
    local bot = GetBot();
    local team = bot:GetTeam();
    local assignedLane = bot:GetAssignedLane();
    local laneFront = GetLaneFrontLocation( team, assignedLane, 0 );
    if ( GetUnitToLocationDistance( bot, laneFront ) > 800 ) then
        print('Just chillin');
        MoveToLocation( laneFront );
    end
end

PossibleActions = {
    { Desire = ConsiderApproachingCreeps, Action = ApproachCreep },
    { Desire = ConsiderCreepBlock, Action = CreepBlock },
    { Desire = ConsiderLastHittingCreeps, Action = LastHitCreep },
    { Desire = ConsiderRemovingAggro, Action = TakeOffAggro },
    { Desire = ConsiderAutoAttackingCreeps, Action = AttackCreep },
    { Desire = ConsiderBackingOff, Action = Retreat },
    { Desire = ConsiderMovingToLane, Action = StayInLane }
};
