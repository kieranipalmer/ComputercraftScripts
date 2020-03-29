inputSide = "bottom"
loadingTime = 60

state = {
    currentState = "detect",
    cartTime = 0
}

stateFile = "/database/loader/state.json"

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

function getTime()
    return os.epoch("utc") / 1000
end

function time()
    if getTime() - state.cartTime >= loadingTime then
        redstone.setOutput("right", true)
        sleep(1)
        redstone.setOutput("right",false)
        state.currentState = "detect"
    else
        redstone.setOutput("back",true)
        sleep(1)
        redstone.setOutput("back",false)
    end
end

function detect()
    if redstone.getInput("left") == true then
        state.currentState = "time"
        state.cartTime = getTime()
    else
        sleep(0.5)
    end
end

loadDeps()
loadState()

states = {time = time, detect = detect}
while true do
    local input = redstone.getInput(inputSide)
    local stateFn = states[state.currentState]
    stateFn(input)
    persistState()
    sleep(0.5)
end