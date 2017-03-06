require( GetScriptDirectory().."/utils/team" )
require( GetScriptDirectory().."/utils/items" )
----------------------------------------------------------------------------------------------------
POOLED = false;

function ItemUsageThink()
    local npcBot = GetBot();
    if ( not POOLED ) then
        if ( GetItemByName( "item_tango" ) ) then
            local midHeroes = GetHeroesByLane()[LANE_MID];
            if ( midHeroes ~= nil and #midHeroes > 0 ) then
                local midHero = midHeroes[1];
                local hasTango = HasItem( midHero, "item_tango_single" );
                if ( not hasTango ) then
                    print('Pooling ' .. midHero:GetUnitName() );
                    PoolTangos( midHero, 2 );
                    POOLED = true;
                end
            end
        end
    end
end