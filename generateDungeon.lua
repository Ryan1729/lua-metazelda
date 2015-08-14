local roomMaker = require("lua-metazelda.roomMaker")

local push = table.insert

local function getDefaultConstraints()
  local constraints = {}
  
  constraints.maxKeys = 0
  constraints.maxRooms = 42
  
  constraints.initialRooms = {1, 2, 3}
  
  function constraints.getCoords(id)
    local result = {}
    
    result.x = id % 6
    result.y = id % 7
    
    return result
  end
  
  return constraints
end

local function getEntranceRoom(constraints)
  -- pick one of the possible initial rooms and
  -- make it the start room
          
  local id = constraints.initialRooms[math.random(1, #constraints.initialRooms)]
  
  return roomMaker(id, constraints.getCoords(id), "start")
end

local function placeRooms(dungeon, levels, roomsPerLock)
  --placeholder
  
  return true, dungeon 
end

local function generateDungeon (constraints, seed)
  constraints = constraints or getDefaultConstraints()
  
  seed = seed or os.time()
  
  math.randomseed(seed)
  
  local result = {}
  
  local roomsPerLock
  if constraints.maxKeys > 0 then
    roomsPerLock = constraints.maxRooms / constraints.maxKeys
  else
    roomsPerLock = constraints.maxRooms;
  end
  
  local roomsPlaced = false
  while not roomsPlaced do
    local dungeon = {};
    
    -- Create the entrance to the dungeon:
    --    should the key into dungeon be the room id?
    push(dungeon, getEntranceRoom(constraints))
    
    roomsPlaced, dungeon = placeRooms(dungeon, levels, roomsPerLock)
    
    if not roomsPlaced then 
      --We can run out of rooms when the constraints are too tight
      print("Ran out of rooms. roomsPerLock was " .. roomsPerLock)
      roomsPerLock = floor( roomsPerLock * constraints.getMaxKeys / constraints.getMaxKeys + 1 )
      print("roomsPerLock is now " .. roomsPerLock)
      
      if roomsPerLock <= 0 then
        error("Failed to place rooms. Have you forgotten to disable boss-locking?")
      end
    end
  end
  
  return result
end

return generateDungeon