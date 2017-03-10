RuneSpawns = {
    RUNE_POWERUP_1,
    RUNE_POWERUP_2,
    RUNE_BOUNTY_1,
    RUNE_BOUNTY_2,
    RUNE_BOUNTY_3,
    RUNE_BOUNTY_4
};

function GetDesire()
    local desire = 0;

    local bot = GetBot();
    local movementSpeed = bot:GetCurrentMovementSpeed();
    for _, runeSpawn in pairs( RuneSpawns ) do
        local runeSpawnLocation = GetRuneSpawnLocation( runeSpawn );
        local runeStatus = GetRuneStatus( runeSpawn );
        local timeToRune = GetUnitToLocationDistance( bot, runeSpawnLocation ) / movementSpeed;
        if ( runeStatus ~= RUNE_STATUS_MISSING ) then
            if ( timeToRune < 5 ) then
                desire = BOT_MODE_DESIRE_MODERATE;
            elseif ( timeToRune < 10 ) then
                desire = BOT_MODE_DESIRE_LOW;
            elseif ( timeToRune < 15 ) then
                desire = BOT_MODE_DESIRE_VERYLOW;
            end
        end
    end

    return desire;
end

function Think()
    local bot = GetBot();
    local closestRuneSpawn = nil;
    local closestRuneSpawnLocation = nil;
    local closestDistance = math.huge;

    for _, runeSpawn in pairs( RuneSpawns ) do
        local runeSpawnLocation = GetRuneSpawnLocation( runeSpawn );
        local runeStatus = GetRuneStatus( runeSpawn );

        if ( runeStatus ~= RUNE_STATUS_MISSING ) then
            local distance = GetUnitToLocationDistance( bot, runeSpawnLocation );
            if ( distance < closestDistance ) then
                closestDistance = distance;
                closestRuneSpawn = runeSpawn;
                closestRuneSpawnLocation = runeSpawnLocation;
            end
        end
    end

    if ( closestRuneSpawn ~= nil ) then
        if ( closestDistance < 100 ) then
            bot:Action_PickUpRune( closestRuneSpawn );
        else
            bot:Action_MoveToLocation( closestRuneSpawnLocation );
        end
    end
end