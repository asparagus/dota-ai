require( GetScriptDirectory().."/item_purchase_generic" )

local tableItemsToBuy = {
    "item_tango",
    "item_courier",
    "item_branches",
    "item_branches",
    "item_observer_ward",
    "item_observer_ward",
    "item_boots",
    "item_flying_courier",
    "item_ring_of_protection",
    "item_ring_of_regen",
    "item_wind_lace",
    "item_void_stone",
    "item_staff_of_wizardry",
    "item_recipe_cyclone",
    "item_blink",
    "item_staff_of_wizardry",
    "item_ring_of_regen",
    "item_recipe_force_staff",
    "item_cloak",
    "item_shadow_amulet",
    "item_recipe_glimmer_cape"
};

function ItemPurchaseThink()

    local npcBot = GetBot();

    if ( #tableItemsToBuy == 0 ) then
        npcBot:SetNextItemPurchaseValue( 0 );
        return;
    end

    local sNextItem = tableItemsToBuy[1];
    npcBot:SetNextItemPurchaseValue( GetItemCost( sNextItem ) );

    if ( npcBot:GetGold() >= GetItemCost( sNextItem ) ) then
        if ( sNextItem == "item_boots" ) then
            if ( BootsProtocol() ) then
                npcBot:ActionImmediate_PurchaseItem( sNextItem );
                table.remove( tableItemsToBuy, 1 );
            else
--                print("awaiting boots protocol");
--                print(npcBot:GetUnitName());
            end
        elseif ( sNextItem == "item_recipe_dagon" ) then
            if ( TravelsDone() ) then
                npcBot:ActionImmediate_PurchaseItem( sNextItem );
                table.remove( tableItemsToBuy, 1 );
            else
--                print("awaiting travels");
--                print(npcBot:GetUnitName());
            end
        else
            npcBot:ActionImmediate_PurchaseItem( sNextItem );
            table.remove( tableItemsToBuy, 1 );
        end
    end

    DoStuff();

end
