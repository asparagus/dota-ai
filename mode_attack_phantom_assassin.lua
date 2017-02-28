function OnStart()
    local npcBot = GetBot();
    local target = npcBot:GetTarget();
    if ( target ~= nil ) then
        print( 'Attacking ' );
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

function ShouldTrade( enemy )
    local npcBot = GetBot();
    local location = enemy:GetLocation();
    local alliedCreeps = enemy:GetNearbyCreeps( 500, true );
    local alliedHeroes =  enemy:GetNearbyHeroes( 800, true, BOT_MODE_NONE );
    local alliedTowers = enemy:GetNearbyTowers( 800, true );

    local enemyCreeps = enemy:GetNearbyCreeps( 500, false );
    local enemyHeroes =  enemy:GetNearbyHeroes( 800, false, BOT_MODE_NONE );
    local enemyTowers = enemy:GetNearbyTowers( 800, false );

    local fightLength = 3; -- Pretend an engagement will last 3 seconds --
    local totalAlliedDamage = 0;
    local totalEnemyDamage = 0;
    if ( alliedCreeps ~= nil and #alliedCreeps > 0 ) then
        for _, alliedCreep in pairs( alliedCreeps ) do
            totalAlliedDamage = totalAlliedDamage + alliedCreep:GetEstimatedDamageToTarget( true, enemy, fightLength, DAMAGE_TYPE_ALL );
        end
    end
    if ( alliedHeroes ~= nil and #alliedHeroes > 0 ) then
        for _, alliedHero in pairs( alliedHeroes ) do
            totalAlliedDamage = totalAlliedDamage + alliedHero:GetEstimatedDamageToTarget( true, enemy, fightLength, DAMAGE_TYPE_ALL );
        end
    end
    if ( alliedTowers ~= nil and #alliedTowers > 0 ) then
        for _, alliedTower in pairs( alliedTowers ) do
            totalAlliedDamage = totalAlliedDamage + alliedTower:GetEstimatedDamageToTarget( true, enemy, fightLength, DAMAGE_TYPE_ALL );
        end
    end

    if ( enemyCreeps ~= nil and #enemyCreeps > 0 ) then
        for _, enemyCreep in pairs( enemyCreeps ) do
            totalEnemyDamage = totalEnemyDamage + enemyCreep:GetEstimatedDamageToTarget( true, npcBot, fightLength, DAMAGE_TYPE_ALL );
        end
    end
    if ( enemyHeroes ~= nil and #enemyHeroes > 0 ) then
        for _, enemyHero in pairs( enemyHeroes ) do
            totalEnemyDamage = totalEnemyDamage + enemyHero:GetEstimatedDamageToTarget( true, npcBot, fightLength, DAMAGE_TYPE_ALL );
        end
    end
    if ( enemyTowers ~= nil and #enemyTowers > 0 ) then
        for _, enemyTower in pairs( enemyTowers ) do
            totalEnemyDamage = totalEnemyDamage + enemyTower:GetEstimatedDamageToTarget( true, npcBot, fightLength, DAMAGE_TYPE_ALL );
        end
    end

    -- The trade is advantageous if the % damage dealt is greated than the received.
    -- Additional condition: Do not die
    if totalEnemyDamage > npcBot:GetHealth() then
        print("Trade would result in death");
        return false;
    end

    local result = totalAlliedDamage / enemy:GetMaxHealth() > totalEnemyDamage / npcBot:GetMaxHealth();
    if ( result ) then
        print("Trade is favorable:");
        -- print("Allies: " .. tostring(#alliedCreeps) .. " creeps, " .. tostring(#alliedHeroes) .. " heroes and " tostring(#alliedTowers) .. " towers");
        -- print("Enemies: " .. tostring(#enemyCreeps) .. " creeps, " .. tostring(#enemyHeroes) .. " towers and " tostring(#enemyTowers) .. " heroes");
        return true;
    else
        print("Trade is unfavorable:");
        -- print("Allies: " .. tostring(#alliedCreeps) .. " creeps, " .. tostring(#alliedHeroes) .. " heroes and " tostring(#alliedTowers) .. " towers");
        -- print("Enemies: " .. tostring(#enemyCreeps) .. " creeps, " .. tostring(#enemyHeroes) .. " towers and " tostring(#enemyTowers) .. " heroes");
        return false;
    end
end

function GetDesire()
    local npcBot = GetBot();
    local target = npcBot:GetTarget();
    if ( target ~= nil and target:IsAlive() and GetUnitToUnitDistance( target, npcBot ) >= 1600 ) then
        if ( ShouldTrade( target ) ) then
            return BOT_ACTION_DESIRE_HIGH;
        end
    end

    -- Set attack mode and go on anyone nearby --
    local nearbyHeroes = npcBot:GetNearbyHeroes( 1600, true, BOT_MODE_NONE );
    if ( #nearbyHeroes > 0 ) then
        bestPossibleTarget = ChooseTarget( nearbyHeroes );
        if ( ShouldTrade( bestPossibleTarget ) ) then
            npcBot:SetTarget( nearbyHeroes[1] );
            return BOT_ACTION_DESIRE_HIGH;
        end
    end

    return BOT_ACTION_DESIRE_NONE;
end

function AttackMove()
    local npcBot = GetBot();
    local target = npcBot:GetTarget();
    local attackRange = npcBot:GetAttackRange();

    if ( target ~= nil and target:IsAlive() ) then
        -- Expected movement --
        local expectedMovement = target:GetExtrapolatedLocation( 0.2 );
        -- Check if we can attack again --
        if ( npcBot:GetLastAttackTime() >= npcBot:GetSecondsPerAttack() and GetUnitToUnitDistance( target, npcBot ) <= attackRange ) then
            -- Attack once and keep moving.
            print('Hitting enemy');
            npcBot:Action_AttackUnit( target, true );
            npcBot:ActionQueue_MoveToLocation( expectedMovement );
        else
            print('Chasing ahead');
            npcBot:Action_MoveToLocation( expectedMovement );
        end
    end
end