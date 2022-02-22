local Super = require(script.Parent)
local MaterialService = Super:Extend()

MaterialService.MaterialData = require(Super.Storage.ItemData).Materials

function MaterialService:OnCreated()
	self.MaterialDatasByInternalName = {}
	for _, materialData in pairs(self.MaterialData) do
		self.MaterialDatasByInternalName[materialData.InternalName] = materialData
	end
end

function MaterialService:GetMaterialData(id)
	local data = {}
	for key, val in pairs(self.MaterialData[id]) do
		data[key] = val
	end
	return data
end

function MaterialService:GetMaterialDataByInternalName(internalName)
	return self.MaterialDatasByInternalName[internalName]
end

local Singleton = MaterialService:Create()
return Singleton
