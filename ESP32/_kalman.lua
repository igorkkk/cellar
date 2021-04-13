local M = {}

 function M.new(varian,varProce)
	local set ={
		Pc = 0.0,
		G = 0.0,
		P = 1.0,
		Xp = 0.0,
		Zp = 0.0,
		Xe = 0.0,
		variance = varian or 1.12184278324081/100000,
		varProcess = varProce or 1/100000000
	}
	return set
end

function M.newkalm(name, variance, varProcess)
    M[name] = M.new(variance, varProcess)
end

M.update = function(name,vol)
	M[name].Pc = M[name].P + M[name].varProcess
	M[name].G = M[name].Pc/(M[name].Pc + M[name].variance)
	M[name].P = (1-M[name].G)*M[name].Pc
	M[name].Xp = M[name].Xe
	M[name].Zp = M[name].Xp
	M[name].Xe = M[name].G*(vol-M[name].Zp) + M[name].Xp  
	-- return M[name].Xe
	return ((math.floor(M[name].Xe*10))/10)
end

return M
