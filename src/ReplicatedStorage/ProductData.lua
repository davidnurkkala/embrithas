local MarketplaceService = game:GetService("MarketplaceService")

local doorkickAnimation = {
	[1] = {
		Name = "Kick",
		Description = "The default doorkick animation.",
		AnimationName = "LegendKick",
		Image = "rbxassetid://5640770868",
	},
	[2] = {
		Name = "Shoulder Charge",
		Description = "Ram into the door with your shoulder like a professional linebacker.",
		AnimationName = "LegendShoulderCharge",
		Image = "rbxassetid://5640923555",
		ProductId = 1084214832,
	},
	[3] = {
		Name = "Headbutt",
		Description = "I don't think this is what Leon meant when he said \"it's important to use your head.\"",
		AnimationName = "LegendHeadbutt",
		Image = "rbxassetid://5640770717",
		ProductId = 1084214870,
	},
	[4] = {
		Name = "Belly Flop",
		Description = "Slamming your abdomen into dooors made of wood, metal, or rock? What could possibly go wrong?",
		AnimationName = "LegendBellyFlop",
		Image = "rbxassetid://5640770481",
		ProductId = 1084214903,
	},
	[5] = {
		Name = "Faceplant",
		Description = "Trip and, uh... fall through the door. Unleash your inner clutz.",
		AnimationName = "LegendFaceplant",
		Image = "rbxassetid://5640770566",
		ProductId = 1084214945,
	},
	[6] = {
		Name = "Uppercut",
		Description = "Deliver a knock-out punch to the door! That'll teach 'em!",
		AnimationName = "LegendUppercut",
		Image = "rbxassetid://5640923615",
		ProductId = 1084214980,
	},
	[7] = {
		Name = "Slide Kick",
		Description = "No matter how unrealistic the friction between your behind and the ground may be, slide kick through doors like an apex legend!",
		AnimationName = "LegendSlideKick",
		Image = "rbxassetid://5640771049",
		ProductId = 1084215024,
	},
	[8] = {
		Name = "Flying Kick",
		Description = "Exactly as Chuck Norris would've done.",
		AnimationName = "LegendFlyingKick",
		Image = "rbxassetid://5640770649",
		ProductId = 1084215060,
	},
	[9] = {
		Name = "Karate Palm",
		Description = "HIYAAA!",
		AnimationName = "LegendKarate",
		Image = "rbxassetid://5640770806",
		ProductId = 1084215119,
	},
	[10] = {
		Name = "T-pose",
		Description = "Assert dominance on whatever doors may cross your path.",
		AnimationName = "LegendTPose",
		Image = "rbxassetid://5714821879",
		ProductId = 1087916228,
	},
}

local lantern = {
	[1] = {
		Name = "Rookie Lantern",
		Description = "A very simple iron lantern.",
		AssetName = "LanternDefault",
		Image = "rbxassetid://5666335890",
	},
	[2] = {
		Name = "Unlimited Lantern",
		Description = "A special lantern given to every purchaser of Heroes! 2 Unlimited.",
		AssetName = "LanternUnlimited",
		Image = "rbxassetid://5696347357",
		UnlimitedItem = true,
	},
	[3] = {
		Name = "Evrig Explorer's Lamp",
		Description = "Lit with enchanted Bluesteel, this durable lamp even works underwater or in gale-force winds. Perfect for the Evrigan sailor.",
		AssetName = "LanternEvrig",
		Image = "rbxassetid://5666335953",
		ProductId = 1085465135,
	},
	[4] = {
		Name = "Jolian Gas Lamp",
		Description = "A foul air pulled from the ground of the Jolian homeland burns brightly inside this precision-engineered lamp.",
		AssetName = "LanternJolian",
		Image = "rbxassetid://5666336019",
		ProductId = 1085465104,
	},
	[5] = {
		Name = "Night Watch's Lantern",
		Description = "A practical black-and-white lantern that burns bright to keep you awake on those long nights.",
		AssetName = "LanternNightWatch",
		Image = "rbxassetid://5666336127",
		ProductId = 1085465053,
	},
	[6] = {
		Name = "Lantern of Valor",
		Description = "A popular style in the League of Valor. Hardy but stylish.",
		AssetName = "LanternValor",
		Image = "rbxassetid://5666336223",
		ProductId = 1085465256,
	},
	[7] = {
		Name = "Jack o' Lantern",
		Description = "A carved pumpkin with a candle inside. Adorable and festive!",
		AssetName = "LanternJackOLantern",
		Image = "rbxassetid://5817291722",
		ProductId = 1105760207,
		Offsale = true,
	},
	[8] = {
		Name = "Dominating Soul Cage",
		Description = "Listen too closely and you'll hear the voices long after you ought to.",
		AssetName = "LanternDominatingSoulCage",
		Image = "rbxassetid://5826643669",
		ProductId = 1106244174,
		Offsale = true,
	},
	[9] = {
		Name = "Devious Soul Cage",
		Description = "Listen too closely and you'll hear the voices long after you ought to.",
		AssetName = "LanternDeviousSoulCage",
		Image = "rbxassetid://5826643763",
		ProductId = 1106852974,
		Offsale = true,
	},
	[10] = {
		Name = "Raging Soul Cage",
		Description = "Listen too closely and you'll hear the voices long after you ought to.",
		AssetName = "LanternRagingSoulCage",
		Image = "rbxassetid://5826643847",
		ProductId = 1106853037,
		Offsale = true,
	},
	[11] = {
		Name = "Mystic Soul Cage",
		Description = "Listen too closely and you'll hear the voices long after you ought to.",
		AssetName = "LanternMysticSoulCage",
		Image = "rbxassetid://5826643591",
		ProductId = 1106853109,
		Offsale = true,
	},
}

local doorEffect = {
	[1] = {
		Name = "None",
		Description = "Doors you kick down will just go flying.",
		Image = "",
	},
}

local hitEffect = {
	[1] = {
		Name = "Default",
		Description = "Simple white sparks.",
		Image = "rbxassetid://5720632576",
		AssetName = "Default",
	},
	[2] = {
		Name = "Hearts",
		Description = "Show your enemies some love.",
		Image = "rbxassetid://5720681325",
		AssetName = "Hearts",
		ProductId = 1088564656,
	},
	
	-- kadentong22 was here 9/22/2020
	[3] = {
		Name = "\"Fruit Punch\"",
		Description = "This delicious beverage will have your enemies feeling sanguine in no time.",
		Image = "rbxassetid://5720791012",
		AssetName = "Blood",
		ProductId = 1088583439, 
	},
	
	[4] = {
		Name = "Gold Coins",
		Description = "Cause gold coins to explode from your enemies!",
		Image = "rbxassetid://5720891408",
		AssetName = "GoldCoins",
		ProductId = 1088599025,
	},
	
	[5] = {
		Name = "Ancient Gold Coins",
		Description = "These coins are said to come from a time long since lost, when Heroes had yet to learn how to sprint...",
		Image = "rbxassetid://5720891499",
		AssetName = "GoldCoinsHeroes1",
		ProductId = 1088599119,
	},
	[6] = {
		Name = "Bats",
		Description = "Who knew monsters made for such good nocturnal roosts?",
		Image = "rbxassetid://5817375304",
		AssetName = "Bats",
		ProductId = 1105766451,
		Offsale = true,
	},
	[7] = {
		Name = "Candy",
		Description = "Trick AND treat. Except the trick is violence.",
		Image = "rbxassetid://5817460674",
		AssetName = "Candy",
		ProductId = 1105772778,
		Offsale = true,
	},
	[8] = {
		Name = "100",
		Description = "Gave up 100 levels when transferring to Embrithas.",
		Image = "rbxassetid://6386058923",
		AssetName = "100Emoji",
		ProductId = -4,
		Offsale = true,
	},
	[9] = {
		Name = "Map",
		Description = "Gave up mission completions with at least 1 raid when transferring to Embrithas.",
		Image = "rbxassetid://6386098516",
		AssetName = "MapEmoji",
		ProductId = -5,
		Offsale = true,
	}
}

local killEffect = {
	[1] = {
		Name = "None",
		InternalName = "None",
		Description = "The default on-kill effect.",
		Image = "",
	},
	[2] = {
		Name = "Ghost",
		InternalName = "Ghost",
		Description = "Your enemies' spooky ghosts will fly away from their bodies!",
		Image = "rbxassetid://5826670391",
		ProductId = 1105791227,
		Offsale = true,
	},
}

local celebrationAnimation = {
	[1] = {
		Name = "None",
		Description = "The default celebration.",
		Image = "",
	},
	[2] = {
		Name = "Cheer",
		Description = "Raise your fist high in victorious cheering!",
		Image = "",
		AnimationName = "CelebrationCheer",
		ProductId = 1118274045,
	},
}

local celebrationEmote = {
	[1] = {
		Name = "None",
		Description = "The default emote to display when celebrating.",
		Image = "",
	},
	[2] = {
		Name = "Slayer Knight Approves",
		Description = "A glowing recommendation from your friendly neighborhood Slayer Knight.",
		Image = "rbxassetid://5968899209",
		ProductId = 1118274510,
	},
	[3] = {
		Name = "Robloxian Hero",
		Description = "A robloxian clad in Slayer's armor looks to the future. Inspiring.",
		Image = "rbxassetid://5968899510",
		ProductId = 1118274815,
	},
	[4] = {
		Name = "Red Flag",
		Description = "Show your loyalty to the red team in a Contest of Slayers!",
		Image = "rbxassetid://5968899402",
		ProductId = 1118275022,
	},
	[5] = {
		Name = "Blue Flag",
		Description = "Show your loyalty to the blue team in a Contest of Slayers!",
		Image = "rbxassetid://5968899122",
		ProductId = 1118275221,
	},
	[6] = {
		Name = "Give to Orc",
		Description = "Everyone's favorite orc lieutenant wants that, and I don't think he's asking permission.",
		Image = "rbxassetid://5968899602",
		ProductId = 1118275554,
	},
	[7] = {
		Name = "Leon Facepalming",
		Description = "\"Rookie, all you have to do is click the \"Start\" button. It's even bolded.\"",
		Image = "rbxassetid://5968899323",
		ProductId = 1118275863,
	},
	[8] = {
		Name = "Threatening Adrasta",
		Description = [["Slayer, do you know what this curious Jolian device does?"]],
		Image = "rbxassetid://5968899012",
		ProductId = 1118276198,
	},
	[9] = {
		Name = "Avery is Displeased",
		Description = "In fairness, is the deacon really ever otherwise?",
		Image = "rbxassetid://5968937080",
		ProductId = 1118276830,
	},
	[10] = {
		Name = "Pixel Golden Blacksmith's Maul",
		Description = "You might not have the weapon, but you can have this!",
		Image = "rbxassetid://5968937174",
		ProductId = 1118277029,
	},
	[11] = {
		Name = "Small Savings",
		Description = "Gave up at least 10,000 gold when transferring to Embrithas.",
		Image = "rbxassetid://6385902821",
		ProductId = -1,
		Offsale = true,
	},
	[12] = {
		Name = "Big Bank",
		Description = "Gave up at least 100,000 gold when transferring to Embrithas.",
		Image = "rbxassetid://6385902716",
		ProductId = -2,
		Offsale = true,
	},
	[13] = {
		Name = "Fabulous Fortune",
		Description = "Gave up at least 1,000,000 gold when transferring to Embrithas.",
		Image = "rbxassetid://6385902624",
		ProductId = -3,
		Offsale = true,
	}
}

local expansion = {
	[1] = {
		Name = "Expansion Pack: Corrupted Elementals",
		Description = "Uncover a new threat to all mortalkind as the forces of nature themselves turn against you.",
		ProductId = 1087064193,
	}
}

local categories = {
	DoorkickAnimation = doorkickAnimation,
	Lantern = lantern,
	Expansion = expansion,
	DoorEffect = doorEffect,
	HitEffect = hitEffect,
	KillEffect = killEffect,
	CelebrationAnimation = celebrationAnimation,
	CelebrationEmote = celebrationEmote,
}

for categoryName, products in pairs(categories) do
	for _, product in pairs(products) do
		if product.ProductId then
			local success, info = pcall(function()
				return MarketplaceService:GetProductInfo(product.ProductId, Enum.InfoType.Product)
			end)
			if success then
				product.Price = info.PriceInRobux
			else
				product.Price = 0
			end
		end
	end
end

return categories