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

function rooms.link(room1, room2, cond)
  linkOneWay(room1, room2, cond or nil);
  linkOneWay(room2, room1, cond or nil);
end

function rooms.linkOneWay(room1, room2, cond)
  --TODO: chack that the rooms are in the dungeon first?
  room1.setEdge(room2.id, cond or nil);
  --rooms.setEdge(room1, room2, cond or nil)
  --or rooms.setEdge(room1.id, room2.id, cond or nil) ?
  
end
    
return rooms