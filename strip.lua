branchSize = 150
state = { trunk = { length = 0, numberOfBranches = 0, lastBranchPosition = 0 },
    branch = {
        length = 0
    },
    position = {
        branch = 0,
        branchFacing = 1,
        trunk = 0,
        trunkFacing = 1
    },
    mine = {
        index = 1
    },
    torch = {
        index = 1
    },
    returnState = "none",
    currentState = "none"
}

stateFile = "/database/strip/state.json"

wasteMaterials = { }
wasteMaterials["minecraft:cobblestone"] = true

function clearForward()
    while turtle.dig() do
        sleep(0.1)
    end
end

function forward()
    while turtle.forward() == false do
        turtle.dig()
    end
end

function up()
    while turtle.up() == false do
        turtle.digUp()
    end
end

function down()
    while turtle.down() == false do
        turtle.digDown()
    end
end

function left()
    turtle.turnLeft()
end

function right()
    turtle.turnRight()
end

function checkFuel()
    return turtle.getFuelLevel() > state.branch.length + state.trunk.length
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

function selectWasteMaterial()
    for i = 1,16 do
        local data = turtle.getItemDetail(i)
        if data then
            if wasteMaterials[data.name] then
                turtle.select(i)
                return true
            end
        end
    end
    return false
end

function placeTorch()
    steps = {left, turtle.place, right} 
    turtle.select(16)
    local fn = steps[state.torch.index]
    fn()
    state.torch.index = state.torch.index + 1

    if state.torch.index > 3 then
        state.torch.index = 1
        state.currentState = state.returnState
    end
    
    turtle.select(1)
end

function mineSlice()
    local mineSliceMap = { forward, up, left, clearForward, down, clearForward, right }
    local func = mineSliceMap[state.mine.index]
    func()
    state.mine.index = state.mine.index + 1
    if state.mine.index == 8 then 
        state.mine.index = 1
        return true
    end
    return false
end

function newBranch()
    return {length = 0, facing = 0}
end

function branch()
    if state.position.branch == 0 and state.branch.facing == 0 then
        if state["trunk"]["numberOfBranches"] % 2 == 0 then
            left()
            state.branch.facing = -1
            state.position.branchFacing = 1
        else
            right()
            state.branch.facing = 1
            state.position.branchFacing = 1
        end
        state.trunk.numberOfBranches = state.trunk.numberOfBranches + 1
    end

    if state.position.branchFacing == -1 then
        left()
        left()
        state.position.branchFacing = 1
        print("Turning around")
    elseif state.position.branchFacing == 0 then
        if state.branch.facing == -1 then
            left()
        else
            right()
        end
        state.position.branchFacing = 1
    end

    if checkInv() == false and state.mine.index == 1 then
        state.currentState = "branchReturn"
    elseif state.branch.length >= branchSize then
        state.currentState = "branchReturn"   
    elseif state.position.branch < state.branch.length then
        forward()
        state.position.branch = state.position.branch + 1
    else
        if mineSlice() then
            state["branch"]["length"] = state["branch"]["length"] + 1
            state["position"]["branch"] = state["position"]["branch"] + 1

            if state.branch.length % 10 == 0 then
                state.returnState = "branch"
                state.currentState = "torch"
            end
        end
    end
end

function branchReturn()
    if state.position.branch == state.branch.length and state.position.branchFacing == 1 then
        left()
        left()
        state.position.branchFacing = -1
    end

    if state.position.branch == 0 then
        state.currentState = "none"
        if state.branch.facing == 1 then
            right()
        else
            left()
        end
    else
        forward()
        state.position.branch = state.position.branch - 1
    end
end

function returnToBranch()
    if state.position.trunkFacing == -1 then
        left()
        left()
        state.position.trunkFacing = 1
    end

    if state.position.trunk < state.trunk.lastBranchPosition then
        forward()
        state.position.trunk = state.position.trunk + 1
    end

    if state.position.trunk == state.trunk.lastBranchPosition then
        state.position.branchFacing = 0
        state.currentState = "branch"
    end
end

function trunkReturn()
    if state.position.trunkFacing == 1 then
        left()
        left()
        state.position.trunkFacing = -1
    end

    if state.position.trunk > 0 then
        forward()
        state.position.trunk = state.position.trunk - 1
    else
        state.currentState = "unload"
    end
end

function unload()
    for i = 1,15 do
        turtle.select(i)
        turtle.drop()
    end
    state.currentState = "none"
end

function mine()
    if state.position.trunkFacing == -1 then
        left()
        left()
        state.position.trunkFacing = 1
    end

    if checkInv() == false and state.mine.index == 1 then
        state.currentState = "trunkReturn"
    elseif checkFuel() == false then 
        state.currentState = "trunkReturn"    
    elseif state.position.trunk < state.trunk.length then
        forward()
        state.position.trunk = state.position.trunk + 1
    elseif ( state.position.trunk == state.trunk.lastBranchPosition + 4 and state.trunk.numberOfBranches % 2 == 0 ) or ( state.position.trunk == state.trunk.lastBranchPosition and state.trunk.numberOfBranches % 2 ~= 0 ) then
        state["currentState"] = "branch"
        state.trunk.lastBranchPosition = state.position.trunk
        state.branch = newBranch()
    else
        if mineSlice() then
            state.position.trunk = state.position.trunk + 1
            state.trunk.length = state.trunk.length + 1

            if state.trunk.length % 10 == 0 then
                state.returnState = "trunk"
                state.currentState = "torch"
            end
        end
    end
end

function decideState()
    if checkFuel() == false or checkInv() == false then
        state.currentState = "trunkReturn"
    elseif state.branch.length < branchSize and state.branch.length > 0 then
        state.currentState = "returnToBranch"
    else
        state.currentState = "trunk"
    end
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
end

loadDeps()
loadState()

stateMap = {trunk = mine, trunkReturn = trunkReturn, branch = branch, branchReturn = branchReturn, returnToBranch = returnToBranch, none = decideState, unload = unload, torch = placeTorch}

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