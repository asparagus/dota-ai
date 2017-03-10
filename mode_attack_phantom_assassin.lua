require( GetScriptDirectory().."/utils/combat" )
require( GetScriptDirectory().."/utils/flavor" )
----------------------------------------------------------------------------------------------------
function GetDesire()
    local npcBot = GetBot();
    local target = npcBot:GetTarget();
    if ( target ~= nil ) then
        if ( target:IsAlive() ) then
            if ( GetUnitToUnitDistance( target, npcBot ) <= 800 ) then
                return EvaluateTrade( target );
            end
        else
            TrashTalk();
        end
    end

    -- Set attack mode and go on anyone nearby --
    local nearbyHeroes = npcBot:GetNearbyHeroes( 800, true, BOT_MODE_NONE );
    if ( #nearbyHeroes > 0 ) then
        local bestPossibleTarget = ChooseTarget( nearbyHeroes );
        local tradeQuality = EvaluateTrade( bestPossibleTarget );
        return tradeQuality;
    end

    return BOT_ACTION_DESIRE_NONE;
end

function Think()
    -- If we're in a teamfight, set the target as the squishier most important hero.
    local npcBot = GetBot();
    local target = npcBot:GetTarget();
    if ( target == nil or not target:IsAlive() ) then
        -- local tableNearbyAttackingAlliedHeroes = npcBot:GetNearbyHeroes( 800, false, BOT_MODE_ATTACK );
        -- if ( #tableNearbyAttackingAlliedHeroes >= 2 )
        -- then
        -- local npcMostDangerousEnemy = nil;
        -- local nMostDangerousDamage = 0;

        local nearbyEnemyHeroes = npcBot:GetNearbyHeroes( 800, true, BOT_MODE_NONE );
        target = ChooseTarget(nearbyEnemyHeroes);

        if ( target ~= nil ) then
            npcBot:SetTarget(target);
        end
        -- end
    end

    if ( target ~= nil ) then
        AttackMove();
    end
end
