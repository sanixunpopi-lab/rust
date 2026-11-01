-- RUST CLONE CHEAT - V7 (Fixed Aimbot + Visible Aim)
-- Меню: ПРАВЫЙ SHIFT (RightShift)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local mouse = player:GetMouse()

-- ================= НАСТРОЙКИ =================
local aimbotEnabled = true
local silentAimEnabled = false
local espEnabled = true
local chamsEnabled = true
local autoSprintEnabled = false
local predictionEnabled = true
local visibleAimEnabled = false -- НОВОЕ: Аим только по видимым
local aimPartOption = "Center"
local circleRadius = 80       
local smoothness = 0.50         
local activationKey = Enum.UserInputType.MouseButton1
local menuKey = Enum.KeyCode.RightShift

local fovOffsetX = 0
local fovOffsetY = -5 

local holdingKey = false
local isMenuOpen = true
local isSprinting = false

local CONFIG_FILE = "RustCheat_Config.json"

-- ================= БЕЗОПАСНОЕ UI =================
local _guiParent = gethui and gethui() or game:GetService("CoreGui")

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RustCheatUI"
ScreenGui.Parent = _guiParent
ScreenGui.ResetOnSpawn = false

-- Меню
local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 420, 0, 700) 
Frame.Position = UDim2.new(0.5, -210, 0.5, -350)
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

-- FOV Круг
local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 2
fovCircle.NumSides = 100 
fovCircle.Radius = circleRadius
fovCircle.Color = Color3.fromRGB(0, 255, 255)
fovCircle.Filled = false
fovCircle.Visible = false
fovCircle.Transparency = 0.8

-- Переменные UI
local espBtn, aimBtn, silentBtn, chamsBtn, sprintBtn, predBtn, visAimBtn, partBtn, fovLabel, smoothLabel, offsetLabel, offsetXLabel, bindBtn
local waitingForKey = false

local function createBtn(text, pos, size, callback)
    local btn = Instance.new("TextButton", Frame)
    btn.Size = size
    btn.Position = pos
    btn.Text = text
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 15
    btn.MouseButton1Click:Connect(callback)
    return btn
end

function updateUI()
    if not espBtn then return end
    espBtn.Text = "ESP: " .. (espEnabled and "ON" or "OFF")
    espBtn.BackgroundColor3 = espEnabled and Color3.fromRGB(0, 180, 80) or Color3.fromRGB(50, 50, 50)
    aimBtn.Text = "Aimbot: " .. (aimbotEnabled and "ON" or "OFF")
    aimBtn.BackgroundColor3 = aimbotEnabled and Color3.fromRGB(0, 180, 80) or Color3.fromRGB(50, 50, 50)
    silentBtn.Text = "Silent: " .. (silentAimEnabled and "ON" or "OFF")
    silentBtn.BackgroundColor3 = silentAimEnabled and Color3.fromRGB(0, 180, 80) or Color3.fromRGB(50, 50, 50)
    chamsBtn.Text = "Chams: " .. (chamsEnabled and "ON" or "OFF")
    chamsBtn.BackgroundColor3 = chamsEnabled and Color3.fromRGB(0, 180, 80) or Color3.fromRGB(50, 50, 50)
    sprintBtn.Text = "Auto Sprint: " .. (autoSprintEnabled and "ON" or "OFF")
    sprintBtn.BackgroundColor3 = autoSprintEnabled and Color3.fromRGB(0, 180, 80) or Color3.fromRGB(50, 50, 50)
    predBtn.Text = "Prediction: " .. (predictionEnabled and "ON" or "OFF")
    predBtn.BackgroundColor3 = predictionEnabled and Color3.fromRGB(0, 180, 80) or Color3.fromRGB(50, 50, 50)
    visAimBtn.Text = "Vis Aim: " .. (visibleAimEnabled and "ON" or "OFF")
    visAimBtn.BackgroundColor3 = visibleAimEnabled and Color3.fromRGB(0, 180, 80) or Color3.fromRGB(50, 50, 50)
    partBtn.Text = "Aim: " .. aimPartOption
    fovLabel.Text = "FOV: " .. circleRadius
    smoothLabel.Text = "Speed: " .. string.format("%.2f", smoothness)
    offsetLabel.Text = "Offset Y: " .. fovOffsetY
    offsetXLabel.Text = "Offset X: " .. fovOffsetX
    if not waitingForKey and bindBtn then
        local keyName = tostring(activationKey):gsub("Enum.UserInputType.", ""):gsub("Enum.KeyCode.", "")
        bindBtn.Text = "Aim Key: " .. keyName
    end
end

-- Конфиги
local function saveConfig()
    if not bindBtn then return end
    local config = {
        aimbotEnabled = aimbotEnabled, silentAimEnabled = silentAimEnabled,
        espEnabled = espEnabled, chamsEnabled = chamsEnabled,
        autoSprintEnabled = autoSprintEnabled, predictionEnabled = predictionEnabled,
        visibleAimEnabled = visibleAimEnabled, aimPartOption = aimPartOption,
        circleRadius = circleRadius, smoothness = smoothness,
        fovOffsetX = fovOffsetX, fovOffsetY = fovOffsetY,
        keyString = tostring(activationKey):gsub("Enum.UserInputType.", ""):gsub("Enum.KeyCode.", ""),
        isKeyUserInputType = tostring(activationKey):find("UserInputType") ~= nil
    }
    local success = pcall(function() writefile(CONFIG_FILE, HttpService:JSONEncode(config)) end)
    bindBtn.Text = success and "Config Saved!" or "Save Error!"
    task.wait(1); updateUI()
end

local function loadConfig()
    if not isfile(CONFIG_FILE) then return end
    local success, data = pcall(function() return HttpService:JSONDecode(readfile(CONFIG_FILE)) end)
    if success and data then
        aimbotEnabled = data.aimbotEnabled ~= nil and data.aimbotEnabled or aimbotEnabled
        silentAimEnabled = data.silentAimEnabled ~= nil and data.silentAimEnabled or silentAimEnabled
        espEnabled = data.espEnabled ~= nil and data.espEnabled or espEnabled
        chamsEnabled = data.chamsEnabled ~= nil and data.chamsEnabled or chamsEnabled
        autoSprintEnabled = data.autoSprintEnabled ~= nil and data.autoSprintEnabled or autoSprintEnabled
        predictionEnabled = data.predictionEnabled ~= nil and data.predictionEnabled or predictionEnabled
        visibleAimEnabled = data.visibleAimEnabled ~= nil and data.visibleAimEnabled or visibleAimEnabled
        aimPartOption = data.aimPartOption or aimPartOption
        circleRadius = data.circleRadius or circleRadius
        smoothness = data.smoothness or smoothness
        fovOffsetX = data.fovOffsetX or fovOffsetX
        fovOffsetY = data.fovOffsetY or fovOffsetY
        if data.keyString then
            if data.isKeyUserInputType then activationKey = Enum.UserInputType[data.keyString]
            else activationKey = Enum.KeyCode[data.keyString] end
        end
        updateUI() 
        if bindBtn then bindBtn.Text = "Config Loaded!"; task.wait(1); updateUI() end
    end
end

-- Создание кнопок
espBtn = createBtn("ESP: OFF", UDim2.new(0.05, 0, 0.08, 0), UDim2.new(0.28, 0, 0, 35), function() espEnabled = not espEnabled; updateUI() end)
aimBtn = createBtn("Aimbot: OFF", UDim2.new(0.36, 0, 0.08, 0), UDim2.new(0.28, 0, 0, 35), function() aimbotEnabled = not aimbotEnabled; updateUI() end)
silentBtn = createBtn("Silent: OFF", UDim2.new(0.67, 0, 0.08, 0), UDim2.new(0.28, 0, 0, 35), function() silentAimEnabled = not silentAimEnabled; updateUI() end)

chamsBtn = createBtn("Chams: OFF", UDim2.new(0.05, 0, 0.16, 0), UDim2.new(0.28, 0, 0, 35), function() chamsEnabled = not chamsEnabled; updateUI() end)
sprintBtn = createBtn("Sprint: OFF", UDim2.new(0.36, 0, 0.16, 0), UDim2.new(0.28, 0, 0, 35), function() autoSprintEnabled = not autoSprintEnabled; updateUI() end)
predBtn = createBtn("Prediction: ON", UDim2.new(0.67, 0, 0.16, 0), UDim2.new(0.28, 0, 0, 35), function() predictionEnabled = not predictionEnabled; updateUI() end)

visAimBtn = createBtn("Vis Aim: OFF", UDim2.new(0.05, 0, 0.24, 0), UDim2.new(0.45, 0, 0, 35), function() visibleAimEnabled = not visibleAimEnabled; updateUI() end)
partBtn = createBtn("Aim: Center", UDim2.new(0.5, 0, 0.24, 0), UDim2.new(0.45, 0, 0, 35), function() aimPartOption = "Center"; updateUI() end)

fovLabel = Instance.new("TextLabel", Frame); fovLabel.Size = UDim2.new(0.4, 0, 0, 35); fovLabel.Position = UDim2.new(0.05, 0, 0.33, 0); fovLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 35); fovLabel.TextColor3 = Color3.fromRGB(255, 255, 255); fovLabel.Font = Enum.Font.SourceSansBold; fovLabel.TextSize = 15
createBtn("-", UDim2.new(0.45, 0, 0.33, 0), UDim2.new(0.22, 0, 0, 35), function() circleRadius = math.max(30, circleRadius - 10); updateUI() end)
createBtn("+", UDim2.new(0.72, 0, 0.33, 0), UDim2.new(0.22, 0, 0, 35), function() circleRadius = math.min(800, circleRadius + 10); updateUI() end)

smoothLabel = Instance.new("TextLabel", Frame); smoothLabel.Size = UDim2.new(0.4, 0, 0, 35); smoothLabel.Position = UDim2.new(0.05, 0, 0.42, 0); smoothLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 35); smoothLabel.TextColor3 = Color3.fromRGB(255, 255, 255); smoothLabel.Font = Enum.Font.SourceSansBold; smoothLabel.TextSize = 15
createBtn("-", UDim2.new(0.45, 0, 0.42, 0), UDim2.new(0.22, 0, 0, 35), function() smoothness = math.max(0.05, smoothness - 0.05); updateUI() end)
createBtn("+", UDim2.new(0.72, 0, 0.42, 0), UDim2.new(0.22, 0, 0, 35), function() smoothness = math.min(1.0, smoothness + 0.05); updateUI() end)

offsetLabel = Instance.new("TextLabel", Frame); offsetLabel.Size = UDim2.new(0.4, 0, 0, 35); offsetLabel.Position = UDim2.new(0.05, 0, 0.51, 0); offsetLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 35); offsetLabel.TextColor3 = Color3.fromRGB(255, 200, 0); offsetLabel.Font = Enum.Font.SourceSansBold; offsetLabel.TextSize = 15
createBtn("Y -", UDim2.new(0.45, 0, 0.51, 0), UDim2.new(0.22, 0, 0, 35), function() fovOffsetY = fovOffsetY - 5; updateUI() end)
createBtn("Y +", UDim2.new(0.72, 0, 0.51, 0), UDim2.new(0.22, 0, 0, 35), function() fovOffsetY = fovOffsetY + 5; updateUI() end)

offsetXLabel = Instance.new("TextLabel", Frame); offsetXLabel.Size = UDim2.new(0.4, 0, 0, 35); offsetXLabel.Position = UDim2.new(0.05, 0, 0.60, 0); offsetXLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 35); offsetXLabel.TextColor3 = Color3.fromRGB(255, 200, 0); offsetXLabel.Font = Enum.Font.SourceSansBold; offsetXLabel.TextSize = 15
createBtn("X -", UDim2.new(0.45, 0, 0.60, 0), UDim2.new(0.22, 0, 0, 35), function() fovOffsetX = fovOffsetX - 5; updateUI() end)
createBtn("X +", UDim2.new(0.72, 0, 0.60, 0), UDim2.new(0.22, 0, 0, 35), function() fovOffsetX = fovOffsetX + 5; updateUI() end)

bindBtn = Instance.new("TextButton", Frame); bindBtn.Size = UDim2.new(0.9, 0, 0, 35); bindBtn.Position = UDim2.new(0.05, 0, 0.69, 0); bindBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50); bindBtn.TextColor3 = Color3.fromRGB(255, 255, 255); bindBtn.Font = Enum.Font.SourceSansBold; bindBtn.TextSize = 15
bindBtn.MouseButton1Click:Connect(function() waitingForKey = true; bindBtn.Text = "Press any key..."; bindBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50) end)

createBtn("SAVE CONFIG", UDim2.new(0.05, 0, 0.78, 0), UDim2.new(0.42, 0, 0, 35), saveConfig)
createBtn("LOAD CONFIG", UDim2.new(0.53, 0, 0.78, 0), UDim2.new(0.42, 0, 0, 35), loadConfig)

loadConfig()
updateUI()

-- ================= ИСПРАВЛЕННЫЙ ВВОД (Не сбивает аим при кликах по меню) =================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    -- Меню работает даже если игра перехватывает ввод
    if input.KeyCode == menuKey then 
        isMenuOpen = not isMenuOpen; Frame.Visible = isMenuOpen; return 
    end

    -- Если мы вводим бинд
    if waitingForKey then
        if input.UserInputType == Enum.UserInputType.Keyboard then activationKey = input.KeyCode else activationKey = input.UserInputType end
        bindBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50); waitingForKey = false; updateUI(); return
    end

    -- ИГНОРИРУЕМ КЛИКИ ПО МЕНЮ (gameProcessed == true)
    if gameProcessed then return end 

    if input.UserInputType == activationKey or input.KeyCode == activationKey then 
        holdingKey = true 
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if input.UserInputType == activationKey or input.KeyCode == activationKey then 
        holdingKey = false 
    end
end)

-- ================= ESP & CHAMS =================
local espObjects = {}
local chamsObjects = {}
local maxESPDistance = 600 

local function isVisible(targetChar)
    local myChar = player.Character
    local targetPart = targetChar:FindFirstChild("Head") or targetChar:FindFirstChild("HumanoidRootPart")
    if not myChar or not myChar:FindFirstChild("Head") or not targetPart then return false end

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = {myChar, targetChar}

    local rayResult = workspace:Raycast(camera.CFrame.Position, targetPart.Position - camera.CFrame.Position, rayParams)
    return rayResult == nil
end

local function createESP(p)
    local draw = {Box = Drawing.new("Square"), Name = Drawing.new("Text"), Health = Drawing.new("Text"), Dist = Drawing.new("Text")}
    draw.Box.Thickness = 1; draw.Box.Color = Color3.fromRGB(255, 50, 50); draw.Box.Filled = false
    draw.Name.Size = 14; draw.Name.Center = true; draw.Name.Outline = true; draw.Name.Color = Color3.fromRGB(255, 255, 255)
    draw.Health.Size = 12; draw.Health.Center = true; draw.Health.Outline = true; draw.Health.Color = Color3.fromRGB(0, 255, 0)
    draw.Dist.Size = 12; draw.Dist.Center = true; draw.Dist.Outline = true; draw.Dist.Color = Color3.fromRGB(255, 200, 0)
    return draw
end

local function updateESP()
    -- Очистка мертвых
    for p, esp in pairs(espObjects) do
        if not p.Parent or not p.Character or not p.Character:FindFirstChild("Humanoid") or p.Character.Humanoid.Health <= 0 then
            esp.Box:Remove(); esp.Name:Remove(); esp.Health:Remove(); esp.Dist:Remove(); espObjects[p] = nil
        end
    end
    for p, chams in pairs(chamsObjects) do
        if not p.Parent or not p.Character then chams:Destroy(); chamsObjects[p] = nil end
    end

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character and p.Character:FindFirstChild("Humanoid") and p.Character:FindFirstChild("Head") then
            local hum = p.Character.Humanoid
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            
            if hum.Health > 0 and hrp then
                local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                local distVal = (myRoot and hrp) and math.floor((myRoot.Position - hrp.Position).Magnitude) or 0
                
                if distVal <= maxESPDistance then
                    -- Chams
                    if chamsEnabled then
                        if not chamsObjects[p] or chamsObjects[p].Parent ~= p.Character then
                            if chamsObjects[p] then chamsObjects[p]:Destroy() end
                            local chams = Instance.new("Highlight")
                            chams.FillTransparency = 0.5; chams.OutlineTransparency = 0; chams.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; chams.Parent = p.Character
                            chams:SetAttribute("LastCheck", 0); chamsObjects[p] = chams
                        end
                        
                        local chams = chamsObjects[p]
                        if tick() - chams:GetAttribute("LastCheck") > 0.1 then
                            chams:SetAttribute("LastCheck", tick())
                            if isVisible(p.Character) then
                                chams.FillColor = Color3.fromRGB(0, 255, 0); chams.OutlineColor = Color3.fromRGB(0, 255, 0)
                            else
                                chams.FillColor = Color3.fromRGB(255, 0, 0); chams.OutlineColor = Color3.fromRGB(255, 255, 255)
                            end
                        end
                    elseif chamsObjects[p] then chamsObjects[p]:Destroy(); chamsObjects[p] = nil end

                    -- ESP
                    if espEnabled then
                        if not espObjects[p] then espObjects[p] = createESP(p) end
                        local esp = espObjects[p]
                        local head = p.Character.Head
                        
                        local headScreen, onScreen = camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                        local rootScreen = camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 2.5, 0))
                        
                        if onScreen then
                            local height = math.abs(headScreen.Y - rootScreen.Y)
                            local width = height * 0.5 
                            esp.Box.Size = Vector2.new(width, height); esp.Box.Position = Vector2.new(headScreen.X - (width / 2), headScreen.Y); esp.Box.Visible = true
                            esp.Name.Text = p.Name; esp.Name.Position = Vector2.new(headScreen.X, headScreen.Y - 32); esp.Name.Visible = true
                            esp.Health.Text = "HP: " .. math.floor(hum.Health); esp.Health.Position = Vector2.new(headScreen.X, headScreen.Y + height + 2); esp.Health.Visible = true
                            esp.Dist.Text = "[" .. distVal .. "m]"; esp.Dist.Position = Vector2.new(headScreen.X, headScreen.Y - 18); esp.Dist.Visible = true
                        else
                            esp.Box.Visible = false; esp.Name.Visible = false; esp.Health.Visible = false; esp.Dist.Visible = false
                        end
                    elseif espObjects[p] then
                        espObjects[p].Box:Remove(); espObjects[p].Name:Remove(); espObjects[p].Health:Remove(); espObjects[p].Dist:Remove(); espObjects[p] = nil
                    end
                end
            end
        end
    end
end

-- ================= AIMBOT (С проверкой на Vis Aim) =================
local function getTarget()
    local closestPart = nil
    local shortestDist = circleRadius
    local screenCenter = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
    local fovCenter = Vector2.new(screenCenter.X + fovOffsetX, screenCenter.Y + fovOffsetY)
    
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character and p.Character:FindFirstChild("Humanoid") then
            local hum = p.Character.Humanoid
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            local head = p.Character:FindFirstChild("Head")
            
            if hum.Health > 0 and hrp and head then
                local targetPos = (head.Position + hrp.Position) / 2 
                local screenPos, onScreen = camera:WorldToViewportPoint(targetPos)
                
                if onScreen then
                    local dist = (fovCenter - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
                    
                    -- Проверяем, в круге ли враг
                    if dist < shortestDist then
                        -- Если включен Visible Aim, проверяем стену
                        if visibleAimEnabled and not isVisible(p.Character) then
                            -- Враг за стеной и Vis Aim включен -> пропускаем
                            continue 
                        end
                        
                        shortestDist = dist
                        local finalTargetPos = targetPos
                        if predictionEnabled then
                            finalTargetPos = finalTargetPos + (hrp.AssemblyLinearVelocity * 0.15)
                        end
                        closestPart = {part = hrp, pos = finalTargetPos}
                    end
                end
            end
        end
    end
    return closestPart
end

-- ================= ГЛАВНЫЙ ЦИКЛ (FIX: Двигаем мышку и камеру) =================
RunService.RenderStepped:Connect(function()
    local screenCenter = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
    
    local showFov = aimbotEnabled or silentAimEnabled
    fovCircle.Position = Vector2.new(screenCenter.X + fovOffsetX, screenCenter.Y + fovOffsetY) 
    fovCircle.Radius = circleRadius
    fovCircle.Visible = showFov

    if espEnabled or chamsEnabled then updateESP() end

    if autoSprintEnabled then
        if not isSprinting then keypress(Enum.KeyCode.LeftShift); isSprinting = true end
    else
        if isSprinting then keyrelease(Enum.KeyCode.LeftShift); isSprinting = false end
    end

    if aimbotEnabled and holdingKey then
        local target = getTarget()
        if target then
            local targetScreenPos = camera:WorldToViewportPoint(target.pos)
            
            -- Сначала пробуем двигать камеру (работает в большинстве игр)
            local goalCFrame = CFrame.new(camera.CFrame.Position, target.pos)
            camera.CFrame = camera.CFrame:Lerp(goalCFrame, smoothness)
            
            -- ДОПОЛНИТЕЛЬНО: Двигаем саму мышку (пробивает блокировки камеры в Rust-клонах)
            local center = Vector2.new(screenCenter.X + fovOffsetX, screenCenter.Y + fovOffsetY)
            mousemoverel((targetScreenPos.X - center.X) * smoothness * 0.5, (targetScreenPos.Y - center.Y) * smoothness * 0.5)
        end
    end
end)
