--[[
    RUST CLONE CHEAT - ULTIMATE EDITION
    Меню: ПРАВЫЙ SHIFT (RightShift)
    Исправлен аим через BindToRenderStep (обход блокировки камеры)
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- ============================================================================
-- КОНФИГУРАЦИЯ И ПЕРЕМЕННЫЕ
-- ============================================================================
local Settings = {
    -- Aimbot
    AimbotEnabled = true,
    SilentAimEnabled = false,
    VisibleAim = true,
    Prediction = true,
    AimPart = "Head", -- "Head", "Torso", "Random"
    FOV = 120,
    Smoothness = 0.35,
    AimbotKey = Enum.UserInputType.MouseButton2,
    
    -- Visuals
    ESPEnabled = true,
    ChamsEnabled = true,
    ChamsStyle = "Visibility", -- "Visibility" (Red/Green) или "Static" (Одноцветный)
    MaxDistance = 800,
    
    -- Misc
    AutoSprint = false,
    MenuKey = Enum.KeyCode.RightShift
}

local State = {
    HoldingKey = false,
    IsSprinting = false,
    MenuOpen = true,
    WaitingForKey = false,
    CurrentTab = "Aimbot"
}

local CONFIG_FILE = "RustCheat_Config.json"

-- ============================================================================
-- БЕЗОПАСНЫЕ ОБЕРТКИ (Чтобы Xeno не крашился)
-- ============================================================================
local function safeWriteFile(path, content)
    local success = pcall(function() writefile(path, content) end)
    return success
end

local function safeReadFile(path)
    local success, content = pcall(function() return readfile(path) end)
    return success and content
end

local function safeIsFile(path)
    local success, exists = pcall(function() return isfile(path) end)
    return success and exists
end

-- ============================================================================
-- СИСТЕМА КОНФИГОВ
-- ============================================================================
local ConfigManager = {}

function ConfigManager.Save()
    local data = HttpService:JSONEncode(Settings)
    if safeWriteFile(CONFIG_FILE, data) then
        return true
    end
    return false
end

function ConfigManager.Load()
    if not safeIsFile(CONFIG_FILE) then return false end
    local content = safeReadFile(CONFIG_FILE)
    if not content then return false end
    
    local success, parsed = pcall(function() return HttpService:JSONDecode(content) end)
    if success and parsed then
        for k, v in pairs(parsed) do
            if Settings[k] ~= nil then
                if k == "AimbotKey" then
                    -- Восстановление Enum значений
                    if type(v) == "string" then
                        if Enum.UserInputType[v] then Settings[k] = Enum.UserInputType[v]
                        elseif Enum.KeyCode[v] then Settings[k] = Enum.KeyCode[v] end
                    end
                else
                    Settings[k] = v
                end
            end
        end
        return true
    end
    return false
end

-- Автозагрузка конфига
pcall(ConfigManager.Load)

-- ============================================================================
-- БИБЛИОТЕКА UI (КРАСИВОЕ МЕНЮ)
-- ============================================================================
local UI = {}
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RustUltimateUI"
ScreenGui.Parent = gethui and gethui() or game:GetService("CoreGui")
ScreenGui.ResetOnSpawn = false

-- Главное окно
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 550, 0, 400)
MainFrame.Position = UDim2.new(0.5, -275, 0.5, -200)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 8)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(50, 50, 60)
MainStroke.Thickness = 1.5
MainStroke.Parent = MainFrame

-- Заголовок
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 40)
TitleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
TitleBar.BackgroundTransparency = 0.5
TitleBar.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 8)
TitleCorner.Parent = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, 0, 1, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "RUST ULTIMATE [RightShift]"
TitleLabel.TextColor3 = Color3.fromRGB(220, 220, 230)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 16
TitleLabel.Parent = TitleBar

-- Вкладки
local TabContainer = Instance.new("Frame")
TabContainer.Size = UDim2.new(0, 120, 1, -40)
TabContainer.Position = UDim2.new(0, 0, 0, 40)
TabContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
TabContainer.Parent = MainFrame

local TabCorner = Instance.new("UICorner")
TabCorner.CornerRadius = UDim.new(0, 8)
TabCorner.Parent = TabContainer

local ContentContainer = Instance.new("Frame")
ContentContainer.Size = UDim2.new(1, -140, 1, -60)
ContentContainer.Position = UDim2.new(0, 130, 0, 50)
ContentContainer.BackgroundTransparency = 1
ContentContainer.Parent = MainFrame

local Pages = {}
local TabButtons = {}

local function CreateTab(name, icon)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 40)
    btn.Position = UDim2.new(0, 5, 0, 5 + (#TabButtons * 45))
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    btn.Text = "  " .. name
    btn.TextColor3 = Color3.fromRGB(180, 180, 190)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 14
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Parent = TabContainer
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn
    
    local page = Instance.new("Frame")
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.Visible = false
    page.Parent = ContentContainer
    
    Pages[name] = page
    table.insert(TabButtons, btn)
    
    btn.MouseButton1Click:Connect(function()
        for pName, pFrame in pairs(Pages) do
            pFrame.Visible = false
        end
        for _, b in pairs(TabButtons) do
            b.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
            b.TextColor3 = Color3.fromRGB(180, 180, 190)
        end
        page.Visible = true
        btn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        State.CurrentTab = name
    end)
    
    return page
end

-- Создаем вкладки
local AimbotPage = CreateTab("Aimbot")
local VisualsPage = CreateTab("Visuals")
local MiscPage = CreateTab("Misc")

-- Элементы UI (Toggle)
local function CreateToggle(parent, text, default, pos, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 30)
    frame.Position = pos
    frame.BackgroundTransparency = 1
    frame.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(200, 200, 210)
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 40, 0, 20)
    toggleBtn.Position = UDim2.new(1, -40, 0.5, -10)
    toggleBtn.BackgroundColor3 = default and Color3.fromRGB(0, 150, 80) or Color3.fromRGB(60, 60, 70)
    toggleBtn.Text = ""
    toggleBtn.Parent = frame
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = toggleBtn
    
    local circle = Instance.new("Frame")
    circle.Size = UDim2.new(0, 16, 0, 16)
    circle.Position = default and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    circle.Parent = toggleBtn
    
    local circleCorner = Instance.new("UICorner")
    circleCorner.CornerRadius = UDim.new(1, 0)
    circleCorner.Parent = circle
    
    local state = default
    
    toggleBtn.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(toggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = state and Color3.fromRGB(0, 150, 80) or Color3.fromRGB(60, 60, 70)}):Play()
        TweenService:Create(circle, TweenInfo.new(0.2), {Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)}):Play()
        callback(state)
    end)
end

-- Элементы UI (Slider)
local function CreateSlider(parent, text, min, max, default, pos, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 45)
    frame.Position = pos
    frame.BackgroundTransparency = 1
    frame.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6, 0, 0, 20)
    label.BackgroundTransparency = 1
    label.Text = text .. ": " .. default
    label.TextColor3 = Color3.fromRGB(200, 200, 210)
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    
    local barBg = Instance.new("Frame")
    barBg.Size = UDim2.new(1, 0, 0, 6)
    barBg.Position = UDim2.new(0, 0, 0, 28)
    barBg.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    barBg.Parent = frame
    
    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(1, 0)
    barCorner.Parent = barBg
    
    local barFill = Instance.new("Frame")
    barFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    barFill.BackgroundColor3 = Color3.fromRGB(80, 120, 255)
    barFill.Parent = barBg
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = barFill
    
    local dragging = false
    
    local function update(input)
        local mouseX = math.clamp(input.Position.X, barBg.AbsolutePosition.X, barBg.AbsolutePosition.X + barBg.AbsoluteSize.X)
        local percent = (mouseX - barBg.AbsolutePosition.X) / barBg.AbsoluteSize.X
        local value = math.floor(min + (max - min) * percent)
        barFill.Size = UDim2.new(percent, 0, 1, 0)
        label.Text = text .. ": " .. value
        callback(value)
    end
    
    barBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            update(input)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            update(input)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

-- Элементы UI (Button)
local function CreateButton(parent, text, pos, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 30)
    btn.Position = pos
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(200, 200, 220)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 14
    btn.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn
    
    btn.MouseButton1Click:Connect(function()
        callback()
    end)
    
    return btn
end

-- ============================================================================
-- НАСТРОЙКА ВКЛАДОК (Добавление элементов)
-- ============================================================================

-- Вкладка Aimbot
CreateToggle(AimbotPage, "Aimbot Enabled", Settings.AimbotEnabled, UDim2.new(0, 0, 0, 0), function(val) Settings.AimbotEnabled = val end)
CreateToggle(AimbotPage, "Silent Aim", Settings.SilentAimEnabled, UDim2.new(0, 0, 0, 35), function(val) Settings.SilentAimEnabled = val end)
CreateToggle(AimbotPage, "Visible Aim (Только видимых)", Settings.VisibleAim, UDim2.new(0, 0, 0, 70), function(val) Settings.VisibleAim = val end)
CreateToggle(AimbotPage, "Prediction (Упреждение)", Settings.Prediction, UDim2.new(0, 0, 0, 105), function(val) Settings.Prediction = val end)
CreateSlider(AimbotPage, "FOV Size", 30, 400, Settings.FOV, UDim2.new(0, 0, 0, 145), function(val) Settings.FOV = val end)
CreateSlider(AimbotPage, "Smoothness", 1, 100, Settings.Smoothness * 100, UDim2.new(0, 0, 0, 195), function(val) Settings.Smoothness = val / 100 end)

local keyBindBtn
keyBindBtn = CreateButton(AimbotPage, "Aim Key: " .. tostring(Settings.AimbotKey):gsub("Enum.UserInputType.", ""), UDim2.new(0, 0, 0, 250), function()
    State.WaitingForKey = true
    keyBindBtn.Text = "Нажми клавишу..."
    keyBindBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
end)

-- Вкладка Visuals
CreateToggle(VisualsPage, "ESP Player Box", Settings.ESPEnabled, UDim2.new(0, 0, 0, 0), function(val) Settings.ESPEnabled = val end)
CreateToggle(VisualsPage, "Chams (Подсветка)", Settings.ChamsEnabled, UDim2.new(0, 0, 0, 35), function(val) Settings.ChamsEnabled = val end)
CreateToggle(VisualsPage, "Chams Mode: Visibility (Красный/Зеленый)", Settings.ChamsStyle == "Visibility", UDim2.new(0, 0, 0, 70), function(val) Settings.ChamsStyle = val and "Visibility" or "Static" end)
CreateSlider(VisualsPage, "Max ESP Distance", 100, 2000, Settings.MaxDistance, UDim2.new(0, 0, 0, 115), function(val) Settings.MaxDistance = val end)

-- Вкладка Misc
CreateToggle(MiscPage, "Auto Sprint", Settings.AutoSprint, UDim2.new(0, 0, 0, 0), function(val) Settings.AutoSprint = val end)
CreateButton(MiscPage, "SAVE CONFIG", UDim2.new(0, 0, 0, 45), function()
    if ConfigManager.Save() then
        keyBindBtn.Text = "Config Saved!"
        task.wait(1)
        keyBindBtn.Text = "Aim Key: " .. tostring(Settings.AimbotKey):gsub("Enum.UserInputType.", ""):gsub("Enum.KeyCode.", "")
    end
end)
CreateButton(MiscPage, "LOAD CONFIG", UDim2.new(0, 0, 0, 85), function()
    if ConfigManager.Load() then
        keyBindBtn.Text = "Config Loaded!"
        task.wait(1)
        keyBindBtn.Text = "Aim Key: " .. tostring(Settings.AimbotKey):gsub("Enum.UserInputType.", ""):gsub("Enum.KeyCode.", "")
    end
end)

-- По умолчанию открываем Aimbot
TabButtons[1].MouseButton1Click:Fire()

-- ============================================================================
-- FOV КРУГ (DRAWING API)
-- ============================================================================
local FovCircle = Drawing.new("Circle")
FovCircle.Thickness = 1.5
FovCircle.NumSides = 100
FovCircle.Radius = Settings.FOV
FovCircle.Color = Color3.fromRGB(80, 120, 255)
FovCircle.Filled = false
FovCircle.Visible = false
FovCircle.Transparency = 0.7

-- ============================================================================
-- ОБРАБОТКА ВВОДА
-- ============================================================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    -- Открытие/Закрытие меню
    if input.KeyCode == Settings.MenuKey then
        State.MenuOpen = not State.MenuOpen
        MainFrame.Visible = State.MenuOpen
    end

    -- Установка бинда
    if State.WaitingForKey then
        if input.UserInputType == Enum.UserInputType.Keyboard then
            Settings.AimbotKey = input.KeyCode
        else
            Settings.AimbotKey = input.UserInputType
        end
        State.WaitingForKey = false
        keyBindBtn.Text = "Aim Key: " .. tostring(Settings.AimbotKey):gsub("Enum.UserInputType.", ""):gsub("Enum.KeyCode.", "")
        keyBindBtn.TextColor3 = Color3.fromRGB(200, 200, 220)
        return
    end

    if gameProcessed then return end

    -- Нажатие бинда аимбота
    if input.UserInputType == Settings.AimbotKey or input.KeyCode == Settings.AimbotKey then
        State.HoldingKey = true
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if input.UserInputType == Settings.AimbotKey or input.KeyCode == Settings.AimbotKey then
        State.HoldingKey = false
    end
end)

-- ============================================================================
-- МОДУЛЬ ESP (ОЧИСТКА И ОТРИСОВКА)
-- ============================================================================
local ESPCache = {}
local ChamsCache = {}

local function IsPlayerVisible(targetChar)
    local myChar = LocalPlayer.Character
    local targetPart = targetChar:FindFirstChild("Head") or targetChar:FindFirstChild("HumanoidRootPart")
    if not myChar or not myChar:FindFirstChild("Head") or not targetPart then return false end

    local RayParams = RaycastParams.new()
    RayParams.FilterType = Enum.RaycastFilterType.Exclude
    RayParams.FilterDescendantsInstances = {myChar, targetChar}

    local RayResult = workspace:Raycast(Camera.CFrame.Position, targetPart.Position - Camera.CFrame.Position, RayParams)
    return RayResult == nil
end

local function CreateESP(targetPlayer)
    local ESP = {
        Box = Drawing.new("Square"),
        Name = Drawing.new("Text"),
        Health = Drawing.new("Text"),
        Dist = Drawing.new("Text")
    }
    
    ESP.Box.Thickness = 1
    ESP.Box.Color = Color3.fromRGB(255, 50, 50)
    ESP.Box.Filled = false
    ESP.Box.Transparency = 1
    
    ESP.Name.Size = 14
    ESP.Name.Center = true
    ESP.Name.Outline = true
    ESP.Name.Color = Color3.fromRGB(255, 255, 255)
    
    ESP.Health.Size = 12
    ESP.Health.Center = true
    ESP.Health.Outline = true
    ESP.Health.Color = Color3.fromRGB(0, 255, 0)
    
    ESP.Dist.Size = 12
    ESP.Dist.Center = true
    ESP.Dist.Outline = true
    ESP.Dist.Color = Color3.fromRGB(255, 200, 0)
    
    return ESP
end

local function UpdateVisuals()
    -- Очистка "мертвых" ESP
    for p, esp in pairs(ESPCache) do
        if not p or not p.Parent or not p.Character or not p.Character:FindFirstChild("Humanoid") or p.Character.Humanoid.Health <= 0 then
            esp.Box.Visible = false
            esp.Name.Visible = false
            esp.Health.Visible = false
            esp.Dist.Visible = false
            ESPCache[p] = nil
            if ChamsCache[p] then
                ChamsCache[p]:Destroy()
                ChamsCache[p] = nil
            end
        end
    end

    -- Отрисовка живых
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Humanoid") and p.Character:FindFirstChild("Head") then
            local hum = p.Character.Humanoid
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            local head = p.Character:FindFirstChild("Head")
            
            if hum.Health > 0 and hrp and head then
                local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                local dist = (myRoot and hrp) and math.floor((myRoot.Position - hrp.Position).Magnitude) or 0

                -- Если дистанция больше лимита, скипаем
                if dist > Settings.MaxDistance then
                    if ESPCache[p] then
                        ESPCache[p].Box.Visible = false
                        ESPCache[p].Name.Visible = false
                        ESPCache[p].Health.Visible = false
                        ESPCache[p].Dist.Visible = false
                    end
                    if ChamsCache[p] then
                        ChamsCache[p]:Destroy()
                        ChamsCache[p] = nil
                    end
                    continue
                end

                -- CHAMS (Подсветка)
                if Settings.ChamsEnabled then
                    if not ChamsCache[p] or ChamsCache[p].Parent ~= p.Character then
                        if ChamsCache[p] then ChamsCache[p]:Destroy() end
                        local chams = Instance.new("Highlight")
                        chams.FillTransparency = 0.6
                        chams.OutlineTransparency = 0
                        chams.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        chams.Parent = p.Character
                        ChamsCache[p] = chams
                    end

                    local chams = ChamsCache[p]
                    if Settings.ChamsStyle == "Visibility" then
                        local visible = IsPlayerVisible(p.Character)
                        chams.FillColor = visible and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
                        chams.OutlineColor = visible and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(255, 0, 0)
                    else
                        chams.FillColor = Color3.fromRGB(255, 0, 0)
                        chams.OutlineColor = Color3.fromRGB(255, 255, 255)
                    end
                elseif ChamsCache[p] then
                    ChamsCache[p]:Destroy()
                    ChamsCache[p] = nil
                end

                -- ESP BOXES
                if Settings.ESPEnabled then
                    if not ESPCache[p] then
                        ESPCache[p] = CreateESP(p)
                    end
                    local esp = ESPCache[p]
                    
                    local headPos = head.Position + Vector3.new(0, 0.5, 0)
                    local rootPos = hrp.Position - Vector3.new(0, 2.5, 0)
                    local screenHead, onScreen = Camera:WorldToViewportPoint(headPos)
                    local screenRoot, _ = Camera:WorldToViewportPoint(rootPos)

                    -- ВАЖНО: Проверка Z > 0 (чтобы не рисовало за спиной)
                    if onScreen and screenHead.Z > 0 then
                        local height = math.abs(screenHead.Y - screenRoot.Y)
                        local width = height * 0.55

                        esp.Box.Size = Vector2.new(width, height)
                        esp.Box.Position = Vector2.new(screenHead.X - (width / 2), screenHead.Y)
                        esp.Box.Visible = true

                        esp.Name.Text = p.Name
                        esp.Name.Position = Vector2.new(screenHead.X, screenHead.Y - 32)
                        esp.Name.Visible = true

                        esp.Health.Text = "HP: " .. math.floor(hum.Health)
                        esp.Health.Position = Vector2.new(screenHead.X, screenHead.Y + height + 2)
                        esp.Health.Visible = true

                        esp.Dist.Text = "[" .. dist .. "m]"
                        esp.Dist.Position = Vector2.new(screenHead.X, screenHead.Y - 18)
                        esp.Dist.Visible = true
                    else
                        esp.Box.Visible = false
                        esp.Name.Visible = false
                        esp.Health.Visible = false
                        esp.Dist.Visible = false
                    end
                elseif ESPCache[p] then
                    ESPCache[p].Box.Visible = false
                    ESPCache[p].Name.Visible = false
                    ESPCache[p].Health.Visible = false
                    ESPCache[p].Dist.Visible = false
                end
            end
        end
    end
end

-- ============================================================================
-- МОДУЛЬ AIMBOT (ИСПРАВЛЕННЫЙ)
-- ============================================================================
local function GetTarget()
    local closestPlayer = nil
    local shortestDist = Settings.FOV
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Humanoid") then
            local hum = p.Character.Humanoid
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            local head = p.Character:FindFirstChild("Head")
            
            if hum.Health > 0 and hrp and head then
                local targetPos = Vector3.new(0, 0, 0)
                
                if Settings.AimPart == "Head" then
                    targetPos = head.Position
                elseif Settings.AimPart == "Torso" then
                    targetPos = hrp.Position
                else
                    targetPos = (head.Position + hrp.Position) / 2
                end

                local screenPos, onScreen = Camera:WorldToViewportPoint(targetPos)
                
                -- Проверка, что цель на экране и перед нами (Z > 0)
                if onScreen and screenPos.Z > 0 then
                    local dist = (screenCenter - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
                    
                    if dist < shortestDist then
                        if Settings.VisibleAim and not IsPlayerVisible(p.Character) then
                            continue
                        end

                        shortestDist = dist
                        
                        -- Предугадывание
                        if Settings.Prediction then
                            local velocity = hrp.AssemblyLinearVelocity
                            targetPos = targetPos + (velocity * 0.15)
                        end

                        closestPlayer = { player = p, part = hrp, pos = targetPos }
                    end
                end
            end
        end
    end
    return closestPlayer
end

-- ============================================================================
-- ГЛАВНЫЙ ЦИКЛ (RunService)
-- ============================================================================

-- Отрисовка меню и ESP (RenderStepped)
RunService.RenderStepped:Connect(function()
    -- FOV Круг
    if Settings.AimbotEnabled and State.MenuOpen == false or Settings.AimbotEnabled then
        local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        FovCircle.Position = screenCenter
        FovCircle.Radius = Settings.FOV
        FovCircle.Visible = Settings.AimbotEnabled
    else
        FovCircle.Visible = false
    end

    -- Обновление ESP
    if Settings.ESPEnabled or Settings.ChamsEnabled then
        UpdateVisuals()
    end

    -- Авто-спринт
    if Settings.AutoSprint then
        if not State.IsSprinting then
            keypress(Enum.KeyCode.LeftShift)
            State.IsSprinting = true
        end
    else
        if State.IsSprinting then
            keyrelease(Enum.KeyCode.LeftShift)
            State.IsSprinting = false
        end
    end
end)

-- КРИТИЧЕСКИЙ ФИКС АИМА (BindToRenderStep)
-- Мы ставим приоритет Camera.Value + 1, чтобы скрипт срабатывал ПОСЛЕ обновления камеры игрой
local AimbotConnection = RunService:BindToRenderStep("RustAimbotCamera", Enum.RenderPriority.Camera.Value + 1, function(deltaTime)
    if not Settings.AimbotEnabled or not State.HoldingKey then return end
    
    local target = GetTarget()
    if target then
        local currentCFrame = Camera.CFrame
        local targetCFrame = CFrame.new(currentCFrame.Position, target.pos)
        
        -- Плавность
        local smooth = math.clamp(Settings.Smoothness, 0.01, 1)
        Camera.CFrame = currentCFrame:Lerp(targetCFrame, smooth)
        
        -- Silent Aim логика
        if Settings.SilentAimEnabled then
            -- В Roblox Silent Aim делается через хук workspace.Raycast или метательные оружия
            -- Так как это клон Rust, добавим попытку хука, если экзекьютор поддерживает
            if type(hookfunction) == "function" and not _G.SilentAimHooked then
                _G.SilentAimHooked = true
                local oldRaycast = workspace.Raycast
                workspace.Raycast = function(self, origin, direction, params)
                    if State.HoldingKey and Settings.SilentAimEnabled then
                        local currentTarget = GetTarget()
                        if currentTarget then
                            direction = (currentTarget.pos - origin).Unit * direction.Magnitude
                        end
                    end
                    return oldRaycast(self, origin, direction, params)
                end
            end
        end
    end
end)

print("[RUST ULTIMATE] Скрипт успешно загружен!")
print("[RUST ULTIMATE] Меню: ПРАВЫЙ SHIFT")
print("[RUST ULTIMATE] Всего строк: 600+")
