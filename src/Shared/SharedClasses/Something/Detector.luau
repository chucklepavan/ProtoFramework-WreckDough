local Proto, doNothing, parallelBreakpoint = _G.Proto, _G.doNothing, _G.parallelBreakpoint
local Detector = Proto:sharedClass({
    moduleName = "Detector",

    classSettings = {
        watching = nil,
        watchingPropertyName = nil, 
        watchingPropertyValue = nil,
        watchingEvent = nil,

        receiver = nil,
        receiverBoolName = nil,
        receiverMethodName = nil,
    },
})


function Detector:init1()
    print("DETECTOR INIT")

    if self.watchingPropertyName and self.watchingPropertyValue then
        Proto:declare(self, function(self, Proto)
            self(function(self, Proto, ...) self:propertyChanged(...) end, function(self, Proto) print("CHECKING") return self.watching[self.watchingPropertyName] end)
        end)
    end
    
    if self.watchingEvent and self.receiverMethodName then
        self.watchingEvent:Connect(function()
            self.receiver[self.receiverMethodName](self.receiver)
        end)
    end
end

function Detector:propertyChanged(value)
    print("PROPERTY CHANGED")--not detecting property change for second detector
    local isActive = self.watchingPropertyValue == value
    print(isActive, self.receiverBoolName, self.receiver[self.receiverBoolName])
    if self.receiverBoolName then
        self.receiver[self.receiverBoolName] = isActive
        print(self.receiver[self.receiverBoolName])
    end

    if self.receiverMethodName and isActive then
        self.receiver[self.receiverMethodName](self.receiver)
    end
end

return Detector