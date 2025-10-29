export type Content = string -- remove that, i needed that only for visual studio code coding
-- my roblox-lsp doesn't have Mesh/Image API classes

-- code is messy lol.

local AssetService = game:GetService("AssetService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local paths, sharedPaths = require(ReplicatedStorage.paths):get()

local LocalPlayer = Players.LocalPlayer

local handler = {}
handler.__index = handler
handler.OkayValues = {
	vertices = require(script:WaitForChild("vertices")),
	normals = require(script:WaitForChild("normals")),
	uvs = require(script:WaitForChild("uvs")),
	faces = require(script:WaitForChild("faces")),
	vertexPositions = require(script:WaitForChild("vertexPositions")),
}

function handler:init(initer)
	if not game:IsLoaded() then
		game.Loaded:Wait()
	end
	initer.Events.HandlersLoaded:Wait()
	print("Guardian status: checking.")
	self = setmetatable({}, handler)
	self.alert = false

	self.checkMeshes = {
		torso = "rbxasset://avatar/meshes/torso.mesh",
		leftarm = "rbxasset://avatar/meshes/leftarm.mesh",
		rightarm = "rbxasset://avatar/meshes/rightarm.mesh",
		leftleg = "rbxasset://avatar/meshes/leftleg.mesh",
		rightleg = "rbxasset://avatar/meshes/rightleg.mesh",
	}
	--[[	for name: string, content: Content in pairs(self.checkMeshes) do
		print(`--------------{name}--------------`)
		local EditableMesh: EditableMesh = AssetService:CreateEditableMeshAsync(content)

		local vertexesPositions = {}

		for index, id in pairs(EditableMesh:GetVertices()) do
			local cords = EditableMesh:GetPosition(id)
			vertexesPositions[index] = `Vector3.new({cords})`
		end
		print(`{name} = `, vertexesPositions)
	end]]

	local function checkValues(name, values1, values2, isPositionCheck)
		local checkResult = true

		local currentValues = values1
		local okayValues = values2

		if #currentValues ~= #okayValues then
			warn(name, "NOT EQUAL VALUE1 AND VALUE2")
			checkResult = false
		end
		if not isPositionCheck then
			for index, _ in pairs(currentValues) do
				if currentValues[index] ~= okayValues[index] then
					warn(name, `WEIRD {index} currentValue: {currentValues[index]}, okayValue = {okayValues[index]}`)
					checkResult = false
					break
				end
			end
		else
			for index, _ in pairs(currentValues) do
				local currentVector3 = Vector3.new(unpack(currentValues[index]))
				local okayVector3 = Vector3.new(unpack(okayValues[index]))
				if currentVector3 ~= okayVector3 then
					warn(name, `WEIRD {index} {(okayVector3 - currentVector3).Magnitude}`)
					checkResult = false
					break
				end
			end
		end
		return checkResult
	end

	local startTick = tick()
	for name: string, content: Content in pairs(self.checkMeshes) do
		--print(`--------------{name}--------------`)
		local EditableMesh: EditableMesh = AssetService:CreateEditableMeshAsync(content)

		do -- total check
			--print(`{name}: getting verts check`)
			local vertsCheck = checkValues(name, EditableMesh:GetVertices(), self.OkayValues.vertices[name])
			--print(`{name}: getting verts-positions check`)

			local currentVertsPositions = {}
			for index, id in pairs(EditableMesh:GetVertices()) do
				local cords = EditableMesh:GetPosition(id)
				currentVertsPositions[index] = { cords.X, cords.Y, cords.Z }
			end

			local vertsPositionsCheck =
				checkValues(name, currentVertsPositions, self.OkayValues.vertexPositions[name], true)

			--print(`{name}: getting normals check`)
			local normalsCheck = checkValues(name, EditableMesh:GetNormals(), self.OkayValues.normals[name])

			--print(`{name}: getting uvs check`)
			local uvsCheck = checkValues(name, EditableMesh:GetUVs(), self.OkayValues.uvs[name])

			--print(`{name}: getting faces check`)
			local facesCheck = checkValues(name, EditableMesh:GetFaces(), self.OkayValues.faces[name])

			--print(`{name}:`, vertsCheck, vertsPositionsCheck, normalsCheck, uvsCheck, facesCheck)

			self.alert = not (vertsCheck and vertsPositionsCheck and normalsCheck and uvsCheck and facesCheck)
		end

		if self.alert then
			break
		end
		print(`{name}: all good, pass`)
	end

	if self.alert then
		warn(`Guardian status: detected weird limb models, USER:{LocalPlayer.UserId}`)
		LocalPlayer:Kick("detected weird character limb models")
	else
		print("Guardian status: all good")
	end
	local endTick = tick()

	print(string.format("Guardian: took %fms (%fs) to process", (endTick - startTick) * 1000, (endTick - startTick)))
end

return handler
