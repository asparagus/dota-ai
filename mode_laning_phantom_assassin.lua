require( GetScriptDirectory().."/utils/combat" )
require( GetScriptDirectory().."/utils/movement" )
require( GetScriptDirectory().."/utils/action" )
----------------------------------------------------------------------------------------------------
PULLING = 1;
PUSHING = 2;

function GetDesire()
    if ( DotaTime() < 600 ) then
        return BOT_MODE_DESIRE_ABSOLUTE;
    end

    -- local bot = GetBot();
    -- local nearbyEnemyCreeps = bot:GetNearbyCreeps( 1600, true );
    -- if ( #nearbyEnemyCreeps > 0 ) then
    --     return BOT_MODE_DESIRE_MODERATE;
    -- else
    --     return BOT_MODE_DESIRE_VERYLOW;
    -- end
end

PossibleActions = {
    MovingToLane:new(),
    LastHit:new(),
    RemoveAggro:new(),
    BackOff:new(),
    ApproachCreep:new(),
    CreepBlock:new(),
    Attack:new()
};

function Think()
    -- Get the most desired action out of the possibilities.
    local utmostDesire = BOT_ACTION_DESIRE_NONE;
    local bestAction = nil;
    local bestTarget = nil;
    for i, possibleAction in pairs( PossibleActions ) do
        local desire, target = possibleAction.getDesire();
        if ( desire > utmostDesire ) then
            utmostDesire = desire;
            bestAction = possibleAction;
            bestTarget = target;
        end
    end

    -- Execute the action on the chosen target, if any
    if ( utmostDesire > BOT_ACTION_DESIRE_NONE ) then
        if ( bestTarget ) then
            bestAction:execute( bestTarget );
        else
            bestAction:execute();
        end
    end
end
