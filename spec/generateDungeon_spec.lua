local generateDungeon = require(".generateDungeon")

describe("generateDungeon tests", function()

  describe("no args check", function()
    local dungeon = generateDungeon()
    
    it("has no disconnected rooms", function()
      for _, room in ipairs(dungeon) do
        assert.is_true(#room.edges >= 1)
      end
    end)

  end)

--  describe("a nested block", function()
--    describe("can have many describes", function()
--      -- tests
--    end)
--  end)

--  -- more tests pertaining to the top level
end)