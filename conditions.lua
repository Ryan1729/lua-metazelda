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



function conditions.add(condition1, condition2) 
  local result = {}
  
  if (condition1.switchState == "either") then
    result.switchState = condition2.switchState
  else
    assert (condition1.switchState == condition2.switchState, "incompatible conditions added togther")
  end
  
  result.keyLevel = getCombinedKeyLevel(condition1.keyLevel, condition2.keyLevel)
  
  return result
end

function conditions.implies(condition1, condition2) 
  return condition1.keyLevel >= condition2.keyLevel and
          (condition1.switchState == condition2.switchState or
          condition2.switchState == "either")
end

return conditions