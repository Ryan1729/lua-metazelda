local conditions = require("lua-metazelda.conditions")
local rooms = {}

local push = table.insert

function rooms.make(id, coords, parent, item, condition)
  local room = {}
  
  room.id = id
  room.coords = coords
  room.parent = parent
  room.item = item
  room.condition = condition or conditions.make()
  room.edges = {}
  room.children = {}
  
  return room
end

function rooms.setKeyLevel(room, keyLevel)
  room.condition = conditions.addKeyLevel(room, keyLevel)
  
  return room
end

function rooms.addChild(room, child)
  push(room.children, child)
  
  return room
end

function rooms.getEdge(room, targetRoomId)
  for _, e in ipairs(room.edges) do
    if e.targetRoomId == targetRoomId then
      return e
    end
  end
  return nil
end

function rooms.setEdge(room, targetRoomId, condition)
  local e = rooms.getEdge(room, targetRoomId)
  
  if e ~= nil then
    e.condition = condition;
  else
    e = {targetRoomId = targetRoomId, condition = condition};
    push(room.edges, e)
  end
  
  return e
end

function rooms.linkOneWay(room1, room2, condition)
  --TODO: check that the rooms are in the dungeon first?
  rooms.setEdge(room1, room2.id, condition or conditions.make())
  
end

function rooms.link(room1, room2, condition)
  rooms.linkOneWay(room1, room2, condition or conditions.make());
  rooms.linkOneWay(room2, room1, condition or conditions.make());
end

    
return rooms