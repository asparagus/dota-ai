require( GetScriptDirectory().."/item_purchase_generic" )

local tableItemsToBuy = {
    "item_tango",
    "item_courier",
    "item_faerie_fire",
    "item_enchanted_mango",
    "item_flask",
    "item_clarity",
    "item_boots",
    "item_flying_courier",
    "item_ring_of_regen",
    "item_ring_of_protection",
    "item_magic_stick",
    "item_branches",
    "item_branches",
    "item_circlet",
    "item_chainmail",
    "item_branches",
    "item_recipe_buckler",
    "item_ring_of_regen",
    "item_branches",
    "item_recipe_headdress",
    "item_recipe_mekansm",
    "item_circlet",
    "item_gauntlets",
    "item_recipe_bracer",
    "item_wind_lace",
    "item_recipe_ancient_janggo",
    "item_sobi_mask",
    "item_staff_of_wizardry",
    "item_ring_of_regen",
    "item_recipe_force_staff",
    "item_recipe_travel_boots",
    "item_boots",
    "item_recipe_necronomicon",
    "item_staff_of_wizardry",
    "item_belt_of_strength",
    "item_recipe_necronomicon",
    "item_recipe_necronomicon",
    "item_recipe_travel_boots",
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
        elseif ( sNextItem == "item_recipe_necronomicon" ) then
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
