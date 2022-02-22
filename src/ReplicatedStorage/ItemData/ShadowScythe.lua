return {
	Name = "Shadow Scythe",
	Class = "WeaponScythe",
	AssetsName = "ShadowScythe",
	Description = "A creation of the League, the semi-conscious shadow-infused worldstone within this weapon can witness and reward acts of great valor.",
	Image = "rbxassetid://5470797716",
	UpgradeMaterials = {Steel = 0.1, Worldstone = 0.01},
	Rarity = "Rare",
	Perks = {
		"Upon hitting three attacks without missing, heal.",
	},
	
	Args = {
		OnHitSuccess = function(self)
			self.ShadowScytheHits = (self.ShadowScytheHits or 0) + 1
			
			if self.ShadowScytheHits >= 3 then
				self.ShadowScytheHits = 0
				
				self:GetService("EffectsService"):RequestEffectAll("AirBlast", {
					Position = self.Legend:GetFootPosition(),
					Radius = 8,
					Color = Color3.new(0, 0, 0),
					Duration = 0.5,
					Style = Enum.EasingStyle.Quint,
					Direction = Enum.EasingDirection.Out,
				})
				
				self.Legend:SoundPlayByObject(self.Assets.Sounds.Heal)
				
				local maxHealth = self.Legend.MaxHealth:Get()
				local healing = maxHealth * 0.1
				healing = math.min(healing, maxHealth - self.Legend.Health)
				
				self:GetService("DamageService"):Heal{
					Target = self.Legend,
					Source = self.Legend,
					Amount = healing,
				}
			end
		end,
		OnHitFailure = function(self)
			self.ShadowScytheHits = 0
		end,
	}
}