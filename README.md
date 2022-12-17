# TPScript

***Please do not take this project seriously, It was originally intended for a small joke.*** Any contributions are welcome, however, I won't pay much attention to them anymore.

A ~~really bad~~ scripting language that can access Lua globals.

Example that runs in Roblox Luau:
```
callset part Instance.new Part workspace
callset v3 Vector3.new 0 20 0

setindex part Anchored $true

add i 0
::loop
add i 0.1
callset t math.sin i
callset r math.cos i
set x v3.X
set z v3.Z
set y v3.Y
mul t 10
mul r 10
add y t
add x r
callset v Vector3.new x y z
setindex part Position v
call wait 0.1
jmp loop
```
Semicolons are also optional.
```
set a 10;
add a 5
log a;
cmt Expected output: 15
```

## Notes

If your Lua enviroment does not have a split function, the interpreter will attempt to add one to the string library and will error if it fails.
