local tablex = require("pl.tablex")
local Set = require("pl.Set")
local rooms = require("lua-metazelda.rooms")
local conditions = require("lua-metazelda.conditions")

local push = table.insert

--move to constraints module later
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

  

  return constraints
end

local function getEntranceRoom(constraints)
  -- pick one of the possible initial rooms and
  -- make it the start room

  local id = constraints.initialRooms[math.random(1, #constraints.initialRooms)]

  return rooms.make(id, constraints.getCoords(id), nil, "start", conditions.make())
end

local function roomCount(dungeon)
  --if rooms are sparsely stored, this will need to change
  return #dungeon
end

local function getRoomFromDungeon(dungeon, roomId)
  --one reason to change to sparse rep, possible duplicate ids!
  for _, v in ipairs(dungeon) do
    if v.id == roomId then
      return v
    end
  end

  return nil
end

local function keyCount(dungeon)
  --might be an idea to keep a copy of this, rather than having to make it each time
  local seenAlready = Set{}
  
  for _, v in ipairs(dungeon) do
    if not seenAlready[v.keyLevel] then
      seenAlready = seenAlready + Set{v.keyLevel}
    end
  end
  
  return Set:len(seenAlready)
end

local function getRoomsFromKeyLevel(dungeon, keyLevel)
  --if rooms are sparsely stored, this will need to change
  --might be an idea to keep a copy of this, rather than having to make it each time
  local result = {}

  for _, v in ipairs(dungeon) do
    if v.condition.keyLevel == keyLevel then
      push(result, v)
    end
  end

  return result
end

local function addRoom (dungeon, room)
  --should the key into dungeon be the room id?
  push(dungeon, room)
  return dungeon
end

-----maybe move into utils module?
--Fisher-Yates shuffle
--found at https://coronalabs.com/blog/2014/09/30/tutorial-how-to-shuffle-table-items/
local function shuffleTable( t )
  local rand = math.random 
  assert( t, "shuffleTable() expected a table, got nil" )
  local iterations = #t
  local j

  for i = iterations, 2, -1 do
    j = rand(i)
    t[i], t[j] = t[j], t[i]
  end
end

local function chooseFreeEdge(room, constraints, dungeon)
  local adjacentRooms = constraints.getAdjacentRooms(room.id)

  for _, id in ipairs(adjacentRooms) do
    if not getRoomFromDungeon(dungeon, id) then
      return id
    end
  end

  return nil
end

local function chooseRoomWithFreeEdge(roomList, constraints, dungeon)
  --we only need a shallow copy here, in fact, 
  --since rooms reference other rooms cyclically,
  --a deep copy causes a stack overflow
  local rooms = tablex.copy(roomList)

  shuffleTable(rooms)

  --this assumes the roomList is an array
  for _, currentRoom in ipairs(rooms) do
    local freeEdge = chooseFreeEdge(currentRoom, constraints, dungeon)
    if freeEdge then
      return currentRoom
    end
  end

  return nil
end

local function placeRooms(dungeon, constraints, levels, roomsPerLock)
  local keyLevel = 0
  local latestKey = 0
  local condition = conditions.make()

  local usableKeys = constraints.maxKeys
  if constraints.isBossRoomLocked then
    usableKeys = usableKeys - 1
  end

  --Loop to place rooms and link them
  while roomCount(dungeon) < constraints.maxRooms do

    local doLock = false;

    -- Decide whether we need to place a new lock
    -- (Don't place the last lock, since that's reserved for the boss)
    if #getRoomsFromKeyLevel(dungeon, keyLevel) >= roomsPerLock and keyLevel < usableKeys then
      latestKey = keyLevel
      keyLevel = keyLevel + 1
      condition = conditions.addKeyLevel(condition, latestKey)
      doLock = true
    end

    -- Find an existing room with a free edge:
    local parentRoom = nil
    if not doLock and math.random(10) > 1 then
      parentRoom = chooseRoomWithFreeEdge(getRoomsFromKeyLevel(dungeon, keyLevel), constraints, dungeon)
    end

    if parentRoom == nil then
      parentRoom = chooseRoomWithFreeEdge(getRoomsFromKeyLevel(dungeon, keyLevel), constraints, dungeon)
      doLock = true;
    end

    if parentRoom == nil then
      error("no free edge found!")
      --return false, dungeon
    end

    -- Decide which direction to put the new room in relative to the
    -- parent
    local nextId = chooseFreeEdge(parentRoom, constraints, dungeon)
    local room = rooms.make(nextId, constraints.getCoords(nextId), parentRoom, nil, condition)

    -- Add the room to the dungeon
    assert (getRoomFromDungeon(dungeon, room.id) == nil, "room already used!")

    dungeon = addRoom(dungeon, room)
    assert(type(room.condition) == "table")
    rooms.addChild(parentRoom, room)
    rooms.link(parentRoom, room, doLock and conditions.make(latestKey) or nil);

    --levels.addRoom(keyLevel, room);
  end

  return true, dungeon 
end

local function roomIsNotEmpty(room, parent)
  return parent == nil or
    #parent.children ~= 1 or
    room.item ~= nil or
    not conditions.implies(parent.condition, room.condition)
end

local function roomCouldBeGoalRoom(room, constraints)
  if #room.children > 0 or room.item ~= nil then
    return false
  end
  
  local parent = room.parent
  if roomIsNotEmpty(room, parent) then
    return false
  end
  
  if constraints and constraints.roomCanFitItem then
    if constraints.generateGoal then
      if not constraints.roomCanFitItem(room.id, "goal") or
        not constraints.roomCanFitItem(parent.id, "boss") then 
        return false
      end
    else
      if not constraints.roomCanFitItem(room.id, "boss") then
        return false
      end
    end
  end

  return true
end

local function placeBossGoalRooms (dungeon, constraints)
  local possibleGoalRooms = {}

  for _, room in ipairs(dungeon) do
    if roomCouldBeGoalRoom(room, constraints) then
      push(possibleGoalRooms, room)
    end
  end
  
  if #possibleGoalRooms <= 0 then
    error("No place for the goal room!")
  end
  
  local goalRoom = possibleGoalRooms[math.random(1, #possibleGoalRooms)]
  local bossRoom = goalRoom.parent
  
  --TODO: check earlier and save some processing?
  if not constraints.generateGoal then
    bossRoom = goalRoom
    goalRoom = nil
  end
  
  if goalRoom ~= nil then 
    goalRoom.item = "goal"
  end
  bossRoom.item = "boss"
  
  if constraints.isBossRoomLocked then
    --local oldKeyLevel = bossRoom.condition.keyLevel
      local newKeyLevel = math.min(keyCount(dungeon), constraints.maxKeys)
    
--    local oldKeyLevelRooms = getRoomsFromKeyLevel(dungeon, oldKeyLevel)
--    if goalRoom ~= nil then
--      oldKeyLevelRooms.remove(goalRoom)
--    end
--    oldKeyLevelRooms.remove(bossRoom);
    
--    if goalRoom ~= nil levels.addRoom(newKeyLevel, goalRoom);
--    levels.addRoom(newKeyLevel, bossRoom);
    
    local bossKey = conditions.make(newKeyLevel-1)
    local precond = conditions.add(bossRoom.condition, bossKey);
    bossRoom.condition = precond
    if goalRoom ~= nil then
      goalRoom.condition = precond
    end
    
    if newKeyLevel == 0 then
      rooms.link(bossRoom.parent, bossRoom)
    else
      rooms.link(bossRoom.parent, bossRoom, bossKey)
    end
    
    if goalRoom ~= nil then
      rooms.link(bossRoom, goalRoom);
    end
    
  end
  
  return dungeon
end

--find the first room in the dungeon that has the same item value as the one passed in
local function findRoomWithItem(item, dungeon)
  for _, room in ipairs(dungeon) do
    if room.item == item then
      return room
    end
  end
  return nil
end

--Returns a path from the goal to the dungeon entrance, along the 'parent'
--relations.
local function getSolutionPath(dungeon)
  local solution = {};
  local room = findRoomWithItem("goal", dungeon)
  while (room ~= nil) do
      push(solution, room)
      room = room.parent;
  end
  return solution;
end

local function removeDescendantsFromList(roomList, room)
  rooms.remove(roomList, room)
  for _, child in ipairs(room.children) do
      roomList = removeDescendantsFromList(roomList, child);
  end
  return roomList
end

-- Adds extra conditions to the given room's preconditions and all
-- of its descendants.
local function addConditionToDescendants(room, cond)
  room.condition = conditions.add(room.condition, cond)
  for _, child in ipairs(room.children) do
      addConditionToDescendants(child, cond);
  end
end

--Randomly locks descendant rooms of the given room with
--edges that require the switch to be in the given state.
local function switchLockChildRooms(room, givenState, dungeon)
  local anyLocks = false;
  local state = givenState ~= "either" 
          and givenState 
          or (math.random(1,2) > 1
              and "on"
              or "off");
  local currentCondition = conditions.make(nil, state)
  
  for _, edge in ipairs(room.edges) do
    local neighborId = edge.targetRoomId
    local nextRoom = getRoomFromDungeon(dungeon, neighborId)
    if (tablex.find(room.children, nextRoom) ~= nil) then
      if (conditions.isDefault(rooms.getEdge(room, neighborId).condition) --[[and math.random() < 0.25]]) then
          rooms.link(room, nextRoom, currentCondition)
          addConditionToDescendants(nextRoom, currentCondition)
          anyLocks = true;
      else
          anyLocks = anyLocks or switchLockChildRooms(nextRoom, currentCondition.switchState, dungeon)
      end
      
      if (givenState == "either") then
          currentCondition = conditions.invertSwitchState(currentCondition);
      end
    end
  end
  return anyLocks;
end


local function placeSwitches(constraints, dungeon)
  if constraints.maxSwitches and constraints.maxSwitches <= 0 then 
    return dungeon
  end

  local solution = getSolutionPath(dungeon);

  for attempt = 1, 10 do
    
    local rooms = tablex.copy(dungeon)
    shuffleTable(rooms);
    shuffleTable(solution);
    
    -- Pick a base room from the solution path so that the player
    -- will have to encounter a switch-lock to solve the dungeon.
    local baseRoom = nil;
    for _, room in ipairs(solution) do
        if #room.children > 1 and room.parent ~= nil then
          baseRoom = room;
          break;
        end
    end
    if baseRoom == nil then
      error("no base room found in placeSwitches")
    end
--    Condition baseRoomCond = baseRoom.getPrecond();

    local potentialSwitchRooms = removeDescendantsFromList(rooms, baseRoom);

    local switchRoom = nil
    for _, room in ipairs(potentialSwitchRooms) do
        if (room and room.item == nil and
                conditions.implies(baseRoom.condition, room.condition) and
                constraints.roomCanFitItem(room.id, "switch")) then
          switchRoom = room
          break
        end
    end
    
    if (switchRoom ~= nil) then
      if (switchLockChildRooms(baseRoom, "either", dungeon)) then
          switchRoom.item = "switch"
          return dungeon;
      end
    end
  end
  error("took too many tries to place switches")
end

local function generateHelper (constraints)
  local dungeon

  local roomsPerLock

  if constraints.maxKeys > 0 then
    roomsPerLock = constraints.maxRooms / constraints.maxKeys
  else
    roomsPerLock = constraints.maxRooms;
  end

  local roomsPlaced = false
  while not roomsPlaced do
    dungeon = {};

    -- Create the entrance to the dungeon:
    dungeon = addRoom(dungeon, getEntranceRoom(constraints))

    roomsPlaced, dungeon = placeRooms(dungeon, constraints, levels, roomsPerLock)

    if not roomsPlaced then 
      --We can run out of rooms when the constraints are too tight
      print("Ran out of rooms. roomsPerLock was " .. roomsPerLock)
      roomsPerLock = math.floor( roomsPerLock * constraints.getMaxKeys / constraints.getMaxKeys + 1 )
      print("roomsPerLock is now " .. roomsPerLock)

      if roomsPerLock <= 0 then
        error("Failed to place rooms. Have you forgotten to disable boss-locking?")
      end
    end
  end

  dungeon = placeBossGoalRooms(dungeon, constraints);

--  Place switch and the locks that require it:
  dungeon = placeSwitches(constraints, dungeon)

--  Make the dungeon less tree-like:
--  graphify();

--  computeIntensity(levels);

--  -- Place the keys within the dungeon:
--  placeKeys(levels);

--  if (levels.keyCount()-1 != constraints.getMaxKeys())
--    throw new RetryException();


  if (not constraints.isAcceptable) or constraints.isAcceptable(dungeon) then
    return dungeon
  else
    error("Unacceptable Dungeon!")
  end
end

local function generateDungeon (constraints, seed)
  constraints = constraints or getDefaultConstraints()

  seed = seed or os.time()

  math.randomseed(seed)

  local retries = 0

  while(retries < constraints.maxRetries) do

    local status, dungeon = pcall(generateHelper, constraints)

    if status then
      return dungeon
    else
      print(dungeon)
      retries = retries + 1
    end

  end

  --should this raise an error instead?
  return nil
end

return generateDungeon