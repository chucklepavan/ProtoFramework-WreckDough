local Proto, doNothing, parallelBreakpoint = _G.Proto, _G.doNothing, _G.parallelBreakpoint
local PropertiesUtil = Proto:sharedModule({
    moduleName = "PropertiesUtil",
})


local propertiesLookup = {}


function PropertiesUtil:hasProperty(instance, propertyName)--working towards a :getProperties() function
    local className = typeof(instance) == "string" and instance or instance.ClassName

    local propertiesInfo = self:getPropertiesInfo(className)

    if propertiesInfo.properties[propertyName] ~= nil then
        return propertiesInfo.properties[propertyName]
    end

    local success = pcall(function() 
        return propertiesInfo.testInstance[propertyName]
    end)

    propertiesInfo.properties[propertyName] = success

    return success
end

function PropertiesUtil:getPropertiesInfo(className)
    local propertiesInfo = propertiesLookup[className]
    if propertiesInfo then return propertiesInfo end

    propertiesInfo = {
        testInstance = Instance.new(className),
        properties = {},
    }

    propertiesLookup[className] = propertiesInfo
    return propertiesInfo
end


return PropertiesUtil