require( GetScriptDirectory().."/item_purchase_generic" )

local tableItemsToBuy = {
    "item_stout_shield",
    "item_slippers",
    "item_slippers",
    "item_branches",
    "item_branches",
    "item_blight_stone",
    "item_boots",
    "item_blades_of_attack",
    "item_blades_of_attack",
    "item_circlet",
    "item_magic_stick",
    "item_wraith_band",
    "item_ring_of_basilius",
    "item_mithril_hammer",
    "item_mithril_hammer",
    "item_lesser_crit",
    "item_ogre_axe",
    "item_mithril_hammer",
    "item_recipe_black_king_bar",
    "item_recipe_travel_boots",
    "item_boots",
    "item_recipe_sange",
    "item_ogre_axe",
    "item_belt_of_strength",
    "item_boots_of_elves",
    "item_blade_of_alacrity",
    "item_recipe_yasha",
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
        elseif ( sNextItem == "item_recipe_sange" ) then
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
