loadstring(game:HttpGet("https://raw.githubusercontent.com/CioKiTTY/NevermoreModules/main/loader.lua"))()

--<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>--
---<< Services >>---
local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local CoreGui = game:GetService("CoreGui")

--<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>-<<->>--
---<< Libraries >>---
local UILibrary = loadstring(game:HttpGet("https://raw.githubusercontent.com/CioKiTTY/LinoriaLib/main/Library.lua"))()
local ThemeManager =
	loadstring(game:HttpGet("https://raw.githubusercontent.com/CioKiTTY/LinoriaLib/main/addons/ThemeManager.lua"))()
local SaveManager =
	loadstring(game:HttpGet("https://raw.githubusercontent.com/CioKiTTY/LinoriaLib/main/addons/SaveManager.lua"))()
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
	Title = game.Name .. " - CioKiTTY",
	Center = true,
	AutoShow = true,
})

local Tabs = {
    ESP = Window:AddTab("ESP"),
	Settings = Window:AddTab("Settings"),
}

--<< Elements >>--
--< ESP
do
	local tab = Tabs.ESP

	-- Players
	do
		local box = tab:AddLeftGroupbox("Players")

		box:AddDivider()

		box:AddToggle("playerESPEnabled", {
			Text = "ESP Enabled",
			Default = cfg.playerESPEnabled,
			Tooltip = "Enable it to see players ESP",
		})
	end

    -- Monsters
	do
		local box = tab:AddRightGroupbox("Monsters")

		box:AddDivider()

		box:AddToggle("monstersESPEnabled", {
			Text = "ESP Enabled",
			Default = cfg.monstersESPEnabled,
			Tooltip = "Enable it to see monsters ESP",
		})
	end
end

--< Settings
do
	local tab = Tabs.Settings

	do
		local box = tab:AddLeftGroupbox("Menu")

		box:AddDivider()

		box:AddButton("Unload", function()
			UILibrary:Unload()
		end)

		box:AddLabel("Toggle UI Keybind"):AddKeyPicker("UIKeybind", {
			Default = "RightShift",
			NoUI = true,
			Text = "Toggle UI Keybind",
		})
	end
end

--<< Logic >>--
--< ESP
do
	Toggles["playerESPEnabled"]:OnChanged(function()
		cfg.playerESPEnabled = Toggles["playerESPEnabled"].Value

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

    Toggles["monstersESPEnabled"]:OnChanged(function()
		cfg.monstersESPEnabled = Toggles["monstersESPEnabled"].Value

        if cfg.monstersESPEnabled then
			highlightMonsters()
		else
            unhighlightMonsters()
        end
	end)
end

--< Settings
do
	UILibrary.ToggleKeybind = Options.UIKeybind

	ThemeManager:SetLibrary(UILibrary)
	SaveManager:SetLibrary(UILibrary)

	SaveManager:IgnoreThemeSettings()
	SaveManager:SetIgnoreIndexes({ "UIKeybind" })

	ThemeManager:SetFolder("CioKiTTY")
	SaveManager:SetFolder("CioKiTTY/IdentityFraud")

    ThemeManager:ApplyToTab(Tabs.Settings)
	SaveManager:BuildConfigSection(Tabs.Settings)

    SaveManager:LoadAutoloadConfig()
end

UILibrary:OnUnload(function()
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
