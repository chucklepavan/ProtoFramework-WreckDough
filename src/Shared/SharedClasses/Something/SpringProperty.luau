local Proto, doNothing, parallelBreakpoint = _G.Proto, _G.doNothing, _G.parallelBreakpoint
local SpringProperty = Proto:sharedClass({
    moduleName = "SpringProperty",

    classSettings = {
        animateInstance = nil,

        propertyName = nil,
        targetValue = nil,

        damping = 1,
        speed = 1,

        active = false,
    },
})


function SpringProperty:init1()
    self.spring = Proto.Spring:new({
        target = self.targetValue,
        value = self.animateInstance[self.propertyName],

        damping = self.damping,
        speed = self.speed,
    })

    local propertyName = self.propertyName

    Proto:declare(self, function(self, Proto)
        self(function(self, Proto, ...) self:activeChanged(...) end, function(self, Proto) return self.active end)

        self.animateInstance[propertyName] = function(self, Proto)
            return self.active and self.spring.value or doNothing
        end
    end)
end


function SpringProperty:activeChanged(active)
    if active then
        self.spring:setValue(self.animateInstance[self.propertyName])
    end
end


return SpringProperty