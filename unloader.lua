inputSide = "bottom"

state = {
    currentState = "high"
}

stateFile = "/database/unloader/state.json"

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

function highState(input)
    if input == false then
        term.clear()
        term.setCursorPos(1,1)
        print("GO CART GO")
        redstone.setOutput("right",true)
        sleep(1)
        redstone.setOutput("right",false)
        state.currentState = "low"
    end
end

function lowState(input)
    if input == true then
        state.currentState = "high"
    end
end

loadDeps()
loadState()

states = {low = lowState, high = highState}
while true do
    local input = redstone.getInput(inputSide)
    local stateFn = states[state.currentState]
    stateFn(input)
    persistState()
    sleep(0.5)
end