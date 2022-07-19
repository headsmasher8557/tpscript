local tpscript = {}

if (_VERSION ~= "Luau") or (not string.split) then
	local canwrite = pcall(function()
		string.split = "abc" -- setting to random thing just to see if we can write
	end)
	if canwrite then
		function string:split(sep)
			if not sep then
				return self
			end
			local t={}
			for str in string.gmatch(self, "([^"..sep.."]+)") do
				table.insert(t, str)
			end
			return t
		end
	else
		error("Can't add split function, string library is read-only")
	end
end

function tpscript.getthing(env, str)
	local token = str:split'.'
	local tar = getfenv(0)
	for i,v in pairs(token) do
		if tar[v] then
			tar = tar[v]
		end
	end
	if tar == getfenv(0) then
		tar = env
		for i,v in pairs(token) do
			if tar[v] then
				tar = tar[v]
			end
		end
		if tar == env then
			tar = nil
		end
	end
	if str:sub(1, 1) == "$" and not tar then
		local e = str:sub(2, #str)
		local isbool = e == "true" or e == "false"
		if isbool then
			return e == "true"
		else 
			return nil
		end
	end
	return tar or env[str]
end

tpscript.instructions = {
	add = function(env, var, val)
		local a = env[var] or tonumber(var) or 0
		local b = env[val] or tpscript.getthing(env, val) or tonumber(val)

		if env[var] then
			if tonumber(env[var]) then
				a = tonumber(env[var])
			end
		end

		if env[val] then
			if tonumber(env[val]) then
				b = tonumber(env[val])
			end
		end

		env[var] = a + b
	end,
	sub = function(env, var, val)
		if not env[var] then
			env[var] = 0
		end
		env[var] -= tonumber(val) or env[val] or val
	end,
	mul = function(env, var, val)
		if not env[var] then
			env[var] = 0
		end
		env[var] *= tonumber(val) or env[val] or val
	end,
	div = function(env, var, val)
		if not env[var] then
			env[var] = 0
		end
		env[var] /= tonumber(val) or env[val] or val
	end,
	copy = function(env, var, var1)
		if not env[var] then
			env[var] = 0
		end
		env[var] = env[var1]
	end,
	call = function(env, var, ...)
		local args = table.pack(...)
		local a = {}
		for i,v in pairs(args) do
			if i ~= "n" then
				table.insert(a, (tonumber(v) or env[v]) or tpscript.getthing(env,v) or v)
			end
		end
		tpscript.getthing(env,var)(table.unpack(a))
	end,
	callset = function(env, towrite, var, ...)
		local args = table.pack(...)
		local a = {}
		for i,v in pairs(args) do
			if i ~= "n" then
				table.insert(a, (tonumber(v) or env[v]) or tpscript.getthing(env,v) or v)
			end
		end
		env[towrite] = tpscript.getthing(env,var)(table.unpack(a))
	end,
	setstr = function(env,var,val)
		env[var] = val
	end,
	logtxt = function(env,text)
		print(text)
	end,
	setindex = function(env,var,index,...)
		local args = table.pack(...)
		local a = {}
		for i,v in pairs(args) do
			if i ~= "n" then
				table.insert(a, v)
			end
		end
		local i = table.concat(a, " ")
		local v = tpscript.getthing(env, i)
		i = v or i
		env[var][index] = i
	end,
	setbool = function(env,var,val)
		env[var] = val == "true"
	end,
	set = function(env, var, path)
		env[var] = tpscript.getthing(env,path)
	end,
	logless = function(env,var)
		print(env[var])
	end,
	log = function(env,var)
		print(tpscript.getthing(env, var))
	end,
	["not"] = function(env,var)
		local v = tpscript.getthing(env, var)
		if v == true or v == false then
			env[var] = not v
		end
	end,
	equ = function(env,writeto,var,var1)
		local v = (tonumber(var) or env[var]) or tpscript.getthing(env,var) or var
		local v1 = (tonumber(var1) or env[var1]) or tpscript.getthing(env,var1) or var1
		env[writeto] = v == v1
	end,
	clrenv = function(env)
		table.clear(env)
	end,
	cmt = function() end -- Yes, you need a semicolon for comments.
}

tpscript.globalenv = setmetatable({}, {__index = getfenv(0)})

local function doinstruction(env,v)
	local words = v:split(' ')
	local args = {}
	for i = 2, #words do
		table.insert(args, words[i])
	end
	local f = tpscript.instructions[words[1]]
	if words[1] == "setstr" then
		local bb = {}
		for i = 3, #words do
			table.insert(bb, words[i])
		end
		f(env, args[1], table.concat(bb, " "))
	elseif words[1] == "logtxt" then
		f(env, table.concat(args, " "))
	else
		if f then
			f(env, table.unpack(args))
		end
	end
end

function tpscript.loadstring(src, useglobal)
	local lines = src:split(";")
	local env = setmetatable({}, {__index = getfenv(0)})

	if useglobal then
		env = tpscript.globalenv
	end

	local n = {}
	for i = 1, #lines do
		if lines[i] then
			table.insert(n, lines[i])
		end
	end
	lines = n

	local points = {}

	for i,v in pairs(lines) do
		if v:sub(1, 2) == "::" then
			local a = v:sub(3, -1)

			points[a] = i
		end
	end

	local n = 1
	while lines[n] do
		local words = lines[n]:split(' ')
		if words[1] == "jmpif" then
			local varcompare = words[2]
			local label = words[3]
			if points[label] and env[varcompare] then
				n = points[label] - 1
			end
		elseif words[1] == "jmp" then
			local label = words[2]
			if points[label] then
				n = points[label] - 1
			end
		else
			doinstruction(env, lines[n])
		end
		n = n + 1
	end
end

return tpscript