--[[
	A model view inside a ViewportFrame.
	By default, shows a view similar to the Toolbox asset preview.

	Required Props:
		Instance Model: The model to view.

	Optional Props:
		boolean CurrentCamera: Whether to use workspace.CurrentCamera.
		callback Start: A function called when the component mounts.
			Passes the viewmodel and camera as parameters. Useful for
			setting up connections to the mouse or other events.

		callback Stop: A function called when the component unmounts.
			Passes the viewmodel and camera as parameters.
]]

local Workspace = game:GetService("Workspace")
local Roact = require(game.ReplicatedStorage.Packages.Roact)

local ModelView = Roact.PureComponent:extend("ModelView")

local t = require(game.ReplicatedStorage.Packages.t)
local typecheck = t.interface({
	Model = t.Instance,
	ZIndex = t.optional(t.integer),
	CurrentCamera = t.optional(t.boolean),
	Start = t.optional(t.callback),
	Stop = t.optional(t.callback),
	ShowOriginal = t.optional(t.boolean),
})

ModelView.defaultProps = {
	Start = function(model, camera)
		local cf, extents = model:GetBoundingBox()
		model:TranslateBy(-cf.p)
		local offset = Vector3.new(1, 1, 1) * extents.magnitude * 0.8
		camera.FieldOfView = 40
		camera.Focus = CFrame.new()
		camera.CFrame = CFrame.new(offset, Vector3.new())
	end,
}

local function safeClone(model)
	local clone = model:Clone()
	for _, descendant in ipairs(clone:GetDescendants()) do
		if descendant:IsA("LuaSourceContainer") then
			descendant:Destroy()
		end
	end
	return clone
end

function ModelView:init(props)
	assert(typecheck(props))
	if props.CurrentCamera then
		self.camera = Workspace.CurrentCamera
		assert(self.camera, "Workspace had no CurrentCamera.")
	else
		self.camera = Instance.new("Camera")
	end

	self.state = {
		Model = props.ShowOriginal and props.Model or safeClone(props.Model),
	}
	self.viewport = Roact.createRef()
end

function ModelView:didUpdate(lastProps)
	local props = self.props
	if lastProps.Model ~= props.Model then
		local newModel = props.ShowOriginal and props.Model or safeClone(props.Model)
		self:setState({
			Model = newModel,
		})
		if self.viewport then
			newModel.Parent = self.viewport.current
			if self.props.Start then
				self.props.Start(newModel, self.camera, self.viewport.current)
			end
		end
	end
end

function ModelView:render()
	local props = self.props

	return Roact.createElement("ViewportFrame", {
		Size = UDim2.fromScale(1, 1),
		ZIndex = props.ZIndex,
		BackgroundTransparency = 1,
		BackgroundColor3 = Color3.new(),
		CurrentCamera = self.camera,
		LightColor = Color3.new(1, 1, 1),
		LightDirection = Vector3.new(-1, -1, 0),
		[Roact.Ref] = self.viewport,
	}, self.props[Roact.Children])
end

function ModelView:didMount()
	if self.viewport then
		self.state.Model.Parent = self.viewport.current
		if self.props.Start then
			self.props.Start(self.state.Model, self.camera, self.viewport.current)
		end
	end
end

function ModelView:willUnmount()
	if self.props.Stop then
		self.props.Stop(self.state.Model, self.camera)
	end
	if self.camera then
		self.camera:Destroy()
	end
	if self.state.Model then
		self.state.Model:Destroy()
	end
end

return ModelView
