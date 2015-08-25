# lua-metazelda
puzzle genetration in lua based on https://github.com/tcoxon/metazelda

requires [Penlight](https://github.com/stevedonovan/Penlight)

# Usage

## requiring
```lua
local generateDungeon = require "lua-metazelda.generateDungeon"
```

uses the [current_folder](http://kiki.to/blog/2014/04/12/rule-5-beware-of-multiple-files/) trick, but should hopefully "just work!"  

## generateDungeon([constraints], [seed])

* constraints: override the default constraints object, see getConstraints.lua for options
* seed: set a seed for the dungeon to be generated from (uses os.time() otherwise)

```lua
-- a dungeon using the default constraints
local defaultDungeon = generateDungeon()
```

A dungeon is an array of rooms in an unspecified order, each room's ```children``` property is an array containing 0 or more references to other rooms. again in no specified order.
Each room has an id number to help distinguish them. 

```lua
--example room
{
	children = {},
	condition = {
	  keyLevel = 1,
	  switchState = "off"
	},
	coords = {
	  x = 0,
	  y = 2
	},
	edges = {
	  {
		condition = {
		  keyLevel = 1,
		  switchState = "either"
		},
		targetRoomId = 7
	  }
	},
	id = 6,
	intensity = 0.65334643486786,
	item = "goal"
}
```
