# TPScript

A ~~really bad~~ work-in-progress scripting language that can access Lua globals.

Example that runs inside of Roblox Luau:
```
callset part Instance.new Part workspace
callset v3 Vector3.new 0 20 0

setindex part Anchored $true

add y 0
::loop
add y 0.1
callset t math.sin y
callset r math.cos y
set x v3.X
set z v3.Z
set u v3.Y
mul t 10
mul r 10
add u t
add x r
callset v Vector3.new x u z
setindex part Position v
call wait 0.1
jmp loop
```
Semicolons are also optional.
```
set a 10;
add a 5
log a;
```
```
15
```

## Notes

**Any code from before [this commit](https://github.com/headsmasher8557/tpscript/commit/7863109923f0b695d93e26032199756caf135819) will NOT run on Lua 5.1, but will run on Luau.** You shouldn't worry about compatibility after the commit, though. (This was just an oversight!)

If your Lua enviroment does not have a split function, the interpreter will attempt to add one to the string library and will error if it fails.
