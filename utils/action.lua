require( GetScriptDirectory().."/utils/combat" )
require( GetScriptDirectory().."/utils/movement" )
----------------------------------------------------------------------------------------------------
Action = {}

function Action:new(name)
  local obj = { name = name }
  self.__index = self
  return setmetatable( obj, self )
end

function Action:getDesire()
    return BOT_ACTION_DESIRE_NONE, nil
end

function Action:execute()
    print("Executing action " .. self.name)
end

-- Approaching Lane
MoveToLane = Action:new('Move to lane')
function MoveToLane:getDesire()
    local bot = GetBot()
    local team = GetTeam()
    local assignedLane = bot:GetAssignedLane()
    local laneFrontAmount = GetLaneFrontAmount( team, assignedLane, true )
    local laneFrontLocation = GetLaneFrontLocation( team, assignedLane, laneFrontAmount )
    if ( GetUnitToLocationDistance( bot, laneFrontLocation ) > 800 ) then
        return BOT_ACTION_DESIRE_MODERATE
    else
        return BOT_ACTION_DESIRE_NONE
    end
end
function MoveToLane:execute()
    local bot = GetBot()
    local team = bot:GetTeam()
    local assignedLane = bot:GetAssignedLane()
    local laneFront = GetLaneFrontLocation( team, assignedLane, 0 )
    if ( GetUnitToLocationDistance( bot, laneFront ) > 800 ) then
        bot:Action_MoveToLocation( laneFront )
    end
end

-- Last hit
LastHit = Action:new('Last hit')
function LastHit:getDesire()
    local bot = GetBot()
    local nAcqRange = bot:GetAcquisitionRange()
    local nDamage = bot:GetAttackDamage()
    local attackPoint = bot:GetAttackPoint()
    local eDamageType = DAMAGE_TYPE_PHYSICAL

    local alliedCreeps = bot:GetNearbyLaneCreeps( nAcqRange, false )
    local enemyCreeps = bot:GetNearbyCreeps( nAcqRange, true )
    -- TODO: ignore creeps that will die before the attack.
    -- TODO: consider using skills to last hit
    for _, creep in pairs( enemyCreeps ) do
        local creepHealth = ExtrapolateHealth( creep, attackPoint )
        -- Check if creep can be last hitted --
        if ( creep:GetActualIncomingDamage( nDamage, eDamageType ) >= creepHealth ) then
            return BOT_ACTION_DESIRE_HIGH, creep
        end
    end

    for _, creep in pairs( alliedCreeps ) do
        local creepHealth = ExtrapolateHealth( creep, attackPoint )
        -- Check if creep can be denied --
        if ( creep:GetActualIncomingDamage( nDamage, eDamageType ) >= creepHealth ) then
            return BOT_ACTION_DESIRE_HIGH, creep
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil
end
function LastHit:execute(target)
    local bot = GetBot()
    bot:Action_AttackUnit( target, false )
end

-- Remove aggro
RemoveAggro = Action:new('Remove aggro')
function RemoveAggro:getDesire()
    local bot = GetBot()
    if ( bot:WasRecentlyDamagedByTower( 1 ) ) then
        return BOT_ACTION_DESIRE_HIGH
    elseif ( bot:WasRecentlyDamagedByCreep( 1 ) ) then
        return BOT_ACTION_DESIRE_MODERATE
    else
        return BOT_ACTION_DESIRE_NONE
    end
end
function RemoveAggro:execute()
    TakeOffAggro()
end

-- Back off
BackOff = Action:new('Back off')
function BackOff:getDesire()
    local bot = GetBot()
    local location = bot:GetLocation()
    local enemyHeroes = bot:GetNearbyHeroes( 1600, true, BOT_MODE_NONE )

    local delta = 0
    for _, hero in pairs( enemyHeroes ) do
        local heroRange = hero:GetAttackRange()
        local currentDistance = GetUnitToUnitDistance( bot, hero )
        if ( currentDistance <= heroRange + 150 ) then
            -- We're almost in attack range of the enemy, retreat.
            -- Always retreat a bit further than needed.
            delta = math.max( heroRange + 150 - currentDistance, delta )
        end
    end

    local fraction = bot:GetHealth() / bot:GetMaxHealth()
    if ( delta > 0 ) then
        if ( fraction < 0.1 ) then
            return BOT_ACTION_DESIRE_ABSOLUTE, delta
        elseif ( fraction < 0.3 ) then
            return BOT_ACTION_DESIRE_VERYHIGH, delta
        elseif ( fraction < 0.5 ) then
            return BOT_ACTION_DESIRE_HIGH, delta
        else
            return BOT_ACTION_DESIRE_MODERATE, delta
        end
    else
        return BOT_ACTION_DESIRE_NONE, delta
    end
end
function BackOff:execute(delta)
    Retreat( delta )
end

-- Approach creep
ApproachCreep = Action:new('Approach creep')
function ApproachCreep:getDesire()
    local bot = GetBot()
    local nDamage = bot:GetAttackDamage()
    local eDamageType = DAMAGE_TYPE_PHYSICAL
    local attackPoint = bot:GetAttackPoint()
    local attackRange = bot:GetAttackRange()
    local nAcqRange = bot:GetAcquisitionRange()
    local movementSpeed = bot:GetCurrentMovementSpeed()
    local alliedCreeps = bot:GetNearbyLaneCreeps( nAcqRange, false )
    local enemyCreeps = bot:GetNearbyLaneCreeps( nAcqRange, true )

    -- Move closer to dying creeps
    for _, creep in pairs ( enemyCreeps ) do
        local timeToReachCreep = (
            math.max( GetUnitToUnitDistance( bot, creep ) - attackRange, 0 ) /
            bot:GetCurrentMovementSpeed()
        )
        local creepHealth = ExtrapolateHealth( creep, timeToReachCreep + attackPoint )
        if ( creep:GetActualIncomingDamage( nDamage, eDamageType ) >= creepHealth ) then
            return BOT_ACTION_DESIRE_MODERATE, creep
        end
    end

    -- Move closer to deny creeps
    for _, creep in pairs ( alliedCreeps ) do
        local timeToReachCreep = (
            math.max( GetUnitToUnitDistance( bot, creep ) - attackRange, 0 ) /
            bot:GetCurrentMovementSpeed()
        )
        local creepHealth = ExtrapolateHealth( creep, timeToReachCreep + attackPoint )
        if ( creep:GetActualIncomingDamage( nDamage, eDamageType ) >= creepHealth ) then
            return BOT_ACTION_DESIRE_MODERATE, creep
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil
end
function ApproachCreep:execute(target)
    local bot = GetBot()
    bot:Action_MoveToUnit( target )
end

-- Creep block
CreepBlock = Action:new('Creep block')
function CreepBlock:getDesire()
    local bot = GetBot()
    local alliedCreeps = bot:GetNearbyLaneCreeps( 1600, false )
    local enemyCreeps = bot:GetNearbyLaneCreeps( 800, true )
    local enemyHeroes = bot:GetNearbyHeroes( 1000, true, BOT_MODE_NONE )
    local enemyTowers = bot:GetNearbyTowers( 1000, true )

    if ( #alliedCreeps > 0 and ( #enemyCreeps + #enemyHeroes + #enemyTowers == 0 ) ) then
        return BOT_ACTION_DESIRE_MODERATE
    else
        return BOT_ACTION_DESIRE_NONE
    end
end
function CreepBlock:execute()
    local bot = GetBot()
    local assignedLane = bot:GetAssignedLane()
    local team = bot:GetTeam()

    local laneCreeps = bot:GetNearbyLaneCreeps( 1600, false )
    local ancient = GetAncient( team )
    local ancientDistance = GetUnitToUnitDistance( bot, ancient )
    local firstCreep = nil
    local firstCreepProgress = 0

    -- Stay ahead of creeps
    for _, creep in pairs( laneCreeps ) do
        local creepProgress = GetUnitToUnitDistance( creep, ancient )

        -- If any creep has already passed us, give up on him
        if ( creepProgress <= ancientDistance and creepProgress > firstCreepProgress ) then
            firstCreepProgress = creepProgress
            firstCreep = creep
        end
    end

    if ( firstCreep ~= nil ) then
        -- Predict the creep's future position and move there to block their way --
        local extrapolatedLocation = firstCreep:GetExtrapolatedLocation( 0.30 )
        bot:Action_MoveToLocation( extrapolatedLocation )
    end
end

-- Attack
Attack = Action:new('Attack')
function Attack:getDesire()
    local bot = GetBot()
    local nearbyHeroes = bot:GetNearbyHeroes( 800, true, BOT_MODE_NONE )
    if ( #nearbyHeroes > 0 ) then
        local bestPossibleTarget = ChooseTarget( nearbyHeroes )
        local tradeQuality = EvaluateTrade( bestPossibleTarget )
        return tradeQuality, bestPossibleTarget
    else
        return BOT_ACTION_DESIRE_NONE, nil
    end
end
function Attack:execute( target )
    local bot = GetBot()
    bot:SetTarget( target )
    AttackMove()
end
