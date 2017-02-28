MODE = nil;
NONE = 0;
PULLING = 1;
PUSHING = 2;

function Think()
    local npcBot = GetBot();
    local assignedLane = npcBot:GetAssignedLane();
    local team = npcBot:GetTeam();
    local opposingTeam = nil;
    if ( team == TEAM_RADIANT ) then
        opposingTeam = TEAM_DIRE;
    else
        opposingTeam = TEAM_RADIANT;
    end

    local time = DotaTime();
    if ( time < 0 ) then
        local midLanePosition = GetLocationAlongLane( assignedLane, 0.30 );
        npcBot:Action_MoveToLocation( midLanePosition );

    elseif ( time < 18 ) then
        CreepBlock();
    else
        local laneFront = GetLaneFrontLocation( team, assignedLane, 0 );
        local alliedTower = GetTower( team, TOWER_MID_1 );
        local enemyTower = GetTower( opposingTeam, TOWER_MID_1 );

        local alliedTowerDistance = GetUnitToLocationDistance( alliedTower, laneFront );
        local enemyTowerDistance = GetUnitToLocationDistance( enemyTower, laneFront );
        local delta = alliedTowerDistance - enemyTowerDistance;

        if ( delta > 0 ) then
            if ( MODE ~= PULLING ) then
                print("Pulling the lane");
            end
            mode = PULLING;
        elseif ( delta < -400 ) then
            if ( MODE ~= PUSHING ) then
                print("Pushing the lane");
            end
            mode = PUSHING;
        else
            if ( MODE ~= NONE ) then
                print("Just chillin");
            end
            MODE = NONE;
        end

        HoldLane();
    end
end


function CreepBlock()
    print("Creep blocking");
    local npcBot = GetBot();
    local assignedLane = npcBot:GetAssignedLane();
    local team = npcBot:GetTeam();

    local laneCreeps = npcBot:GetNearbyLaneCreeps( 1600, false );
    local firstCreep = nil;
    local firstCreepProgress = 0;
    for _, creep in pairs( laneCreeps ) do
        local creepLocation = creep:GetLocation();
        local creepProgress = GetAmountAlongLane( assignedLane, creepLocation )['amount'];
        if ( creepProgress > firstCreepProgress ) then
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

function HoldLane()
    local npcBot = GetBot();
    local nDamage = npcBot:GetAttackDamage();
    local eDamageType = DAMAGE_TYPE_PHYSICAL;
    local nAcqRange = npcBot:GetAcquisitionRange();

    local assignedLane = npcBot:GetAssignedLane();
    local team = npcBot:GetTeam();
    local laneFront = GetLaneFrontLocation( team, assignedLane, - 200 );

    local alliedCreeps = npcBot:GetNearbyCreeps( nAcqRange, false );
    local enemyCreeps = npcBot:GetNearbyCreeps( nAcqRange, true );
    for _, creep in pairs( enemyCreeps ) do
        local creepHealth = creep:GetHealth();
        -- Check if creep can be last hitted --
        if ( creep:GetActualIncomingDamage( nDamage, eDamageType ) >= creepHealth ) then
            npcBot:Action_AttackUnit(creep, false);
            print("Last hitting");
            return;
        end
    end

    for _, creep in pairs( alliedCreeps ) do
        local creepHealth = creep:GetHealth();
        -- Check if creep can be denied --
        if ( creep:GetActualIncomingDamage( nDamage, eDamageType ) >= creepHealth ) then
            npcBot:Action_AttackUnit(creep, false);
            print("Denying");
            return;
        end
    end

    if ( MODE == PULLING and #alliedCreeps >= #enemyCreeps ) then
        for _, creep in pairs( alliedCreeps ) do
            local creepHealth = creep:GetHealth();
            -- Check if creep can be attacked, if so attack once. --
            if ( ( creepHealth / creep:GetMaxHealth() <= 0.5) and
                 ( creepHealth > 2 * creep:GetActualIncomingDamage( nDamage, eDamageType ) ) ) then
                npcBot:Action_AttackUnit( creep, true );
                return;
            end
        end
    end

    if ( MODE == PUSHING and #alliedCreeps <= #enemyCreeps ) then
        for _, creep in pairs( enemyCreeps ) do
            if ( ( creepHealth > 2 * creep:GetActualIncomingDamage( nDamage, eDamageType ) ) ) then
                npcBot:Action_AttackUnit( creep, true );
                return;
            end
        end
    end

    -- If nothing has been done, check if we can push or pull the lane --
    if ( npcBot:WasRecentlyDamagedByCreep( 1 ) or npcBot:WasRecentlyDamagedByTower( 1 ) ) then
        TakeOffAggro();
        npcBot:Action_MoveToLocation(laneFront);
    end

    print('Moving to lane front');
    if ( GetUnitToLocationDistance( npcBot, laneFront ) > 200 ) then
        npcBot:Action_MoveToLocation(laneFront);
    end
end

function TakeOffAggro()
    print("Taking off aggro");
    local npcBot = GetBot();
    local team = npcBot:GetTeam();
    local ancient = GetAncient(team);
    npcBot:Action_AttackUnit(ancient, true);
end
