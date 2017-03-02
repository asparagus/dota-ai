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
    local health = npcBot:GetHealth();
    local maxHealth = npcBot:GetMaxHealth();
    local fraction = health / maxHealth;

    if ( fraction <= 0.4 ) then
        return BOT_ACTION_DESIRE_MODERATE;
    elseif ( fraction <= 0.3 ) then
        return BOT_ACTION_DESIRE_HIGH;
    elseif ( fraction <= 0.2 ) then
        return BOT_ACTION_DESIRE_VERY_HIGH;
    elseif ( fraction <= 0.1 ) then
        return
    end
end

function Think()
    local npcBot = GetBot();
    local closestShrineDistance = math.huge;
    local closestActiveShrine = nil;
    local team = npcBot:GetTeam();

    print('Checking shrine cds');
    for _, n_shrine in pairs( SHRINES ) do
        local shrine = GetShrine( team, n_shrine );
        local shrineCd = GetShrineCooldown( shrine );
        print(shrineCd);
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
        print('Using shrine');
        npcBot:Action_UseShrine( closestActiveShrine );
    else
        local home = GetShopLocation( team, SHOP_HOME );
        print('Walking to fountain');
        npcBot:Action_MoveToLocation( home );
    end
end