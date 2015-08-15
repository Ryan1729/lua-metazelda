local rooms = {}

local push = table.insert

function rooms.make(id, coords, parent, item, keyLevel)
  local room = {}
  
  room.id = id
  room.coords = coords
  room.parent = parent
  room.item = item
  room.keyLevel = keyLevel or 0
  room.edges = {}
  room.children = {}
  
  return room
end

function rooms.setKeyLevel(room, keyLevel)
  room.keyLevel = math.max(room.keyLevel, keyLevel)
  
  return room
end

function rooms.addChild(room, child)
  push(room.children, child)
  
  return room
end

function rooms.getEdge(room, targetRoomId)
  for _, e in ipairs(room.edges) do
    if e.id == targetRoomId then
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
  rooms.setEdge(room1, room2.id, condition or nil)
  
end

function rooms.link(room1, room2, condition)
  rooms.linkOneWay(room1, room2, condition or nil);
  rooms.linkOneWay(room2, room1, condition or nil);
end

    
return rooms