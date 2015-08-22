# lua-metazelda
puzzle genetration in lua based on https://github.com/tcoxon/metazelda

requires [Penlight](https://github.com/stevedonovan/Penlight)

Still WIP



# Usage

## requiring
```lua
local generateDungeon = require "lua-metazelda.generateDungeon"
```

uses the [current_folder](http://kiki.to/blog/2014/04/12/rule-5-beware-of-multiple-files/) trick, but should hopefully "just work!"  

## generateDungeon([constraints], [seed])

* constraints: override the default constraints object
* seed: set a seed for the dungeon to be generated from (uses os.time() otherwise)

```lua
-- a dungeon using the default constraints
local defaultDungeon = generateDungeon()
```
