function HasItem( hero, item )
    local itemFound = false;

    -- Iterate over inventory slots.
    for i = 0, 5 do
        local currentItem = hero:GetItemInSlot( i );
        if ( currentItem ~= nil  and currentItem:GetName() == item ) then
            return true;
        end
    end

    -- Item not found in inventory.
    return false;
end


function PoolTangos( teammate, amount )
    local npcBot = GetBot();
    local tango = GetItemByName("item_tango");
    npcBot:Action_UseAbilityOnEntity( tango, teammate );
    for i = 2, amount do
        npcBot:ActionQueue_UseAbilityOnEntity( tango, teammate );
    end
end