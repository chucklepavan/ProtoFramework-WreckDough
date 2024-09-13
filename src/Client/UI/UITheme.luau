local Proto, doNothing, parallelBreakpoint = _G.Proto, _G.doNothing, _G.parallelBreakpoint
local UITheme = Proto:clientClass({
    moduleName = "UITheme",

    theme = "light",
    currentColors = {},
})


local themePresets = {
    background = {
        light = Color3.fromHex("FFFFFF"),
        dark = Color3.fromHex("2D2D2D")
    },
    text = {
        light = Color3.fromHex("2D2D2D"),
        dark = Color3.fromHex("FFFFFF")
    },
}


function UITheme.static:init2()
    Proto:declare(self, function(self, Proto)
        for colorName, colorOptions in themePresets do
            self[colorName] = function(self, thing)
                return colorOptions[self.theme] 
            end
        end
    end)
end

function UITheme:init1()
    Proto:declare(self, function(self, Proto)
        --self.color = function(self, Proto) return self.background end

        self.instance.BackgroundColor3 = function(self, Proto) return self.background or doNothing end--does it add as dependency if it inherits the value?
    end)
end

--[[
-- TODO:
    detecting if the table changes AT ALL when __iter
    iterate table like a set
    detect instances changed events and attributes?

    possibly change updating a variable to just call an updator that updates the variable
    that way its closer to just calling the updator every frame

    change calling function relationship later on, -- will probably have to change how you define calling a function when args change

    make recursive setting value still update IF its the only used dependency? or if it returns doNothing? or both? instead of just ignoring it
    i think keep using it until it returns doNothing

    returning table needs to return the tabl and not hte proxy

    peek() function for calling functions and getting variables without invoking dependency

    snippets
]]
return UITheme