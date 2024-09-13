local ProtoPlayerUtil = {}

local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer



function ProtoPlayerUtil:playerAddedCallback(method, module, ...)
    assert(method, "method argument is required")
    assert(module, "module argument is required")

    local args = {...}

    Players.PlayerAdded:Connect(function(player)
        method(module, player, table.unpack(args))
    end)

    for _, player in Players:GetPlayers() do
        task.spawn(method, module, player, table.unpack(args))
    end
end

function ProtoPlayerUtil:playerRemovingCallback(method, module, ...)
    assert(method, "method argument is required")
    assert(module, "module argument is required")

    local args = {...}

    Players.PlayerRemoving:Connect(function(player)
        method(module, player, table.unpack(args))
    end)
end

function ProtoPlayerUtil:characterAddedCallback(method, module, ...)
    assert(method, "method argument is required")
    assert(module, "module argument is required")

    local args = {...}

    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(character)
            method(module, player, character, table.unpack(args))
        end)

        if player.Character then
            method(module, player, player.Character, table.unpack(args))
        end
    end)

    for _, player in Players:GetPlayers() do
        player.CharacterAdded:Connect(function(character)
            method(module, player, character, table.unpack(args))
        end)

        if player.Character then
            task.spawn(method, module, player, player.Character, table.unpack(args))
        end
    end
end

function ProtoPlayerUtil:characterRemovingCallback(method, module, ...)
    assert(method, "method argument is required")
    assert(module, "module argument is required")

    local args = {...}

    Players.PlayerRemoving:Connect(function(player)
        player.CharacterRemoving:Connect(function(character)
            method(module, player, character, table.unpack(args))
        end)
    end)

    for _, player in Players:GetPlayers() do
        player.CharacterRemoving:Connect(function(character)
            method(module, player, character, table.unpack(args))
        end)
    end
end

function ProtoPlayerUtil:otherCharacterAddedCallback(method, module, ...)
    assert(localPlayer, "cannot call this method on the server")
    assert(method, "method argument is required")
    assert(module, "module argument is required")

    local args = {...}

    Players.PlayerAdded:Connect(function(player)
        if player == localPlayer then return end

        player.CharacterAdded:Connect(function(character)
            method(module, player, character, table.unpack(args))
        end)

        if player.Character then
            method(module, player, player.Character, table.unpack(args))
        end
    end)

    for _, player in Players:GetPlayers() do
        if player == localPlayer then continue end

        player.CharacterAdded:Connect(function(character)
            method(module, player, character, table.unpack(args))
        end)

        if player.Character then
            task.spawn(method, module, player, player.Character, table.unpack(args))
        end
    end
end

function ProtoPlayerUtil:otherCharacterRemovingCallback(method, module, ...)
    assert(localPlayer, "cannot call this method on the server")
    assert(method, "method argument is required")
    assert(module, "module argument is required")

    local args = {...}

    Players.PlayerRemoving:Connect(function(player)
        if player == localPlayer then return end

        player.CharacterRemoving:Connect(function(character)
            method(module, player, character, table.unpack(args))
        end)
    end)

    for _, player in Players:GetPlayers() do
        if player == localPlayer then continue end

        player.CharacterRemoving:Connect(function(character)
            method(module, player, character, table.unpack(args))
        end)
    end
end

function ProtoPlayerUtil:localCharacterAddedCallback(method, module, ...)
    assert(localPlayer, "cannot call this method on the server")
    assert(method, "method argument is required")
    assert(module, "module argument is required")

    local args = {...}

    localPlayer.CharacterAdded:Connect(function(character)
        method(module, localPlayer, character, table.unpack(args))
    end)

    if localPlayer.Character then
        task.spawn(method, module, localPlayer, localPlayer.Character, table.unpack(args))
    end
end

function ProtoPlayerUtil:localCharacterRemovingCallback(method, module, ...)
    assert(localPlayer, "cannot call this method on the server")
    assert(method, "method argument is required")
    assert(module, "module argument is required")

    local args = {...}

    localPlayer.CharacterRemoving:Connect(function(character)
        method(module, localPlayer, character, table.unpack(args))
    end)
end


return ProtoPlayerUtil