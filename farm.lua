farmWidth = 9
farmHeight = 9
growTimeSeconds = 3000

state = { 
    wait = {
        startTime = 0
    },
    farm = {
        position = {
            y = 0,
            x = 0
        },
        faceDir = {
            x = 0,
            y = 1
        },
        cornerIndex = 1
    },
    returnState = "none",
    currentState = "wait"
}

stateFile = "/database/farm/state.json"


function forward()
    while turtle.forward() == false do
        sleep(1)
    end
end

function left()
    return turtle.turnLeft()
end

function right()
    turtle.turnRight()
end

function isGrown()
    local success, data = turtle.inspectDown()
    if success then
        return data.name == "minecraft:wheat" and data.state.age == 7
    else
        return false
    end
end

function harvestCrop()
    if isGrown() then
        turtle.digDown()
        plant()
    end
end

function wait()
    term.clear()
    print(growTimeSeconds - ((os.epoch("utc") / 1000) - state.wait.startTime))
    if (os.epoch("utc") / 1000) - state.wait.startTime >= growTimeSeconds then
        state.currentState = "harvest"
    else
        sleep(1)
    end
end

function leftCorner()
    local steps = {left, forward, left, forward}
    local fn = steps[state.farm.cornerIndex]
    fn()
    state.farm.cornerIndex = state.farm.cornerIndex + 1

    if state.farm.cornerIndex > 4 then
        state.farm.cornerIndex = 1
        state.currentState = state.returnState
    end
end

function rightCorner()
    local steps = {right, forward, right, forward}
    local fn = steps[state.farm.cornerIndex]
    fn()
    state.farm.cornerIndex = state.farm.cornerIndex + 1

    if state.farm.cornerIndex > 4 then
        state.farm.cornerIndex = 1
        state.currentState = state.returnState
    end
end

function selectSeeds()
    while turtle.getItemCount(15) < 2 and turtle.getItemCount(16) < 2 do
        term.clear()
        print("Enter seeds")
        local inp = read()
    end

    if turtle.getItemCount(15) > 1 then
        turtle.select(15)
    else
        turtle.select(16)
    end
end

function plant()
    selectSeeds()
    turtle.placeDown()
end

function harvest()

    harvestCrop()
    turtle.suckDown()
    forward()
    state.farm.position.y = state.farm.position.y + state.farm.faceDir.y

    if (state.farm.faceDir.y == 1 and state.farm.position.x == farmWidth - 1 and state.farm.position.y == farmHeight) or (state.farm.faceDir.y == -1 and state.farm.position.x == farmWidth - 1 and state.farm.position.y == 0) then
        state.currentState = "home"
    elseif state.farm.position.x % 2 == 0 and state.farm.position.y == farmHeight then
        state.currentState = "leftCorner"
        state.returnState = "harvest"
        state.farm.faceDir.y = -1
        state.farm.position.x = state.farm.position.x + 1
    elseif state.farm.position.x % 2 ~= 0 and state.farm.position.y == 0 then
        state.currentState = "rightCorner"
        state.returnState = "harvest"
        state.farm.faceDir.y = 1
        state.farm.position.x = state.farm.position.x + 1
    end
end

function homeX()
    turtle.suckDown()
    if state.farm.faceDir.y == 1 then
        right()
        state.farm.faceDir.y = 0
        state.farm.faceDir.x = -1
    elseif state.farm.faceDir.y == -1 then
        left()
        state.farm.faceDir.y = 0
        state.farm.faceDir.x = -1
    end

    if state.farm.position.x > 0 then
        forward()
        state.farm.position.x = state.farm.position.x - 1
    else
        state.currentState = "homeY"
    end

end

function homeY()
    turtle.suckDown()
    if state.farm.faceDir.x == 1 then
        left()
        state.farm.faceDir.y = -1
        state.farm.faceDir.x = 0
    elseif state.farm.faceDir.x == -1 then
        right()
        state.farm.faceDir.y = -1
        state.farm.faceDir.x = 0
    end

    if state.farm.position.y > 0 then
        forward()
        state.farm.position.y = state.farm.position.y - 1
    else
        left()
        left()
        state.farm.faceDir.y = 1
        state.wait.startTime = os.epoch("utc") / 1000
        state.currentState = "wait"
    end
end

function home()
    state.currentState = "homeX"
end

function checkFuel()
    return turtle.getFuelLevel() > 500
end

function refuel()
    for i = 1, 16 do -- loop through the slots
        turtle.select(i) -- change to the slot
        if turtle.refuel(0) then -- if it's valid fuel
            turtle.refuel()
        end
    end
    turtle.select(1)
end

function checkInv()

    if turtle.getItemCount(16) <= 1 then
        return false
    end

    for i = 1,15 do
        if turtle.getItemCount(i) == 0 then
            return true
        end
    end
    return false
end

function loadDeps()
    local loadedJson = os.loadAPI("json")
    if loaded == false then
        shell.run("pastebin","get","4nRg9CHU","json")
        os.loadAPI("json")
    end

    print("Loaded dependencies")
end

function loadState()
    if fs.exists(stateFile) then
        local h = fs.open(stateFile,"r")
        local stateString = h.readAll()
        state = json.decode(stateString)
        h.close()
        print("Loaded state")
    else
        print("No state found")
    end
end

function persistState()
    local h = fs.open(stateFile,"w")
    jsonstring = json.encode(state)
    h.write(jsonstring)
    h.close()
end

function display()
    term.clear()
    local x, h = term.getSize()

    term.setCursorPos(1,1)
    term.write("State: " .. state.currentState)

    term.setCursorPos(x - 10, 1)
    term.write("Fuel: " .. turtle.getFuelLevel())

    local yOffset = 3
    local xOffset = 1
    for x=0,farmWidth do
        for y=0, farmHeight do
            term.setCursorPos(x + xOffset, y + yOffset)
            
            if x == state.farm.position.x -1 and y == state.farm.position.y then
                term.write("X")
            elseif y == 0 or x == 0 or x == farmWidth or y == farmHeight then
                term.write("-")
            else

            end

        end
    end
end

loadDeps()
loadState()

stateMap = {wait = wait, harvest = harvest, leftCorner = leftCorner, rightCorner = rightCorner, home = home, homeX = homeX, homeY = homeY}

while state.currentState ~= "stop" do

    while checkFuel() == false do
        term.clear()
        print("Enter fuel")
        local inp = read()
        refuel()
    end

    display()

    stateFunc = stateMap[state["currentState"]]
    stateFunc()
    persistState()
end