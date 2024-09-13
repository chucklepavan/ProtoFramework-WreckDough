local Proto, doNothing, parallelBreakpoint = _G.Proto, _G.doNothing, _G.parallelBreakpoint
local Tweener = Proto:sharedClass({
    moduleName = "Tweener",

    classSettings = {
        enabled = true,

        target = 0,
        value = 0,

        style = Enum.EasingStyle.Quad,
        direction = Enum.EasingDirection.Out,
        length = 1,

        alpha = 0,
        startTime = 0,
    },
})


function Tweener:init1()--need to overwrite value if target is changed to a diff type or opposite for spring
    Proto:declare(self, function(self, Proto)
        self(function(self, Proto, ...) self:targetChanged(...) end, function(self, Proto) return self.target, self.enabled end)

        self.value = function(self, Proto)
            if not self.enabled then return doNothing end
            if not self.target or not self.startValue or typeof(self.target) ~= typeof(self.startValue) then return doNothing end

            local lerpAlpha = Proto.TweenService:GetValue(self.alpha, self.style, self.direction)
            return Proto.Math:lerp(self.startValue, self.target, lerpAlpha) or doNothing
        end

        self.alpha = function(self, Proto)
            if not self.enabled then return doNothing end
            if self.alpha == 1 then return doNothing end
   
            local timeSinceStart = Proto.heartbeatTime - self.startTime
            local alpha = math.clamp(timeSinceStart / self.length, 0, 1)
            return alpha
        end

        self.active = function(self, Proto)
            return self.alpha ~= 1 and self.enabled
        end
    end)
end

function Tweener:setValue(value)
    self.value = value

    self:targetChanged()
end

function Tweener:targetChanged()
    self.startValue = self.value
    self.startTime = Proto.heartbeatTime
    self.alpha = 0
end


return Tweener