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
cfg.playerESPEnabled = true
cfg.monstersESPEnabled = true

--<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>--
---<< Variables >---
local maid = Maid.new()

--<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>--
---<< Game Objects >>---
local npcs: Model = workspace:WaitForChild("NPCs")
local highlighter: Folder = Instance.new("Folder")

--<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>--
---<< Helper Functions >>---
local function isHighlighted(object: Instance)
	return highlighter:FindFirstChild(object.Name)
end

--<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>--
---<< Core Functions >>---
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
	ESP = Window:CreateTab({ Title = "ESP", Icon = "radar" }),
	Settings = Window:CreateTab({ Title = "Settings", Icon = "settings" }),
}

local Elements = UILibrary.Options

--<< Elements >>--
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

--<< Logic >>--
--< ESP
do
	Elements["playerESPEnabled"]:OnChanged(function()
		cfg.playerESPEnabled = Elements["playerESPEnabled"].Value

		if cfg.playerESPEnabled then
			for _, player in ipairs(Players:GetPlayers()) do
				highlightPlayer(player.Character)
			end
		else
			for _, player in ipairs(Players:GetPlayers()) do
				unhighlightPlayer(player.Character)
			end
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

--<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>--
---<< Main >>---
--< ESP
highlightMonsters()

maid:GiveTask(Players.PlayerAdded:Connect(function(player)
	maid:GiveTask(player.CharacterAdded:Connect(function(character)
		if cfg.playerESPEnabled then
			highlightPlayer(character)
		end
	end))
end))

for _, player in ipairs(Players:GetPlayers()) do
	if player == Players.LocalPlayer then
		continue
	end

	highlightPlayer(player.Character)
	maid:GiveTask(player.CharacterAdded:Connect(function(character)
		if cfg.playerESPEnabled then
			highlightPlayer(character)
		end
	end))
end
