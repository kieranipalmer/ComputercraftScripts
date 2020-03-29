recipeFolder = "/database/crafter/"
slots = {1,2,3,5,6,7,9,10,11}

function clearInventory()
    for i=1,16 do
        turtle.select(i)
        turtle.drop()
    end
    turtle.select(1)
end

function turnAround()
    turtle.turnLeft()
    turtle.turnLeft()
end 

function checkIsItem(name)
    local data = turtle.getItemDetail(slotIndex)

    if data then
        local slotName = data.name
        print(slotName)
        print(name)
        print("**********")
        return slotName == name
    end

    return false
end

function findItem(name)
    turtle.select(4)
    turnAround()
    turtle.drop()
    turnAround()
    while turtle.suck() do
        if checkIsItem(name) then
            return true
        end

        turnAround()
        turtle.drop()
        turnAround()
    end

    return false
end

function resetChests()
    clearInventory()
    turnAround()
    while turtle.suck() do 
        turnAround()
        turtle.drop()
        turnAround()
    end
    turnAround()
end

function getRecipeFile(recipe)
    local path = recipeFolder .. recipe .. ".craft"
    if fs.exists(path) == false then
        return false, nil
    end

    local handle = fs.open(path, "r")
    return true, handle
end

function parseRecipieFile(handle)
    local line = handle.readLine()
    local i = 1
    local data = {}
    while line do
        data[i] = line
        line = handle.readLine()
        i = i + 1
    end
    return data
end

function craft(recipe)
    local exists, handle = getRecipeFile(recipe)

    if exists == false then
        print("I don't know how to make " ..recipe)
        return false
    end

    recipeShape = parseRecipieFile(handle)
    handle.close()

    for i=1,10 do
        local itemName = recipeShape[i]
        if itemName ~= "nil" then
            local found = findItem(itemName)
            if found == false then
                print("I can't find " .. itemName)
                local crafted = craft(itemName)
                turtle.select(1)

                return false
            end
            
            turtle.transferTo(slots[i])
        end
    end

    return turtle.craft()
end

resetChests()
print("Enter recipie")
local recipe = read()
local success = craft(recipe)
if success then
    print("Done!")
end
resetChests()