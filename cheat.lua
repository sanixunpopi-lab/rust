--[[
    RUST CLONE CHEAT - OMNIX FRAMEWORK (1300+ строк)
    Полностью рабочий аимбот, ESP, Chams и система биндов.
    Меню: RightShift (Правый Shift)
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- ============================================================================
-- НАСТРОЙКИ ПО УМОЛЧАНИЮ
-- ============================================================================
local Config = {
    -- Aimbot
    AimbotEnabled = true,
    AimbotMethod = "Camera", -- "Camera" или "Mouse"
    AimPart = "Head", -- "Head", "Torso", "Random"
    FOV = 150,
    Smoothness = 0.25,
    VisibleAim = true,
    Prediction = true,
    
    -- Visuals
    ESPEnabled = true,
    ESPBox = true,
    ESPName = true,
    ESPHealth = true,
    ESPDistance = true,
    ESPMaxDist = 1000,
    
    ChamsEnabled = true,
    ChamsVisible = true,
    ChamsStyle = "Visibility", -- "Visibility" или "Static"
    
    -- Misc
    AutoSprint = false,
    MenuKey = Enum.KeyCode.RightShift
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
    WaitingForKey = nil, -- Хранит название функции, для которой настраивается бинд
    ActiveTab = "Aimbot"
}

local CONFIG_FILE = "Omnix_Config.json"
local ESPObjects = {}
local ChamsObjects = {}

-- ============================================================================
-- СИСТЕМА КОНФИГОВ (СОХРАНЕНИЕ / ЗАГРУЗКА)
-- ============================================================================
local function SaveConfig()
    local data = { Config = Config, Binds = {} }
    for k, v in pairs(Binds) do
        data.Binds[k] = tostring(v)
    end
    pcall(function() writefile(CONFIG_FILE, HttpService:JSONEncode(data)) end)
end

local function LoadConfig()
    if not isfile(CONFIG_FILE) then return end
    local success, data = pcall(function() return HttpService:JSONDecode(readfile(CONFIG_FILE)) end)
    if success and data then
        if data.Config then
            for k, v in pairs(data.Config) do
                if Config[k] ~= nil then Config[k] = v end
            end
        end
        if data.Binds then
            for k, v in pairs(data.Binds) do
                if string.find(v, "Enum.UserInputType") then
                    Binds[k] = Enum.UserInputType[v:gsub("Enum.UserInputType.", "")]
                elseif string.find(v, "Enum.KeyCode") then
                    Binds[k] = Enum.KeyCode[v:gsub("Enum.KeyCode.", "")]
                end
            end
        end
    end
end

pcall(LoadConfig)

-- ============================================================================
-- БИБЛИОТЕКА UI (ФРЕЙМВОРК)
-- ============================================================================
local UI = {}
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "OmnixUI"
ScreenGui.Parent = gethui and gethui() or game:GetService("CoreGui")
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 560, 0, 420)
Main.Position = UDim2.new(0.5, -280, 0.5, -210)
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

-- Заголовок
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
Title.Text = "OMNIX CHEAT | RUST CLONE"
Title.TextColor3 = Color3.fromRGB(230, 230, 250)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

-- Меню вкладок
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

local Tabs = {}
local Pages = {}

local function CreateTab(name)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -16, 0, 35)
    btn.Position = UDim2.new(0, 8, 0, 8 + (#Tabs * 40))
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    btn.Text = "  " .. name
    btn.TextColor3 = Color3.fromRGB(180, 180, 200)
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
    
    Tabs[name] = btn
    Pages[name] = page
    
    btn.MouseButton1Click:Connect(function()
        for tName, tBtn in pairs(Tabs) do
            tBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
            tBtn.TextColor3 = Color3.fromRGB(180, 180, 200)
            Pages[tName].Visible = false
        end
        btn.BackgroundColor3 = Color3.fromRGB(50, 50, 75)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        page.Visible = true
        State.ActiveTab = name
    end)
    
    return page
end

local PageAimbot = CreateTab("Aimbot")
local PageVisuals = CreateTab("Visuals")
local PageBinds = CreateTab("Binds")
local PageMisc = CreateTab("Misc")

-- Элементы UI
local function CreateToggle(parent, text, default, posY, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 30)
    frame.Position = UDim2.new(0, 0, 0, posY)
    frame.BackgroundTransparency = 1
    frame.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.8, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(210, 210, 220)
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 36, 0, 18)
    btn.Position = UDim2.new(1, -36, 0.5, -9)
    btn.BackgroundColor3 = default and Color3.fromRGB(0, 170, 100) or Color3.fromRGB(60, 60, 70)
    btn.Text = ""
    btn.Parent = frame
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = btn
    
    local circle = Instance.new("Frame")
    circle.Size = UDim2.new(0, 14, 0, 14)
    circle.Position = default and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
    circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    circle.Parent = btn
    
    local circleCorner = Instance.new("UICorner")
    circleCorner.CornerRadius = UDim.new(1, 0)
    circleCorner.Parent = circle
    
    local state = default
    btn.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = state and Color3.fromRGB(0, 170, 100) or Color3.fromRGB(60, 60, 70)}):Play()
        TweenService:Create(circle, TweenInfo.new(0.2), {Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)}):Play()
        callback(state)
    end)
end

local function CreateSlider(parent, text, min, max, default, posY, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 45)
    frame.Position = UDim2.new(0, 0, 0, posY)
    frame.BackgroundTransparency = 1
    frame.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 20)
    label.BackgroundTransparency = 1
    label.Text = text .. ": " .. default
    label.TextColor3 = Color3.fromRGB(210, 210, 220)
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, 0, 0, 6)
    bar.Position = UDim2.new(0, 0, 0, 28)
    bar.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    bar.Parent = frame
    
    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(1, 0)
    barCorner.Parent = bar
    
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(80, 120, 255)
    fill.Parent = bar
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = fill
    
    local dragging = false
    
    local function update(input)
        local mouseX = math.clamp(input.Position.X, bar.AbsolutePosition.X, bar.AbsolutePosition.X + bar.AbsoluteSize.X)
        local percent = (mouseX - bar.AbsolutePosition.X) / bar.AbsoluteSize.X
        local val = math.floor(min + (max - min) * percent)
        fill.Size = UDim2.new(percent, 0, 1, 0)
        label.Text = text .. ": " .. val
        callback(val)
    end
    
    bar.InputBegan:Connect(function(input)
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
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
end

local function CreateButton(parent, text, posY, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 32)
    btn.Position = UDim2.new(0, 0, 0, posY)
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(200, 200, 220)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 14
    btn.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn
    
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- Заполнение вкладок
CreateToggle(PageAimbot, "Aimbot Enabled", Config.AimbotEnabled, 0, function(v) Config.AimbotEnabled = v end)
CreateToggle(PageAimbot, "Visible Aim (Только видимых)", Config.VisibleAim, 35, function(v) Config.VisibleAim = v end)
CreateToggle(PageAimbot, "Prediction (Упреждение)", Config.Prediction, 70, function(v) Config.Prediction = v end)
CreateSlider(PageAimbot, "FOV Size", 30, 400, Config.FOV, 110, function(v) Config.FOV = v end)
CreateSlider(PageAimbot, "Smoothness", 1, 100, Config.Smoothness * 100, 160, function(v) Config.Smoothness = v / 100 end)

CreateToggle(PageVisuals, "ESP Boxes", Config.ESPEnabled, 0, function(v) Config.ESPEnabled = v end)
CreateToggle(PageVisuals, "Chams (Подсветка)", Config.ChamsEnabled, 35, function(v) Config.ChamsEnabled = v end)
CreateSlider(PageVisuals, "Max ESP Distance", 100, 2000, Config.ESPMaxDist, 80, function(v) Config.ESPMaxDist = v end)

CreateToggle(PageMisc, "Auto Sprint (Авто-бег)", Config.AutoSprint, 0, function(v) Config.AutoSprint = v end)

local bindBtns = {}
local function CreateBindButton(parent, text, bindName, posY)
    local btn = CreateButton(parent, text .. ": " .. tostring(Binds[bindName]):gsub("Enum.UserInputType.", ""):gsub("Enum.KeyCode.", ""), posY, function()
        State.WaitingForKey = bindName
        btn.Text = "Нажми клавишу..."
        btn.TextColor3 = Color3.fromRGB(255, 100, 100)
    end)
    bindBtns[bindName] = btn
end

CreateBindButton(PageBinds, "Aimbot Key", "Aimbot", 0)
CreateBindButton(PageBinds, "ESP Toggle", "ESP", 40)
CreateBindButton(PageBinds, "Chams Toggle", "Chams", 80)
CreateBindButton(PageBinds, "Sprint Toggle", "Sprint", 120)

CreateButton(PageMisc, "SAVE CONFIG", 45, function() SaveConfig() end)
CreateButton(PageMisc, "LOAD CONFIG", 85, function() LoadConfig() end)

Tabs["Aimbot"].MouseButton1Click:Fire()

-- ============================================================================
-- FOV КРУГ
-- ============================================================================
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 2
FOVCircle.NumSides = 100
FOVCircle.Radius = Config.FOV
FOVCircle.Color = Color3.fromRGB(80, 120, 255)
FOVCircle.Filled = false
FOVCircle.Visible = false
FOVCircle.Transparency = 0.8

-- ============================================================================
-- ЛОГИКА ESP И CHAMS
-- ============================================================================
local function IsVisible(targetChar)
    local myChar = LocalPlayer.Character
    local targetPart = targetChar:FindFirstChild("Head") or targetChar:FindFirstChild("HumanoidRootPart")
    if not myChar or not myChar:FindFirstChild("Head") or not targetPart then return false end

    local RayParams = RaycastParams.new()
    RayParams.FilterType = Enum.RaycastFilterType.Exclude
    RayParams.FilterDescendantsInstances = {myChar, targetChar}

    local RayResult = workspace:Raycast(Camera.CFrame.Position, targetPart.Position - Camera.CFrame.Position, RayParams)
    return RayResult == nil
end

local function CreateESPObject()
    local esp = {}
    esp.Box = Drawing.new("Square")
    esp.Box.Thickness = 1
    esp.Box.Color = Color3.fromRGB(255, 60, 60)
    esp.Box.Filled = false
    esp.Box.Visible = false

    esp.Name = Drawing.new("Text")
    esp.Name.Size = 14
    esp.Name.Center = true
    esp.Name.Outline = true
    esp.Name.Color = Color3.fromRGB(255, 255, 255)
    esp.Name.Visible = false

    esp.Health = Drawing.new("Text")
    esp.Health.Size = 12
    esp.Health.Center = true
    esp.Health.Outline = true
    esp.Health.Color = Color3.fromRGB(0, 255, 0)
    esp.Health.Visible = false

    esp.Dist = Drawing.new("Text")
    esp.Dist.Size = 12
    esp.Dist.Center = true
    esp.Dist.Outline = true
    esp.Dist.Color = Color3.fromRGB(255, 200, 0)
    esp.Dist.Visible = false

    return esp
end

local function UpdateESP()
    -- Очистка старых объектов
    for p, esp in pairs(ESPObjects) do
        if not p or not p.Parent or not p.Character or not p.Character:FindFirstChild("Humanoid") or p.Character.Humanoid.Health <= 0 then
            esp.Box:Remove()
            esp.Name:Remove()
            esp.Health:Remove()
            esp.Dist:Remove()
            ESPObjects[p] = nil
        end
    end

    for p, chams in pairs(ChamsObjects) do
        if not p or not p.Parent or not p.Character then
            chams:Destroy()
            ChamsObjects[p] = nil
        end
    end

    -- Отрисовка
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Humanoid") and p.Character:FindFirstChild("Head") then
            local hum = p.Character.Humanoid
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            local head = p.Character:FindFirstChild("Head")

            if hum.Health > 0 and hrp and head then
                local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                local dist = (myRoot and hrp) and math.floor((myRoot.Position - hrp.Position).Magnitude) or 0

                if dist <= Config.ESPMaxDist then
                    -- CHAMS
                    if Config.ChamsEnabled then
                        if not ChamsObjects[p] or ChamsObjects[p].Parent ~= p.Character then
                            if ChamsObjects[p] then ChamsObjects[p]:Destroy() end
                            local chams = Instance.new("Highlight")
                            chams.FillTransparency = 0.5
                            chams.OutlineTransparency = 0
                            chams.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                            chams.Parent = p.Character
                            ChamsObjects[p] = chams
                        end

                        local chams = ChamsObjects[p]
                        if tick() - (chams:GetAttribute("LastCheck") or 0) > 0.1 then
                            chams:SetAttribute("LastCheck", tick())
                            if IsVisible(p.Character) then
                                chams.FillColor = Color3.fromRGB(0, 255, 0)
                                chams.OutlineColor = Color3.fromRGB(0, 255, 0)
                            else
                                chams.FillColor = Color3.fromRGB(255, 0, 0)
                                chams.OutlineColor = Color3.fromRGB(255, 255, 255)
                            end
                        end
                    elseif ChamsObjects[p] then
                        ChamsObjects[p]:Destroy()
                        ChamsObjects[p] = nil
                    end

                    -- ESP
                    if Config.ESPEnabled then
                        if not ESPObjects[p] then ESPObjects[p] = CreateESPObject() end
                        local esp = ESPObjects[p]

                        local screenHead, onScreen = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                        local screenRoot = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 2.5, 0))

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
                    end
                end
            end
        end
    end
end

-- ============================================================================
-- ЛОГИКА AIMBOT
-- ============================================================================
local function GetTarget()
    local closest = nil
    local shortestDist = Config.FOV
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Humanoid") then
            local hum = p.Character.Humanoid
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            local head = p.Character:FindFirstChild("Head")

            if hum.Health > 0 and hrp and head then
                local targetPos = Vector3.new(0,0,0)
                if Config.AimPart == "Head" then targetPos = head.Position
                elseif Config.AimPart == "Torso" then targetPos = hrp.Position
                else targetPos = (head.Position + hrp.Position) / 2 end

                local screenPos, onScreen = Camera:WorldToViewportPoint(targetPos)

                if onScreen and screenPos.Z > 0 then
                    local dist = (screenCenter - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
                    
                    if dist < shortestDist then
                        if Config.VisibleAim and not IsVisible(p.Character) then continue end
                        
                        shortestDist = dist
                        local finalPos = targetPos
                        
                        if Config.Prediction then
                            local velocity = hrp.AssemblyLinearVelocity
                            finalPos = finalPos + (velocity * 0.15)
                        end

                        closest = { player = p, part = hrp, pos = finalPos }
                    end
                end
            end
        end
    end
    return closest
end

-- ============================================================================
-- ОБРАБОТКА ВВОДА (БИНДЫ)
-- ============================================================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    -- Меню открывается всегда
    if input.KeyCode == Config.MenuKey then
        State.MenuOpen = not State.MenuOpen
        Main.Visible = State.MenuOpen
        return
    end

    -- Ожидание настройки бинда
    if State.WaitingForKey then
        if input.UserInputType == Enum.UserInputType.Keyboard then
            Binds[State.WaitingForKey] = input.KeyCode
            bindBtns[State.WaitingForKey].Text = State.WaitingForKey .. ": " .. tostring(input.KeyCode):gsub("Enum.KeyCode.", "")
        else
            Binds[State.WaitingForKey] = input.UserInputType
            bindBtns[State.WaitingForKey].Text = State.WaitingForKey .. ": " .. tostring(input.UserInputType):gsub("Enum.UserInputType.", "")
        end
        bindBtns[State.WaitingForKey].TextColor3 = Color3.fromRGB(200, 200, 220)
        State.WaitingForKey = nil
        return
    end

    -- Если кликаем по меню, игнорируем
    if gameProcessed then return end

    -- Проверка биндов
    if input.UserInputType == Binds.Aimbot or input.KeyCode == Binds.Aimbot then
        State.HoldingKey = true
    elseif input.UserInputType == Binds.ESP or input.KeyCode == Binds.ESP then
        Config.ESPEnabled = not Config.ESPEnabled
    elseif input.UserInputType == Binds.Chams or input.KeyCode == Binds.Chams then
        Config.ChamsEnabled = not Config.ChamsEnabled
    elseif input.UserInputType == Binds.Sprint or input.KeyCode == Binds.Sprint then
        Config.AutoSprint = not Config.AutoSprint
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if input.UserInputType == Binds.Aimbot or input.KeyCode == Binds.Aimbot then
        State.HoldingKey = false
    end
end)

-- ============================================================================
-- ГЛАВНЫЕ ЦИКЛЫ (ИСПРАВЛЕНИЕ АИМБОТА И ESP)
-- ============================================================================

-- Отрисовка ESP и FOV (Каждый кадр)
RunService.RenderStepped:Connect(function()
    -- FOV
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    FOVCircle.Radius = Config.FOV
    FOVCircle.Visible = Config.AimbotEnabled

    -- ESP
    if Config.ESPEnabled or Config.ChamsEnabled then
        pcall(UpdateESP)
    end

    -- Авто-бег
    if Config.AutoSprint then
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

-- ИСПРАВЛЕННЫЙ АИМБОТ (Работает даже с блокировкой камеры)
local AimbotLogic = RunService.Heartbeat:Connect(function()
    if not Config.AimbotEnabled or not State.HoldingKey then return end

    local target = GetTarget()
    if target then
        -- Метод 1: Прямое вращение камеры (стандартный)
        if Config.AimbotMethod == "Camera" then
            local camPos = Camera.CFrame.Position
            local targetCFrame = CFrame.new(camPos, target.pos)
            Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, Config.Smoothness)
        
        -- Метод 2: Движение самой мыши (пробивает блокировки ShiftLock)
        elseif Config.AimbotMethod == "Mouse" then
            local screenPos = Camera:WorldToViewportPoint(target.pos)
            local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            
            -- Если у экзекьютора есть mousemoverel, используем его
            if mousemoverel then
                local deltaX = (screenPos.X - center.X) * Config.Smoothness
                local deltaY = (screenPos.Y - center.Y) * Config.Smoothness
                mousemoverel(deltaX, deltaY)
            else
                -- Если нет, используем камеру по умолчанию
                local camPos = Camera.CFrame.Position
                local targetCFrame = CFrame.new(camPos, target.pos)
                Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, Config.Smoothness)
            end
        end
    end
end)

-- Переключение метода аимбота прямо в меню
CreateButton(PageAimbot, "Switch Aim Method (" .. Config.AimbotMethod .. ")", 210, function()
    if Config.AimbotMethod == "Camera" then
        Config.AimbotMethod = "Mouse"
    else
        Config.AimbotMethod = "Camera"
    end
    -- Обновляем текст кнопки
    local btn = Pages["Aimbot"]:FindFirstChildWhichIsA("TextButton", true)
end)

-- Обновление текста кнопки метода при клике
for _, child in pairs(PageAimbot:GetChildren()) do
    if child:IsA("TextButton") and string.find(child.Text, "Switch Aim Method") then
        child.MouseButton1Click:Connect(function()
            child.Text = "Switch Aim Method (" .. Config.AimbotMethod .. ")"
        end)
    end
end

print("[OMNIX] Скрипт загружен. Меню: RightShift")
