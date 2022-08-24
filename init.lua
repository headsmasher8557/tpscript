local tpscript = {}

if (_VERSION ~= "Luau") then
	local canwrite = pcall(function()
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
	end)
	if not canwrite then
		error("Can't add split function, string library is read-only")
	end

	local canwrite = pcall(function()
		table.unpack = unpack
	end)
	if not canwrite then
		error("Can't add split function, table library is read-only")
	end
end

function tpscript.getthing(env, str)
	local token = str:split'.'
	local tar = getfenv(0)
	local fail = false
	for i,v in pairs(token) do
		local tn = tonumber(v)
		if tar[v] then
			tar = tar[v]
		elseif tn then
			if tar[tn] then
				tar = tar[tn]
			end
		else
			fail = true
			break
		end
	end
	if fail then
		tar = env
		fail = false
		for i,v in pairs(token) do
			local tn = tonumber(v)
			if tar[v] then
				tar = tar[v]
			elseif tn then
				if tar[tn] then
					tar = tar[tn]
				end
			else
				fail = true
			end
		end
		if fail then
			tar = nil
		end
	end
	if str:sub(1, 1) == "$" and not tar then
		local e = str:sub(2, #str)
		local isbool = (e == "true" or e == "false") or (e == "yes" or e == "no")
		if isbool then
			return e == "true" or e == "yes"
		else 
			return nil
		end
	end
	return tar or env[str]
end

tpscript.instructions = {
	add = function(env, var, val)
		if not env[var] then
			env[var] = 0
		end
		local v = (tonumber(var) or env[var]) or tpscript.getthing(env,var) or var
		local v1 = (tonumber(val) or env[val]) or tpscript.getthing(env,val) or val
		
		env[var] = v + v1
	end,
	sub = function(env, var, val)
		if not env[var] then
			env[var] = 0
		end
		local v = (tonumber(var) or env[var]) or tpscript.getthing(env,var) or var
		local v1 = (tonumber(val) or env[val]) or tpscript.getthing(env,val) or val
		
		env[var] = v - v1
	end,
	mul = function(env, var, val)
		if not env[var] then
			env[var] = 0
		end
		local v = (tonumber(var) or env[var]) or tpscript.getthing(env,var) or var
		local v1 = (tonumber(val) or env[val]) or tpscript.getthing(env,val) or val
		
		env[var] = v * v1
	end,
	div = function(env, var, val)
		if not env[var] then
			env[var] = 0
		end
		local v = (tonumber(var) or env[var]) or tpscript.getthing(env,var) or var
		local v1 = (tonumber(val) or env[val]) or tpscript.getthing(env,val) or val
		
		env[var] = v / v1
	end,
	copy = function(env, var, var1)
		if not env[var] then
			env[var] = 0
		end
		env[var] = env[var1]
	end,
	call = function(env, var, ...)
		local args = {...}
		local a = {}
		for i,v in pairs(args) do
			if i ~= "n" then
				table.insert(a, (tonumber(v) or env[v]) or tpscript.getthing(env,v) or v)
			end
		end
		tpscript.getthing(env,var)(table.unpack(a))
	end,
	callset = function(env, towrite, var, ...)
		local args = {...}
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
		local args = {...}
		local a = {}
		for i,v in pairs(args) do
			if i ~= "n" then
				table.insert(a, v)
			end
		end
		local i = table.concat(a, " ")
		local v = (tonumber(i) or env[i]) or tpscript.getthing(env,i) or i
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
		env[var] = not tpscript.getthing(env, var)
	end,
	equ = function(env,writeto,var,var1)
		local v = (tonumber(var) or env[var]) or tpscript.getthing(env,var) or var
		local v1 = (tonumber(var1) or env[var1]) or tpscript.getthing(env,var1) or var1
		env[writeto] = v == v1
	end,
	clrenv = function(env)
		table.clear(env)
	end,
	cmt = function() end,
	grt = function(env,writeto,var,var1)
		local v = (tonumber(var) or env[var]) or tpscript.getthing(env,var) or var
		local v1 = (tonumber(var1) or env[var1]) or tpscript.getthing(env,var1) or var1
		env[writeto] = v > v1
	end,
	les = function(env,writeto,var,var1)
		local v = (tonumber(var) or env[var]) or tpscript.getthing(env,var) or var
		local v1 = (tonumber(var1) or env[var1]) or tpscript.getthing(env,var1) or var1
		env[writeto] = v < v1
	end,
	chk = function(env,writeto,typ,var,val)
		local v = (tonumber(var) or env[var]) or tpscript.getthing(env,var) or var
		local l = (tonumber(val) or env[val]) or tpscript.getthing(env,val) or val
		local tv, tl = v, l
		if tv and tl then
			if typ == '$equ' then
				env[writeto] = tv == tl
			elseif typ == '$grt' then
				env[writeto] = tv > tl
			elseif typ == '$lss' then
				env[writeto] = tv < tl
			elseif typ == '$egrt' then
				env[writeto] = tv >= tl
			elseif typ == '$elss' then
				env[writeto] = tv <= tl
			end
		elseif type(v) == "string" then
			if typ == '$equ' then
				env[writeto] = v == l
			end
		end
	end,
	len = function(env,writeto,var)
		local v = (tonumber(var) or env[var]) or tpscript.getthing(env,var) or var
		if type(v) ~= "table" then
			env[writeto] = #tostring(v)
		else
			env[writeto] = #v
		end
	end
}

tpscript.globalenv = setmetatable({}, {__index = getfenv(0)})

local function doinstruction(env,words)
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

function tpscript.formatsrc(src) -- It would get so messy if i put all this on tpscript.loadstring function
	local lines = src:gsub("\n;", ";"):gsub("\n", ";"):split(";")--src:gsub("\n", ""):split(";")
	for i = 1, #lines do
		lines[i] = lines[i]:gsub("^%s*", "")
	end
	return lines
end

function tpscript.loadstring(src, useglobal)
	local lines = tpscript.formatsrc(src)
	local env = setmetatable({}, {__index = getfenv(0)})

	if type(useglobal) == "table" then
		env = useglobal 
	elseif useglobal then
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

	local makingvf = false
	local vfuncsetting = {writeto = nil,args = nil,source = ""}

	local n = 1
	while lines[n] do
		local words = lines[n]:split(' ')
		for i = 1, #words do
			words[i] = words[i]:gsub("$space", " "):gsub("$\\space", "$space") -- couldn't find a better way to do this, tell me if you do
		end
		if not makingvf then
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
			elseif words[1] == "makevirtualfunction" or words[1] == "mvf" then
				local writeto = words[2]
				local args = {}
				for i = 3, #words do
					table.insert(args, words[i])
				end
				vfuncsetting.writeto = writeto
				vfuncsetting.args = args

				makingvf = true
			else
				doinstruction(env, words)
			end
		elseif lines[n] ~= "\\*" then
			vfuncsetting.source = vfuncsetting.source .. lines[n] .. "\n"
		else
			makingvf = false
			local source = vfuncsetting.source
			local arglist = vfuncsetting.args
			env[vfuncsetting.writeto] = function(...)
				local argtable = {}
				local a = {...}
				local e = {}
				for i = 1, #arglist do
					e[arglist[i]] = a[i]
				end
				local nenv = setmetatable(e, {
					__index = env,
					__newindex = env
				})
				tpscript.loadstring(source, nenv)
			end
			vfuncsetting = {writeto = nil,args = nil,source = ""}
		end
		n = n + 1
	end
end

return tpscript
