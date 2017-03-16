require( GetScriptDirectory().."/utils/action" )
require( GetScriptDirectory().."/utils/mode" )
----------------------------------------------------------------------------------------------------
Laning = Mode:new(
    'Laning', {
        MoveToLane:new(),
        LastHit:new(),
        RemoveAggro:new(),
        BackOff:new(),
        ApproachCreep:new(),
        CreepBlock:new(),
        Attack:new()
    }
)

function Laning:getBaseDesire()
    return BOT_MODE_DESIRE_ABSOLUTE
end

----------------------------------------------------------------------------------------------------
mode = Laning:new()

function GetDesire()
    return mode:getDesire()
end

function Think()
    mode:think()
end