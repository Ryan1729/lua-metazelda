local generateDungeon = require(".generateDungeon")
local getConstraints = require(".getConstraints")

--TODO: refactor so these local functions aren't duplicated here?

--checking if the two coordinates are within 1 vertically or horizontally
local function coordsAreAdjacent(coord1, coord2)
  return (coord1.x == coord2.x and (coord1.y == coord2.y + 1 or coord1.y == coord2.y - 1))
      or (coord1.y == coord2.y and (coord1.x == coord2.x + 1 or coord1.x == coord2.x - 1)) 
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

-----------------------------------------------------------------

local basicTests = function(dungeon)
  return function ()
     it("has no disconnected rooms", function()
      for _, room in ipairs(dungeon) do
        assert.is_true(#room.edges >= 1)
      end
    end)
  
    it("has intensity set on all rooms", function()
      for _, room in ipairs(dungeon) do
        assert.is_true(type(room.intensity) == "number")
      end
    end)
  
    it("has vaild condition set on all rooms", function()
      for _, room in ipairs(dungeon) do
        assert.is.truthy(room.condition)
        assert.is_true(type(room.condition.keyLevel) == "number")
        assert.is_true(type(room.condition.switchState) == "string")
      end
    end)
  
  end
end

local function goalRoomTest(dungeon)
  it("has one goal room with only one edge", function()
    local goalRoom = nil
    for _, room in ipairs(dungeon) do
      if room.item == "goal" then
        if goalRoom == nil then
          goalRoom = room
        else
          error("multiple goals")
        end
      end
    end
    
    assert.are.equal(1, #goalRoom.edges)
  end)
end

local function fourWayTests(fourWayDungeon)
  return function()
    it("has only 4 way adjacent rooms", function()
        
      for _, room in ipairs(fourWayDungeon) do
        for _, edge in ipairs(room.edges) do
          local targetRoomCoords = getRoomFromDungeon(fourWayDungeon, edge.targetRoomId).coords
          
          assert.is_true(coordsAreAdjacent(room.coords, targetRoomCoords))
        end
      end

    end)

    it("has at most 4 edges per room", function()
        
      for _, room in ipairs(fourWayDungeon) do
        
        assert.is_true(#room.edges <= 4)
        
      end

    end)
  end
end

describe("generateDungeon tests", function()

  local defaultDungeon = generateDungeon()
  describe("default dungeon", basicTests(defaultDungeon))
  describe("default dungeon", goalRoomTest(defaultDungeon))
  
  local maxKeys = 10
  local tenKeyDungeon = generateDungeon(getConstraints({maxKeys = maxKeys}))
  describe("ten Key dungeon", basicTests(tenKeyDungeon))
  describe("ten Key dungeon", goalRoomTest(tenKeyDungeon))
  describe("ten Key dungeon", function()
    it("has a level ten key", function()
      
      local highestSeenKey = 0
      for _, room in ipairs(tenKeyDungeon) do
        if (room.condition.keyLevel > highestSeenKey) then
          highestSeenKey = room.condition.keyLevel
        end
      end
      
      assert.are.equal(maxKeys, highestSeenKey)
      
    end)
    
  end)
  
  local noGoalDungeon = generateDungeon(getConstraints({generateGoal = false}))
  describe("no goal room dungeon", basicTests(noGoalDungeon))
  describe("no goal room dungeon", function()
    it("has no goal", function()
        
      for _, room in ipairs(noGoalDungeon) do
        assert.is_true(room.item ~= "goal")
      end

    end)
    
  end)

  local fourWayDungeon = generateDungeon(getConstraints({fourWayAdjacency= true}))
    
  describe("4 way constrained dungeon", basicTests(fourWayDungeon))
  describe("4 way constrained dungeon", goalRoomTest(fourWayDungeon))
  describe("4 way constrained dungeon", fourWayTests(fourWayDungeon))

--this dungeon once was the only known case where a problem occured
  local problemFourWayDungeon = generateDungeon(getConstraints({fourWayAdjacency = true}), 1234)
  
  describe("problem 4 way constrained dungeon", basicTests(problemFourWayDungeon))
  describe("problem 4 way constrained dungeon", goalRoomTest(problemFourWayDungeon))
  describe("problem 4 way constrained dungeon", fourWayTests(problemFourWayDungeon))

  local bossUnlockedDungeon = generateDungeon(getConstraints({isBossRoomLocked = false}))
    
  describe("boss Unlocked dungeon", basicTests(bossUnlockedDungeon))
  describe("boss Unlocked dungeon", goalRoomTest(bossUnlockedDungeon))

  local rejectAtLeastOnce = (function()
    local timesRan = 0
    
    return function()
      timesRan = timesRan + 1
      
      if timesRan <= 1 then 
        return false
      else
        -- make it more and more likely to finally accept
        return math.random(1, timesRan) > 1
      end
      
    end
    
  end)()
  
  local rejectedDungeon = generateDungeon(getConstraints({isAcceptable = rejectAtLeastOnce}))
    
  describe("rejected dungeon", basicTests(rejectedDungeon))
  describe("rejected dungeon", goalRoomTest(rejectedDungeon))


end)