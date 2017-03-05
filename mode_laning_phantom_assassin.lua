require( GetScriptDirectory().."/utils/combat" )
require( GetScriptDirectory().."/utils/movement" )
----------------------------------------------------------------------------------------------------
PULLING = 1;
PUSHING = 2;

function Think()
    local npcBot = GetBot();
    local assignedLane = npcBot:GetAssignedLane();

    if ( ConsiderInitialPosition() > BOT_ACTION_DESIRE_NONE ) then
        npcBot:Action_MoveToLocation( GetLocationAlongLane( assignedLane, 0.30 ) );
    elseif ( ConsiderCreepBlock() > BOT_ACTION_DESIRE_NONE ) then
        CreepBlock();
    else
        -- Use these!
        desireToApproachCreeps, creepToApproach = ConsiderApproachingCreeps();
        desireToLastHit, creepToLastHit = ConsiderLastHittingCreeps();
        desireToRemoveAggro = ConsiderRemovingAggro();
        desireToAutoAttack, creepToAutoAttack = ConsiderAutoAttackingCreeps();
        desireToBackOff, backOffAmount = ConsiderBackingOff();

        utmostDesire = math.max(
            desireToApproachCreeps,
            desireToLastHit,
            desireToRemoveAggro,
            desireToAutoAttack,
            desireToBackOff
        );

        local npcBot = GetBot();
        if ( utmostDesire > BOT_ACTION_DESIRE_NONE ) then
            if ( desireToApproachCreeps == utmostDesire ) then
                ApproachCreep( creepToApproach );
            elseif ( desireToLastHit == utmostDesire ) then
                LastHitCreep( creepToLastHit );
            elseif ( desireToRemoveAggro == utmostDesire ) then
                TakeOffAggro();
            elseif ( desireToAutoAttack == utmostDesire ) then
                AttackCreep( creepToAutoAttack );
            elseif ( desireToBackOff == utmostDesire ) then
                Retreat( backOffAmount );
            end
        else
            StayInLane();
        end
    end
end

function ConsiderInitialPosition()
    local time = DotaTime();
    if ( time < 0 ) then
        return BOT_ACTION_DESIRE_HIGH;
    else
        return BOT_ACTION_DESIRE_NONE;
    end
end

function ConsiderCreepBlock()
    local time = DotaTime();
    if ( 0 < time and time < 18 ) then
        return BOT_ACTION_DESIRE_HIGH;
    else
        return BOT_ACTION_DESIRE_NONE;
    end
end

function CreepBlock()
    local npcBot = GetBot();
    local assignedLane = npcBot:GetAssignedLane();
    local team = npcBot:GetTeam();

    local laneCreeps = npcBot:GetNearbyLaneCreeps( 1600, false );
    local ancient = GetAncient(team);
    local ancientDistance = GetUnitToUnitDistance( npcBot, ancient );
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
        npcBot:Action_MoveToLocation( extrapolatedLocation );
    end
end

function ConsiderApproachingCreeps()
    local npcBot = GetBot();
    local nDamage = npcBot:GetAttackDamage();
    local eDamageType = DAMAGE_TYPE_PHYSICAL;
    local attackPoint = npcBot:GetAttackPoint();
    local attackRange = npcBot:GetAttackRange();
    local nAcqRange = npcBot:GetAcquisitionRange();
    local movementSpeed = npcBot:GetCurrentMovementSpeed();
    local alliedCreeps = npcBot:GetNearbyCreeps( nAcqRange, false );
    local enemyCreeps = npcBot:GetNearbyCreeps( nAcqRange, true );

    -- TODO: Include a function in combat.lua to extrapolate future HP based on attackers
    -- Move closer to dying creeps
    for _, creep in pairs ( enemyCreeps ) do
        local timeToReachCreep = (
            math.max( GetUnitToUnitDistance( npcBot, creep ) - attackRange, 0 ) /
            npcBot:GetCurrentMovementSpeed()
        );
        local creepHealth = ExtrapolateHealth( creep, timeToReachCreep + attackPoint );
        if ( creep:GetActualIncomingDamage( nDamage, eDamageType ) >= creepHealth ) then
            return BOT_ACTION_DESIRE_MODERATE, creep;
        end
    end

    -- Move closer to deny creeps
    for _, creep in pairs ( alliedCreeps ) do
        local timeToReachCreep = (
            math.max( GetUnitToUnitDistance( npcBot, creep ) - attackRange, 0 ) /
            npcBot:GetCurrentMovementSpeed()
        );
        local creepHealth = ExtrapolateHealth( creep, timeToReachCreep + attackPoint );
        if ( creep:GetActualIncomingDamage( nDamage, eDamageType ) >= creepHealth ) then
            return BOT_ACTION_DESIRE_MODERATE, creep;
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil;
end

function ApproachCreep( creep )
    local npcBot = GetBot();
    npcBot:Action_MoveToUnit( creep );
end

function AttackCreep( creep )
    local npcBot = GetBot();
    npcBot:Action_AttackUnit( creep, true );
end

function MoveToLocation( location )
    local npcBot = GetBot();
    npcBot:Action_MoveToLocation( location );
end

function ConsiderLastHittingCreeps()
    local npcBot = GetBot();
    local nAcqRange = npcBot:GetAcquisitionRange();
    local nDamage = npcBot:GetAttackDamage();
    local attackPoint = npcBot:GetAttackPoint();
    local eDamageType = DAMAGE_TYPE_PHYSICAL;

    local alliedCreeps = npcBot:GetNearbyCreeps( nAcqRange, false );
    local enemyCreeps = npcBot:GetNearbyCreeps( nAcqRange, true );
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
    local npcBot = GetBot();
    npcBot:Action_AttackUnit(creep, false);
end

function ConsiderRemovingAggro()
    local npcBot = GetBot();
    if ( npcBot:WasRecentlyDamagedByCreep( 1 ) or npcBot:WasRecentlyDamagedByTower( 1 ) ) then
        return BOT_ACTION_DESIRE_HIGH;
    else
        return BOT_ACTION_DESIRE_NONE;
    end
end

function ConsiderAutoAttackingCreeps()
    local npcBot = GetBot();
    local assignedLane = npcBot:GetAssignedLane();

    local nDamage = npcBot:GetAttackDamage();
    local eDamageType = DAMAGE_TYPE_PHYSICAL;
    local nAcqRange = npcBot:GetAcquisitionRange();

    local team = npcBot:GetTeam();
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

    local alliedCreeps = npcBot:GetNearbyCreeps( nAcqRange, false );
    local enemyCreeps = npcBot:GetNearbyCreeps( nAcqRange, true );
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
    local npcBot = GetBot();
    local location = npcBot:GetLocation();
    local enemyHeroes = npcBot:GetNearbyHeroes( 1600, true, BOT_MODE_NONE );

    local delta = 0;
    for _, hero in pairs( enemyHeroes ) do
        local heroRange = hero:GetAttackRange();
        local heroLocation = hero:GetLocation();
        local currentDistance = GetUnitToUnitDistance( npcBot, hero );
        if ( currentDistance <= heroRange + 100 ) then
            -- We're in attack range of the enemy, retreat.
            -- Always retreat a bit further than needed.
            delta = math.max( heroRange + 150 - currentDistance, delta );
        end
    end

    local fraction = npcBot:GetHealth() / npcBot:GetMaxHealth();
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
    local npcBot = GetBot();
    local team = npcBot:GetTeam();
    local assignedLane = npcBot:GetAssignedLane();
    local laneFront = GetLaneFrontLocation( team, assignedLane, 0 );
    if ( GetUnitToLocationDistance( npcBot, laneFront ) > 200 ) then
        MoveToLocation( laneFront );
    end
end
