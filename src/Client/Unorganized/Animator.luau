local Proto, doNothing, parallelBreakpoint = _G.Proto, _G.doNothing, _G.parallelBreakpoint
local Animator = Proto:sharedClass({
    moduleName = "Animator",

})


function Animator.static:setDescendantsToTarget(object, animationName)
    local _, animations = object:getDescendantsWithComponentOfClass("Animator")

    for _, animation in animations do
        if animation.animationName == animationName then
            animation:setToTarget()
        end
    end
end

function Animator.static:playDescendantsAnimationAsync(object, animationName)
    local _, animations = object:getDescendantsWithComponentOfClass("Animator")

    for _, animation in animations do
        if animation.animationName == animationName then
            animation:play()
        end
    end

    self.yieldedThread = coroutine.running()
    return coroutine.yield()
end

function Animator:setToTarget()--really should just make a method of the animation component so that it can work with a currently playing animation
    for propertyName, animationComponent in self.animatingProperties do
        self.animatingInstance[propertyName] = animationComponent.target
    end
end

function Animator:play()
    --stop all other animations on this instance
    for _, sibling in self.object.components do
        if sibling.class == Animator then
            sibling:stop()
        end
    end

    for propertyName, animationComponent in self.animatingProperties do
        local currentValue = self.animatingInstance[propertyName]
        animationComponent:setValue(currentValue)
    end

    self.playing = true
end

function Animator:stop()
    self.playing = false
end

function Animator:stateChanged(active)
    if not active and self.yieldedThread then
        coroutine.resume(self.yieldedThread, self.playing)
    end
end



function Animator:init1()
    self:stop()

    self.animationName = self.instance.Name
    self.animatingInstance = self.instance.Parent

    self.animatingProperties = {}

    for _, goalInstance in self.instance:GetChildren() do
        local animationComponent = self:getAnimationComponent(goalInstance)

        self[animationComponent] = animationComponent

        local propertyName = goalInstance.Name
        self.animatingProperties[propertyName] = animationComponent

        self:declareProperties(animationComponent, propertyName)
    end

    Proto:declare(self, function(self, Proto)
        self(function(self, Proto, ...) self:stateChanged(...) end, function(self, Proto)
            for _, animationComponent in self.animatingProperties do
                if animationComponent.active then
                    return true
                end
            end

            return false
        end)
    end)
end

function Animator:declareProperties(animationComponent, propertyName)
    Proto:declare(self, function(self, Proto)
        self[animationComponent].enabled = function(self, Proto)
            return self.playing
        end

        self.animatingInstance[propertyName] = function(self, Proto)
            if not self.playing then return doNothing end

            return self[animationComponent].value
        end
    end)
end

function Animator:getAnimationComponent(goalInstance)
    local targetValue = goalInstance:GetAttribute("target")
    assert(targetValue, "target attribute must be set on goal instance")

    local componentType = goalInstance:GetAttribute("animationComponentType") or "Tweener"

    if componentType == "Tweener" then
        return Proto.Tweener:new({
            enabled = false,

            target = targetValue,
            length = goalInstance:GetAttribute("length"),
            style = goalInstance:GetAttribute("easingStyle"),
            direction = goalInstance:GetAttribute("easingDirection"),
        })
    elseif componentType == "Spring" then
        local spring = Proto.Spring:new({
            enabled = false,

            target = targetValue,
            damping = goalInstance:GetAttribute("damping"),
            speed = goalInstance:GetAttribute("speed"),
        })

        return spring
    end

    error("Invalid AnimationComponentType")
end


return Animator