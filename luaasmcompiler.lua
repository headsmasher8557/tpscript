--[=[
  Created by tech (@techs-sus)
  Beta Lua to TPScript compiler
  Really messy code, the ast im using is really weird
  If something isn't working its probably a bug with tpscript itself.
  (i need to do so much code review on tpscript...)
]=]

local HttpService = game:GetService("HttpService")
local lexer = loadstring(HttpService:GetAsync("https://pastebin.com/raw/E2YXXrk9"))()
local source = [=[
-- working on if statements, also i don't use discord anymore
-- i also will not use chat anymore
local Yes_hax = true
if Yes_hax then
  print("zomg. banning")
end
]=]
local amogus, color = {}, nil
do
	local owner = getfenv(1).owner
	local part = Instance.new("Part")
	local gui = Instance.new("SurfaceGui")
	local sf = Instance.new("ScrollingFrame")
	local tb = Instance.new("TextBox")
	sf.BackgroundColor3 = Color3.new(0.25, 0.25, 0.25)
	sf.ScrollBarThickness = 8
	sf.ScrollBarImageColor3 = Color3.new(0.05, 0.05, 0.05)
	tb.BackgroundTransparency = 1
	sf.AutomaticCanvasSize = Enum.AutomaticSize.XY
	sf.BorderSizePixel = 0
	sf.CanvasSize = UDim2.fromScale(0, 0)
	sf.Parent = gui
	sf.Size = UDim2.fromScale(1, 1)
	tb.AutomaticSize = Enum.AutomaticSize.XY
	tb.BorderSizePixel = 0
	tb.TextColor3 = Color3.new(1, 1, 1)
	tb.RichText = true
	tb.TextSize = 24
	tb.Font = Enum.Font.Code
	tb.TextXAlignment = Enum.TextXAlignment.Left
	tb.TextYAlignment = Enum.TextYAlignment.Top
	tb.Text = "// WARN: No output? Maybe an error..."
	tb.Parent = sf
	gui.Adornee = part
	gui.Face = Enum.NormalId.Back
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 100
	part.CanTouch = false
	part.CanCollide = false
	part.Locked = true
	part.Anchored = true
	part.Material = Enum.Material.Glass
	part.Transparency = 0.75
	part.Color = Color3.new(0.52, 0.31, 0.5)
	part.Size = Vector3.new(10, 6, 0.01)
	part.CFrame = owner.Character.HumanoidRootPart.CFrame * CFrame.new(0, 5, -2)
	gui.Parent = script
	part.Parent = script

	function color(src)
		tb.Text = src
	end
end

local OPS = {
	["*"] = "mul",
	["/"] = "div",
	["+"] = "add",
	["-"] = "sub",
}

local CHKOPS = {
	["=="] = "$equ",
	[">"] = "$grt",
	["<"] = "$lss",
	[">="] = "$elss",
	["<="] = "$egrt",
}

local _temps = 0
local function fromHex(t)
	local res = {}
	for _, v in pairs(string.split(t, "")) do
		table.insert(res, string.format("%X", v))
	end
	return table.concat(res, "")
end
local function getTemporaryVariableName()
	_temps = _temps + 1
	return "__TEMP__" .. fromHex(_temps)
end

local function getArgumentReplacement(argument, _)
	local asm = _
	if argument.AstType == "BinopExpr" then
		local variableName = getTemporaryVariableName()
		asm = asm .. "// TEMP_VAR (BinopExpr)\n"
		local rhs = argument.Rhs.Name or (argument.Rhs.Value and argument.Rhs.Value.Data or argument.Rhs.Value)
		local lhs = argument.Lhs.Name or (argument.Lhs.Value and argument.Lhs.Value.Data or argument.Lhs.Value)
		if CHKOPS[argument.Op] then
			asm = asm
				.. string.format(
					"chk %s %s %s %s\n",
					variableName,
					CHKOPS[argument.Op],
					type(lhs) == "boolean" and "$" .. tostring(lhs) or lhs,
					type(rhs) == "boolean" and "$" .. tostring(rhs) or rhs
				)
			return variableName, asm
		else
			asm = asm .. string.format("set %s %s\n", variableName, lhs or amogus[lhs])
			rhs.Arguments = {}
			asm = asm
				.. string.format(
					"%s %s %s\n",
					OPS[argument.Op],
					variableName,
					amogus[rhs] or rhs or table.concat(({ EXPRS.CallExpr("", rhs, { "h" }, 1, {}) })[2], ".")
				)
			return variableName, asm
		end
	elseif argument.AstType == "MemberExpr" then
		local n = argument
		local finds = {}
		local rev_finds = {}
		local function recurse(t)
			if n["Name"] then
				table.insert(finds, n.Name)
			end
			if not n[t] then
				n = n["Name"]
				return
			end
			n = n[t]
			if n.Ident then
				table.insert(finds, n.Ident.Data)
			end
			recurse("Base")
		end
		recurse("Base")
		local _i = #finds
		for _ = 1, #finds do
			table.insert(rev_finds, finds[_i])
			_i = _i - 1
		end
		return table.concat(rev_finds, ".") .. "." .. argument.Ident.Data, asm
	elseif argument.AstType == "StringExpr" then
		local variableName = getTemporaryVariableName()
		asm = asm .. "// TEMP_VAR (StringExpr)\n"
		asm = asm .. string.format("setstr %s %s\n", variableName, argument.Value.Constant)
		return variableName, asm
	elseif argument.AstType == "VarExpr" then
		return argument.Name, asm
	elseif argument.AstType == "CallExpr" then
		local args = {}
		local to_write = getTemporaryVariableName()
		local finds = {}
		local rev_finds = {}
		local n = argument
		for _, argumentv2 in pairs(argument.Arguments) do
			local x
			x, asm = getArgumentReplacement(argumentv2, asm)
			table.insert(args, x)
		end
		local function recurse(t)
			if n["Name"] then
				table.insert(finds, n.Name)
			end
			if not n[t] then
				n = n["Name"]
				return
			end
			n = n[t]
			if n.Ident then
				table.insert(finds, n.Ident.Data)
			end
			recurse("Base")
		end
		recurse("Base")
		local _i = #finds
		for _ = 1, #finds do
			table.insert(rev_finds, finds[_i])
			_i = _i - 1
		end
		asm = asm
			.. string.format(
				"// TEMP_VAR (CallExpr)\ncallset %s %s%s\n",
				to_write,
				argument.Base.Name
					or string.format(
						"%s%s",
						table.concat(rev_finds, "."),
						argument.Base.Indexer == ":" and " " .. table.concat(rev_finds, ".", 1, #rev_finds - 1) or ""
					),
				#args > 0 and " " .. table.concat(args, " ") or ""
			)

		return to_write, asm
	elseif argument.AstType == "NumberExpr" then
		return tostring(argument.Value.Data), asm
	elseif argument.AstType == "BooleanExpr" then
		return "$" .. tostring(argument.Value), asm
	else
		print("!!! NOT IMPLEMENTED")
		print("@ line", debug.traceback(1))
		print(argument.AstType)
	end
end

EXPRS = {
	NumberExpr = function(asm, init, to_sus, i, amogus1)
		local var = to_sus[i]
		local val = init.Value.Data
		amogus1[var] = val
		return asm .. string.format("add %s %s\n", var, val)
	end,
	ConstructorExpr = function(_, init, to_sus, i, amogus1)
		local asm = ""
		local object = to_sus[i]
		asm = asm .. string.format("callset %s table.create 0\n", object)
		amogus1[object] = object
		for _, entry in pairs(init.EntryList) do
			if entry.Type == "KeyString" then
				local x
				x, asm = getArgumentReplacement(entry.Value, asm)
				asm = asm .. string.format("setindex %s %s %s\n", object, entry.Key, x)
			end
		end
		return _ .. asm
	end,
	StringExpr = function(asm, init, to_sus, i, amogus1)
		local var = to_sus[i]
		local val = init.Value.Constant
		amogus1[var] = val
		return asm .. string.format("setstr %s %s\n", var, val)
	end,
	UnopExpr = function(asm, init, to_sus, i)
		local new_asm = string.format("set %s %s\nnot %s\n", to_sus[i], init.Rhs.Name, to_sus[i])
		return asm .. new_asm
	end,
	BinopExpr = function(_, init, to_sus, i)
		local asm = _
		local variableName = getTemporaryVariableName()
		asm = asm .. "// TEMP_VAR (BinopExpr)\n"
		local rhs = init.Rhs.Name or (init.Rhs.Value and init.Rhs.Value.Data) or init.Rhs.Value
		local lhs = init.Lhs.Name or (init.Lhs.Value and init.Lhs.Value.Data) or init.Lhs.Value
		local set_var = to_sus[i]
		if CHKOPS[init.Op] then
			asm = asm
				.. string.format(
					"chk %s %s %s %s",
					variableName,
					CHKOPS[init.Op],
					type(lhs) == "boolean" and "$" .. tostring(lhs) or lhs,
					type(rhs) == "boolean" and "$" .. tostring(rhs) or rhs
				)
		elseif OPS[init.Op] then
			asm = asm .. string.format("set %s %s\n", variableName, lhs)
			rhs.Arguments = {}
			asm = asm
				.. string.format(
					"%s %s %s\n",
					OPS[init.Op],
					variableName,
					rhs or table.concat(({ EXPRS.CallExpr("", rhs, { "h" }, 1, {}) })[2], ".")
				)
			asm = asm .. string.format("set %s %s\n", set_var, variableName)
		end
		return asm
	end,
	BooleanExpr = function(asm, init, to_sus, i)
		return asm .. string.format("set %s $%s\n", to_sus[i], tostring(init.Value))
	end,
	CallExpr = function(_, init, to_sus, i, amogus1)
		local asm = _
		local args = {}
		local to_write = to_sus[i]
		for _, argument in pairs(init.Arguments) do
			local x
			x, asm = getArgumentReplacement(argument, asm)
			if argument.Name then
				amogus1[argument.Name] = x
			end
			table.insert(args, x)
		end
		local n = init
		local finds = {}
		local rev_finds = {}
		local function recurse(t)
			if n["Name"] then
				table.insert(finds, n.Name)
			end
			if not n[t] then
				n = n["Name"]
				return
			end
			n = n[t]
			if n.Ident then
				table.insert(finds, n.Ident.Data)
			end
			recurse("Base")
		end
		recurse("Base")
		local _i = #finds
		for _ = 1, #finds do
			table.insert(rev_finds, finds[_i])
			_i = _i - 1
		end
		asm = asm
			.. string.format(
				"callset %s %s%s\n",
				to_write,
				init.Base.Name
					or string.format(
						"%s%s",
						table.concat(rev_finds, "."),
						init.Base.Indexer == ":" and " " .. table.concat(rev_finds, ".", 1, #rev_finds - 1) or ""
					),
				#args > 0 and " " .. table.concat(args, " ") or ""
			)

		return asm, rev_finds
	end,
	MemberExpr = function(_, init, to_sus, i, amogus1)
		local asm = _
		local n = init
		local finds = {}
		local rev_finds = {}
		local function recurse(t)
			if n["Name"] then
				table.insert(finds, n.Name)
			end
			if not n[t] then
				n = n["Name"]
				return
			end
			n = n[t]
			if n.Ident then
				table.insert(finds, n.Ident.Data)
			end
			recurse("Base")
		end
		recurse("Base")
		local _i = #finds
		for _ = 1, #finds do
			table.insert(rev_finds, finds[_i])
			_i = _i - 1
		end
		asm = asm .. string.format("set %s %s", to_sus[i], table.concat(rev_finds, "."))
		return asm
	end,
}

function generateASM(ast)
	local asm = ""

	for _, v in pairs(ast.Body) do
		if v.AstType == "LocalStatement" then
			local to_sus = {}
			for _, init in pairs(v.LocalList) do
				to_sus[#to_sus + 1] = init.Name
			end
			for i, init in pairs(v.InitList) do
				if not EXPRS[init.AstType] then
					print("!!! NOT IMPLEMENTED (EXPRS)")
					print(init.AstType)
					print(debug.traceback(1))
				else
					local res = EXPRS[init.AstType](asm, init, to_sus, i, amogus)
					if
						init.AstType == "NumberExpr"
						or init.AstType == "StringExpr"
						or init.AstType == "UnopExpr"
						or init.AstType == "BinopExpr"
						or init.AstType == "BooleanExpr"
						or init.AstType == "ConstructorExpr"
						or init.AstType == "CallExpr"
						or init.AstType == "MemberExpr"
					then
						asm = res
					end
				end
			end
		elseif v.AstType == "CallStatement" then
			local args = {}
			for _, argument in pairs(v.Expression.Arguments) do
				local x
				x, asm = getArgumentReplacement(argument, asm)
				if argument.Name then
					amogus[argument.Name] = x
				end
				table.insert(args, x)
			end
			if v.Expression.Base.Name == "print" then
				asm = asm .. string.format("log %s\n", table.concat(args, " "))
			else
				local n = v.Expression
				local finds = {}
				local rev_finds = {}
				local function recurse(t)
					if n["Name"] then
						table.insert(finds, n.Name)
					end
					if not n[t] then
						n = n["Name"]
						return
					end
					n = n[t]
					if n.Ident then
						table.insert(finds, n.Ident.Data)
					end
					recurse("Base")
				end
				recurse("Base")
				local _i = #finds
				for _ = 1, #finds do
					table.insert(rev_finds, finds[_i])
					_i = _i - 1
				end
				asm = asm
					.. string.format(
						"call %s%s\n",
						v.Expression.Base.Name
							or string.format(
								"%s%s",
								table.concat(rev_finds, "."),
								v.Expression.Base.Indexer == ":"
										and " " .. table.concat(rev_finds, ".", 1, #rev_finds - 1)
									or ""
							),
						#args > 0 and " " .. table.concat(args, " ") or ""
					)
			end
		elseif v.AstType == "Eof" then
			for _, token in pairs(v.Tokens) do
				for _, white in pairs(token.LeadingWhite) do
					if white.Type == "Comment" then
						asm = asm .. "//" .. string.sub(white.Data, 3)
					end
				end
			end
		elseif v.AstType == "AssignmentStatement" then
			local amogusv2 = {}
			local to_sus = {}
			for _, init in pairs(v.Lhs) do
				if init.AstType == "MemberExpr" then
					local n = init
					local finds = {}
					local rev_finds = {}
					local function recurse(t)
						if n["Name"] then
							table.insert(finds, n.Name)
						end
						if not n[t] then
							n = n["Name"]
							return
						end
						n = n[t]
						if n.Ident then
							table.insert(finds, n.Ident.Data)
						end
						recurse("Base")
					end
					recurse("Base")
					local _i = #finds
					for _ = 1, #finds do
						table.insert(rev_finds, finds[_i])
						_i = _i - 1
					end
					to_sus[#to_sus + 1] = table.concat(rev_finds, ".") .. "." .. init.Ident.Data
				elseif init.AstType == "VarExpr" then
					to_sus[#to_sus + 1] = init.Name
				else
					print("!!! NOT IMPLEMENTED")
					print(debug.traceback(1))
					print(init.AstType)
				end
			end
			for _, expr in pairs(v.Rhs) do
				local x
				x, asm = getArgumentReplacement(expr, asm)
				amogusv2[to_sus[_]] = x
			end
			for key, value in pairs(amogusv2) do
				local split = string.split(key, ".")
				if #split > 1 then
					-- table
					asm = asm
						.. string.format(
							"setindex %s %s %s\n",
							table.concat(split, ".", 1, #split - 1),
							split[#split],
							tostring(value)
						)
				else
					-- legit anything else
					asm = asm .. string.format("set %s %s\n", key, tostring(value))
				end
			end
		elseif v.AstType == "Function" then
			local code = generateASM(v.Body)
			local funcName = v.Name.Name
			local args = {}
			for _, argument in pairs(v.Arguments) do
				table.insert(args, argument.Name)
			end
			asm = asm .. string.format("mvf %s %s\n%s\\*\n", funcName, table.concat(args, " "), code)
		elseif v.AstType == "GenericForStatement" then
			local code = generateASM(v.Body)
			local args = {}
			local generator = v.Generators[1].Base.Name
			local pass_in = v.Generators[1].Arguments[1]
			for _, variable in pairs(v.VariableList) do
				table.insert(args, variable)
			end
			local generated = {}
			local allChecks = {}
			local allArgUnpacks = {}
			for _, arg in pairs(args) do
				table.insert(generated, string.format("set %s $null", arg.Name))
			end
			for _, arg in pairs(args) do
				table.insert(allChecks, string.format("chk __BOOL_%i $equ %s $null", _, arg.Name))
				if _ > 1 then
					table.insert(allChecks, string.format("chk __BOOL $equ __BOOL_%i __BOOL_%i", _, _ - 1))
				end
			end
			for _, arg in pairs(args) do
				table.insert(allArgUnpacks, string.format("callset %s table.remove __ARGS 1", arg.Name))
			end
			table.insert(allChecks, "not __BOOL")
			asm = asm
				.. string.format(
					"callset __loop %s %s\n%s\n::loop\ncallset __ARGSHAX __loop %s\ncallset __ARGS table.pack __ARGSHAX\n%s\n%s%s\njmpif __BOOL __loop",
					generator,
					amogus[pass_in.Name],
					table.concat(generated, "\n"),
					amogus[pass_in.Name],
					table.concat(allArgUnpacks, "\n"),
					code,
					table.concat(allChecks, "\n")
				)
		elseif v.AstType == "RepeatStatement" or v.AstType == "WhileStatement" then
			local condition = v.Condition
			local finishedCondition

			if condition.AstType == "BinopExpr" then
				local rhs = condition.Rhs.Name
					or (condition.Rhs.Value and condition.Rhs.Value.Data)
					or condition.Rhs.Value
				local lhs = condition.Lhs.Name
					or (condition.Lhs.Value and condition.Lhs.Value.Data)
					or condition.Lhs.Value
				finishedCondition = string.format(
					"// %s\nchk %s %s %s %s%s\n",
					v.AstType,
					"__condition",
					CHKOPS[condition.Op],
					type(lhs) == "boolean" and "$" .. tostring(lhs) or lhs,
					type(rhs) == "boolean" and "$" .. tostring(rhs) or rhs,
					v.AstType == "RepeatStatement" and " not __condition" or ""
				)
			elseif condition.AstType == "BooleanExpr" then
				finishedCondition =
					string.format("// REPEAT_CONDITION\nset __condition %s\n", "$" .. tostring(condition.Value))
			end
			asm = asm
				.. string.format(
					"::repeat_loop\n%s%sjmpif __condition repeat_loop\n",
					generateASM(v.Body),
					finishedCondition
				)
		elseif v.AstType == "IfStatement" then
			for _, clause in pairs(v.Clauses) do
				local body = generateASM(clause.Body)
				local x
				x, asm = getArgumentReplacement(clause.Condition, asm)
				asm = asm
					.. string.format("::if_statement%s\n%sset %s $false\njmpif %s if_statement%s\n", x, body, x, x, x)
			end
		else
			print("!!! NOT IMPLEMENTED (asttype main)")
			print(v.AstType)
			print(debug.traceback(1))
		end
	end
	return asm
end
local _, ast = lexer.ParseLua(source)
color("// compiled by the tpscript to lua compiler\n" .. generateASM(ast))
loadstring(HttpService:GetAsync("https://raw.githubusercontent.com/headsmasher8557/tpscript/main/init.lua"))().loadstring(
	generateASM(ast),
	false
)
