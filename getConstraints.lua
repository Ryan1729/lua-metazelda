local push = table.insert

--options is optional, leave it out for the default dungeon

---- options parameters:
-- isBossRoomLocked (default true): controls whether the boss room requires a key or not
-- generateGoal (default true): controls whether a final room after the boss is generated or not
-- maxKeys (default 0): the amount of keys (and therefore types of locks) that are generated
-- maxRooms (default 42): the total number of rooms that can be generated
-- maxRetries (default 10): the number of retries before a dungeon generation failure

-- intensity algorithm used in generateDungeon is based on
--  Calvin Ashmore's thesis on "Key and Lock Puzzles in Procedural Gameplay"
-- see http://hdl.handle.net/1853/16823 for more details
-- intensityEaseOff (default 0.2): the amount that the difficulty dips down by after each key 
-- intensityEaseOff (default 0.1): this number scales the random amount that intensity changes by 

-- fourWayAdjacency (default false): if this value is truthy then only rooms with coordinates
--  either vertically or horizontally different by exactly 1 are considered adjacent. 
--  overrides any function set in options.getAdjacentRooms and/or the default function
-- getAdjacentRooms (default nil): if this value is truthy it is assumed to be a function and 
-- it will be used instead of the default getAdjacentRooms function which considers all other
-- rooms to be adjacent to every room in the dungeon
-- isAcceptable (default nil): if this value is truthy it is assumed to be a function and 
-- it will be used after the dungeon is completed to check any additional constraints. The
--funtion should return true if the passed in dungeon is acceptable and false otherwise


-- edgeCount (default false): By default, keys are placed in higher intensity rooms 
--  where available. Alternatively, set options.edgeCount to true to put keys at 
--  'dead end' rooms where available

local function getConstraints(options)
  options = options or {}
  
  local constraints = {}

  constraints.isBossRoomLocked = options.isBossRoomLocked ~= false and true or false
  constraints.generateGoal = options.generateGoal ~= false and true or false
  constraints.maxKeys = options.maxKeys or 0
  constraints.maxRooms = options.maxRooms or 42
  constraints.maxRetries = options.maxRetries or 10
  
  constraints.intensityEaseOff = options.intensityEaseOff or 0.2
  constraints.intensityGrowthJitter = options.intensityGrowthJitter or 0.1

  constraints.initialRooms = {1, 2, 3}

  function constraints.getCoords(id)
    local result = {}

    result.x = id % 6
    result.y = math.floor(id / 7) + 1

    return result
  end
  
  
  --returns a list of IDs of adjacent rooms
  if options.fourWayAdjacency then
    
    --checking if the two coordinates are within 1 vertically or horizontally
    local function coordsAreAdjacent(coord1, coord2)
      return (coord1.x == coord2.x and (coord1.y == coord2.y + 1 or coord1.y == coord2.y - 1))
          or (coord1.y == coord2.y and (coord1.x == coord2.x + 1 or coord1.x == coord2.x - 1)) 
    end
    
    constraints.getAdjacentRooms = function (id)
        local result = {}
        local coords = constraints.getCoords(id)
        
        for i = 1, constraints.maxRooms do
          local currentCoords = constraints.getCoords(i)
          
          if coordsAreAdjacent(coords, currentCoords) then
            push(result, i)
          end
        end
        return result
      end
  else
    if options.getAdjacentRooms then
      constraints.getAdjacentRooms = options.getAdjacentRooms
    else
      --all other rooms are adjacent to every room
      constraints.getAdjacentRooms = function (id)
        local result = {}
        for i = 1, constraints.maxRooms do
          if i ~= id then
            push(result, i)
          end
        end
        return result
      end
      
    end
  end
  function constraints.roomCanFitItem()
    return true
  end
  
  --check any additional constraints
  if options.isAcceptable then
    constraints.isAcceptable = options.isAcceptable
  else
    function constraints.isAcceptable(dungeon)
      return true
    end
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

return getConstraints