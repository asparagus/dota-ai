require( GetScriptDirectory().."/utils/items" )
require( GetScriptDirectory().."/item_builds" )
----------------------------------------------------------------------------------------------------
-- Builds for all the heroes of this team.
local ItemBuilds = {};

function ItemPurchaseThink()
    local bot = GetBot();
    local botName = bot:GetUnitName();

    -- Set up the builds from the item_builds script
    if ( ItemBuilds[ botName ] == nil ) then
        ItemBuilds[ botName ] = GetBuild( botName );
    else
        local botBuild = ItemBuilds[ botName ];
        if ( #botBuild == 0 ) then
            bot:SetNextItemPurchaseValue( 0 );
            return;
        end

        local nextItem = botBuild[ 1 ];
        local nextItemCost = GetItemCost( nextItem );
        bot:SetNextItemPurchaseValue( nextItemCost );

        local currentGold = bot:GetGold();
        if ( currentGold >= nextItemCost ) then
            bot:ActionImmediate_PurchaseItem( nextItem );
            table.remove( botBuild, 1 );
        end

        -- SortItems();
    end
end
