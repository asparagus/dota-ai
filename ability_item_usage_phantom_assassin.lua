require( GetScriptDirectory().."/utils/combat" )
----------------------------------------------------------------------------------------------------

castDaggerDesire = 0;
castBlinkDesire = 0;

function AbilityUsageThink()

    local npcBot = GetBot();

    -- Check if we're already using an ability
    if ( npcBot:IsUsingAbility() ) then return end;

    abilityDagger = npcBot:GetAbilityByName( "phantom_assassin_stifling_dagger" );
    abilityBlink = npcBot:GetAbilityByName( "phantom_assassin_phantom_strike" );

    -- Consider using each ability
    castDaggerDesire, castDaggerTarget = ConsiderStiflingDagger();
    castBlinkDesire, castBlinkTarget = ConsiderPhantomStrike();

    if ( castDaggerDesire > 0 )
    then
        npcBot:Action_UseAbilityOnEntity( abilityDagger, castDaggerTarget );
        return;
    end

    if ( castBlinkDesire > 0 )
    then
        npcBot:Action_UseAbilityOnEntity( abilityBlink, castBlinkTarget );
        return;
    end

end

----------------------------------------------------------------------------------------------------

function CanCastStiflingDaggerOnTarget( npcTarget )
    return npcTarget:CanBeSeen() and not npcTarget:IsMagicImmune();
end


function CanCastPhantomStrikeOnTarget( npcTarget )
    return npcTarget:CanBeSeen();
end

----------------------------------------------------------------------------------------------------

daggerMultiplier = { 0.25, 0.25, 0.40, 0.40, 0.55, 0.55 };
for lvl = 7, 25 do
    daggerMultiplier[lvl] = 0.70;
end

function ConsiderStiflingDagger()

    local npcBot = GetBot();

    -- Make sure it's castable
    if (not abilityDagger:IsFullyCastable() ) then
        return BOT_ACTION_DESIRE_NONE, 0;
    end

    -- Get some of its values
    local autoAttackDamage = npcBot:GetAttackDamage();
    local autoAttackRange = npcBot:GetAttackRange();
    local level = npcBot:GetLevel();

    local nCastRange = abilityDagger:GetCastRange();
    local baseDamage = 65;

    local nDamage = baseDamage + daggerMultiplier[level] * autoAttackDamage;
    local eDamageType = DAMAGE_TYPE_PHYSICAL;

    -- If a mode has set a target, and we can kill them, do it
    local npcTarget = npcBot:GetTarget();
    if ( npcTarget ~= nil and CanCastStiflingDaggerOnTarget( npcTarget ) )
    then
        if (npcTarget:GetActualIncomingDamage( nDamage, eDamageType ) > npcTarget:GetHealth() and GetUnitToUnitDistance( npcTarget, npcBot ) < ( nCastRange + 200 ) )
        then
            print("Using dagger on target");
            return BOT_ACTION_DESIRE_HIGH, npcTarget
        end
    end

    if ( npcBot:GetActiveMode() == BOT_MODE_LANING ) then
        -- Check for creeps to last hit
        local currentMana = npcBot:GetMana();
        if ( currentMana > 150 ) then
            local nearbyCreeps = npcBot:GetNearbyCreeps( nCastRange + 200, true );
            local nearbyEnemies = npcBot:GetNearbyHeroes( 1600, true, BOT_MODE_NONE );
            for _, creep in pairs( nearbyCreeps ) do
                local creepHealth = creep:GetHealth();
                -- Check if the target would die with a dagger
                if ( creep:GetActualIncomingDamage( nDamage, eDamageType ) >= creepHealth ) then
                    local travelDistance = math.max( GetUnitToUnitDistance( npcBot, creep ) - autoAttackRange, 0 );
                    for _,npcEnemy in pairs ( nearbyEnemies ) do
                        local enemyTravelDistance = math.max( GetUnitToUnitDistance( npcEnemy, creep ) - npcEnemy:GetAttackRange(), 0 );
                        if ( ( enemyTravelDistance < travelDistance or enemyTravelDistance == 0 ) and npcEnemy:GetAttackDamage() > autoAttackDamage ) then
                            print("Using dagger to avoid a deny");
                            return BOT_ACTION_DESIRE_MODERATE, creep;
                        end
                    end
                end
            end
        end

        -- Harass --
        local enemiesToHarass = npcBot:GetNearbyHeroes( nCastRange + 400, true, BOT_MODE_NONE );
        local weakestHero = nil;
        local weakestHeroHealth = 999999;
        for _,npcTarget in pairs( enemiesToHarass ) do
            local currentHealth = npcTarget:GetHealth();
            local expectedDamage = npcTarget:GetActualIncomingDamage( nDamage, eDamageType );
            local remainingHealth = currentHealth - expectedDamage;
            if ( remainingHealth < weakestHeroHealth ) then
                weakestHeroHealth = remainingHealth;
                weakestHero = npcTarget;
            end
        end

        if ( weakestHero ~= nil ) then
            local currentMana = npcBot:GetMana();
            local currentHealth = npcBot:GetHealth();
            if ( currentMana >= 150 or ( currentMana / npcBot:GetMaxMana() >= currentHealth / npcBot:GetMaxHealth() ) ) then
                print("Using dagger to harass");
                return BOT_ACTION_DESIRE_MODERATE, weakestHero;
            end
        end
    end

    -- If we're in a teamfight, use it on the most valuable fragile target
    local tableNearbyAttackingAlliedHeroes = npcBot:GetNearbyHeroes( 1000, false, BOT_MODE_ATTACK );
    if ( #tableNearbyAttackingAlliedHeroes >= 2 )
    then

        local npcMostDangerousEnemy = nil;
        local nMostDangerousDamage = 0;

        local nearbyEnemyHeroes = npcBot:GetNearbyHeroes( nCastRange, true, BOT_MODE_NONE );
        local target = ChooseTarget(nearbyEnemyHeroes);

        if ( target ~= nil ) then
            npcBot:SetTarget( target );
            print("Using dagger on chosen teamfight hero");
            return BOT_ACTION_DESIRE_HIGH, target;
        end
    end

    -- If we're seriously retreating, see if we can slow someone who's damaged us recently
    if ( npcBot:GetActiveMode() == BOT_MODE_RETREAT and npcBot:GetActiveModeDesire() >= BOT_MODE_DESIRE_HIGH )
    then
        local tableNearbyEnemyHeroes = npcBot:GetNearbyHeroes( nCastRange + 200, true, BOT_MODE_NONE );
        for _,npcEnemy in pairs( tableNearbyEnemyHeroes )
        do
            if ( npcBot:WasRecentlyDamagedByHero( npcEnemy, 2.0 ) ) then
                if ( CanCastStiflingDaggerOnTarget( npcEnemy ) ) then
                    print("Using dagger to slow an attacker");
                    return BOT_ACTION_DESIRE_MODERATE, npcEnemy;
                end
            end
        end
    end

    -- If we're going after someone
    if ( npcBot:GetActiveMode() == BOT_MODE_ROAM or
         npcBot:GetActiveMode() == BOT_MODE_TEAM_ROAM or
         npcBot:GetActiveMode() == BOT_MODE_GANK or
         npcBot:GetActiveMode() == BOT_MODE_DEFEND_ALLY or
         npcBot:GetActiveMode() == BOT_MODE_ATTACK )
    then
        local npcTarget = npcBot:GetTarget();

        if ( npcTarget ~= nil ) then
            if ( CanCastStiflingDaggerOnTarget( npcTarget ) ) then
                print("Using dagger to chase");
                return BOT_ACTION_DESIRE_HIGH, npcTarget;
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE, 0;
end

----------------------------------------------------------------------------------------------------

function ConsiderPhantomStrike()
    local npcBot = GetBot();

    -- Make sure it's castable
    if (not abilityBlink:IsFullyCastable() ) then
        return BOT_ACTION_DESIRE_NONE, 0;
    end

    -- Get some of its values
    local nCastRange = abilityBlink:GetCastRange();
    local nDamage = npcBot:GetAttackDamage() * 3;
    local eDamageType = DAMAGE_TYPE_PHYSICAL;

    -- If a mode has set a target go on them
    local npcTarget = npcBot:GetTarget();
    if ( npcTarget ~= nil and CanCastPhantomStrikeOnTarget( npcTarget ) )
    then
        return BOT_ACTION_DESIRE_HIGH, npcTarget;
    end

    -- If we're seriously retreating, try to run to a teammate
    if ( npcBot:GetActiveMode() == BOT_MODE_RETREAT and npcBot:GetActiveModeDesire() >= BOT_MODE_DESIRE_HIGH )
    then
        local distanceToFountain = npcBot:DistanceFromFountain();
        -- local tableNearbyEnemyHeroes = npcBot:GetNearbyHeroes( nCastRange + nRadius + 200, true, BOT_MODE_NONE );
        -- for _,npcEnemy in pairs( tableNearbyEnemyHeroes )
        -- do
        --     if ( npcBot:WasRecentlyDamagedByHero( npcEnemy, 2.0 ) )
        --     then
        --         if ( CanCastPhantomStrikeOnTarget( npcEnemy ) )
        --         then
        --             return BOT_ACTION_DESIRE_MODERATE, npcEnemy;
        --         end
        --     end
        -- end
    end

    -- If we're going after someone
    if ( npcBot:GetActiveMode() == BOT_MODE_ROAM or
         npcBot:GetActiveMode() == BOT_MODE_TEAM_ROAM or
         npcBot:GetActiveMode() == BOT_MODE_GANK or
         npcBot:GetActiveMode() == BOT_MODE_DEFEND_ALLY or
         npcBot:GetActiveMode() == BOT_MODE_ATTACK )
    then
        local npcTarget = npcBot:GetTarget();

        if ( npcTarget ~= nil ) then
            if ( CanCastPhantomStrikeOnTarget( npcTarget ) ) then
                return BOT_ACTION_DESIRE_HIGH, npcTarget;
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE, 0;
end
