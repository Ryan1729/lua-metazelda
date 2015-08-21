local push = table.insert

--options is optional

-- By default, keys are placed in higher intensity rooms where available.
-- Alternatively, set options.edgeCount to put keys at 'dead end' rooms
-- where available

local function getDefaultConstraints(options)
  options = options or {}
  
  local constraints = {}

  constraints.isBossRoomLocked = true
  constraints.generateGoal = true
  constraints.maxKeys = 0
  constraints.maxRooms = 42
  constraints.maxRetries = 10
  constraints.intensityEaseOff = 0.2
  constraints.intensityGrowthJitter = 0.1

  constraints.initialRooms = {1, 2, 3}

  function constraints.getCoords(id)
    local result = {}

    result.x = id % 6
    result.y = id % 7

    return result
  end

  --returns a list of IDs of adjacent rooms
  function constraints.getAdjacentRooms(id)
    --TODO: make this make sense
    local result = {}
    for i = 1, constraints.maxRooms do
      if i ~= id then
        push(result, i)
      end
    end

    return result
  end

  function constraints.roomCanFitItem()
    return true
  end
  
  --check any additional constraints
  function constraints.isAcceptable(dungeon)
    return math.random(1,10) > 3--true
  end

  function constraints.edgeGraphifyProbability(id, nextId) 
    return 0.2
  end

  if options.edgeCount then
    constraints.keyChanceSorter = function(room1, room2)
      return #room1.edges < #room2.edges
    end
  else
    constraints.keyChanceSorter = function(room1, room2)
      return room1.intensity > room2.intensity
    end
  end
  
  return constraints
end

return getDefaultConstraints