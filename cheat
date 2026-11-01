-- RUST CLONE CHEAT - FINAL VERSION (С системой конфигов и настройками по умолчанию)
-- Меню открывается/закрывается на ПРАВЫЙ SHIFT (RightShift)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local mouse = player:GetMouse()

-- ================= НАСТРОЙКИ ПО УМОЛЧАНИЮ (С твоего скриншота) =================
local aimbotEnabled = true
local silentAimEnabled = false
local espEnabled = true
local aimPartOption = "Center"
local circleRadius = 80       
local smoothness = 0.50         
local activationKey = Enum.UserInputType.MouseButton1
local menuKey = Enum.KeyCode.RightShift

-- Смещение круга (твои настройки)
local fovOffsetX = 0
local fovOffsetY = -5 

local holdingKey = false
local targetPart = nil
local isMenuOpen = true

local CONFIG_FILE = "RustCheat_Config.json"

-- ================= БЕЗОПАСНОЕ UI =================
local _guiParent
local ok, result = pcall(function() return gethui() end)
if ok and result then _guiParent = result else _guiParent = game:GetService("CoreGui") end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RustCheatUI"
ScreenGui.Parent = _guiParent
ScreenGui.ResetOnSpawn = false

-- УВЕЛИЧЕННОЕ МЕНЮ (добавили место под кнопки конфига)
local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 400, 0, 600) 
Frame.Position = UDim2.new(0.5, -200, 0.5, -300)
Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true

local Title = Instance.new("TextLabel", Frame)
Title.Text = "RUST CHEAT [RightShift]"
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 18

-- ================= FOV КРУГ =================
local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 2
fovCircle.NumSides = 100 
fovCircle.Radius = circleRadius
fovCircle.Color = Color3.fromRGB(0, 255, 255)
fovCircle.Filled = false
fovCircle.Visible = false
fovCircle.Transparency = 0.8

-- ================= ЭЛЕМЕНТЫ МЕНЮ =================
local function createBtn(text, pos, size, callback)
    local btn = Instance.new("TextButton", Frame)
    btn.Size = size
    btn.Position = pos
    btn.Text = text
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 16
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- Ссылки на элементы для обновления UI
local espBtn, aimBtn, silentBtn, partBtn, fovLabel, smoothLabel, offsetLabel, offsetXLabel, bindBtn
local waitingForKey = false

function updateUI()
    if not espBtn then return end
    espBtn.Text = "ESP: " .. (espEnabled and "ON" or "OFF")
    espBtn.BackgroundColor3 = espEnabled and Color3.fromRGB(0, 180, 80) or Color3.fromRGB(50, 50, 50)
    
    aimBtn.Text = "Aimbot: " .. (aimbotEnabled and "ON" or "OFF")
    aimBtn.BackgroundColor3 = aimbotEnabled and Color3.fromRGB(0, 180, 80) or Color3.fromRGB(50, 50, 50)
    
    silentBtn.Text = "Silent: " .. (silentAimEnabled and "ON" or "OFF")
    silentBtn.BackgroundColor3 = silentAimEnabled and Color3.fromRGB(0, 180, 80) or Color3.fromRGB(50, 50, 50)
    
    partBtn.Text = "Aim: " .. aimPartOption
    fovLabel.Text = "FOV: " .. circleRadius
    smoothLabel.Text = "Speed: " .. string.format("%.2f", smoothness)
    offsetLabel.Text = "Offset Y: " .. fovOffsetY
    offsetXLabel.Text = "Offset X: " .. fovOffsetX
    
    if not waitingForKey then
        local keyName = tostring(activationKey):gsub("Enum.UserInputType.", ""):gsub("Enum.KeyCode.", "")
        bindBtn.Text = "Aim Key: " .. keyName
    end
end

-- ================= СИСТЕМА КОНФИГОВ =================
local function saveConfig()
    local config = {
        aimbotEnabled = aimbotEnabled,
        silentAimEnabled = silentAimEnabled,
        espEnabled = espEnabled,
        aimPartOption = aimPartOption,
        circleRadius = circleRadius,
        smoothness = smoothness,
        fovOffsetX = fovOffsetX,
        fovOffsetY = fovOffsetY,
        keyString = tostring(activationKey):gsub("Enum.UserInputType.", ""):gsub("Enum.KeyCode.", ""),
        isKeyUserInputType = tostring(activationKey):find("UserInputType") ~= nil
    }
    
    local success, err = pcall(function()
        writefile(CONFIG_FILE, HttpService:JSONEncode(config))
    end)
    
    if success then
        bindBtn.Text = "Config Saved!"
        wait(1)
        updateUI()
    else
        bindBtn.Text = "Save Error!"
        wait(1)
        updateUI()
    end
end

local function loadConfig()
    if not isfile(CONFIG_FILE) then return end
    
    local success, data = pcall(function()
        return HttpService:JSONDecode(readfile(CONFIG_FILE))
    end)
    
    if success and data then
        aimbotEnabled = data.aimbotEnabled or aimbotEnabled
        silentAimEnabled = data.silentAimEnabled or silentAimEnabled
        espEnabled = data.espEnabled or espEnabled
        aimPartOption = data.aimPartOption or aimPartOption
        circleRadius = data.circleRadius or circleRadius
        smoothness = data.smoothness or smoothness
        fovOffsetX = data.fovOffsetX or fovOffsetX
        fovOffsetY = data.fovOffsetY or fovOffsetY
        
        if data.keyString then
            if data.isKeyUserInputType then
                activationKey = Enum.UserInputType[data.keyString]
            else
                activationKey = Enum.KeyCode[data.keyString]
            end
        end
        
        updateUI()
        
        bindBtn.Text = "Config Loaded!"
        wait(1)
        updateUI()
    end
end

-- Автозагрузка конфига при запуске
loadConfig()
updateUI()

-- ================= СОЗДАНИЕ КНОПОК =================
-- Ряд 1
espBtn = createBtn("ESP: OFF", UDim2.new(0.05, 0, 0.1, 0), UDim2.new(0.45, 0, 0, 40), function() espEnabled = not espEnabled; updateUI() end)
aimBtn = createBtn("Aimbot: OFF", UDim2.new(0.5, 0, 0.1, 0), UDim2.new(0.45, 0, 0, 40), function() aimbotEnabled = not aimbotEnabled; updateUI() end)

-- Ряд 2
silentBtn = createBtn("Silent: OFF", UDim2.new(0.05, 0, 0.2, 0), UDim2.new(0.45, 0, 0, 40), function() silentAimEnabled = not silentAimEnabled; updateUI() end)
partBtn = createBtn("Aim: Center", UDim2.new(0.5, 0, 0.2, 0), UDim2.new(0.45, 0, 0, 40), function()
    aimPartOption = "Center"
    updateUI()
end)

-- Ряд 3: FOV
fovLabel = Instance.new("TextLabel", Frame)
fovLabel.Size = UDim2.new(0.4, 0, 0, 40)
fovLabel.Position = UDim2.new(0.05, 0, 0.3, 0)
fovLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
fovLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
fovLabel.Font = Enum.Font.SourceSansBold
fovLabel.TextSize = 16

createBtn("-", UDim2.new(0.45, 0, 0.3, 0), UDim2.new(0.22, 0, 0, 40), function()
    circleRadius = math.max(30, circleRadius - 10)
    updateUI()
end)
createBtn("+", UDim2.new(0.72, 0, 0.3, 0), UDim2.new(0.22, 0, 0, 40), function()
    circleRadius = math.min(800, circleRadius + 10)
    updateUI()
end)

-- Ряд 4: Speed
smoothLabel = Instance.new("TextLabel", Frame)
smoothLabel.Size = UDim2.new(0.4, 0, 0, 40)
smoothLabel.Position = UDim2.new(0.05, 0, 0.4, 0)
smoothLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
smoothLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
smoothLabel.Font = Enum.Font.SourceSansBold
smoothLabel.TextSize = 16

createBtn("-", UDim2.new(0.45, 0, 0.4, 0), UDim2.new(0.22, 0, 0, 40), function()
    smoothness = math.max(0.05, smoothness - 0.05)
    updateUI()
end)
createBtn("+", UDim2.new(0.72, 0, 0.4, 0), UDim2.new(0.22, 0, 0, 40), function()
    smoothness = math.min(1.0, smoothness + 0.05)
    updateUI()
end)

-- Ряд 5: Смещение Y
offsetLabel = Instance.new("TextLabel", Frame)
offsetLabel.Size = UDim2.new(0.4, 0, 0, 40)
offsetLabel.Position = UDim2.new(0.05, 0, 0.5, 0)
offsetLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
offsetLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
offsetLabel.Font = Enum.Font.SourceSansBold
offsetLabel.TextSize = 16

createBtn("Y -", UDim2.new(0.45, 0, 0.5, 0), UDim2.new(0.22, 0, 0, 40), function()
    fovOffsetY = fovOffsetY - 5
    updateUI()
end)
createBtn("Y +", UDim2.new(0.72, 0, 0.5, 0), UDim2.new(0.22, 0, 0, 40), function()
    fovOffsetY = fovOffsetY + 5
    updateUI()
end)

-- Ряд 6: Смещение X
offsetXLabel = Instance.new("TextLabel", Frame)
offsetXLabel.Size = UDim2.new(0.4, 0, 0, 40)
offsetXLabel.Position = UDim2.new(0.05, 0, 0.6, 0)
offsetXLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
offsetXLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
offsetXLabel.Font = Enum.Font.SourceSansBold
offsetXLabel.TextSize = 16

createBtn("X -", UDim2.new(0.45, 0, 0.6, 0), UDim2.new(0.22, 0, 0, 40), function()
    fovOffsetX = fovOffsetX - 5
    updateUI()
end)
createBtn("X +", UDim2.new(0.72, 0, 0.6, 0), UDim2.new(0.22, 0, 0, 40), function()
    fovOffsetX = fovOffsetX + 5
    updateUI()
end)

-- Бинд
bindBtn = Instance.new("TextButton", Frame)
bindBtn.Size = UDim2.new(0.9, 0, 0, 40)
bindBtn.Position = UDim2.new(0.05, 0, 0.7, 0)
bindBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
bindBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
bindBtn.Font = Enum.Font.SourceSansBold
bindBtn.TextSize = 16

bindBtn.MouseButton1Click:Connect(function()
    waitingForKey = true
    bindBtn.Text = "Press any key..."
    bindBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
end)

-- Кнопки КОНФИГА
createBtn("SAVE CONFIG", UDim2.new(0.05, 0, 0.82, 0), UDim2.new(0.42, 0, 0, 40), saveConfig)
createBtn("LOAD CONFIG", UDim2.new(0.53, 0, 0.82, 0), UDim2.new(0.42, 0, 0, 40), loadConfig)

-- ================= ОБРАБОТКА ВВОДА =================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == menuKey then
        isMenuOpen = not isMenuOpen
        Frame.Visible = isMenuOpen
        return
    end

    if waitingForKey then
        if input.UserInputType == Enum.UserInputType.Keyboard then
            activationKey = input.KeyCode
        else
            activationKey = input.UserInputType
        end
        bindBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        waitingForKey = false
        updateUI()
        return
    end

    if input.UserInputType == activationKey or input.KeyCode == activationKey then
        holdingKey = true
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if input.UserInputType == activationKey or input.KeyCode == activationKey then
        holdingKey = false
    end
end)

-- ================= ESP =================
local espObjects = {}
local function createESP(p)
    local draw = {}
    draw.Box = Drawing.new("Square")
    draw.Box.Thickness = 1
    draw.Box.Color = Color3.fromRGB(255, 50, 50)
    draw.Box.Filled = false
    draw.Name = Drawing.new("Text")
    draw.Name.Size = 14
    draw.Name.Center = true
    draw.Name.Outline = true
    draw.Name.Color = Color3.fromRGB(255, 255, 255)
    draw.Health = Drawing.new("Text")
    draw.Health.Size = 12
    draw.Health.Center = true
    draw.Health.Outline = true
    draw.Health.Color = Color3.fromRGB(0, 255, 0)
    draw.player = p
    return draw
end

local function updateESP()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character and p.Character:FindFirstChild("Humanoid") and p.Character:FindFirstChild("Head") then
            local hum = p.Character.Humanoid
            if hum.Health > 0 then
                if not espObjects[p] then espObjects[p] = createESP(p) end
                local esp = espObjects[p]
                local head = p.Character.Head
                local root = p.Character:FindFirstChild("HumanoidRootPart") or head
                
                local topPos = head.Position + Vector3.new(0, 0.5, 0)
                local bottomPos = root.Position - Vector3.new(0, 2.5, 0)
                
                local headScreen, onScreen = camera:WorldToViewportPoint(topPos)
                local rootScreen = camera:WorldToViewportPoint(bottomPos)
                
                if onScreen then
                    local height = math.abs(headScreen.Y - rootScreen.Y)
                    local width = height * 0.5 
                    esp.Box.Size = Vector2.new(width, height)
                    esp.Box.Position = Vector2.new(headScreen.X - (width / 2), headScreen.Y)
                    esp.Box.Visible = true
                    esp.Name.Text = p.Name
                    esp.Name.Position = Vector2.new(headScreen.X, headScreen.Y - 18)
                    esp.Name.Visible = true
                    esp.Health.Text = "HP: " .. math.floor(hum.Health)
                    esp.Health.Position = Vector2.new(headScreen.X, headScreen.Y + height + 2)
                    esp.Health.Visible = true
                else
                    esp.Box.Visible = false; esp.Name.Visible = false; esp.Health.Visible = false
                end
            else
                if espObjects[p] then
                    espObjects[p].Box:Remove(); espObjects[p].Name:Remove(); espObjects[p].Health:Remove()
                    espObjects[p] = nil
                end
            end
        elseif espObjects[p] then
            espObjects[p].Box:Remove(); espObjects[p].Name:Remove(); espObjects[p].Health:Remove()
            espObjects[p] = nil
        end
    end
end

-- ================= AIMBOT =================
local function getTarget()
    local closestPart = nil
    local shortestDist = circleRadius
    
    local screenCenter = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
    local fovCenter = Vector2.new(screenCenter.X + fovOffsetX, screenCenter.Y + fovOffsetY)
    
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character and p.Character:FindFirstChild("Humanoid") then
            local hum = p.Character.Humanoid
            if hum.Health > 0 then
                local head = p.Character:FindFirstChild("Head")
                local root = p.Character:FindFirstChild("HumanoidRootPart")
                
                if head and root then
                    local targetPos = (head.Position + root.Position) / 2 
                    local screenPos, onScreen = camera:WorldToViewportPoint(targetPos)
                    if onScreen then
                        local dist = (fovCenter - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
                        if dist < shortestDist then
                            shortestDist = dist
                            closestPart = {part = root, pos = targetPos}
                        end
                    end
                end
            end
        end
    end
    return closestPart
end

-- ================= ГЛАВНЫЙ ЦИКЛ =================
RunService.RenderStepped:Connect(function()
    local screenCenter = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
    
    local showFov = aimbotEnabled or silentAimEnabled
    fovCircle.Position = Vector2.new(screenCenter.X + fovOffsetX, screenCenter.Y + fovOffsetY) 
    fovCircle.Radius = circleRadius
    fovCircle.Visible = showFov

    if espEnabled then updateESP() else
        for p, esp in pairs(espObjects) do
            esp.Box:Remove(); esp.Name:Remove(); esp.Health:Remove()
            espObjects[p] = nil
        end
    end

    if aimbotEnabled and holdingKey then
        targetPart = getTarget()
        if targetPart then
            local goalCFrame = CFrame.new(camera.CFrame.Position, targetPart.pos)
            camera.CFrame = camera.CFrame:Lerp(goalCFrame, smoothness)
        end
    end
end)
