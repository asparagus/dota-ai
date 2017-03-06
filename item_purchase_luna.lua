require( GetScriptDirectory().."/item_purchase_generic" )

local tableItemsToBuy = {
    "item_tango",
    "item_wraith_band",
    "item_ring_of_basilius",
    "item_boots",
    "item_boots_of_elves",
    "item_gloves",
    "item_infused_raindrops",
    "item_boots_of_elves",
    "item_boots_of_elves",
    "item_ogre_axe",
    "item_boots_of_elves",
    "item_blade_of_alacrity",
    "item_recipe_yasha",
    "item_ogre_axe",
    "item_mithril_hammer",
    "item_recipe_black_king_bar",
    "item_ultimate_orb",
    "item_recipe_manta"
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
        elseif ( sNextItem == "item_broadsword" ) then
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
