--[[
    pisunRust v2 - OMNIX FRAMEWORK (V20 - RAINBOW HUD & FPS)
    Меню: RightShift (Правый Shift)
    Выключить: Кнопка в меню или клавиша END
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ============================================================================
-- НАСТРОЙКИ
-- ============================================================================
local Config = {
    AimbotEnabled = true,
    AimbotMethod = "Camera", 
    FOV = 150,
    Smoothness = 0.25,
    VisibleAim = true,
    Prediction = true,
    
    ESPEnabled = true,
    ESPMaxDist = 1000,
    ChamsEnabled = true,
    DamageNumbers = true,
    
    AutoSprint = false,
    Fullbright = true,
    MenuKey = Enum.KeyCode.RightShift,
    PanicKey = Enum.KeyCode.End
}

local Binds = {
    Aimbot = Enum.UserInputType.MouseButton2,
    ESP = Enum.KeyCode.E,
    Chams = Enum.KeyCode.C,
    Sprint = Enum.KeyCode.Z
}

local State = {
    MenuOpen = true,
    HoldingKey = false,
    IsSprinting = false,
    WaitingForKey = nil,
    Unloaded = false,
    Stats = { Dealt = 0, Taken = 0 },
    
    -- Переменные для HUD
    FPS = 60,
    Frames = 0,
    Time = 0,
    RainbowHue = 0
}

local ESPObjects = {}
local ChamsObjects = {}
local DamagePopups = {}
local Connections = {}

-- ============================================================================
-- FULLBRIGHT (БЕЗ МЕРЦАНИЯ)
-- ============================================================================
local function ApplyLighting()
    if not Config.Fullbright or State.Unloaded then return end
    Lighting.ClockTime = 12
    Lighting.Brightness = 2.5
    Lighting.Ambient = Color3.fromRGB(255, 255, 255)
    Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 100000
    Lighting.FogStart = 0
    for _, v in pairs(Lighting:GetChildren()) do
        if v:IsA("Atmosphere") then v.Density = 0; v.Haze = 0
        elseif v:IsA("Sky") then v.StarCount = 0 end
    end
end

-- ============================================================================
-- UI ФРЕЙМВОРК + HUD
-- ============================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "pisunRustUI_v2"
ScreenGui.Parent = gethui and gethui() or game:GetService("CoreGui")
ScreenGui.ResetOnSpawn = false

-- ================= РАДУЖНЫЙ HUD (СВЕРХУ СЛЕВА) =================
local TopHUD = Instance.new("Frame")
TopHUD.Size = UDim2.new(0, 220, 0, 85)
TopHUD.Position = UDim2.new(0, 20, 0, 20)
TopHUD.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
TopHUD.BackgroundTransparency = 0.4
TopHUD.BorderSizePixel = 0
TopHUD.Parent = ScreenGui

local TopHUDCorner = Instance.new("UICorner")
TopHUDCorner.CornerRadius = UDim.new(0, 6)
TopHUDCorner.Parent = TopHUD

local TopHUDStroke = Instance.new("UIStroke")
TopHUDStroke.Color = Color3.fromRGB(50, 50, 65)
TopHUDStroke.Thickness = 1
TopHUDStroke.Parent = TopHUD

-- Название чита
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -10, 0, 25)
TitleLabel.Position = UDim2.new(0, 5, 0, 5)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "pisunRust v2"
TitleLabel.Font = Enum.Font.GothamBlack
TitleLabel.TextSize = 18
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TopHUD

-- FPS
local FPSLabel = Instance.new("TextLabel")
FPSLabel.Size = UDim2.new(1, -10, 0, 20)
FPSLabel.Position = UDim2.new(0, 5, 0, 25)
FPSLabel.BackgroundTransparency = 1
FPSLabel.Text = "FPS: 60"
FPSLabel.Font = Enum.Font.GothamBold
FPSLabel.TextSize = 14
FPSLabel.TextXAlignment = Enum.TextXAlignment.Left
FPSLabel.Parent = TopHUD

-- Список активных функций
local FeaturesLabel = Instance.new("TextLabel")
FeaturesLabel.Size = UDim2.new(1, -10, 0, 35)
FeaturesLabel.Position = UDim2.new(0, 5, 0, 45)
FeaturesLabel.BackgroundTransparency = 1
FeaturesLabel.Text = "Aimbot: ON | ESP: ON\nChams: ON | Light: ON"
FeaturesLabel.Font = Enum.Font.GothamSemibold
FeaturesLabel.TextSize = 12
FeaturesLabel.TextXAlignment = Enum.TextXAlignment.Left
FeaturesLabel.TextYAlignment = Enum.TextYAlignment.Top
FeaturesLabel.Parent = TopHUD

-- ================= HUD УРОНА (СНИЗУ) =================
local BottomHUD = Instance.new("Frame")
BottomHUD.Size = UDim2.new(0, 300, 0, 40)
BottomHUD.Position = UDim2.new(0.5, -150, 1, -60)
BottomHUD.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
BottomHUD.BackgroundTransparency = 0.2
BottomHUD.BorderSizePixel = 0
BottomHUD.Parent = ScreenGui

local BottomHUDCorner = Instance.new("UICorner")
BottomHUDCorner.CornerRadius = UDim.new(0, 8)
BottomHUDCorner.Parent = BottomHUD

local BottomHUDStroke = Instance.new("UIStroke")
BottomHUDStroke.Color = Color3.fromRGB(50, 50, 65)
BottomHUDStroke.Thickness = 1
BottomHUDStroke.Parent = BottomHUD

local BottomHUDText = Instance.new("TextLabel")
BottomHUDText.Size = UDim2.new(1, 0, 1, 0)
BottomHUDText.BackgroundTransparency = 1
BottomHUDText.Text = "Dealt: 0  |  Taken: 0"
BottomHUDText.TextColor3 = Color3.fromRGB(255, 255, 255)
BottomHUDText.Font = Enum.Font.GothamBold
BottomHUDText.TextSize = 16
BottomHUDText.Parent = BottomHUD

-- ================= ГЛАВНОЕ МЕНЮ =================
local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 520, 0, 400)
Main.Position = UDim2.new(0.5, -260, 0.5, -200)
Main.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 8)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(45, 45, 60)
MainStroke.Thickness = 2
MainStroke.Parent = Main

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 45)
Header.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
Header.Parent = Main

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 8)
HeaderCorner.Parent = Header

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -20, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "pisunRust v2 | Menu"
Title.TextColor3 = Color3.fromRGB(230, 230, 250)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local TabContainer = Instance.new("Frame")
TabContainer.Size = UDim2.new(0, 130, 1, -45)
TabContainer.Position = UDim2.new(0, 0, 0, 45)
TabContainer.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
TabContainer.Parent = Main

local ContentContainer = Instance.new("Frame")
ContentContainer.Size = UDim2.new(1, -150, 1, -65)
ContentContainer.Position = UDim2.new(0, 140, 0, 55)
ContentContainer.BackgroundTransparency = 1
ContentContainer.Parent = Main

local Tabs, Pages, tabY = {}, {}, 8 

local function CreateTab(name)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -16, 0, 35)
    btn.Position = UDim2.new(0, 8, 0, tabY)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    btn.Text = "  " .. name
    btn.TextColor3 = Color3.fromRGB(180, 180, 200)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 14
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Parent = TabContainer
    
    local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 6); corner.Parent = btn
    local page = Instance.new("Frame"); page.Size = UDim2.new(1, 0, 1, 0); page.BackgroundTransparency = 1; page.Visible = false; page.Parent = ContentContainer
    
    Tabs[name] = btn; Pages[name] = page; tabY = tabY + 40 
    
    btn.MouseButton1Click:Connect(function()
        for tName, tBtn in pairs(Tabs) do
            tBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 45); tBtn.TextColor3 = Color3.fromRGB(180, 180, 200); Pages[tName].Visible = false
        end
        btn.BackgroundColor3 = Color3.fromRGB(50, 50, 75); btn.TextColor3 = Color3.fromRGB(255, 255, 255); page.Visible = true
    end)
    return page
end

local PageAimbot = CreateTab("Aimbot")
local PageVisuals = CreateTab("Visuals")
local PageBinds = CreateTab("Binds")
local PageMisc = CreateTab("Misc")

local function CreateToggle(parent, text, default, posY, callback)
    local frame = Instance.new("Frame"); frame.Size = UDim2.new(1, 0, 0, 30); frame.Position = UDim2.new(0, 0, 0, posY); frame.BackgroundTransparency = 1; frame.Parent = parent
    local label = Instance.new("TextLabel"); label.Size = UDim2.new(0.8, 0, 1, 0); label.BackgroundTransparency = 1; label.Text = text; label.TextColor3 = Color3.fromRGB(210, 210, 220); label.Font = Enum.Font.Gotham; label.TextSize = 14; label.TextXAlignment = Enum.TextXAlignment.Left; label.Parent = frame
    local btn = Instance.new("TextButton"); btn.Size = UDim2.new(0, 36, 0, 18); btn.Position = UDim2.new(1, -36, 0.5, -9); btn.BackgroundColor3 = default and Color3.fromRGB(0, 170, 100) or Color3.fromRGB(60, 60, 70); btn.Text = ""; btn.Parent = frame
    local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(1, 0); corner.Parent = btn
    local circle = Instance.new("Frame"); circle.Size = UDim2.new(0, 14, 0, 14); circle.Position = default and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7); circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255); circle.Parent = btn
    local circleCorner = Instance.new("UICorner"); circleCorner.CornerRadius = UDim.new(1, 0); circleCorner.Parent = circle
    local state = default
    btn.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = state and Color3.fromRGB(0, 170, 100) or Color3.fromRGB(60, 60, 70)}):Play()
        TweenService:Create(circle, TweenInfo.new(0.2), {Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)}):Play()
        callback(state)
    end)
end

local function CreateSlider(parent, text, min, max, default, posY, callback)
    local frame = Instance.new("Frame"); frame.Size = UDim2.new(1, 0, 0, 45); frame.Position = UDim2.new(0, 0, 0, posY); frame.BackgroundTransparency = 1; frame.Parent = parent
    local label = Instance.new("TextLabel"); label.Size = UDim2.new(1, 0, 0, 20); label.BackgroundTransparency = 1; label.Text = text .. ": " .. default; label.TextColor3 = Color3.fromRGB(210, 210, 220); label.Font = Enum.Font.Gotham; label.TextSize = 14; label.TextXAlignment = Enum.TextXAlignment.Left; label.Parent = frame
    local bar = Instance.new("Frame"); bar.Size = UDim2.new(1, 0, 0, 6); bar.Position = UDim2.new(0, 0, 0, 28); bar.BackgroundColor3 = Color3.fromRGB(40, 40, 55); bar.Parent = frame
    local barCorner = Instance.new("UICorner"); barCorner.CornerRadius = UDim.new(1, 0); barCorner.Parent = bar
    local fill = Instance.new("Frame"); fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0); fill.BackgroundColor3 = Color3.fromRGB(80, 120, 255); fill.Parent = bar
    local fillCorner = Instance.new("UICorner"); fillCorner.CornerRadius = UDim.new(1, 0); fillCorner.Parent = fill
    local dragging = false
    local function update(input)
        local mouseX = math.clamp(input.Position.X, bar.AbsolutePosition.X, bar.AbsolutePosition.X + bar.AbsoluteSize.X)
        local percent = (mouseX - bar.AbsolutePosition.X) / bar.AbsoluteSize.X
        local val = math.floor(min + (max - min) * percent)
        fill.Size = UDim2.new(percent, 0, 1, 0); label.Text = text .. ": " .. val; callback(val)
    end
    bar.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; update(input) end end)
    UserInputService.InputChanged:Connect(function(input) if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then update(input) end end)
    UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
end

local function CreateButton(parent, text, posY, callback, color)
    local btn = Instance.new("TextButton"); btn.Size = UDim2.new(1, 0, 0, 32); btn.Position = UDim2.new(0, 0, 0, posY); btn.BackgroundColor3 = color or Color3.fromRGB(35, 35, 50); btn.Text = text; btn.TextColor3 = Color3.fromRGB(200, 200, 220); btn.Font = Enum.Font.GothamSemibold; btn.TextSize = 14; btn.Parent = parent
    local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 6); corner.Parent = btn
    btn.MouseButton1Click:Connect(callback)
    return btn
end

CreateToggle(PageAimbot, "Aimbot Enabled", Config.AimbotEnabled, 0, function(v) Config.AimbotEnabled = v end)
CreateToggle(PageAimbot, "Visible Aim", Config.VisibleAim, 35, function(v) Config.VisibleAim = v end)
CreateSlider(PageAimbot, "FOV Size", 30, 400, Config.FOV, 70, function(v) Config.FOV = v end)
CreateSlider(PageAimbot, "Smoothness", 1, 100, Config.Smoothness * 100, 120, function(v) Config.Smoothness = v / 100 end)

local methodBtn = CreateButton(PageAimbot, "Method: " .. Config.AimbotMethod, 170, function()
    Config.AimbotMethod = (Config.AimbotMethod == "Camera") and "Mouse" or "Camera"
    methodBtn.Text = "Method: " .. Config.AimbotMethod
end)

CreateToggle(PageVisuals, "ESP Boxes", Config.ESPEnabled, 0, function(v) Config.ESPEnabled = v end)
CreateToggle(PageVisuals, "Chams", Config.ChamsEnabled, 35, function(v) Config.ChamsEnabled = v end)
CreateToggle(PageVisuals, "Damage Numbers", Config.DamageNumbers, 70, function(v) Config.DamageNumbers = v end)
CreateSlider(PageVisuals, "Max ESP Distance", 100, 2000, Config.ESPMaxDist, 105, function(v) Config.ESPMaxDist = v end)

CreateToggle(PageMisc, "Auto Sprint", Config.AutoSprint, 0, function(v) Config.AutoSprint = v end)
CreateToggle(PageMisc, "Fullbright (Свет)", Config.Fullbright, 35, function(v) Config.Fullbright = v; ApplyLighting() end)

local bindBtns = {}
local function CreateBindButton(parent, text, bindName, posY)
    local btn = CreateButton(parent, text .. ": " .. tostring(Binds[bindName]):gsub("Enum.UserInputType.", ""):gsub("Enum.KeyCode.", ""), posY, function()
        State.WaitingForKey = bindName; btn.Text = "Нажми клавишу..."; btn.TextColor3 = Color3.fromRGB(255, 100, 100)
    end)
    bindBtns[bindName] = btn
end
CreateBindButton(PageBinds, "Aimbot Key", "Aimbot", 0)
CreateBindButton(PageBinds, "ESP Toggle", "ESP", 40)
CreateBindButton(PageBinds, "Chams Toggle", "Chams", 80)

Tabs["Aimbot"].BackgroundColor3 = Color3.fromRGB(50, 50, 75)
Tabs["Aimbot"].TextColor3 = Color3.fromRGB(255, 255, 255)
Pages["Aimbot"].Visible = true

-- ============================================================================
-- СИСТЕМА ПОЛНОГО ВЫКЛЮЧЕНИЯ (UNLOAD)
-- ============================================================================
local function FullCleanup()
    State.Unloaded = true
    for _, conn in pairs(Connections) do pcall(function() conn:Disconnect() end) end
    Connections = {}
    if ScreenGui then pcall(function() ScreenGui:Destroy() end) end
    
    pcall(function() FOVCircle:Remove() end)
    for p, esp in pairs(ESPObjects) do
        pcall(function()
            esp.Box1:Remove(); esp.Box2:Remove(); esp.Box3:Remove(); esp.Box4:Remove()
            esp.Name:Remove(); esp.Dist:Remove(); esp.HealthBarBg:Remove(); esp.HealthBarFill:Remove()
        end)
    end
    ESPObjects = {}
    
    for p, chams in pairs(ChamsObjects) do pcall(function() chams:Destroy() end) end
    ChamsObjects = {}
    for _, popup in pairs(DamagePopups) do pcall(function() popup.Text:Remove() end) end
    DamagePopups = {}
    
    pcall(function() keyrelease(Enum.KeyCode.LeftShift) end)
    pcall(function()
        Lighting.ClockTime = 14
        Lighting.Brightness = 1
        Lighting.Ambient = Color3.fromRGB(70, 70, 70)
        Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
        Lighting.GlobalShadows = true
        Lighting.FogEnd = 1000
    end)
    print("[pisunRust v2] Cheat successfully unloaded. All clean.")
end

CreateButton(PageMisc, "UNLOAD CHEAT (PANIC)", 80, FullCleanup, Color3.fromRGB(150, 30, 30))

-- ============================================================================
-- СИСТЕМА УРОНА (DAMAGE NUMBERS & STATS)
-- ============================================================================
local function SpawnDamageNumber(position, damage, isTaken)
    if not Config.DamageNumbers or State.Unloaded then return end
    local text = Drawing.new("Text")
    text.Text = (isTaken and "+" or "-") .. tostring(math.floor(damage))
    text.Color = isTaken and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(50, 255, 50)
    text.Size = 20; text.Center = true; text.Outline = true; text.OutlineColor = Color3.fromRGB(0, 0, 0); text.Transparency = 1
    
    local screenPos, onScreen = Camera:WorldToViewportPoint(position)
    if onScreen then
        text.Position = Vector2.new(screenPos.X, screenPos.Y)
        table.insert(DamagePopups, {Text = text, Life = 1, StartY = screenPos.Y, CurrentY = screenPos.Y})
    else
        text:Remove()
    end
end

local function TrackPlayer(p)
    if p == LocalPlayer then
        local function setupMyChar(char)
            local hum = char:WaitForChild("Humanoid", 5)
            if hum then
                hum.HealthChanged:Connect(function(newHealth)
                    local oldHealth = hum:GetAttribute("LastHealth") or newHealth
                    if newHealth < oldHealth then
                        local dmg = oldHealth - newHealth
                        State.Stats.Taken = State.Stats.Taken + dmg
                        local head = char:FindFirstChild("Head")
                        if head then SpawnDamageNumber(head.Position + Vector3.new(0, 2, 0), dmg, true) end
                    end
                    hum:SetAttribute("LastHealth", newHealth)
                end)
            end
        end
        if LocalPlayer.Character then setupMyChar(LocalPlayer.Character) end
        LocalPlayer.CharacterAdded:Connect(setupMyChar)
        return
    end

    local function setupChar(char)
        local hum = char:WaitForChild("Humanoid", 5)
        if hum then
            hum.HealthChanged:Connect(function(newHealth)
                local oldHealth = hum:GetAttribute("LastHealth") or newHealth
                if newHealth < oldHealth then
                    local dmg = oldHealth - newHealth
                    State.Stats.Dealt = State.Stats.Dealt + dmg
                    local head = char:FindFirstChild("Head")
                    if head and dmg > 0 then SpawnDamageNumber(head.Position + Vector3.new(0, 1, 0), dmg, false) end
                end
                hum:SetAttribute("LastHealth", newHealth)
            end)
        end
    end
    if p.Character then setupChar(p.Character) end
    p.CharacterAdded:Connect(setupChar)
end

for _, p in pairs(Players:GetPlayers()) do TrackPlayer(p) end
Players.PlayerAdded:Connect(TrackPlayer)

-- ============================================================================
-- УМНЫЙ ESP
-- ============================================================================
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 2; FOVCircle.NumSides = 100; FOVCircle.Radius = Config.FOV; FOVCircle.Color = Color3.fromRGB(80, 120, 255); FOVCircle.Filled = false; FOVCircle.Visible = false

local function IsVisible(targetChar)
    local myChar = LocalPlayer.Character
    local targetPart = targetChar:FindFirstChild("Head") or targetChar:FindFirstChild("HumanoidRootPart")
    if not myChar or not myChar:FindFirstChild("Head") or not targetPart then return false end
    local RayParams = RaycastParams.new(); RayParams.FilterType = Enum.RaycastFilterType.Exclude; RayParams.FilterDescendantsInstances = {myChar, targetChar}
    return workspace:Raycast(Camera.CFrame.Position, targetPart.Position - Camera.CFrame.Position, RayParams) == nil
end

local function CreateESPObject()
    local esp = {}
    for i=1, 4 do esp["Box"..i] = Drawing.new("Line"); esp["Box"..i].Thickness = 1.5; esp["Box"..i].Color = Color3.fromRGB(255, 60, 60); esp["Box"..i].Visible = false end
    esp.Name = Drawing.new("Text"); esp.Name.Size = 15; esp.Name.Center = true; esp.Name.Outline = true; esp.Name.Font = 2; esp.Name.Color = Color3.fromRGB(255, 255, 255); esp.Name.Visible = false
    esp.Dist = Drawing.new("Text"); esp.Dist.Size = 13; esp.Dist.Center = true; esp.Dist.Outline = true; esp.Dist.Color = Color3.fromRGB(255, 200, 0); esp.Dist.Visible = false
    esp.HealthBarBg = Drawing.new("Square"); esp.HealthBarBg.Filled = true; esp.HealthBarBg.Color = Color3.fromRGB(0, 0, 0); esp.HealthBarBg.Thickness = 1; esp.HealthBarBg.Visible = false
    esp.HealthBarFill = Drawing.new("Square"); esp.HealthBarFill.Filled = true; esp.HealthBarFill.Color = Color3.fromRGB(0, 255, 0); esp.HealthBarFill.Visible = false
    return esp
end

local function CleanupESP(p)
    if ESPObjects[p] then
        local esp = ESPObjects[p]
        pcall(function()
            esp.Box1:Remove(); esp.Box2:Remove(); esp.Box3:Remove(); esp.Box4:Remove()
            esp.Name:Remove(); esp.Dist:Remove(); esp.HealthBarBg:Remove(); esp.HealthBarFill:Remove()
        end)
        ESPObjects[p] = nil
    end
end

Players.PlayerRemoving:Connect(function(p)
    CleanupESP(p)
    if ChamsObjects[p] then ChamsObjects[p]:Destroy(); ChamsObjects[p] = nil end
end)

local function UpdateESP()
    if State.Unloaded then return end
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("Humanoid") or LocalPlayer.Character.Humanoid.Health <= 0 then
        for _, esp in pairs(ESPObjects) do
            esp.Box1.Visible = false; esp.Box2.Visible = false; esp.Box3.Visible = false; esp.Box4.Visible = false
            esp.Name.Visible = false; esp.Dist.Visible = false; esp.HealthBarBg.Visible = false; esp.HealthBarFill.Visible = false
        end
        return
    end

    for p, _ in pairs(ESPObjects) do
        if not p or not p.Parent or not p.Character or not p.Character:FindFirstChild("Humanoid") or p.Character.Humanoid.Health <= 0 then CleanupESP(p) end
    end

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Humanoid") and p.Character:FindFirstChild("Head") then
            local hum = p.Character.Humanoid; local hrp = p.Character:FindFirstChild("HumanoidRootPart"); local head = p.Character:FindFirstChild("Head")

            if hum.Health > 0 and hrp and head then
                local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                local dist = (myRoot and hrp) and math.floor((myRoot.Position - hrp.Position).Magnitude) or 0

                if dist <= Config.ESPMaxDist then
                    if Config.ChamsEnabled then
                        if not ChamsObjects[p] or ChamsObjects[p].Parent ~= p.Character then
                            if ChamsObjects[p] then pcall(function() ChamsObjects[p]:Destroy() end) end
                            local chams = Instance.new("Highlight"); chams.FillTransparency = 0.5; chams.OutlineTransparency = 0; chams.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; chams.Parent = p.Character
                            ChamsObjects[p] = chams
                        end
                        local chams = ChamsObjects[p]
                        if tick() - (chams:GetAttribute("LastCheck") or 0) > 0.1 then
                            chams:SetAttribute("LastCheck", tick())
                            if IsVisible(p.Character) then chams.FillColor = Color3.fromRGB(0, 255, 0); chams.OutlineColor = Color3.fromRGB(0, 255, 0)
                            else chams.FillColor = Color3.fromRGB(255, 0, 0); chams.OutlineColor = Color3.fromRGB(255, 255, 255) end
                        end
                    elseif ChamsObjects[p] then pcall(function() ChamsObjects[p]:Destroy() end); ChamsObjects[p] = nil end

                    if Config.ESPEnabled then
                        if not ESPObjects[p] then ESPObjects[p] = CreateESPObject() end
                        local esp = ESPObjects[p]
                        
                        local screenHead, onScreen = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                        local screenRoot = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 2.5, 0))

                        if onScreen and screenHead.Z > 0 then
                            local height = math.abs(screenHead.Y - screenRoot.Y)
                            local width = height * 0.55
                            local x, y = screenHead.X - (width / 2), screenHead.Y
                            local length = width * 0.25

                            esp.Box1.From = Vector2.new(x, y); esp.Box1.To = Vector2.new(x + length, y)
                            esp.Box2.From = Vector2.new(x, y); esp.Box2.To = Vector2.new(x, y + length)
                            esp.Box3.From = Vector2.new(x + width, y + height); esp.Box3.To = Vector2.new(x + width - length, y + height)
                            esp.Box4.From = Vector2.new(x + width, y + height); esp.Box4.To = Vector2.new(x + width, y + height - length)
                            
                            esp.Box1.Visible = true; esp.Box2.Visible = true; esp.Box3.Visible = true; esp.Box4.Visible = true

                            esp.Name.Text = p.Name; esp.Name.Position = Vector2.new(screenHead.X, y - 30); esp.Name.Visible = true
                            esp.Dist.Text = "[" .. dist .. "m]"; esp.Dist.Position = Vector2.new(screenHead.X, y - 15); esp.Dist.Visible = true

                            local barWidth = 3; local barHeight = height; local barX = x - 6
                            esp.HealthBarBg.Size = Vector2.new(barWidth, barHeight); esp.HealthBarBg.Position = Vector2.new(barX, y); esp.HealthBarBg.Visible = true
                            local healthPercent = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                            local fillHeight = barHeight * healthPercent
                            esp.HealthBarFill.Size = Vector2.new(barWidth, fillHeight); esp.HealthBarFill.Position = Vector2.new(barX, y + (barHeight - fillHeight))
                            
                            if healthPercent > 0.5 then esp.HealthBarFill.Color = Color3.fromRGB(255 * (1 - (healthPercent - 0.5) * 2), 255, 0)
                            else esp.HealthBarFill.Color = Color3.fromRGB(255, 255 * (healthPercent * 2), 0) end
                            
                            esp.HealthBarFill.Visible = true
                        else
                            esp.Box1.Visible = false; esp.Box2.Visible = false; esp.Box3.Visible = false; esp.Box4.Visible = false
                            esp.Name.Visible = false; esp.Dist.Visible = false; esp.HealthBarBg.Visible = false; esp.HealthBarFill.Visible = false
                        end
                    end
                end
            end
        end
    end
end

-- ============================================================================
-- AIMBOT
-- ============================================================================
local function GetTarget()
    if State.Unloaded or not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("Humanoid") or LocalPlayer.Character.Humanoid.Health <= 0 then return nil end
    local closest = nil; local shortestDist = Config.FOV
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Humanoid") then
            local hum = p.Character.Humanoid; local hrp = p.Character:FindFirstChild("HumanoidRootPart"); local head = p.Character:FindFirstChild("Head")
            if hum.Health > 0 and hrp and head then
                local targetPos = head.Position
                local screenPos, onScreen = Camera:WorldToViewportPoint(targetPos)
                if onScreen and screenPos.Z > 0 then
                    local dist = (screenCenter - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
                    if dist < shortestDist then
                        if Config.VisibleAim and not IsVisible(p.Character) then continue end
                        shortestDist = dist
                        local finalPos = targetPos
                        if Config.Prediction then finalPos = finalPos + (hrp.AssemblyLinearVelocity * 0.15) end
                        closest = { player = p, pos = finalPos }
                    end
                end
            end
        end
    end
    return closest
end

-- ============================================================================
-- ВВОД И ЦИКЛЫ
-- ============================================================================
table.insert(Connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if State.Unloaded then return end
    if input.KeyCode == Config.PanicKey then FullCleanup(); return end
    if input.KeyCode == Config.MenuKey then State.MenuOpen = not State.MenuOpen; Main.Visible = State.MenuOpen; return end
    
    if State.WaitingForKey then
        local keyName = ""
        if input.UserInputType == Enum.UserInputType.Keyboard then Binds[State.WaitingForKey] = input.KeyCode; keyName = tostring(input.KeyCode):gsub("Enum.KeyCode.", "")
        else Binds[State.WaitingForKey] = input.UserInputType; keyName = tostring(input.UserInputType):gsub("Enum.UserInputType.", "") end
        bindBtns[State.WaitingForKey].Text = State.WaitingForKey .. ": " .. keyName; bindBtns[State.WaitingForKey].TextColor3 = Color3.fromRGB(200, 200, 220); State.WaitingForKey = nil
        return
    end
    if gameProcessed then return end

    if input.UserInputType == Binds.Aimbot or input.KeyCode == Binds.Aimbot then State.HoldingKey = true
    elseif input.UserInputType == Binds.ESP or input.KeyCode == Binds.ESP then Config.ESPEnabled = not Config.ESPEnabled
    elseif input.UserInputType == Binds.Chams or input.KeyCode == Binds.Chams then Config.ChamsEnabled = not Config.ChamsEnabled
    elseif input.UserInputType == Binds.Sprint or input.KeyCode == Binds.Sprint then Config.AutoSprint = not Config.AutoSprint end
end))

table.insert(Connections, UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if State.Unloaded then return end
    if input.UserInputType == Binds.Aimbot or input.KeyCode == Binds.Aimbot then State.HoldingKey = false end
end))

table.insert(Connections, RunService.RenderStepped:Connect(function(deltaTime)
    if State.Unloaded then return end

    ApplyLighting()
    
    -- ================= РАСЧЕТ FPS =================
    State.Frames = State.Frames + 1
    State.Time = State.Time + deltaTime
    if State.Time >= 1 then
        State.FPS = math.floor(State.Frames / State.Time)
        State.Frames = 0
        State.Time = 0
    end

    -- ================= РАДУЖНЫЙ HUD =================
    State.RainbowHue = (State.RainbowHue + 0.005) % 1
    local RainbowColor = Color3.fromHSV(State.RainbowHue, 1, 1)
    
    TitleLabel.TextColor3 = RainbowColor
    FPSLabel.Text = "FPS: " .. State.FPS
    FPSLabel.TextColor3 = RainbowColor
    FeaturesLabel.TextColor3 = RainbowColor
    
    local featuresText = string.format("Aimbot: %s | ESP: %s\nChams: %s | Light: %s", 
        Config.AimbotEnabled and "ON" or "OFF",
        Config.ESPEnabled and "ON" or "OFF",
        Config.ChamsEnabled and "ON" or "OFF",
        Config.Fullbright and "ON" or "OFF"
    )
    FeaturesLabel.Text = featuresText

    -- ================= НИЖНИЙ HUD УРОНА =================
    BottomHUDText.Text = string.format("Dealt: %d  |  Taken: %d", math.floor(State.Stats.Dealt), math.floor(State.Stats.Taken))

    -- ================= ОСТАЛЬНАЯ ЛОГИКА =================
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    FOVCircle.Radius = Config.FOV
    FOVCircle.Visible = Config.AimbotEnabled and (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") and LocalPlayer.Character.Humanoid.Health > 0)

    if Config.ESPEnabled or Config.ChamsEnabled then pcall(UpdateESP) end

    for i = #DamagePopups, 1, -1 do
        local popup = DamagePopups[i]
        popup.Life = popup.Life - 0.02
        popup.CurrentY = popup.CurrentY - 1.5 
        popup.Text.Position = Vector2.new(popup.Text.Position.X, popup.CurrentY)
        popup.Text.Transparency = popup.Life
        if popup.Life <= 0 then pcall(function() popup.Text:Remove() end); table.remove(DamagePopups, i) end
    end

    if Config.AutoSprint then
        if not State.IsSprinting then keypress(Enum.KeyCode.LeftShift); State.IsSprinting = true end
    else
        if State.IsSprinting then keyrelease(Enum.KeyCode.LeftShift); State.IsSprinting = false end
    end
end))

table.insert(Connections, RunService.Heartbeat:Connect(function()
    if State.Unloaded or not Config.AimbotEnabled or not State.HoldingKey then return end
    local target = GetTarget()
    if target then
        if Config.AimbotMethod == "Camera" then
            local camPos = Camera.CFrame.Position
            local targetCFrame = CFrame.new(camPos, target.pos)
            Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, Config.Smoothness)
        elseif Config.AimbotMethod == "Mouse" and mousemoverel then
            local screenPos = Camera:WorldToViewportPoint(target.pos)
            local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            mousemoverel((screenPos.X - center.X) * Config.Smoothness, (screenPos.Y - center.Y) * Config.Smoothness)
        end
    end
end))

print("[pisunRust v2] Loaded. Rainbow HUD & FPS Counter active.")
