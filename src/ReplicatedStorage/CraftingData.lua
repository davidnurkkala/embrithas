local ItemData = require(script.Parent.ItemData)

local function material(id, count)
	return {Category = "Materials", Id = id, Count = count or 1}
end

local function weapon(id, count)
	return {Category = "Weapons", Id = id, Count = count or 1}
end

local function ability(id, count)
	return {Category = "Ability", Id = id, Count = count or 1}
end

local function gold(amount)
	return {Category = "Gold", Amount = amount}
end

local function alignment(faction, amount)
	return {Category = "Alignment", Faction = faction, Amount = amount}
end

local categories = {
	[1] = {
		Name = "Basic Weapons",
		Recipes = {
			-- hunting bow
			{
				Inputs = {
					material(6, 10),
					material(1, 5),
				},
				Outputs = {
					weapon(6, 1),
				}
			},
			
			-- iron-ringed wand
			{
				Inputs = {
					material(6, 10),
					material(1, 5),
				},
				Outputs = {
					weapon(66, 1)
				}
			},
		}
	},
	
	[2] = {
		Name = "Advanced Weapons",
		Recipes = {
			-- crossbow
			{
				Inputs = {
					material(1, 10),
					material(6, 20),
					gold(2500),
				},
				Outputs = {
					weapon(22, 1),
				}
			},
			
			-- spiked axe and buckler
			{
				Inputs = {
					material(2, 50),
					material(6, 25),
					weapon(2, 1),
					gold(5000),
				},
				Outputs = {
					weapon(34, 1),
				}
			},
			
			-- lightning staff
			{
				Inputs = {
					material(2, 50),
					material(10, 25),
					weapon(13, 1),
					gold(5000),
				},
				Outputs = {
					weapon(18, 1),
				}
			},
			
			-- blade of vengeance
			{
				Name = "Blade of Vengeance",
				Inputs = {
					material(8, 50),
					weapon(8, 1),
					alignment("College", 10),
				},
				Outputs = {
					weapon(20, 1),
					alignment("Order", -2),
				}
			},
		}
	},
	
	[3] = {
		Name = "Material Refining",
		Recipes = {
			-- steel
			{
				Inputs = {
					material(1, 2),
					material(12, 1),
				},
				Outputs = {
					material(2, 1),
				}
			},
			
			-- burn wood for charcoal
			{
				Name = "Burn Iskith Planks for Charcoal",
				Inputs = {
					material(6, 5),
					gold(100),
				},
				Outputs = {
					material(12, 2),
				},
			},
			
			-- metallic corruption seeding in steel
			{
				Name = "Corrupt Steel",
				Inputs = {
					material(2, 4),
					material(8, 1),
				},
				Outputs = {
					material(8, 2),
					alignment("Order", -1),
				},
			},
			
			-- metallic corruption seeding in bluesteel
			{
				Name = "Corrupt Bluesteel",
				Inputs = {
					material(4, 2),
					material(8, 1),
				},
				Outputs = {
					material(8, 2),
					alignment("Order", -1),
				}
			},
		}
	},
	
	[4] = {
		Name = "Steel Weapons",
		Recipes = {
			-- steel halberd
			{
				Inputs = {
					weapon(9, 1),
					material(2, 50),
				},
				Outputs = {
					weapon(10, 1),
				},
			},
			
			-- steel dual dirks
			{
				Inputs = {
					weapon(43, 1),
					material(2, 50),
				},
				Outputs = {
					weapon(44, 1),
				}
			},
			
			-- steel rapier
			{
				Inputs = {
					weapon(38, 1),
					material(2, 50),
				},
				Outputs = {
					weapon(39, 1),
				}
			}
		}
	},
	
	[5] = {
		Name = "Bluesteel Weapons",
		Recipes = {
			-- bluesteel handaxes
			{
				Inputs = {
					weapon(31, 1),
					material(4, 35),
				},
				Outputs = {
					weapon(32, 1),
				}
			},
			
			-- bluesteel battleaxe
			{
				Inputs = {
					weapon(3, 1),
					material(4, 35),
				},
				Outputs = {
					weapon(33, 1),
				}
			},
			
			-- bluesteel crossbow
			{
				Inputs = {
					weapon(22, 1),
					material(4, 35),
				},
				Outputs = {
					weapon(40, 1),
				}
			},
			
			-- bluesteel sword
			{
				Inputs = {
					weapon(4, 1),
					material(4, 35),
				},
				Outputs = {
					weapon(41, 1),
				},
			},
			
			-- bluesteel axe
			{
				Inputs = {
					weapon(2, 1),
					material(4, 35),
				},
				Outputs = {
					weapon(42, 1),
				}
			},
		}
	},
	
	[6] = {
		Name = "Shadow Weapons",
		Recipes = {
			-- staff of shadows
			{
				Name = "Staff of Shadows",
				Inputs = {
					material(11, 1),
					material(2, 50),
					material(6, 50),
					gold(10000),
					alignment("College", 25),
				},
				Outputs = {
					weapon(28, 1),
					alignment("Order", -5),
				},
			},
			
			-- shadow scythe
			{
				Name = "Shadow Scythe",
				Inputs = {
					material(11, 1),
					material(2, 50),
					material(6, 50),
					gold(10000),
					alignment("League", 25),
				},
				Outputs = {
					weapon(29, 1),
					alignment("Order", -5),
				}
			},
			
			-- shadow wand
			{
				Name = "Shadow Wand",
				Inputs = {
					material(11, 1),
					material(2, 25),
					material(6, 50),
					material(10, 25),
					gold(10000),
				},
				Outputs = {
					weapon(67, 1),
					alignment("Order", -5),
				}
			},
		}
	},
	
	[7] = {
		Name = "Undead Weapons",
		Recipes = {
			{
				Inputs = {
					weapon(48, 1),
					alignment("Order", 50),
				},
				Outputs = {
					weapon(50, 1),
				}
			},
			{
				Inputs = {
					weapon(48, 1),
					alignment("League", 50),
				},
				Outputs = {
					weapon(51, 1),
				}
			}
		}
	}
}

-- iron weapons
for _, id in pairs{2, 3, 4, 5, 9, 12} do
	table.insert(categories[1].Recipes, 1, {
		Inputs = {
			material(1, 10),
			material(6, 5),
		},
		Outputs = {
			weapon(id, 1),
		}
	})
end

for categoryIndex, category in pairs(categories) do
	for index, recipe in pairs(category.Recipes) do
		recipe.Id = index
		recipe.CategoryIndex = categoryIndex
		
		if not recipe.Name then
			if #recipe.Outputs > 1 then
				error("Recipe "..index.." has more than one output and cannot be auto-named. Provide a manual name.")
			else
				local output = recipe.Outputs[1]
				local category = output.Category
				local id = output.Id
				local itemData = ItemData[category][id]
				recipe.Name = itemData.Name
			end
		end
	end
end

return {
	Categories = categories,
}