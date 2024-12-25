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

cfg.loopFindPath = false
cfg.maxComputeRetries = 3

--<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>--
---<< Variables >---
local maid = Maid.new()
local pathTargetLists = {}
local pathTarget = nil :: Model

--<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>--
---<< Game Objects >>---
local localPlayer = Players.LocalPlayer
local mouse = localPlayer:GetMouse()
local npcs: Model = workspace:WaitForChild("NPCs")

local highlighter: Folder = Instance.new("Folder")
local waypointStorage: Model = Instance.new("Model")

--<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>--
---<< Helper Functions >>---
local function getHumanoidRootPart()
	local character = localPlayer.Character

	if not character then
		return
	end

	return character:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
	local character = localPlayer.Character

	if not character then
		return
	end

	return character:FindFirstChildWhichIsA("Humanoid")
end

local function refreshPathTargetList()
	local keys = {}
	for key, _ in pairs(pathTargetLists) do
		table.insert(keys, key)
	end

	UILibrary.Options["pathFindTarget"]:SetValues(keys)
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
	raycastParams.FilterDescendantsInstances = { character }
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

	local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)

	if result then
		local hitPosition = result.Position

		local characterPosition = character.PrimaryPart.Position
		local lookVector = (hitPosition - characterPosition).Unit

		local markCFrame = CFrame.new(hitPosition, hitPosition + Vector3.new(lookVector.X, 0, lookVector.Z))

		game:GetService("ReplicatedStorage").Mark:FireServer(markCFrame)
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

	local path = PathfindingService:CreatePath()

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

local function visualizePath(path: Path)
	if path.Status == Enum.PathStatus.Success then
		local waypoints = path:GetWaypoints()

		for i, point in ipairs(waypoints) do
			local marker = Instance.new("Part")
			marker.Name = `Point {i}`

			marker.Size = Vector3.new(0.8, 0.8, 0.8)
			marker.CFrame = CFrame.new(point.Position)

			marker.Color = Color3.fromRGB(0, 255, 0)
			marker.Shape = Enum.PartType.Ball

			marker.Anchored = true
			marker.CanCollide = false
			marker.CanQuery = false
			marker.CanTouch = false

			marker.Parent = waypointStorage
		end
	else
		UILibrary:Notify({
			Title = "3",
			Content = "3",
			Duration = 5,
		})
		return
	end
end

local function loopFindPath()
	if UILibrary.Unloaded then
		return false
	end

	if not cfg.loopFindPath then
		return true
	end

	if not pathTarget then
		return true
	end

	local path = computePathTo(pathTarget:GetPivot().Position)
	if not path then
		return true
	end

	waypointStorage:ClearAllChildren()
	visualizePath(path)

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
		end
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

	tab:CreateDropdown("pathFindTarget", {
		Title = "Target",
		Values = { "None" },
		Multi = false,
		Default = 1,
	})

	tab:CreateToggle("loopFindPath", {
		Title = "Find Path Continuously",
		Default = cfg.loopFindPath,
	})

	tab:CreateButton({
		Title = "Find Path",
		Description = "Find the path to the target",
		Callback = function()
			if not pathTarget then
				UILibrary:Notify({
					Title = "No target",
					Content = "Please select a target",
					Duration = 5,
				})
				return
			end

			local path = computePathTo(pathTarget:GetPivot().Position)
			if not path then
				UILibrary:Notify({
					Title = "69",
					Content = "69",
					Duration = 5,
				})
				return
			end

			waypointStorage:ClearAllChildren()
			visualizePath(path)
		end,
	})
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
	Elements["loopFindPath"]:OnChanged(function()
		cfg.loopFindPath = Elements["loopFindPath"].Value
	end)

	Elements["pathFindTarget"]:OnChanged(function(value)
		if pathTargetLists[value] and pathTargetLists[value].Parent ~= nil then
			pathTarget = pathTargetLists[value]
		end
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
waypointsHighlight.FillColor = Color3.fromRGB(0, 255, 0)
waypointsHighlight.Adornee = waypointStorage
waypointsHighlight.Parent = highlighter

waypointStorage.Name = "Waypoints"
waypointStorage.Parent = workspace

--<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>--
---<< Main >>---
highlightMonsters()

for _, npc in (npcs:GetChildren()) do
	pathTargetLists[npc.Name] = npc
	refreshPathTargetList()
end

maid:GiveTask(Players.PlayerAdded:Connect(function(player)
	maid:GiveTask(player.CharacterAdded:Connect(function(character)
		if cfg.playerESPEnabled then
			highlightPlayer(character)
		end

		pathTargetLists[player.Name] = character
		refreshPathTargetList()

		local humanoid = character:WaitForChild("Humanoid")
		maid:GiveTask(humanoid.Died:Connect(function()
			pathTargetLists[player.Name] = nil
			refreshPathTargetList()
		end))
	end))
end))

maid:GiveTask(Players.PlayerRemoving:Connect(function(player)
	if pathTargetLists[player.Name] then
		pathTargetLists[player.Name] = nil
		refreshPathTargetList()
	end
end))

for _, player in ipairs(Players:GetPlayers()) do
	if player == Players.LocalPlayer then
		continue
	end

	if cfg.playerESPEnabled then
		highlightPlayer(player.Character)
	end
	pathTargetLists[player.Name] = player.Character
	refreshPathTargetList()

	maid:GiveTask(player.CharacterAdded:Connect(function(character)
		if cfg.playerESPEnabled then
			highlightPlayer(character)
		end

		pathTargetLists[player.Name] = character
		refreshPathTargetList()

		local humanoid = character:WaitForChild("Humanoid")
		maid:GiveTask(humanoid.Died:Connect(function()
			pathTargetLists[player.Name] = nil
			refreshPathTargetList()
		end))
	end))
end

task.spawn(function()
	while true do
		task.wait()

		local canContinue = loopFindPath()

		if not canContinue then
			break
		end
	end
end)
