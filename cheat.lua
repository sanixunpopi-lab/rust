--[[
    pisunRust v2 - OMNIX FRAMEWORK (V24 - WEAPON FIX & DEALT-ONLY LOG)
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
    ESPWeapon = true,
    ChamsEnabled = true,
    DamageNumbers = true,
    ShowDamageLog = true,
    
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
    FPS = 60,
    Frames = 0,
    Time = 0,
    RainbowHue = 0
}

local ESPObjects = {}
local ChamsObjects = {}
local DamagePopups = {}
local ActiveNotifications = {}
local Connections = {}

-- ============================================================================
-- FULLBRIGHT
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
-- ПОИСК И СОКРАЩЕНИЕ ОРУЖИЯ (ФИКС)
-- ============================================================================
local function GetWeaponName(character)
    -- 1. Ищем стандартный Tool в персонаже
    local tool = character:FindFirstChildOfClass("Tool")
    if tool then return tool.Name end
    
    -- 2. Ищем Tool в руках (часто бывает в клонах)
    local rightHand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
    local leftHand = character:FindFirstChild("LeftHand") or character:FindFirstChild("Left Arm")
    
    if rightHand then
        local toolInHand = rightHand:FindFirstChildOfClass("Tool")
        if toolInHand then return toolInHand.Name end
        -- Иногда оружие это просто модель в руке
        for _, child in pairs(rightHand:GetChildren()) do
            if child:IsA("Model") or child:IsA("Part") then
                if string.find(string.lower(child.Name), "gun") or string.find(string.lower(child.Name), "rifle") or string.find(string.lower(child.Name), "bow") or string.find(string.lower(child.Name), "sword") then
                    return child.Name
                end
            end
        end
    end
    
    -- 3. Ищем вообще везде внутри персонажа
    for _, v in pairs(character:GetDescendants()) do
        if v:IsA("Tool") then return v.Name end
    end
    
    return nil
end

local function GetShortWeaponName(toolName)
    local mappings = {
        ["Assault Rifle"] = "AR", ["Semi-Automatic Rifle"] = "SAR",
        ["Bolt Action Rifle"] = "Bolt", ["Custom SMG"] = "SMG",
        ["Thompson"] = "Tommy", ["Pump Shotgun"] = "Pump",
        ["Double Barrel Shotgun"] = "DB", ["Hunting Bow"] = "Bow",
        ["Crossbow"] = "XBow", ["Rocket Launcher"] = "RPG",
        ["M92 Pistol"] = "Pistol", ["Python"] = "Revolver",
        ["Salvaged Sword"] = "Sword", ["Rock"] = "Rock", ["Torch"] = "Torch"
    }
    if mappings[toolName] then return mappings[toolName] end
    
    local words = {}
    for word in string.gmatch(toolName, "%a+") do table.insert(words, word) end
    if #words > 1 then
        local abbr = ""
        for i = 1, math.min(#words, 3) do abbr = abbr .. string.sub(words[i], 1, 1) end
        return string.upper(abbr)
    else
        if #toolName > 4 then return string.upper(string.sub(toolName, 1, 4)) end
        return toolName
    end
end

-- ============================================================================
-- UI
-- ============================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "pisunRustUI_v2"
ScreenGui.Parent = gethui and gethui() or game:GetService("CoreGui")
ScreenGui.ResetOnSpawn = false

-- Верхний HUD
local TopHUD = Instance.new("Frame")
TopHUD.Size = UDim2.new(0, 220, 0, 85)
TopHUD.Position = UDim2.new(0, 20, 0, 20)
TopHUD.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
TopHUD.BackgroundTransparency = 0.4
TopHUD.BorderSizePixel = 0
TopHUD.Parent = ScreenGui
local TopHUDCorner = Instance.new("UICorner"); TopHUDCorner.CornerRadius = UDim.new(0, 6); TopHUDCorner.Parent = TopHUD
local TopHUDStroke = Instance.new("UIStroke"); TopHUDStroke.Color = Color3.fromRGB(50, 50, 65); TopHUDStroke.Thickness = 1; TopHUDStroke.Parent = TopHUD

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -10, 0, 25); TitleLabel.Position = UDim2.new(0, 5, 0, 5); TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "pisunRust v2"; TitleLabel.Font = Enum.Font.GothamBlack; TitleLabel.TextSize = 18; TitleLabel.TextXAlignment = Enum.TextXAlignment.Left; TitleLabel.Parent = TopHUD

local FPSLabel = Instance.new("TextLabel")
FPSLabel.Size = UDim2.new(1, -10, 0, 20); FPSLabel.Position = UDim2.new(0, 5, 0, 25); FPSLabel.BackgroundTransparency = 1
FPSLabel.Text = "FPS: 60"; FPSLabel.Font = Enum.Font.GothamBold; FPSLabel.TextSize = 14; FPSLabel.TextXAlignment = Enum.TextXAlignment.Left; FPSLabel.Parent = TopHUD

local FeaturesLabel = Instance.new("TextLabel")
FeaturesLabel.Size = UDim2.new(1, -10, 0, 35); FeaturesLabel.Position = UDim2.new(0, 5, 0, 45); FeaturesLabel.BackgroundTransparency = 1
FeaturesLabel.Text = "Aimbot: ON | ESP: ON\nChams: ON | Light: ON"; FeaturesLabel.Font = Enum.Font.GothamSemibold; FeaturesLabel.TextSize = 12; FeaturesLabel.TextXAlignment = Enum.TextXAlignment.Left; FeaturesLabel.TextYAlignment = Enum.TextYAlignment.Top; FeaturesLabel.Parent = TopHUD

-- Меню урона
local DamageLogPanel = Instance.new("Frame")
DamageLogPanel.Size = UDim2.new(0, 180, 0, 160); DamageLogPanel.Position = UDim2.new(1, -200, 0.5, -80)
DamageLogPanel.BackgroundColor3 = Color3.fromRGB(15, 15, 20); DamageLogPanel.BackgroundTransparency = 0.3; DamageLogPanel.BorderSizePixel = 0; DamageLogPanel.Visible = Config.ShowDamageLog; DamageLogPanel.Parent = ScreenGui
local DLCorner = Instance.new("UICorner"); DLCorner.CornerRadius = UDim.new(0, 6); DLCorner.Parent = DamageLogPanel
local DLStroke = Instance.new("UIStroke"); DLStroke.Color = Color3.fromRGB(50, 50, 65); DLStroke.Thickness = 1; DLStroke.Parent = DamageLogPanel

local DLTitle = Instance.new("TextLabel")
DLTitle.Size = UDim2.new(1, -10, 0, 25); DLTitle.Position = UDim2.new(0, 5, 0, 0); DLTitle.BackgroundTransparency = 1
DLTitle.Text = "Damage Log (Dealt)"; DLTitle.TextColor3 = Color3.fromRGB(200, 200, 220); DLTitle.Font = Enum.Font.GothamBold; DLTitle.TextSize = 14; DLTitle.TextXAlignment = Enum.TextXAlignment.Left; DLTitle.Parent = DamageLogPanel

local DLContainer = Instance.new("Frame")
DLContainer.Size = UDim2.new(1, -10, 1, -30); DLContainer.Position = UDim2.new(0, 5, 0, 25); DLContainer.BackgroundTransparency = 1; DLContainer.Parent = DamageLogPanel
local DLContainerLayout = Instance.new("UIListLayout"); DLContainerLayout.SortOrder = Enum.SortOrder.LayoutOrder; DLContainerLayout.VerticalAlignment = Enum.VerticalAlignment.Top; DLContainerLayout.Padding = UDim.new(0, 4); DLContainerLayout.Parent = DLContainer

-- ТЕПЕРЬ ЛОГ ТОЛЬКО ДЛЯ НАНЕСЕННОГО УРОНА
local function AddNotification(amount)
    if not Config.ShowDamageLog or State.Unloaded then return end
    amount = math.floor(amount)
    if amount <= 0 then return end
    
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, 0, 0, 24); bar.BackgroundColor3 = Color3.fromRGB(25, 25, 30); bar.BackgroundTransparency = 0.2; bar.BorderSizePixel = 0; bar.Parent = DLContainer
    local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 4); corner.Parent = bar
    local indicator = Instance.new("Frame"); indicator.Size = UDim2.new(0, 4, 1, 0); indicator.BackgroundColor3 = Color3.fromRGB(50, 255, 50); indicator.BorderSizePixel = 0; indicator.Parent = bar
    local indCorner = Instance.new("UICorner"); indCorner.CornerRadius = UDim.new(0, 4); indCorner.Parent = indicator
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -10, 1, 0); label.Position = UDim2.new(0, 8, 0, 0); label.BackgroundTransparency = 1
    label.Text = "Dealt: -" .. amount; label.TextColor3 = Color3.fromRGB(50, 255, 50); label.Font = Enum.Font.GothamSemibold; label.TextSize = 13; label.TextXAlignment = Enum.TextXAlignment.Left; label.Parent = bar
    
    table.insert(ActiveNotifications, bar)
    if #ActiveNotifications > 3 then local oldest = table.remove(ActiveNotifications, 1); oldest:Destroy() end
    
    task.spawn(function()
        task.wait(3)
        if bar and bar.Parent then
            TweenService:Create(bar, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
            TweenService:Create(label, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
            TweenService:Create(indicator, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
            task.wait(0.4)
            for i, v in pairs(ActiveNotifications) do if v == bar then table.remove(ActiveNotifications, i); break end end
            bar:Destroy()
        end
    end)
end

-- Главное меню
local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 520, 0, 400); Main.Position = UDim2.new(0.5, -260, 0.5, -200); Main.BackgroundColor3 = Color3.fromRGB(18, 18, 24); Main.BorderSizePixel = 0; Main.Active = true; Main.Draggable = true; Main.Parent = ScreenGui
local MainCorner = Instance.new("UICorner"); MainCorner.CornerRadius = UDim.new(0, 8); MainCorner.Parent = Main
local MainStroke = Instance.new("UIStroke"); MainStroke.Color = Color3.fromRGB(45, 45, 60); MainStroke.Thickness = 2; MainStroke.Parent = Main

local Header = Instance.new("Frame"); Header.Size = UDim2.new(1, 0, 0, 45); Header.BackgroundColor3 = Color3.fromRGB(25, 25, 35); Header.Parent = Main
local HeaderCorner = Instance.new("UICorner"); HeaderCorner.CornerRadius = UDim.new(0, 8); HeaderCorner.Parent = Header
local Title = Instance.new("TextLabel"); Title.Size = UDim2.new(1, -20, 1, 0); Title.Position = UDim2.new(0, 15, 0, 0); Title.BackgroundTransparency = 1; Title.Text = "pisunRust v2 | Menu"; Title.TextColor3 = Color3.fromRGB(230, 230, 250); Title.Font = Enum.Font.GothamBold; Title.TextSize = 16; Title.TextXAlignment = Enum.TextXAlignment.Left; Title.Parent = Header

local TabContainer = Instance.new("Frame"); TabContainer.Size = UDim2.new(0, 130, 1, -45); TabContainer.Position = UDim2.new(0, 0, 0, 45); TabContainer.BackgroundColor3 = Color3.fromRGB(22, 22, 30); TabContainer.Parent = Main
local ContentContainer = Instance.new("Frame"); ContentContainer.Size = UDim2.new(1, -150, 1, -65); ContentContainer.Position = UDim2.new(0, 140, 0, 55); ContentContainer.BackgroundTransparency = 1; ContentContainer.Parent = Main

local Tabs, Pages, tabY = {}, {}, 8 

local function CreateTab(name)
    local btn = Instance.new("TextButton"); btn.Size = UDim2.new(1, -16, 0, 35); btn.Position = UDim2.new(0, 8, 0, tabY); btn.BackgroundColor3 = Color3.fromRGB(30, 30, 45); btn.Text = "  " .. name; btn.TextColor3 = Color3.fromRGB(180, 180, 200); btn.Font = Enum.Font.GothamSemibold; btn.TextSize = 14; btn.TextXAlignment = Enum.TextXAlignment.Left; btn.Parent = TabContainer
    local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 6); corner.Parent = btn
    local page = Instance.new("Frame"); page.Size = UDim2.new(1, 0, 1, 0); page.BackgroundTransparency = 1; page.Visible = false; page.Parent = ContentContainer
    Tabs[name] = btn; Pages[name] = page; tabY = tabY + 40 
    btn.MouseButton1Click:Connect(function()
        for tName, tBtn in pairs(Tabs) do tBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 45); tBtn.TextColor3 = Color3.fromRGB(180, 180, 200); Pages[tName].Visible = false end
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
CreateToggle(PageVisuals, "ESP Weapon Name", Config.ESPWeapon, 35, function(v) Config.ESPWeapon = v end)
CreateToggle(PageVisuals, "Chams", Config.ChamsEnabled, 70, function(v) Config.ChamsEnabled = v end)
CreateToggle(PageVisuals, "Damage Numbers", Config.DamageNumbers, 105, function(v) Config.DamageNumbers = v end)
CreateToggle(PageVisuals, "Show Damage Log", Config.ShowDamageLog, 140, function(v) Config.ShowDamageLog = v; DamageLogPanel.Visible = v end)
CreateSlider(PageVisuals, "Max ESP Distance", 100, 2000, Config.ESPMaxDist, 175, function(v) Config.ESPMaxDist = v end)

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

Tabs["Aimbot"].BackgroundColor3 = Color3.fromRGB(50, 50, 75); Tabs["Aimbot"].TextColor3 = Color3.fromRGB(255, 255, 255); Pages["Aimbot"].Visible = true

-- ============================================================================
-- UNLOAD
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
            esp.Name:Remove(); esp.Dist:Remove(); esp.HealthBarBg:Remove(); esp.HealthBarFill:Remove(); esp.Weapon:Remove()
        end)
    end
    ESPObjects = {}
    for p, chams in pairs(ChamsObjects) do pcall(function() chams:Destroy() end) end
    ChamsObjects = {}
    for _, popup in pairs(DamagePopups) do pcall(function() popup.Text:Remove() end) end
    DamagePopups = {}
    pcall(function() keyrelease(Enum.KeyCode.LeftShift) end)
    pcall(function()
        Lighting.ClockTime = 14; Lighting.Brightness = 1
        Lighting.Ambient = Color3.fromRGB(70, 70, 70); Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
        Lighting.GlobalShadows = true; Lighting.FogEnd = 1000
    end)
    print("[pisunRust v2] Unloaded.")
end
CreateButton(PageMisc, "UNLOAD CHEAT (PANIC)", 80, FullCleanup, Color3.fromRGB(150, 30, 30))

-- ============================================================================
-- СИСТЕМА УРОНА (ТЕПЕРЬ ЛОГ ТОЛЬКО НАНЕСЕННОГО)
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
    else text:Remove() end
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
                        local head = char:FindFirstChild("Head")
                        -- Показываем только цифру, в лог не пишем
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
                    local head = char:FindFirstChild("Head")
                    if head and dmg > 0 then 
                        SpawnDamageNumber(head.Position + Vector3.new(0, 1, 0), dmg, false)
                        AddNotification(dmg) -- ТОЛЬКО НАНЕСЕННЫЙ УРОН В ЛОГ
                    end
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
-- ESP
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
    esp.Weapon = Drawing.new("Text"); esp.Weapon.Size = 14; esp.Weapon.Center = true; esp.Weapon.Outline = true; esp.Weapon.Color = Color3.fromRGB(255, 150, 50); esp.Weapon.Visible = false
    esp.HealthBarBg = Drawing.new("Square"); esp.HealthBarBg.Filled = true; esp.HealthBarBg.Color = Color3.fromRGB(0, 0, 0); esp.HealthBarBg.Thickness = 1; esp.HealthBarBg.Visible = false
    esp.HealthBarFill = Drawing.new("Square"); esp.HealthBarFill.Filled = true; esp.HealthBarFill.Color = Color3.fromRGB(0, 255, 0); esp.HealthBarFill.Visible = false
    return esp
end

local function CleanupESP(p)
    if ESPObjects[p] then
        local esp = ESPObjects[p]
        pcall(function()
            esp.Box1:Remove(); esp.Box2:Remove(); esp.Box3:Remove(); esp.Box4:Remove()
            esp.Name:Remove(); esp.Dist:Remove(); esp.HealthBarBg:Remove(); esp.HealthBarFill:Remove(); esp.Weapon:Remove()
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
            esp.Name.Visible = false; esp.Dist.Visible = false; esp.HealthBarBg.Visible = false; esp.HealthBarFill.Visible = false; esp.Weapon.Visible = false
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

                            -- Сместили текст чуть выше, чтобы оружие влезло
                            esp.Name.Text = p.Name; esp.Name.Position = Vector2.new(screenHead.X, y - 45); esp.Name.Visible = true
                            esp.Dist.Text = "[" .. dist .. "m]"; esp.Dist.Position = Vector2.new(screenHead.X, y - 30); esp.Dist.Visible = true
                            
                            -- ФИКС ОРУЖИЯ
                            if Config.ESPWeapon then
                                local weaponName = GetWeaponName(p.Character)
                                if weaponName then
                                    esp.Weapon.Text = "[" .. GetShortWeaponName(weaponName) .. "]"
                                    esp.Weapon.Position = Vector2.new(screenHead.X, y - 15)
                                    esp.Weapon.Visible = true
                                else
                                    esp.Weapon.Visible = false
                                end
                            else
                                esp.Weapon.Visible = false
                            end

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
                            esp.Name.Visible = false; esp.Dist.Visible = false; esp.HealthBarBg.Visible = false; esp.HealthBarFill.Visible = false; esp.Weapon.Visible = false
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
-- ВВОД
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
    
    State.Frames = State.Frames + 1
    State.Time = State.Time + deltaTime
    if State.Time >= 1 then
        State.FPS = math.floor(State.Frames / State.Time)
        State.Frames = 0
        State.Time = 0
    end

    State.RainbowHue = (State.RainbowHue + 0.005) % 1
    local RainbowColor = Color3.fromHSV(State.RainbowHue, 1, 1)
    TitleLabel.TextColor3 = RainbowColor
    FPSLabel.Text = "FPS: " .. State.FPS
    FPSLabel.TextColor3 = RainbowColor
    FeaturesLabel.TextColor3 = RainbowColor
    
    FeaturesLabel.Text = string.format("Aimbot: %s | ESP: %s\nChams: %s | Light: %s", 
        Config.AimbotEnabled and "ON" or "OFF", Config.ESPEnabled and "ON" or "OFF",
        Config.ChamsEnabled and "ON" or "OFF", Config.Fullbright and "ON" or "OFF"
    )

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

print("[pisunRust v2] V24 Loaded. Dealt-only log and Robust Weapon ESP active.")
