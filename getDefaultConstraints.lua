local push = table.insert

local function getDefaultConstraints()
  local constraints = {}

  constraints.isBossRoomLocked = true
  constraints.generateGoal = true
  constraints.maxKeys = 0
  constraints.maxRooms = 42
  constraints.maxRetries = 10

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

  return constraints
end

return getDefaultConstraints