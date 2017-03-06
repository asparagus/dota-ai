require( GetScriptDirectory().."/item_purchase_generic" )

local tableItemsToBuy = {
    "item_tango",
    "item_flask",
    "item_flask",
    "item_clarity",
    "item_branches",
    "item_branches",
    "item_boots",
    "item_circlet",
    "item_magic_stick",
    "item_arcane_booster",
    "item_arcane_booster",
    "item_ring_of_health",
    "item_recipe_aether_lens",
    "item_point_booster",
    "item_ogre_axe",
    "item_staff_of_wizardry",
    "item_blade_of_alacrity"
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
