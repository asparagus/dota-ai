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

function IsBoot( item )
    local name = item:GetName();
    return ( name == "item_boots" or
             name == "item_power_treads" or
             name == "item_phase_boots" or
             name == "item_tranquil_boots" or
             name == "item_arcane_boots" or
             name == "item_travel_boots" or
             name == "item_travel_boots_2" );
end

function SortItems()
    local bot = GetBot();
    local bestBoots = nil;
    for slot = 0, 8 do
        local item = bot:GetItemInSlot( slot );
        if ( item ~= nil and IsBoot( item ) ) then
            if ( bestBoots == nil or GetItemCost( item:GetName() ) > GetItemCost( bestBoots:GetName() ) ) then
                bestBoots = item;
            end
        end
    end

    -- If the bot has boots, put them in slot 0.
    -- Sort all others according to price.
    local sortStartIndex = 0;
    if ( bestBoots ~= nil ) then
        local bootSlot = bot:FindItemSlot( bestBoots:GetName() );
        bot:ActionImmediate_SwapItems( bootSlot, 0 );
        sortStartIndex = 1;
    end

    -- Sort items, put more costly items first.
    -- Cheaper items are moved to the backpack.
    for slot = sortStartIndex, 7 do
        local bestItem = nil;
        local bestItemCost = 0;
        local bestItemSlot = nil;
        -- Get the highest value item for this position.
        for candidateSlot = slot, 8 do
            local item = bot:GetItemInSlot( candidateSlot );
            if ( item ~= nil ) then
                local cost = GetItemCost( item:GetName() );
                if ( cost > bestItemCost ) then
                    bestItemSlot = candidateSlot;
                    bestItemCost = cost;
                    bestItem = item;
                end
            end
        end
        -- Swap the best candidate.
        if ( bestItem ~= nil ) then
            bot:ActionImmediate_SwapItems( bestItemSlot, slot );
        end
    end
end

function IsDiscardable(item)
    return not IsBoot(item);
end

function ChooseItemToDiscard()
    -- Get the cheapest item that is not boots.
    local npcBot = GetBot();
    local cheapestDroppableItem = nil;
    local cheapestDroppableItemCost = 9999;
    for slot = 0, 5 do
        local item = npcBot:GetItemInSlot(slot);
        if ( IsDiscardable( item ) ) then
            local cost = GetItemCost( item:GetName() );
            if ( cost < cheapestDroppableItemCost ) then
                cheapestDroppableItemCost = cost;
                cheapestDroppableItem = item;
            end
        end
    end

    return cheapestDroppableItem;
end

function PoolTangos( teammate, amount )
    local npcBot = GetBot();
    local tango = GetItemByName("item_tango");
    npcBot:Action_UseAbilityOnEntity( tango, teammate );
    for i = 2, amount do
        npcBot:ActionQueue_UseAbilityOnEntity( tango, teammate );
    end
end