-- created on July 23rd, 2024 @TritiusDumorix
--!nolint LocalUnused 
local Proto, doNothing, parallelBreakpoint = _G.Proto, _G.doNothing, _G.parallelBreakpoint
local TableUtil = Proto:sharedModule({
    moduleName = "TableUtil",
})

--[[------------------------------------------------------------
				 list vecotrization operations
--]]------------------------------------------------------------
-- returns list[1] and list[2] and ... list[n];
-- assumes there are no nil values in list
-- returns false if list is empty
function TableUtil:andAll(list)
	if #list == 0 then return false end
	local val = true
	for i, v in ipairs(list) do 
		val = val and v
	end 
	return val
end 

-- returns list[1] or list[2] or ... list[n];
-- assumes there are no nil values in list
-- returns false if list is empty
function TableUtil:orAll(list)
	if #list == 0 then return false end
	local val = false
	for i, v in ipairs(list) do 
		val = val or v
	end 
	return val
end 


--[[------------------------------------------------------------
					  table manipulation
--]]------------------------------------------------------------
function TableUtil:tablesEqualDeep(table0, table1)
	for i, v0 in pairs(table0) do
		local v1 = table1[i]
		if type(v0) == "table" and type(v1) == "table" then
			if not self:tablesEqualDeep(v0, v1) then 
				return false
			end
		elseif v0 ~= v1 then
			return false
		end
	end 
	
	for i, v0 in pairs(table1) do
		local v1 = table0[i]
		if type(v0) == "table" and type(v1) == "table" then
			if not self:tablesEqualDeep(v0, v1) then 
				return false
			end
		elseif v0 ~= v1 then
			return false
		end
	end
	
	return true
end

function TableUtil:tablesEqualShallow(table0, table1)
	for i, v in pairs(table0) do
		if v ~= table1[i] then 
			return false 
		end
	end 
	for i, v in pairs(table1) do
		if v ~= table0[i] then 
			return false 
		end
	end
	return true
end

function TableUtil:copyDeep(table0)
	local newTable = {}
	for i, v in pairs(table0) do
		newTable[i] = if type(v) == "table" then self:copyDeep(v) else v
	end
	return newTable
end

function TableUtil:copyShallow(table0)
	local newTable = {}
	for i, v in pairs(table0) do
		newTable[i] = v
	end
	return newTable
end

function TableUtil:replaceDeep(src, target)
	for i, v in pairs(src) do
		target[i] = if type(v) == "table" then self:copyDeep(v) else v
	end
end

function TableUtil:replaceShallow(src, target)
	for i, v in pairs(src) do
		target[i] = v
	end
end

return TableUtil