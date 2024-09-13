-- created on July 25th, 2024 @TritiusDumorix
--!nolint LocalUnused
local Proto, doNothing, parallelBreakpoint = _G.Proto, _G.doNothing, _G.parallelBreakpoint
local ExampleRoundComp = Proto:serverClass({
    moduleName = "ExampleRoundComp"
})

-- RoundComponents
-- init 2-3 is initalizing round components
-- init 5-6 is starting the round components 
-- (init 5-6 called after all inbound players joined and before round thread / heartbeat)

-- DO NOT DEFINE init1, init4, init7
function ExampleRoundComp:init2()
    print("Initalizing round component")
end

function ExampleRoundComp:init5()
    print("starting round component")
end

-- called every heartbeat
function ExampleRoundComp:heartbeat(deltaTime)
    -- code here
end

-- if returns true, round will end; at least one round
-- component must return true for round to end
function ExampleRoundComp:endCondition()
    return nil    
end

-- called after round is finished before round components are destroyed
function ExampleRoundComp:roundEnded()
    print("Round ending, doing partical round component cleanup")
end

-- called whenever a player joins the round
function ExampleRoundComp:playerJoinedRound(playerObject)
    print(`Player {playerObject.instance.Name} has joined round; handling player join for round component`)
end

-- called whenever a player leaves the round
function ExampleRoundComp:playerLeftRound(playerObject)
    print(`Player {playerObject.instance.Name} has left the round; handling player left for round component`)
end

-- if returns false, player cannot join; all round
-- components that do not return nil must return true for player
-- to be able to join the round; This will not apply to players
-- being joined into the round when it is created, but only if
-- a player requests to join in the middle of it
function ExampleRoundComp:canJoin(playerObject)
    print(`Player {playerObject.instance.Name} wants to join round; round component returning true`)
    return true
end

-- if returns false, player cannot respawn; all round
-- components that do not return nil must return true for player
-- to be able to respawn;
function ExampleRoundComp:canRespawn(playerObject)
    print(`Player {playerObject.instance.Name} wants to respawn; round component returning true`)
    return true
end

-- called after the round has ended; called in order for round 
-- component to give rewards; ought to be specific to round component,
-- i.e. RoundKills component ought to only give rewards for player kills, etc...
function ExampleRoundComp:rewardPlayer(playerObject, playerData)
    print(`round component giving rewards to player {playerObject.instance.Name}`)
    return true
end


return ExampleRoundComp