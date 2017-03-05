

----------------------------------------------------------------------------------------------------

function Think()


    if ( GetTeam() == TEAM_RADIANT )
    then
        print( "selecting radiant" );
        SelectHero( 2, "npc_dota_hero_phantom_assassin" );
        SelectHero( 3, "npc_dota_hero_axe" );
        SelectHero( 4, "npc_dota_hero_dazzle" );
        SelectHero( 5, "npc_dota_hero_razor" );
        SelectHero( 6, "npc_dota_hero_skywrath_mage" );
    elseif ( GetTeam() == TEAM_DIRE )
    then
        print( "selecting dire" );
        SelectHero( 7, "npc_dota_hero_phantom_assassin" );
        SelectHero( 8, "npc_dota_hero_axe" );
        SelectHero( 9, "npc_dota_hero_crystal_maiden" );
        SelectHero( 10, "npc_dota_hero_razor" );
        SelectHero( 11, "npc_dota_hero_skywrath_mage" );
    end

end

function UpdateLaneAssignments()

    if ( GetTeam() == TEAM_RADIANT )
    then
        --print( "Radiant lane assignments" );
        return {
        [1] = LANE_MID,
        [2] = LANE_TOP,
        [3] = LANE_TOP,
        [4] = LANE_BOT,
        [5] = LANE_BOT,
        };
    elseif ( GetTeam() == TEAM_DIRE )
    then
        --print( "Dire lane assignments" );
        return {
        [1] = LANE_MID,
        [2] = LANE_BOT,
        [3] = LANE_BOT,
        [4] = LANE_TOP,
        [5] = LANE_TOP,
        };
    end
end

----------------------------------------------------------------------------------------------------
