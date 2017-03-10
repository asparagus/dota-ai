

----------------------------------------------------------------------------------------------------

function Think()

    local team = GetTeam();
    local players = GetTeamPlayers( team );

    local mode = GetGameMode();
    local heroes = nil;

    if ( mode == GAMEMODE_AP ) then
        print('All pick');
        heroes = {
            "npc_dota_hero_axe",
            "npc_dota_hero_crystal_maiden",
            "npc_dota_hero_phantom_assassin",
            "npc_dota_hero_luna",
            "npc_dota_hero_warlock",
        };
    -- elseif ( mode == GAMEMODE_1V1MID ) then
    --     print('1v1 Mid');
    --     heroes = {
    --         "npc_dota_hero_phantom_assassin"
    --     };

    --     -- If a human player is on this team, do not pick.
    --     for _, player in pairs( players ) do
    --         if ( IsPlayerInHeroSelectionControl( player ) ) then
    --             heroes = {};
    --             break;
    --         end
    --     end
    end

    for _, player in pairs( players ) do
        if ( #heroes  == 0 ) then
            break;
        end

        SelectHero( player, heroes[1] );
        table.remove( heroes, 1 );
    end
end

function UpdateLaneAssignments()

    if ( GetTeam() == TEAM_RADIANT )
    then
        --print( "Radiant lane assignments" );
        return {
        [1] = LANE_TOP,
        [2] = LANE_TOP,
        [3] = LANE_MID,
        [4] = LANE_BOT,
        [5] = LANE_BOT,
        };
    elseif ( GetTeam() == TEAM_DIRE )
    then
        --print( "Dire lane assignments" );
        return {
        [1] = LANE_BOT,
        [2] = LANE_BOT,
        [3] = LANE_MID,
        [4] = LANE_TOP,
        [5] = LANE_TOP,
        };
    end
end

----------------------------------------------------------------------------------------------------
