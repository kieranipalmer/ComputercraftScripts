recipeFolder = "/database/crafter/"
slots = {1,2,3,5,6,7,9,10,11}

function isValidRecipe()
    return turtle.craft(0)
end

function getRecipe()
    recipe = {}
    for i=1,10 do
        local slotIndex = slots[i]
        local data = turtle.getItemDetail(slotIndex)

        if data then
            recipe[i] = data.name
            print("Item name: ", data.name)
            print("Item damage value: ", data.damage)
            print("Item count: ", data.count)
        else
            recipe[i] = "nil"
        end
    end

    return recipe
end

function getRecipeOutput()
    local didCraft = turtle.craft()
    local data = turtle.getItemDetail(1)
    return didCraft, data.name
end

if isValidRecipe() == false then
    print("Not a valid recipe")
else
    local recipe = getRecipe()
    local didCraft, name = getRecipeOutput()
    local path = recipeFolder .. name .. ".craft"
    local handle = fs.open(path, "w")
    for i=1,10 do
        local name = recipe[i]
        handle.writeLine(name)
    end
    handle.close()
    print("I learnt how to make a " .. name)
end