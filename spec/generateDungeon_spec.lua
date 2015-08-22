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

describe("generateDungeon tests", function()

  describe("default dungeon", basicTests(generateDungeon()))
  
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
  describe("4 way constrained dungeon", function()
    it("has only 4 way adjacent rooms", function()
        
      for _, room in ipairs(fourWayDungeon) do
        for _, edge in ipairs(room.edges) do
          local targetRoomCoords = getRoomFromDungeon(fourWayDungeon, edge.targetRoomId).coords
          
          assert.is_true(coordsAreAdjacent(room.coords, targetRoomCoords))
        end
      end

    end)
  end)


end)