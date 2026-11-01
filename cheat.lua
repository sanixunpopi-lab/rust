-- RUST CLONE CHEAT - V9 (Рабочий аим через камеру)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- ================= НАСТРОЙКИ =================
local aimbotEnabled = true
local espEnabled = true
local chamsEnabled = true
local autoSprintEnabled = false
local predictionEnabled = false -- ВЫКЛЮЧЕНО: чтобы наводка была точной
local visibleAimEnabled = false 
local circleRadius = 120       
local smoothness = 0.30         
local activationKey = Enum.UserInputType.MouseButton2
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

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 420, 0, 680) 
Frame.Position = UDim2.new(0.5, -210, 0.5, -340)
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
local espBtn, aimBtn, chamsBtn, sprintBtn, predBtn, visAimBtn, fovLabel, smoothLabel, offsetLabel, offsetXLabel, bindBtn
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
    chamsBtn.Text = "Chams: " .. (chamsEnabled and "ON" or "OFF")
    chamsBtn.BackgroundColor3 = chamsEnabled and Color3.fromRGB(0, 180, 80) or Color3.fromRGB(50, 50, 50)
    sprintBtn.Text = "Sprint: " .. (autoSprintEnabled and "ON" or "OFF")
    sprintBtn.BackgroundColor3 = autoSprintEnabled and Color3.fromRGB(0, 180, 80) or Color3.fromRGB(50, 50, 50)
    predBtn.Text = "Prediction: " .. (predictionEnabled and "ON" or "OFF")
    predBtn.BackgroundColor3 = predictionEnabled and Color3.fromRGB(0, 180, 80) or Color3.fromRGB(50, 50, 50)
    visAimBtn.Text = "Vis Aim: " .. (visibleAimEnabled and "ON" or "OFF")
    visAimBtn.BackgroundColor3 = visibleAimEnabled and Color3.fromRGB(0, 180, 80) or Color3.fromRGB(50, 50, 50)
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
        aimbotEnabled = aimbotEnabled, espEnabled = espEnabled, chamsEnabled = chamsEnabled,
        autoSprintEnabled = autoSprintEnabled, predictionEnabled = predictionEnabled,
        visibleAimEnabled = visibleAimEnabled, circleRadius = circleRadius, smoothness = smoothness,
        fovOffsetX = fovOffsetX, fovOffsetY = fovOffsetY,
        keyString = tostring(activationKey):gsub("Enum.UserInputType.", ""):gsub("Enum.KeyCode.", ""),
        isKeyUserInputType = tostring(activationKey):find("UserInputType") ~= nil
    }
    pcall(function() writefile(CONFIG_FILE, HttpService:JSONEncode(config)) end)
    bindBtn.Text = "Saved!"; task.wait(1); updateUI()
end

local function loadConfig()
    if not isfile(CONFIG_FILE) then return end
    local success, data = pcall(function() return HttpService:JSONDecode(readfile(CONFIG_FILE)) end)
    if success and data then
        aimbotEnabled = data.aimbotEnabled ~= nil and data.aimbotEnabled or aimbotEnabled
        espEnabled = data.espEnabled ~= nil and data.espEnabled or espEnabled
        chamsEnabled = data.chamsEnabled ~= nil and data.chamsEnabled or chamsEnabled
        autoSprintEnabled = data.autoSprintEnabled ~= nil and data.autoSprintEnabled or autoSprintEnabled
        predictionEnabled = data.predictionEnabled ~= nil and data.predictionEnabled or predictionEnabled
        visibleAimEnabled = data.visibleAimEnabled ~= nil and data.visibleAimEnabled or visibleAimEnabled
        circleRadius = data.circleRadius or circleRadius
        smoothness = data.smoothness or smoothness
        fovOffsetX = data.fovOffsetX or fovOffsetX
        fovOffsetY = data.fovOffsetY or fovOffsetY
        if data.keyString then
            if data.isKeyUserInputType then activationKey = Enum.UserInputType[data.keyString]
            else activationKey = Enum.KeyCode[data.keyString] end
        end
        updateUI() 
        if bindBtn then bindBtn.Text = "Loaded!"; task.wait(1); updateUI() end
    end
end

-- Создание кнопок
espBtn = createBtn("ESP: OFF", UDim2.new(0.05, 0, 0.08, 0), UDim2.new(0.28, 0, 0, 35), function() espEnabled = not espEnabled; updateUI() end)
aimBtn = createBtn("Aimbot: OFF", UDim2.new(0.36, 0, 0.08, 0), UDim2.new(0.28, 0, 0, 35), function() aimbotEnabled = not aimbotEnabled; updateUI() end)
visAimBtn = createBtn("Vis Aim: OFF", UDim2.new(0.67, 0, 0.08, 0), UDim2.new(0.28, 0, 0, 35), function() visibleAimEnabled = not visibleAimEnabled; updateUI() end)
chamsBtn = createBtn("Chams: OFF", UDim2.new(0.05, 0, 0.16, 0), UDim2.new(0.28, 0, 0, 35), function() chamsEnabled = not chamsEnabled; updateUI() end)
sprintBtn = createBtn("Sprint: OFF", UDim2.new(0.36, 0, 0.16, 0), UDim2.new(0.28, 0, 0, 35), function() autoSprintEnabled = not autoSprintEnabled; updateUI() end)
predBtn = createBtn("Prediction: OFF", UDim2.new(0.67, 0, 0.16, 0), UDim2.new(0.28, 0, 0, 35), function() predictionEnabled = not predictionEnabled; updateUI() end)

fovLabel = Instance.new("TextLabel", Frame); fovLabel.Size = UDim2.new(0.4, 0, 0, 35); fovLabel.Position = UDim2.new(0.05, 0, 0.25, 0); fovLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 35); fovLabel.TextColor3 = Color3.fromRGB(255, 255, 255); fovLabel.Font = Enum.Font.SourceSansBold; fovLabel.TextSize = 15
createBtn("-", UDim2.new(0.45, 0, 0.25, 0), UDim2.new(0.22, 0, 0, 35), function() circleRadius = math.max(30, circleRadius - 10); updateUI() end)
createBtn("+", UDim2.new(0.72, 0, 0.25, 0), UDim2.new(0.22, 0, 0, 35), function() circleRadius = math.min(800, circleRadius + 10); updateUI() end)

smoothLabel = Instance.new("TextLabel", Frame); smoothLabel.Size = UDim2.new(0.4, 0, 0, 35); smoothLabel.Position = UDim2.new(0.05, 0, 0.34, 0); smoothLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 35); smoothLabel.TextColor3 = Color3.fromRGB(255, 255, 255); smoothLabel.Font = Enum.Font.SourceSansBold; smoothLabel.TextSize = 15
createBtn("-", UDim2.new(0.45, 0, 0.34, 0), UDim2.new(0.22, 0, 0, 35), function() smoothness = math.max(0.05, smoothness - 0.05); updateUI() end)
createBtn("+", UDim2.new(0.72, 0, 0.34, 0), UDim2.new(0.22, 0, 0, 35), function() smoothness = math.min(1.0, smoothness + 0.05); updateUI() end)

offsetLabel = Instance.new("TextLabel", Frame); offsetLabel.Size = UDim2.new(0.4, 0, 0, 35); offsetLabel.Position = UDim2.new(0.05, 0, 0.43, 0); offsetLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 35); offsetLabel.TextColor3 = Color3.fromRGB(255, 200, 0); offsetLabel.Font = Enum.Font.SourceSansBold; offsetLabel.TextSize = 15
createBtn("Y -", UDim2.new(0.45, 0, 0.43, 0), UDim2.new(0.22, 0, 0, 35), function() fovOffsetY = fovOffsetY - 5; updateUI() end)
createBtn("Y +", UDim2.new(0.72, 0, 0.43, 0), UDim2.new(0.22, 0, 0, 35), function() fovOffsetY = fovOffsetY + 5; updateUI() end)

offsetXLabel = Instance.new("TextLabel", Frame); offsetXLabel.Size = UDim2.new(0.4, 0, 0, 35); offsetXLabel.Position = UDim2.new(0.05, 0, 0.52, 0); offsetXLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 35); offsetXLabel.TextColor3 = Color3.fromRGB(255, 200, 0); offsetXLabel.Font = Enum.Font.SourceSansBold; offsetXLabel.TextSize = 15
createBtn("X -", UDim2.new(0.45, 0, 0.52, 0), UDim2.new(0.22, 0, 0, 35), function() fovOffsetX = fovOffsetX - 5; updateUI() end)
createBtn("X +", UDim2.new(0.72, 0, 0.52, 0), UDim2.new(0.22, 0, 0, 35), function() fovOffsetX = fovOffsetX + 5; updateUI() end)

bindBtn = Instance.new("TextButton", Frame); bindBtn.Size = UDim2.new(0.9, 0, 0, 35); bindBtn.Position = UDim2.new(0.05, 0, 0.62, 0); bindBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50); bindBtn.TextColor3 = Color3.fromRGB(255, 255, 255); bindBtn.Font = Enum.Font.SourceSansBold; bindBtn.TextSize = 15
bindBtn.MouseButton1Click:Connect(function() waitingForKey = true; bindBtn.Text = "Press any key..."; bindBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50) end)

createBtn("SAVE CONFIG", UDim2.new(0.05, 0, 0.72, 0), UDim2.new(0.42, 0, 0, 35), saveConfig)
createBtn("LOAD CONFIG", UDim2.new(0.53, 0, 0.72, 0), UDim2.new(0.42, 0, 0, 35), loadConfig)

loadConfig()
updateUI()

-- ================= ВВОД =================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == menuKey then isMenuOpen = not isMenuOpen; Frame.Visible = isMenuOpen; return end
    if waitingForKey then
        if input.UserInputType == Enum.UserInputType.Keyboard then activationKey = input.KeyCode else activationKey = input.UserInputType end
        bindBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50); waitingForKey = false; updateUI(); return
    end
    if gameProcessed then return end 
    if input.UserInputType == activationKey or input.KeyCode == activationKey then holdingKey = true end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if input.UserInputType == activationKey or input.KeyCode == activationKey then holdingKey = false end
end)

-- ================= ESP & CHAMS =================
local espObjects = {}
local chamsObjects = {}
local maxESPDistance = 800 

local function isVisible(targetChar)
    local myChar = player.Character
    local targetPart = targetChar:FindFirstChild("Head")
    if not myChar or not myChar:FindFirstChild("Head") or not targetPart then return false end
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = {myChar, targetChar}
    local rayResult = workspace:Raycast(camera.CFrame.Position, targetPart.Position - camera.CFrame.Position, rayParams)
    return rayResult == nil
end

local function createESP(p)
    local esp = {}
    esp.Box = Drawing.new("Square"); esp.Box.Thickness = 1; esp.Box.Color = Color3.fromRGB(255, 50, 50); esp.Box.Filled = false; esp.Box.Visible = false
    esp.Name = Drawing.new("Text"); esp.Name.Size = 14; esp.Name.Center = true; esp.Name.Outline = true; esp.Name.Color = Color3.fromRGB(255, 255, 255); esp.Name.Visible = false
    esp.Health = Drawing.new("Text"); esp.Health.Size = 12; esp.Health.Center = true; esp.Health.Outline = true; esp.Health.Color = Color3.fromRGB(0, 255, 0); esp.Health.Visible = false
    esp.Dist = Drawing.new("Text"); esp.Dist.Size = 12; esp.Dist.Center = true; esp.Dist.Outline = true; esp.Dist.Color = Color3.fromRGB(255, 200, 0); esp.Dist.Visible = false
    return esp
end

local function updateESP()
    for _, p in pairs(Players:GetPlayers()) do
        if p == player or not p.Character or not p.Character:FindFirstChild("Humanoid") or p.Character.Humanoid.Health <= 0 then
            if espObjects[p] then espObjects[p].Box.Visible = false; espObjects[p].Name.Visible = false; espObjects[p].Health.Visible = false; espObjects[p].Dist.Visible = false end
            if chamsObjects[p] then chamsObjects[p]:Destroy(); chamsObjects[p] = nil end
            continue
        end

        local hum = p.Character.Humanoid
        local hrp = p.Character:FindFirstChild("HumanoidRootPart")
        local head = p.Character:FindFirstChild("Head")
        if not hrp or not head then continue end
        
        local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        local distVal = (myRoot and hrp) and math.floor((myRoot.Position - hrp.Position).Magnitude) or 0

        if distVal > maxESPDistance then
            if espObjects[p] then espObjects[p].Box.Visible = false; espObjects[p].Name.Visible = false; espObjects[p].Health.Visible = false; espObjects[p].Dist.Visible = false end
            if chamsObjects[p] then chamsObjects[p]:Destroy(); chamsObjects[p] = nil end
            continue
        end

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
                if isVisible(p.Character) then chams.FillColor = Color3.fromRGB(0, 255, 0); chams.OutlineColor = Color3.fromRGB(0, 255, 0)
                else chams.FillColor = Color3.fromRGB(255, 0, 0); chams.OutlineColor = Color3.fromRGB(255, 255, 255) end
            end
        elseif chamsObjects[p] then chamsObjects[p]:Destroy(); chamsObjects[p] = nil end

        if espEnabled then
            if not espObjects[p] then espObjects[p] = createESP(p) end
            local esp = espObjects[p]
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
            espObjects[p].Box.Visible = false; espObjects[p].Name.Visible = false; espObjects[p].Health.Visible = false; espObjects[p].Dist.Visible = false
        end
    end
end

-- ================= АИМ (ЖЕСТКАЯ КАМЕРА) =================
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
                    if dist < shortestDist then
                        if visibleAimEnabled and not isVisible(p.Character) then continue end
                        shortestDist = dist
                        local finalTargetPos = targetPos
                        if predictionEnabled then finalTargetPos = finalTargetPos + (hrp.AssemblyLinearVelocity * 0.15) end
                        closestPart = {part = hrp, pos = finalTargetPos}
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
    
    fovCircle.Position = Vector2.new(screenCenter.X + fovOffsetX, screenCenter.Y + fovOffsetY) 
    fovCircle.Radius = circleRadius
    fovCircle.Visible = aimbotEnabled

    if espEnabled or chamsEnabled then updateESP() end

    if autoSprintEnabled then
        if not isSprinting then keypress(Enum.KeyCode.LeftShift); isSprinting = true end
    else
        if isSprinting then keyrelease(Enum.KeyCode.LeftShift); isSprinting = false end
    end

    -- ЖЕСТКИЙ АИМ (Прямое изменение CFrame)
    if aimbotEnabled and holdingKey then
        local target = getTarget()
        if target then
            local cameraPos = camera.CFrame.Position
            local targetPos = target.pos
            
            -- Плавно (или резко) поворачиваем камеру
            local newCFrame = CFrame.new(cameraPos, targetPos)
            camera.CFrame = camera.CFrame:Lerp(newCFrame, smoothness)
        end
    end
end)
