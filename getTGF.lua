--convert the dungeon to Trivial Graph Format
--for debugging purposes only

-- options.coords: if true then coords will be shown on the node label rather
--  than the item number
local function getTGF(dungeon, options)
  --might be broken by changes to dungeon format
  options = options or {}
  
  local result = ""
  
  for _, room in ipairs(dungeon) do
    local nodeData = options.coords and "(" .. room.coords.x .. ", " .. room.coords.y .. ")" or (room.item or "")
    result = result .. "v" .. room.id .. " " .. room.id .. "," .. nodeData .. "\n"
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