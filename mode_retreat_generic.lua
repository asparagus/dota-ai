require( GetScriptDirectory().."/utils/movement" )
----------------------------------------------------------------------------------------------------
SHRINES = {
    SHRINE_BASE_1,
    SHRINE_BASE_2,
    SHRINE_BASE_3,
    SHRINE_BASE_4,
    SHRINE_BASE_5,
    SHRINE_JUNGLE_1,
    SHRINE_JUNGLE_2
};

function GetDesire()
    local npcBot = GetBot();
    local team = npcBot:GetTeam();

    local health = npcBot:GetHealth();
    local maxHealth = npcBot:GetMaxHealth();
    local fraction = health / maxHealth;

    if ( fraction <= 0.4 ) then
        return BOT_ACTION_DESIRE_MODERATE;
    elseif ( fraction <= 0.3 ) then
        return BOT_ACTION_DESIRE_HIGH;
    elseif ( fraction <= 0.2 ) then
        return BOT_ACTION_DESIRE_VERY_HIGH;
    end

    if ( IsHealing() ) then
        return BOT_ACTION_DESIRE_HIGH;
    end
end

function IsHealing()
    local npcBot = GetBot();
    local team = npcBot:GetTeam();

    local health = npcBot:GetHealth();
    local maxHealth = npcBot:GetMaxHealth();
    local mana = npcBot:GetMana();
    local maxMana = npcBot:GetMaxMana();

    if ( health < maxHealth or mana < maxMana ) then
        if ( npcBot:DistanceFromFountain() == 0 ) then
            return true;
        end

        local nearbyShrines = npcBot:GetNearbyShrines( 1600, false );
        if ( #nearbyShrines > 0 ) then
            if ( IsShrineHealing( nearbyShrines[1] ) ) then
                return true;
            end
        end
    end

    return false;
end

function Think()
    if ( IsHealing() ) then
        -- Just stay there
        return;
    end

    local npcBot = GetBot();
    local closestShrineDistance = math.huge;
    local closestActiveShrine = nil;
    local team = npcBot:GetTeam();

    for _, n_shrine in pairs( SHRINES ) do
        local shrine = GetShrine( team, n_shrine );
        local shrineCd = GetShrineCooldown( shrine );
        if ( GetShrineCooldown( shrine ) == 0 ) then
            local distance = GetUnitToUnitDistance( npcBot, shrine );
            if ( distance < closestShrineDistance ) then
                closestShrineDistance = distance;
                closestActiveShrine = shrine;
            end
        end
    end

    local fountainDistance = npcBot:DistanceFromFountain();

    if ( closestShrineDistance < fountainDistance ) then
        npcBot:Action_UseShrine( closestActiveShrine );
    else
        local home = GetShopLocation( team, SHOP_HOME );
        npcBot:Action_MoveToLocation( home );
    end
end