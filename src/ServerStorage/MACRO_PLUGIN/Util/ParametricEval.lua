-- Evaluate a string from a parametric input box and return a number.
-- Expressions are sandboxed with access to standard Lua math functions.

-- By Fractality

local parametricEval do
	local envTemplate = {
		abs = math.abs,
		acos = math.acos,
		asin = math.asin,
		atan = math.atan,
		atan2 = math.atan2,
		ceil = math.ceil,
		cos = math.cos,
		cosh = math.cosh,
		deg = math.deg,
		exp = math.exp,
		floor = math.floor,
		fmod = math.fmod,
		frexp = math.frexp,
		huge = math.huge,
		ldexp = math.ldexp,
		log = math.log,
		log10 = math.log10,
		max = math.max,
		min = math.min,
		modf = math.modf,
		pow = math.pow,
		rad = math.rad,
		random = math.random,
		sin = math.sin,
		sinh = math.sinh,
		sqrt = math.sqrt,
		tan = math.tan,
		tanh = math.tanh,
		pi = math.pi,
		tau = 2*math.pi,
		e = math.exp(1),
		phi = (math.sqrt(5) + 1)/2,
	}
	
	local envMt = {
		__metatable = false,
		__index = function(_, k)
			warn(tostring(k) .. ' is undefined')
		end,
	}
	
	local function parse(str, env)
		local f = loadstring(('return (%s)'):format(str))
		if f then
			setfenv(f, env)
			local s, ret = pcall(f)
			if s then
				return ret
			end
		end
		warn('Evaluation failed')
	end
	
	function parametricEval(str)
		local ret = tonumber(str)
		if ret then
			return ret
		else
			local env = {}
			for k, v in next, envTemplate do
				env[k] = v
			end
			local parseResult = parse(str, setmetatable(env, envMt))
			if parseResult and tonumber(parseResult) then
				return tonumber(parseResult)
			elseif ret ~= nil then
				warn('Evaluation output is not a number')
			end
		end
	end
end

return parametricEval
