loadstring(game:HttpGet("https://raw.githubusercontent.com/CioKiTTY/NevermoreModules/main/loader.lua"))()

--<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>--
---<< Services >>---
local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local CoreGui = game:GetService("CoreGui")

--<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>--
---<< Libraries >>---
local UILibrary = loadstring(
	game:HttpGetAsync("https://github.com/ActualMasterOogway/Fluent-Renewed/releases/latest/download/Fluent.luau")
)()
local SaveManager = loadstring(
	game:HttpGetAsync(
		"https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/master/Addons/SaveManager.luau"
	)
)()
local InterfaceManager = loadstring(
	game:HttpGetAsync(
		"https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/master/Addons/InterfaceManager.luau"
	)
)()
local Maid = getgenv().NVRMR_REQUIRE("maid")

--<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>--
---<< Config >---
local cfg = {}

--<< ESP
cfg.playerESPEnabled = false
cfg.monstersESPEnabled = false

cfg.worldLoopFindPath = false
cfg.worldWaypointColor = Color3.fromRGB(0, 255, 0)

cfg.playerLoopFindPath = false
cfg.playerWaypointColor = Color3.fromRGB(255, 255, 0)

cfg.monsterLoopFindPath = false
cfg.monsterWaypointColor = Color3.fromRGB(255, 0, 0)

--<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>--
---<< Constants >---
local LOCATIONS = {
	["Maze 1 - Exit Door"] = Vector3.new(533.2, 5, -555.5),

	["Maze 2 - Camp 1"] = Vector3.new(954, -7, -417),
	["Maze 2 - Camp 21"] = Vector3.new(1146, -7, -923),
	["Maze 2 - Camp 22"] = Vector3.new(1210, -21, -508),
	["Maze 2 - Camp 23"] = Vector3.new(1216, -7, -491),
	["Maze 2 - Camp 24"] = Vector3.new(1338, 3, -489),
	["Maze 2 - Camp 3"] = Vector3.new(825, -7, -107),
	["Maze 2 - Exit Door"] = Vector3.new(1423, 5, -44),

	["Maze 3 - Exit Door"] = Vector3.new(1786, 3, 277),
}

--<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>--
---<< Variables >---
local maid = Maid.new()

local playerPathfindTargets = {}

local worldPathTarget = nil :: Vector3
local playerPathTarget = nil :: Model
local monsterPathTarget = nil :: Model

local isComputingWorldPath = false
local isComputingPlayerPath = false
local isComputingMonsterPath = false

--<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>--
---<< Game Objects >>---
local localPlayer = Players.LocalPlayer
local mouse = localPlayer:GetMouse()
local npcs: Model = workspace:WaitForChild("NPCs")

local highlighter: Folder = Instance.new("Folder")
local waypointStorage: Model = Instance.new("Model")
local worldWaypoints: Model = Instance.new("Model")
local playerWaypoints: Model = Instance.new("Model")
local monsterWaypoints: Model = Instance.new("Model")

--<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>--
---<< Helper Functions >>---
local function getHumanoidRootPart()
	local character = localPlayer.Character

	if not character then
		return
	end

	return character:FindFirstChild("HumanoidRootPart")
end

local function getKeys(dict: {})
	local keys = {}
	for key, _ in pairs(dict) do
		table.insert(keys, key)
	end

	return keys
end

local function refreshPathfindTargets(keys: {}, dropdownKey: string)
	table.insert(keys, 1, "None")

	UILibrary.Options[dropdownKey]:SetValues(keys)
end

local function refreshPlayerPathfindTargets()
	local keys = getKeys(playerPathfindTargets)

	refreshPathfindTargets(keys, "playerPathfindTargets")
end

local function isHighlighted(object: Instance)
	return highlighter:FindFirstChild(object.Name)
end

--<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>--
---<< Core Functions >>---
--<< World Functions >>--
local function mark()
	local character = localPlayer.Character

	local rayOrigin = mouse.UnitRay.Origin
	local rayDirection = mouse.UnitRay.Direction * 20
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {
		character,
		workspace.CurrentCamera:WaitForChild("Light_Source"),
		workspace:WaitForChild(`{localPlayer.Name}_Crumbs`),
	}
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

	local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)

	if result then
		local hitPosition = result.Position

		local characterPosition = character.PrimaryPart.Position
		local lookVector = (hitPosition - characterPosition).Unit

		local markCFrame = CFrame.new(hitPosition, hitPosition + Vector3.new(lookVector.X, 0, lookVector.Z))

		local rightOffsetCFrame = markCFrame * CFrame.new(2, 0, 0)
		local leftOffsetCFrame = markCFrame * CFrame.new(-2, 0, 0)
		local frontOffsetCFrame = markCFrame * CFrame.new(0, 0, -2)
		local rearOffsetCFrame = markCFrame * CFrame.new(0, 0, 2)

		game:GetService("ReplicatedStorage").Mark:FireServer(markCFrame)
		game:GetService("ReplicatedStorage").Mark:FireServer(rightOffsetCFrame)
		game:GetService("ReplicatedStorage").Mark:FireServer(leftOffsetCFrame)
		game:GetService("ReplicatedStorage").Mark:FireServer(frontOffsetCFrame)
		game:GetService("ReplicatedStorage").Mark:FireServer(rearOffsetCFrame)
	end
end

--<< ESP Functions >>--
local function highlightMonsters()
	if not isHighlighted(npcs) then
		local highlight = Instance.new("Highlight")
		highlight.Name = npcs.Name
		highlight.Adornee = npcs
		highlight.Parent = highlighter
	end
end

local function unhighlightMonsters()
	local highlight = isHighlighted(npcs)

	if highlight then
		highlight:Destroy()
	end
end

local function highlightPlayer(character: Model)
	if not isHighlighted(character) then
		local highlight = Instance.new("Highlight")
		highlight.Name = character.Name
		highlight.FillColor = Color3.fromRGB(0, 255, 0)
		highlight.Adornee = character
		highlight.Parent = highlighter
		highlight:SetAttribute("Type", "Player")
	end
end

local function unhighlightPlayer(character: Model)
	local highlight = isHighlighted(character)

	if highlight then
		highlight:Destroy()
	end
end

local function highlightAllPlayers()
	for _, player in ipairs(Players:GetPlayers()) do
		if player == Players.LocalPlayer then
			continue
		end

		highlightPlayer(player.Character)
	end
end

local function unhighlightAllPlayers()
	for _, player in ipairs(Players:GetPlayers()) do
		unhighlightPlayer(player.Character)
	end
end

--<< Path Finding Functions >>--
local function computePathTo(targetPosition: Vector3)
	local humanoidRootPart = getHumanoidRootPart()

	if not humanoidRootPart then
		return
	end

	local path = PathfindingService:CreatePath({
		AgentCanClimb = true,
	})

	local numOfRetries = 0
	local success, errorMessage

	repeat
		numOfRetries += 1

		success, errorMessage = pcall(path.ComputeAsync, path, humanoidRootPart.CFrame.Position, targetPosition)

		if not success then
			UILibrary:Notify({
				Title = "1",
				Content = "1",
				Duration = 5,
			})
			task.wait(0.5)
		end
	until success == true or numOfRetries > cfg.maxComputeRetries

	if success then
		return path
	else
		UILibrary:Notify({
			Title = "2",
			Content = "2",
			Duration = 5,
		})
		return
	end
end

local function visualizePath(path: Path, color: Color3, parent: Model)
	if
		path.Status == Enum.PathStatus.Success
		or path.Status == Enum.PathStatus.ClosestNoPath
		or path.Status == Enum.PathStatus.ClosestOutOfRange
	then
		local waypoints = path:GetWaypoints()

		for i, point in ipairs(waypoints) do
			local marker = Instance.new("Part")
			marker.Name = `Point {i}`

			marker.Size = Vector3.new(0.8, 0.8, 0.8)
			marker.CFrame = CFrame.new(point.Position)

			marker.Color = color
			marker.Material = Enum.Material.Neon
			marker.Shape = Enum.PartType.Ball

			marker.Anchored = true
			marker.CanCollide = false
			marker.CanQuery = false
			marker.CanTouch = false

			marker.Parent = parent
		end
	else
		return
	end
end

local function loopFindPath()
	if UILibrary.Unloaded then
		return false
	end

	if not isComputingWorldPath then
		task.spawn(function()
			isComputingWorldPath = true
			if not cfg.worldLoopFindPath then
				return
			end

			if not worldPathTarget then
				return
			end

			local path = computePathTo(worldPathTarget)
			if not path then
				return
			end

			worldWaypoints:ClearAllChildren()
			visualizePath(path, cfg.worldWaypointColor, worldWaypoints)
			isComputingWorldPath = false
		end)
	end

	if not isComputingPlayerPath then
		task.spawn(function()
			isComputingPlayerPath = true
			if not cfg.playerLoopFindPath then
				return
			end

			if not playerPathTarget then
				return
			end

			local path = computePathTo(playerPathTarget:GetPivot().Position)
			if not path then
				return
			end

			playerWaypoints:ClearAllChildren()
			visualizePath(path, cfg.playerWaypointColor, playerWaypoints)
			isComputingPlayerPath = false
		end)
	end

	if not isComputingMonsterPath then
		task.spawn(function()
			isComputingMonsterPath = true
			if not cfg.monsterLoopFindPath then
				return
			end

			if not monsterPathTarget then
				return
			end

			local path = computePathTo(monsterPathTarget:GetPivot().Position)
			if not path then
				return
			end

			monsterWaypoints:ClearAllChildren()
			visualizePath(path, cfg.monsterWaypointColor, monsterWaypoints)
			isComputingMonsterPath = false
		end)
	end

	return true
end

--<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>--
---<< Interface >>---
local Window = UILibrary:CreateWindow({
	Title = `{game.Name} Script`,
	SubTitle = "by CioKiTTY",
	TabWidth = 160,
	Size = UDim2.fromOffset(830, 525),
	Resize = true,
	MinSize = Vector2.new(470, 380),
	Acrylic = false,
	Theme = "Dark",
	MinimizeKey = Enum.KeyCode.RightShift,
})

local Tabs = {
	World = Window:CreateTab({ Title = "World", Icon = "earth" }),
	ESP = Window:CreateTab({ Title = "ESP", Icon = "radar" }),
	PathFinder = Window:CreateTab({ Title = "Path Finder", Icon = "route" }),
	Settings = Window:CreateTab({ Title = "Settings", Icon = "settings" }),
}

local Elements = UILibrary.Options

--<< Elements >>--
--< World
do
	local tab = Tabs.World

	tab:CreateKeybind("markKeybind", {
		Title = "Mark Keybind",
		Mode = "Toggle",
		Default = "E",
		ChangedCallback = function(newKey: Enum.KeyCode)
			if newKey == Enum.KeyCode.Q then
				Elements["markKeybind"]:SetValue("E")
				UILibrary:Notify({
					Title = "Invalid Keybind",
					Content = "You can't set the keybind to Q",
					Duration = 5,
				})
			end
		end,
	})
end

--< ESP
do
	local tab = Tabs.ESP

	-- Players
	do
		local section = tab:AddSection("Players")

		section:CreateToggle("playerESPEnabled", {
			Title = "ESP Enabled",
			Default = cfg.playerESPEnabled,
		})
	end

	-- Monsters
	do
		local section = tab:AddSection("Monsters")

		Elements["monstersESPEnabled"] = section:CreateToggle("monstersESPEnabled", {
			Title = "ESP Enabled",
			Default = cfg.monstersESPEnabled,
		})
	end
end

--< PathFinder
do
	local tab = Tabs.PathFinder

	do
		local section = tab:AddSection("World")

		section:CreateDropdown("worldPathfindTargets", {
			Title = "Path Find Target",
			Values = { "None" },
			Multi = false,
			Default = 1,
		})

		section:CreateButton({
			Title = "Find Path",
			Description = "Find the route to the target",
			Callback = function()
				if not worldPathTarget then
					UILibrary:Notify({
						Title = "No target",
						Content = "Please select a target",
						Duration = 5,
					})
					return
				end

				UILibrary:Notify({
					Title = "Finding a route...",
					Content = "Please wait until we found a route to the target",
					Duration = 1,
				})
				local path = computePathTo(worldPathTarget)
				if
					not path
					or path.Status == Enum.PathStatus.NoPath
					or path.Status == Enum.PathStatus.FailStartNotEmpty
					or path.Status == Enum.PathStatus.FailFinishNotEmpty
				then
					UILibrary:Notify({
						Title = "Route not found",
						Content = "Move somewhere and try again",
						SubContent = `Path.Status = {path.Status}`,
						Duration = 3,
					})
					return
				end

				UILibrary:Notify({
					Title = "Route found!",
					Content = "We found a route to the target",
					Duration = 3,
				})
				worldWaypoints:ClearAllChildren()
				visualizePath(path, cfg.worldWaypointColor, worldWaypoints)
			end,
		})

		section:CreateToggle("worldLoopFindPath", {
			Title = "Find Path Continuously",
			Default = cfg.worldLoopFindPath,
		})

		section:CreateColorpicker("worldWaypointColor", {
			Title = "Path Color",
			Default = cfg.worldWaypointColor,
		})

		section:CreateButton({
			Title = "Clear Path",
			Description = "Clear visualized path to the target",
			Callback = function()
				worldWaypoints:ClearAllChildren()
			end,
		})
	end

	do
		local section = tab:AddSection("Player")

		section:CreateDropdown("playerPathfindTargets", {
			Title = "Path Find Target",
			Values = { "None" },
			Multi = false,
			Default = 1,
		})

		section:CreateButton({
			Title = "Find Path",
			Description = "Find the route to the target",
			Callback = function()
				if not playerPathTarget then
					UILibrary:Notify({
						Title = "No target",
						Content = "Please select a target",
						Duration = 5,
					})
					return
				end

				UILibrary:Notify({
					Title = "Finding a route...",
					Content = "Please wait until we found a route to the target",
					Duration = 1,
				})
				local path = computePathTo(playerPathTarget:GetPivot().Position)
				if
					not path
					or path.Status == Enum.PathStatus.NoPath
					or path.Status == Enum.PathStatus.FailStartNotEmpty
					or path.Status == Enum.PathStatus.FailFinishNotEmpty
				then
					UILibrary:Notify({
						Title = "Route not found",
						Content = "Move somewhere and try again",
						SubContent = `Path.Status = {path.Status}`,
						Duration = 3,
					})
					return
				end

				UILibrary:Notify({
					Title = "Route found!",
					Content = "We found a route to the target",
					Duration = 3,
				})
				playerWaypoints:ClearAllChildren()
				visualizePath(path, cfg.playerWaypointColor, playerWaypoints)
			end,
		})

		section:CreateToggle("playerLoopFindPath", {
			Title = "Find Path Continuously",
			Default = false,
		})

		section:CreateColorpicker("playerWaypointColor", {
			Title = "Path Color",
			Default = cfg.playerWaypointColor,
		})

		section:CreateButton({
			Title = "Clear Path",
			Description = "Clear visualized path to the target",
			Callback = function()
				playerWaypoints:ClearAllChildren()
			end,
		})
	end

	do
		local section = tab:AddSection("Monster")

		section:CreateDropdown("monsterPathfindTargets", {
			Title = "Path Find Target",
			Values = { "None" },
			Multi = false,
			Default = 1,
		})

		section:CreateButton({
			Title = "Find Path",
			Description = "Find the route to the target",
			Callback = function()
				if not monsterPathTarget then
					UILibrary:Notify({
						Title = "No target",
						Content = "Please select a target",
						Duration = 5,
					})
					return
				end

				UILibrary:Notify({
					Title = "Finding a route...",
					Content = "Please wait until we found a route to the target",
					Duration = 1,
				})
				local path = computePathTo(monsterPathTarget:GetPivot().Position)
				if
					not path
					or path.Status == Enum.PathStatus.NoPath
					or path.Status == Enum.PathStatus.FailStartNotEmpty
					or path.Status == Enum.PathStatus.FailFinishNotEmpty
				then
					UILibrary:Notify({
						Title = "Route not found",
						Content = "Move somewhere and try again",
						SubContent = `Path.Status = {path.Status}`,
						Duration = 3,
					})
					return
				end

				UILibrary:Notify({
					Title = "Route found!",
					Content = "We found a route to the target",
					Duration = 3,
				})
				monsterWaypoints:ClearAllChildren()
				visualizePath(path, cfg.monsterWaypointColor, monsterWaypoints)
			end,
		})

		section:CreateToggle("monsterLoopFindPath", {
			Title = "Find Path Continuously",
			Default = false,
		})

		section:CreateColorpicker("monsterWaypointColor", {
			Title = "Path Color",
			Default = cfg.monsterWaypointColor,
		})

		section:CreateButton({
			Title = "Clear Path",
			Description = "Clear visualized path to the target",
			Callback = function()
				monsterWaypoints:ClearAllChildren()
			end,
		})
	end
end

--<< Logic >>--
--< World
do
	Elements["markKeybind"]:OnClick(function()
		mark()
	end)
end

--< ESP
do
	Elements["playerESPEnabled"]:OnChanged(function()
		cfg.playerESPEnabled = Elements["playerESPEnabled"].Value

		if cfg.playerESPEnabled then
			highlightAllPlayers()
		else
			unhighlightAllPlayers()
		end
	end)

	Elements["monstersESPEnabled"]:OnChanged(function()
		cfg.monstersESPEnabled = Elements["monstersESPEnabled"].Value

		if cfg.monstersESPEnabled then
			highlightMonsters()
		else
			unhighlightMonsters()
		end
	end)
end

--< PathFinder
do
	-- World
	Elements["worldPathfindTargets"]:OnChanged(function(value)
		if LOCATIONS[value] then
			worldPathTarget = LOCATIONS[value]
		else
			worldPathTarget = nil
		end
	end)

	Elements["worldLoopFindPath"]:OnChanged(function()
		cfg.worldLoopFindPath = Elements["worldLoopFindPath"].Value
	end)

	Elements["worldWaypointColor"]:OnChanged(function()
		cfg.worldWaypointColor = Elements["worldWaypointColor"].Value
	end)

	-- Player
	Elements["playerPathfindTargets"]:OnChanged(function(value)
		if playerPathfindTargets[value] and playerPathfindTargets[value].Parent ~= nil then
			playerPathTarget = playerPathfindTargets[value]
		else
			playerPathTarget = nil
		end
	end)

	Elements["playerLoopFindPath"]:OnChanged(function()
		cfg.playerLoopFindPath = Elements["playerLoopFindPath"].Value
	end)

	Elements["playerWaypointColor"]:OnChanged(function()
		cfg.playerWaypointColor = Elements["playerWaypointColor"].Value
	end)

	-- Monster
	Elements["monsterPathfindTargets"]:OnChanged(function(value)
		if npcs:FindFirstChild(value) then
			monsterPathTarget = npcs:FindFirstChild(value)
		else
			monsterPathTarget = nil
		end
	end)

	Elements["monsterLoopFindPath"]:OnChanged(function()
		cfg.monsterLoopFindPath = Elements["monsterLoopFindPath"].Value
	end)

	Elements["monsterWaypointColor"]:OnChanged(function()
		cfg.monsterWaypointColor = Elements["monsterWaypointColor"].Value
	end)
end

--< Settings
do
	SaveManager:SetLibrary(UILibrary)
	InterfaceManager:SetLibrary(UILibrary)

	SaveManager:IgnoreThemeSettings()
	SaveManager:SetIgnoreIndexes({})

	SaveManager:SetFolder("CioKiTTY/IdentityFraud")
	InterfaceManager:SetFolder("CioKiTTY")

	SaveManager:BuildConfigSection(Tabs.Settings)
	InterfaceManager:BuildInterfaceSection(Tabs.Settings)

	SaveManager:LoadAutoloadConfig()
end

UILibrary.OnUnload:Connect(function()
	maid:DoCleaning()

	highlighter:Destroy()
	waypointStorage:Destroy()
end)

--<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>--
---<< Initialize >>---
if CoreGui:FindFirstChild("Highlighter") then
	CoreGui:FindFirstChild("Highlighter"):Destroy()
end
highlighter.Name = "Highlighter"
highlighter.Parent = CoreGui

if workspace:FindFirstChild("Waypoints") then
	workspace:FindFirstChild("Waypoints"):Destroy()
end

local waypointsHighlight = Instance.new("Highlight")
waypointsHighlight.FillTransparency = 1
waypointsHighlight.Adornee = waypointStorage
waypointsHighlight.Parent = highlighter

waypointStorage.Name = "Waypoints"

worldWaypoints.Name = "World"
playerWaypoints.Name = "Player"
monsterWaypoints.Name = "Monster"

worldWaypoints.Parent = waypointStorage
playerWaypoints.Parent = waypointStorage
monsterWaypoints.Parent = waypointStorage
waypointStorage.Parent = workspace

--<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>--
---<< Main >>---
if cfg.monstersESPEnabled then
	highlightMonsters()
end

do
	local locationKeys = getKeys(LOCATIONS)

	refreshPathfindTargets(locationKeys, "worldPathfindTargets")
end

do
	local npcNames = {}
	for _, npc in (npcs:GetChildren()) do
		table.insert(npcNames, npc.Name)
	end
	refreshPathfindTargets(npcNames, "monsterPathfindTargets")
end

maid:GiveTask(Players.PlayerAdded:Connect(function(player)
	maid:GiveTask(player.CharacterAdded:Connect(function(character)
		if cfg.playerESPEnabled then
			highlightPlayer(character)
		end

		playerPathfindTargets[player.Name] = character
		refreshPlayerPathfindTargets()

		local humanoid = character:WaitForChild("Humanoid")
		maid:GiveTask(humanoid.Died:Connect(function()
			playerPathfindTargets[player.Name] = nil
			refreshPlayerPathfindTargets()
		end))
	end))
end))

maid:GiveTask(Players.PlayerRemoving:Connect(function(player)
	if playerPathfindTargets[player.Name] then
		playerPathfindTargets[player.Name] = nil
		refreshPlayerPathfindTargets()
	end
end))

for _, player in ipairs(Players:GetPlayers()) do
	if player == Players.LocalPlayer then
		continue
	end

	if cfg.playerESPEnabled then
		highlightPlayer(player.Character)
	end
	playerPathfindTargets[player.Name] = player.Character
	refreshPlayerPathfindTargets()

	maid:GiveTask(player.CharacterAdded:Connect(function(character)
		if cfg.playerESPEnabled then
			highlightPlayer(character)
		end

		playerPathfindTargets[player.Name] = character
		refreshPlayerPathfindTargets()

		local humanoid = character:WaitForChild("Humanoid")
		maid:GiveTask(humanoid.Died:Connect(function()
			playerPathfindTargets[player.Name] = nil
			refreshPlayerPathfindTargets()
		end))
	end))
end

task.spawn(function()
	while true do
		task.wait(0.5)

		local canContinue = loopFindPath()

		if not canContinue then
			break
		end
	end
end)
