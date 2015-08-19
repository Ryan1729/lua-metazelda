local tablex = require("pl.tablex")
local conditions = {}

function conditions.make(keyLevel, switchState)
  local result = {}
  
  result.keyLevel = keyLevel or 0
  result.switchState = switchState or "either"
  
  return result
end

function conditions.isDefault(condition)
  return condition.keyLevel == 0 and condition.switchState == "either"
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
    result.switchState = condition2.switchState
  end
  
  result.keyLevel = getCombinedKeyLevel(condition1.keyLevel, condition2.keyLevel)
  
  return result
end

function conditions.implies(condition1, condition2) 
  return condition1.keyLevel >= condition2.keyLevel and
          (condition1.switchState == condition2.switchState or
          condition2.switchState == "either")
end

function conditions.invertSwitchState(condition)
  local result = {}
  
  if condition.switchState == "on" then
    result.switchState = "off"
  elseif condition.switchState == "off" then
    result.switchState = "on"
  else
    result.switchState = "either"
  end

  result.keyLevel = condition.keyLevel
  
  return result
end

function conditions.singleSymbolDifference(condition1, condition2) 
  -- If the difference between condition1 and condition2 can be made up by obtaining
  -- a single new symbol, condition1 returns the symbol. If multiple or no
  -- symbols are required, returns nil.
  
  assert(condition1.keyLevel)
  assert(condition1.switchState)
  assert(condition2.keyLevel)
  assert(condition2.switchState)
  
  if (tablex.deepcompare(condition1, condition2)) then
    return nil
  end
  
  if (condition1.switchState == condition2.switchState) then
    return conditions.make(getCombinedKeyLevel(condition1.keyLevel, condition2.keyLevel)-1);
  else
    -- Multiple symbols needed
    if (condition1.keyLevel ~= condition2.keyLevel) then
      return nil;
    end
    
    --we know condition1.switchState ~= condition2.switchState
    if (condition1.switchState ~= "either" and condition2.switchState ~= "either") then
      return nil;
    end
    
    local nonEither = condition1.switchState ~= "either"
            and condition1.switchState
            or condition2.switchState
    
    return conditions.make(nil, nonEither)
  end
end

return conditions