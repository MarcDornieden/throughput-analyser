local item = table.deepcopy(data.raw.armor["heavy-armor"])

item.name = "TA-Armor"
item.icons= {
   {
      icon=item.icon,
      tint={r=0,g=0,b=1,a=0.3}
   },
}

local recipe = table.deepcopy(data.raw.recipe["heavy-armor"])
recipe.enabled = true
recipe.name = "TA-Armor"
recipe.ingredients = {{"copper-plate",200},{"steel-plate",50},{"electronic-circuit",10}}
recipe.result = "TA-Armor"

data:extend{item,recipe}