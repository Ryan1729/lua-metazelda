--convert the dungeon to Trivial Graph Format
--for debugging purposes only
local function getTGF(dungeon)
  --might be broken by changes to dungeon format
  local result = ""
  
  for _, room in ipairs(dungeon) do
    result = result .. "v" .. room.id .. " " .. room.id .. "," .. (room.item or "") .. "\n"
  end
  
  result = result .. "#\n"
  
  for _, room in ipairs(dungeon) do
    for _, edge in ipairs(room.edges) do
      result = result .. "v" .. room.id .. " v" .. edge.targetRoomId .. " " .. edge.condition.keyLevel .. "\n"
    end
  end
  
  return result
end

return getTGF