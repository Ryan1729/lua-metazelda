local conditions = {}

function conditions.make(keyLevel, switchState)
  local result = {}
  
  result.keyLevel = keyLevel or 0
  result.switchState = switchState or "either"
  
  return result
end

local getCombinedKeyLevel= math.max

function conditions.addKeyLevel(condition, keyLevel)
  condition.keyLevel = getCombinedKeyLevel(condition.keyLevel, keyLevel)
  
  return condition
end



function conditions.add(cond1, cond2) 
  local result = {}
  
  if (cond1.switchState == "either") then
    result.switchState = cond2.switchState
  else
    assert (cond1.switchState == cond2.switchState, "incompatible conditions added togther")
  end
  
  result.keyLevel = getCombinedKeyLevel(cond1.keyLevel, cond2.keyLevel)
  
  return result
end

return conditions