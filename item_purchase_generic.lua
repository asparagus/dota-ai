require( GetScriptDirectory().."/utils/items" )
require( GetScriptDirectory().."/utils/team" )
require( GetScriptDirectory().."/item_builds" )
----------------------------------------------------------------------------------------------------
-- Builds for all the heroes of this team.
local ItemBuilds = {};
local POOLED = false;

function ItemPurchaseThink()
    local bot = GetBot();
    local botName = bot:GetUnitName();

    -- Set up the builds from the item_builds script
    if ( ItemBuilds[ botName ] == nil ) then
        ItemBuilds[ botName ] = GetBuild( botName );
    else
        local botBuild = ItemBuilds[ botName ];

        -- The hero with the lowest farm priority buys the wards.
        if ( GetFarmPriority( bot ) == 5 ) then
            PurchaseWards();
        elseif ( GetFarmPriority( bot ) == 4 ) then
            PurchaseFlyingCourier();
            PoolTangosToMid();
        end

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

function PurchaseWards()
    local bot = GetBot();
    local botName = bot:GetUnitName();
    local build = ItemBuilds[ botName ];
    if ( build[1] ~= 'item_ward_observer' and GetItemStockCount( 'item_ward_observer' ) > 0 ) then
        table.insert( build, 1, 'item_ward_observer' );
    end
end

function PurchaseFlyingCourier()
    local bot = GetBot();
    local courier = GetCourier( 0 );
    if ( DotaTime() > 180 and not IsFlyingCourier( courier ) ) then
        if ( bot:GetGold() > 150 ) then
            bot:ActionImmediate_PurchaseItem("item_Flying_courier");
        end
    end
end

function PoolTangosToMid()
    if ( DotaTime() < 0 and not POOLED ) then
        local bot = GetBot();
        local tangoSlot = bot:FindItemSlot( 'item_tango' );
        local tangoSlotType = bot:GetItemSlotType( tangoSlot );

        if ( tangoSlotType  == ITEM_SLOT_TYPE_MAIN ) then
            local midHero = GetHeroesByLane()[ LANE_MID ][ 1 ];
            PoolTangos( midHero, 2 );
            POOLED = true;
        end
    end
end