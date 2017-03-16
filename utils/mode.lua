require( GetScriptDirectory().."/utils/action" )
----------------------------------------------------------------------------------------------------
Mode = {}

function Mode:new(name, actions)
  local obj = { name = name, actions = actions }
  self.__index = self
  return setmetatable( obj, self )
end

function Mode:getBaseDesire()
    return 0
end

function Mode:getDesire()
    if ( self.currentDesire ~= nil ) then
        return self.currentDesire
    else
        return self.getBaseDesire()
    end
end

function Mode:think()
    local utmostDesire = BOT_ACTION_DESIRE_NONE;
    local bestAction = nil;
    local bestTarget = nil;
    for i, action in pairs( self.actions ) do
        local desire, target = action.getDesire();
        if ( desire > utmostDesire ) then
            utmostDesire = desire;
            bestAction = action;
            bestTarget = target;
        end
    end

    -- Execute the action on the chosen target, if any
    if ( utmostDesire > BOT_ACTION_DESIRE_NONE ) then
        if ( self.currentAction ~= bestAction ) then
            print(bestAction.name);
            self.currentDesire = utmostDesire
            self.currentAction = bestAction
            self.currentTarget = bestTarget
        end

        if ( self.currentTarget ) then
            self.currentAction:execute( self.currentTarget )
        else
            self.currentAction:execute()
        end
    else
        self.currentAction = nil;
        self.currentTarget = nil;
        self.currentDesire = nil;
    end
end
