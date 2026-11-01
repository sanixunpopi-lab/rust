--[[
    pisunRust v2 - OMNIX FRAMEWORK (V52 - KEY SYSTEM FINAL)
    Меню чита: RightShift
    Panic: END
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ============================================================================
-- KEY CONFIG
-- ============================================================================
local KEY_URL = "https://raw.githubusercontent.com/sanixunpopi-lab/rust/refs/heads/main/keys.json"
local LOCAL_KEY_FILE = "pisunrust_keys.json"

local function GetHWID()
    local ok, hwid = pcall(function() return gethwid() end)
    if ok and hwid and hwid ~= "" then return hwid end
    ok, hwid = pcall(function() return game:GetService("RbxAnalyticsService"):GetClientId() end)
    if ok and hwid then return hwid end
    return "UNKNOWN_HWID"
end

local function ReadLocalKeys()
    if not isfile(LOCAL_KEY_FILE) then return {} end
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(LOCAL_KEY_FILE)) end)
    if ok and data then return data end
    return {}
end

local function WriteLocalKeys(data)
    pcall(function() writefile(LOCAL_KEY_FILE, HttpService:JSONEncode(data)) end)
end

local function FormatTime(seconds)
    if seconds <= 0 then return "0 сек" end
    if seconds < 60 then return math.floor(seconds) .. " сек" end
    if seconds < 3600 then return math.floor(seconds/60) .. " мин" end
    if seconds < 86400 then return math.floor(seconds/3600) .. " ч" end
    return math.floor(seconds/86400) .. " дн"
end

local function ValidateKey(key)
    local hwid = GetHWID()
    local localData = ReadLocalKeys()
    
    if localData[key] then
        local entry = localData[key]
        if entry.hwid and entry.hwid ~= hwid then
            return false, "Ключ привязан к другому ПК"
        end
        if entry.duration and entry.duration ~= -1 then
            local elapsed = os.time() - (entry.first_used or os.time())
            if elapsed > entry.duration then
                return false, "Ключ истек"
            end
            return false, "Ключ уже активирован (осталось: " .. FormatTime(entry.duration - elapsed) .. ")"
        end
        return true, "Ключ активен"
    end
    
    local ok, response = pcall(function() return game:HttpGet(KEY_URL) end)
    if not ok or not response or response == "" then
        return false, "Нет связи с сервером ключей"
    end
    
    local ok2, remoteData = pcall(function() return HttpService:JSONDecode(response) end)
    if not ok2 or not remoteData then
        return false, "Ошибка базы ключей"
    end
    
    if not remoteData[key] then
        return false, "Неверный ключ"
    end
    
    local keyInfo = remoteData[key]
    if keyInfo.used == true then
        return false, "Этот ключ уже использован"
    end
    
    localData[key] = {
        first_used = os.time(),
        hwid = hwid,
        duration = keyInfo.duration or 604800
    }
    WriteLocalKeys(localData)
    
    return true, "Ключ активирован на " .. FormatTime(keyInfo.duration or 604800)
end

-- ============================================================================
-- KEY UI
-- ============================================================================
local function ShowKeyUI(onSuccess)
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "PisunKeySystem"
    ScreenGui.Parent = gethui and gethui() or game:GetService("CoreGui")
    ScreenGui.ResetOnSpawn = false
    
    -- Градиентный фон
    local Background = Instance.new("Frame")
    Background.Size = UDim2.new(1, 0, 1, 0)
    Background.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
    Background.BackgroundTransparency = 0.3
    Background.BorderSizePixel = 0
    Background.Parent = ScreenGui
    
    local BgGradient = Instance.new("UIGradient")
    BgGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 120, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(150, 60, 200)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 120, 255))
    }
    BgGradient.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.95),
        NumberSequenceKeypoint.new(0.5, 0.85),
        NumberSequenceKeypoint.new(1, 0.95)
    }
    BgGradient.Parent = Background
    
    local Main = Instance.new("Frame")
    Main.Size = UDim2.new(0, 440, 0, 380)
    Main.Position = UDim2.new(0.5, -220, 0.5, -190)
    Main.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    Main.BorderSizePixel = 0
    Main.Active = true
    Main.Draggable = true
    Main.Parent = ScreenGui
    
    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 10)
    MainCorner.Parent = Main
    
    local MainStroke = Instance.new("UIStroke")
    MainStroke.Color = Color3.fromRGB(80, 120, 255)
    MainStroke.Thickness = 2
    MainStroke.Transparency = 0.3
    MainStroke.Parent = Main
    
    -- Верхняя полоска
    local TopBar = Instance.new("Frame")
    TopBar.Size = UDim2.new(1, 0, 0, 6)
    TopBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    TopBar.BorderSizePixel = 0
    TopBar.Parent = Main
    
    local TopBarCorner = Instance.new("UICorner")
    TopBarCorner.CornerRadius = UDim.new(0, 10)
    TopBarCorner.Parent = TopBar
    
    local TopBarGradient = Instance.new("UIGradient")
    TopBarGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 120, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 60, 255))
    }
    TopBarGradient.Parent = TopBar
    
    -- Аватарка
    local Avatar = Instance.new("ImageLabel")
    Avatar.Size = UDim2.new(0, 70, 0, 70)
    Avatar.Position = UDim2.new(0.5, -35, 0, 30)
    Avatar.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    Avatar.BorderSizePixel = 0
    Avatar.Image = "rbxthumb://type=Asset&id=0&w=150&h=150"
    Avatar.Parent = Main
    
    local AvatarCorner = Instance.new("UICorner")
    AvatarCorner.CornerRadius = UDim.new(1, 0)
    AvatarCorner.Parent = Avatar
    
    local AvatarStroke = Instance.new("UIStroke")
    AvatarStroke.Color = Color3.fromRGB(80, 120, 255)
    AvatarStroke.Thickness = 3
    AvatarStroke.Parent = Avatar
    
    -- Текст "ЮЗ @deimov"
    local BuyLabel = Instance.new("TextLabel")
    BuyLabel.Size = UDim2.new(1, -40, 0, 30)
    BuyLabel.Position = UDim2.new(0, 20, 0, 108)
    BuyLabel.BackgroundTransparency = 1
    BuyLabel.Text = "ЮЗ @deimov BUY CHEAT"
    BuyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    BuyLabel.Font = Enum.Font.GothamBold
    BuyLabel.TextSize = 18
    BuyLabel.Parent = Main
    
    local BuyGradient = Instance.new("UIGradient")
    BuyGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 200, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 100, 255))
    }
    BuyGradient.Parent = BuyLabel
    
    -- Подсказка
    local Hint = Instance.new("TextLabel")
    Hint.Size = UDim2.new(1, -40, 0, 20)
    Hint.Position = UDim2.new(0, 20, 0, 138)
    Hint.BackgroundTransparency = 1
    Hint.Text = "Введите ваш ключ для активации"
    Hint.TextColor3 = Color3.fromRGB(160, 160, 180)
    Hint.Font = Enum.Font.Gotham
    Hint.TextSize = 13
    Hint.Parent = Main
    
    -- Поле ввода
    local InputBox = Instance.new("Frame")
    InputBox.Size = UDim2.new(1, -40, 0, 50)
    InputBox.Position = UDim2.new(0, 20, 0, 170)
    InputBox.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
    InputBox.BorderSizePixel = 0
    InputBox.Parent = Main
    
    local InputCorner = Instance.new("UICorner")
    InputCorner.CornerRadius = UDim.new(0, 8)
    InputCorner.Parent = InputBox
    
    local InputStroke = Instance.new("UIStroke")
    InputStroke.Color = Color3.fromRGB(60, 60, 85)
    InputStroke.Thickness = 1.5
    InputStroke.Parent = InputBox
    
    local Icon = Instance.new("TextLabel")
    Icon.Size = UDim2.new(0, 40, 1, 0)
    Icon.Position = UDim2.new(0, 5, 0, 0)
    Icon.BackgroundTransparency = 1
    Icon.Text = "🔑"
    Icon.TextSize = 20
    Icon.Parent = InputBox
    
    local TextBox = Instance.new("TextBox")
    TextBox.Size = UDim2.new(1, -55, 1, 0)
    TextBox.Position = UDim2.new(0, 45, 0, 0)
    TextBox.BackgroundTransparency = 1
    TextBox.PlaceholderText = "PISUN-XXXX-XXXX-XXXX"
    TextBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 120)
    TextBox.Text = ""
    TextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    TextBox.Font = Enum.Font.Gotham
    TextBox.TextSize = 16
    TextBox.TextXAlignment = Enum.TextXAlignment.Left
    TextBox.ClearTextOnFocus = false
    TextBox.Parent = InputBox
    
    -- Кнопка ENTER
    local EnterBtn = Instance.new("TextButton")
    EnterBtn.Size = UDim2.new(1, -40, 0, 55)
    EnterBtn.Position = UDim2.new(0, 20, 0, 235)
    EnterBtn.BackgroundColor3 = Color3.fromRGB(80, 120, 255)
    EnterBtn.BorderSizePixel = 0
    EnterBtn.Text = "ENTER"
    EnterBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    EnterBtn.Font = Enum.Font.GothamBold
    EnterBtn.TextSize = 18
    EnterBtn.Parent = Main
    
    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 8)
    BtnCorner.Parent = EnterBtn
    
    local BtnGradient = Instance.new("UIGradient")
    BtnGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 120, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 80, 255))
    }
    BtnGradient.Parent = EnterBtn
    
    local BtnStroke = Instance.new("UIStroke")
    BtnStroke.Color = Color3.fromRGB(120, 160, 255)
    BtnStroke.Thickness = 1.5
    BtnStroke.Transparency = 0.5
    BtnStroke.Parent = EnterBtn
    
    -- Статус
    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Size = UDim2.new(1, -40, 0, 25)
    StatusLabel.Position = UDim2.new(0, 20, 0, 300)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Text = ""
    StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
    StatusLabel.Font = Enum.Font.Gotham
    StatusLabel.TextSize = 13
    StatusLabel.Parent = Main
    
    -- HWID
    local HWIDLabel = Instance.new("TextLabel")
    HWIDLabel.Size = UDim2.new(1, -40, 0, 20)
    HWIDLabel.Position = UDim2.new(0, 20, 0, 330)
    HWIDLabel.BackgroundTransparency = 1
    HWIDLabel.Text = "HWID: " .. GetHWID():sub(1, 20) .. "..."
    HWIDLabel.TextColor3 = Color3.fromRGB(80, 80, 100)
    HWIDLabel.Font = Enum.Font.Gotham
    HWIDLabel.TextSize = 11
    HWIDLabel.TextXAlignment = Enum.TextXAlignment.Left
    HWIDLabel.Parent = Main
    
    -- Анимация появления
    Main.Position = UDim2.new(0.5, -220, 0.6, -190)
    Main.BackgroundTransparency = 1
    TweenService:Create(Main, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -220, 0.5, -190)
    }):Play()
    
    -- Hover эффекты
    EnterBtn.MouseEnter:Connect(function()
        TweenService:Create(EnterBtn, TweenInfo.new(0.2), {Size = UDim2.new(1, -30, 0, 55), Position = UDim2.new(0, 15, 0, 235)}):Play()
    end)
    EnterBtn.MouseLeave:Connect(function()
        TweenService:Create(EnterBtn, TweenInfo.new(0.2), {Size = UDim2.new(1, -40, 0, 55), Position = UDim2.new(0, 20, 0, 235)}):Play()
    end)
    
    local trying = false
    
    local function TryActivate()
        if trying then return end
        trying = true
        
        local key = TextBox.Text:gsub("%s+", "")
        if key == "" then
            StatusLabel.Text = "⚠ Введите ключ"
            StatusLabel.TextColor3 = Color3.fromRGB(255, 180, 0)
            trying = false
            return
        end
        
        StatusLabel.Text = "⏳ Проверка ключа..."
        StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
        EnterBtn.Text = "ПРОВЕРКА..."
        
        task.wait(0.4)
        
        local valid, msg = ValidateKey(key)
        
        if valid then
            StatusLabel.Text = "✅ " .. msg
            StatusLabel.TextColor3 = Color3.fromRGB(50, 255, 50)
            EnterBtn.Text = "ДОСТУП РАЗРЕШЕН"
            EnterBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 80)
            BtnGradient.Color = ColorSequence.new(Color3.fromRGB(0, 200, 100))
            task.wait(1.2)
            
            -- Плавное закрытие
            TweenService:Create(Main, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                Position = UDim2.new(0.5, -220, 0.7, -190),
                BackgroundTransparency = 1
            }):Play()
            task.wait(0.4)
            ScreenGui:Destroy()
            onSuccess()
        else
            StatusLabel.Text = "❌ " .. msg
            StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
            EnterBtn.Text = "ENTER"
            trying = false
            
            -- Тряска
            local origPos = Main.Position
            for i = 1, 3 do
                TweenService:Create(Main, TweenInfo.new(0.05), {Position = origPos + UDim2.new(0, 5, 0, 0)}):Play()
                task.wait(0.05)
                TweenService:Create(Main, TweenInfo.new(0.05), {Position = origPos - UDim2.new(0, 5, 0, 0)}):Play()
                task.wait(0.05)
            end
            TweenService:Create(Main, TweenInfo.new(0.05), {Position = origPos}):Play()
        end
    end
    
    EnterBtn.MouseButton1Click:Connect(TryActivate)
    TextBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then TryActivate() end
    end)
end

-- ============================================================================
-- CHEAT CODE
-- ============================================================================
local function StartCheat()
    local Config = {
        AimbotEnabled = false, AimbotMethod = "Camera", FOV = 150, Smoothness = 0.25,
        VisibleAim = false, Prediction = false, WallshotEnabled = false,
        ESPEnabled = false, ESPMaxDist = 1000, ESPWeapon = false, ESPHealthText = true,
        DamageNumbers = false, ShowDamageLog = false, PlayerChamsEnabled = false, ESPBoxHue = 0,
        ItemESPEnabled = false, ItemESPMaxDist = 300, ItemESPFilter = "", ItemESPColorHue = 120,
        XRayEnabled = false, XRayValue = 50, XRayDistance = 500,
        HeadSizeEnabled = false, HeadSizeValue = 1,
        OptTextures = false, OptParticles = false, OptGraphics = false, UltraShakalMode = false,
        AutoSprint = false, Fullbright = false,
        MenuKey = Enum.KeyCode.RightShift, PanicKey = Enum.KeyCode.End
    }
    
    local Binds = { Aimbot = Enum.UserInputType.MouseButton2, ESP = Enum.KeyCode.E, Sprint = Enum.KeyCode.Z }
    local State = { MenuOpen = true, HoldingKey = false, IsSprinting = false, WaitingForKey = nil, Unloaded = false, FPS = 60, Frames = 0, Time = 0, RainbowHue = 0, LastItemScan = 0 }
    local ESPObjects, ChamsObjects, ItemESPObjects = {}, {}, {}
    local DamagePopups, ActiveNotifications, Connections = {}, {}, {}
    local OriginalTransparencies, OriginalHeadSizes, OriginalProps, OriginalUltraProps = {}, {}, {}, {}
    
    -- ========== WALLSHOT ==========
    task.spawn(function()
        if type(hookfunction) == "function" then
            pcall(function()
                local oldRaycast = workspace.Raycast
                hookfunction(workspace.Raycast, function(self, origin, direction, params)
                    if Config.WallshotEnabled and not State.Unloaded and LocalPlayer.Character then
                        local newParams = RaycastParams.new()
                        newParams.FilterType = Enum.RaycastFilterType.Include
                        newParams.FilterDescendantsInstances = {}
                        for _, p in pairs(Players:GetPlayers()) do
                            if p ~= LocalPlayer and p.Character then table.insert(newParams.FilterDescendantsInstances, p.Character) end
                        end
                        local result = oldRaycast(self, origin, direction, newParams)
                        if result and result.Instance then return result end
                    end
                    return oldRaycast(self, origin, direction, params)
                end)
            end)
        end
    end)
    
    -- ========== FULLBRIGHT ==========
    local function ApplyLighting()
        if State.Unloaded then return end
        if Config.Fullbright then
            Lighting.ClockTime = 12; Lighting.Brightness = 2.5
            Lighting.Ambient = Color3.fromRGB(255, 255, 255); Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
            Lighting.GlobalShadows = false; Lighting.FogEnd = 100000; Lighting.FogStart = 0
            for _, v in pairs(Lighting:GetChildren()) do
                if v:IsA("Atmosphere") then v.Density = 0; v.Haze = 0 elseif v:IsA("Sky") then v.StarCount = 0 end
            end
        else
            Lighting.ClockTime = 14; Lighting.Brightness = 1
            Lighting.Ambient = Color3.fromRGB(70, 70, 70); Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
            Lighting.GlobalShadows = true; Lighting.FogEnd = 1000
        end
    end
    
    -- ========== GREY TEXTURES ==========
    local function GreyObject(obj)
        if not obj or not obj.Parent then return end
        if obj:IsA("BasePart") then
            if not OriginalUltraProps[obj] then OriginalUltraProps[obj] = {Color = obj.Color} end
            obj.Color = Color3.fromRGB(163, 162, 165)
        elseif obj:IsA("Decal") or obj:IsA("Texture") then
            if not OriginalUltraProps[obj] then OriginalUltraProps[obj] = {Transparency = obj.Transparency} end
            obj.Transparency = 1
        elseif obj:IsA("SurfaceAppearance") then
            if not OriginalUltraProps[obj] then OriginalUltraProps[obj] = {Enabled = obj.Enabled} end
            obj.Enabled = false
        end
    end
    local function ApplyGreyTextures()
        if State.Unloaded or not Config.UltraShakalMode then return end
        task.spawn(function()
            for _, obj in pairs(workspace:GetDescendants()) do
                if not Config.UltraShakalMode or State.Unloaded then break end
                GreyObject(obj)
            end
        end)
    end
    local function RestoreGreyTextures()
        for obj, props in pairs(OriginalUltraProps) do
            if obj and obj.Parent then
                pcall(function()
                    if props.Color ~= nil then obj.Color = props.Color end
                    if props.Transparency ~= nil then obj.Transparency = props.Transparency end
                    if props.Enabled ~= nil then obj.Enabled = props.Enabled end
                end)
            end
        end
        OriginalUltraProps = {}
    end
    workspace.DescendantAdded:Connect(function(obj) if Config.UltraShakalMode and not State.Unloaded then GreyObject(obj) end end)
    
    -- ========== ITEM ESP ==========
    local function UpdateItemESP()
        if State.Unloaded then return end
        for item, esp in pairs(ItemESPObjects) do
            if not item or not item.Parent or not Config.ItemESPEnabled then
                esp.Box:Remove(); esp.Text:Remove(); ItemESPObjects[item] = nil
            else
                local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                local itemPart = item:IsA("BasePart") and item or item:FindFirstChildWhichIsA("BasePart")
                if myRoot and itemPart and (itemPart.Position - myRoot.Position).Magnitude > Config.ItemESPMaxDist then
                    esp.Box:Remove(); esp.Text:Remove(); ItemESPObjects[item] = nil
                end
            end
        end
        if not Config.ItemESPEnabled then return end
        for item, esp in pairs(ItemESPObjects) do
            local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if myRoot and esp.Part then
                local screenPos, onScreen = Camera:WorldToViewportPoint(esp.Part.Position)
                if onScreen and screenPos.Z > 0 then
                    local dist = math.floor((esp.Part.Position - myRoot.Position).Magnitude)
                    esp.Box.Size = Vector2.new(10, 10); esp.Box.Position = Vector2.new(screenPos.X - 5, screenPos.Y - 5); esp.Box.Visible = true
                    esp.Text.Text = "[" .. dist .. "m] " .. item.Name; esp.Text.Position = Vector2.new(screenPos.X, screenPos.Y - 20); esp.Text.Visible = true
                else esp.Box.Visible = false; esp.Text.Visible = false end
            end
        end
        if tick() - State.LastItemScan > 0.5 then
            State.LastItemScan = tick()
            local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not myRoot then return end
            local filter = string.lower(Config.ItemESPFilter)
            local itemColor = Color3.fromHSV(Config.ItemESPColorHue / 360, 1, 1)
            for _, obj in pairs(workspace:GetDescendants()) do
                if obj:IsA("Tool") or obj:IsA("Model") then
                    local part = obj:FindFirstChildWhichIsA("BasePart")
                    if part then
                        local dist = (part.Position - myRoot.Position).Magnitude
                        if dist <= Config.ItemESPMaxDist then
                            local objName = string.lower(obj.Name)
                            local isLoot = false
                            if filter ~= "" then if string.find(objName, filter) then isLoot = true end
                            else if string.find(objName, "crate") or string.find(objName, "box") or string.find(objName, "loot") or string.find(objName, "bag") or string.find(objName, "weapon") or string.find(objName, "tool") or obj:IsA("Tool") then isLoot = true end end
                            if isLoot and not ItemESPObjects[obj] then
                                local box = Drawing.new("Square"); box.Thickness = 1; box.Color = itemColor; box.Filled = false; box.Visible = false
                                local text = Drawing.new("Text"); text.Size = 12; text.Center = true; text.Outline = true; text.Color = itemColor; text.Visible = false
                                ItemESPObjects[obj] = {Box = box, Text = text, Part = part}
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- ========== HEAD SIZE ==========
    local function UpdateHeadSize()
        if State.Unloaded then return end
        for head, _ in pairs(OriginalHeadSizes) do if not head or not head.Parent then OriginalHeadSizes[head] = nil end end
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local head = p.Character:FindFirstChild("Head")
                if head and head:IsA("BasePart") then
                    if not OriginalHeadSizes[head] then OriginalHeadSizes[head] = head.Size end
                    if Config.HeadSizeEnabled then
                        local newSize = OriginalHeadSizes[head] * Config.HeadSizeValue
                        if head.Size ~= newSize then pcall(function() head.Size = newSize end) end
                    else if head.Size ~= OriginalHeadSizes[head] then pcall(function() head.Size = OriginalHeadSizes[head] end) end end
                end
            end
        end
    end
    
    -- ========== XRAY ==========
    local function ApplyXRay()
        if State.Unloaded then return end
        if Config.XRayEnabled then
            local targetModifier = 1 - (Config.XRayValue / 100)
            local myPos = Camera.CFrame.Position
            for _, obj in pairs(workspace:GetDescendants()) do
                if obj:IsA("BasePart") then
                    local isCharacter = false
                    local parent = obj.Parent
                    while parent do
                        if parent:IsA("Model") and parent:FindFirstChildOfClass("Humanoid") then isCharacter = true; break end
                        if parent:IsA("Tool") or parent:IsA("Accessory") then isCharacter = true; break end
                        parent = parent.Parent
                    end
                    if not isCharacter then
                        local dist = (obj.Position - myPos).Magnitude
                        if dist <= Config.XRayDistance then
                            if not OriginalTransparencies[obj] then OriginalTransparencies[obj] = obj.LocalTransparencyModifier end
                            pcall(function() obj.LocalTransparencyModifier = targetModifier end)
                        else if OriginalTransparencies[obj] then pcall(function() obj.LocalTransparencyModifier = OriginalTransparencies[obj] end); OriginalTransparencies[obj] = nil end end
                    end
                end
            end
        else
            for obj, origMod in pairs(OriginalTransparencies) do if obj and obj.Parent then pcall(function() obj.LocalTransparencyModifier = origMod end) end end
            OriginalTransparencies = {}
        end
    end
    task.spawn(function() while not State.Unloaded do if Config.XRayEnabled then ApplyXRay() end task.wait(0.5) end end)
    
    -- ========== WEAPON ==========
    local function GetWeaponName(character)
        local tool = character:FindFirstChildOfClass("Tool")
        if tool then return tool.Name end
        local rightHand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
        if rightHand then
            local toolInHand = rightHand:FindFirstChildOfClass("Tool")
            if toolInHand then return toolInHand.Name end
            for _, child in pairs(rightHand:GetChildren()) do
                if child:IsA("Model") or child:IsA("Part") or child:IsA("MeshPart") then
                    local name = string.lower(child.Name)
                    if string.find(name, "gun") or string.find(name, "rifle") or string.find(name, "bow") or string.find(name, "sword") or string.find(name, "pistol") or string.find(name, "shotgun") or string.find(name, "weapon") or string.find(name, "tool") then return child.Name end
                end
            end
        end
        for _, v in pairs(character:GetDescendants()) do if v:IsA("Tool") then return v.Name end end
        return nil
    end
    local function GetShortWeaponName(toolName)
        local mappings = {["Assault Rifle"] = "AR", ["Semi-Automatic Rifle"] = "SAR", ["Bolt Action Rifle"] = "Bolt", ["Custom SMG"] = "SMG", ["Thompson"] = "Tommy", ["Pump Shotgun"] = "Pump", ["Double Barrel Shotgun"] = "DB", ["Hunting Bow"] = "Bow", ["Crossbow"] = "XBow", ["Rocket Launcher"] = "RPG", ["M92 Pistol"] = "Pistol", ["Python"] = "Revolver", ["Salvaged Sword"] = "Sword", ["Rock"] = "Rock", ["Torch"] = "Torch"}
        if mappings[toolName] then return mappings[toolName] end
        local words = {}
        for word in string.gmatch(toolName, "%a+") do table.insert(words, word) end
        if #words > 1 then local abbr = ""; for i = 1, math.min(#words, 3) do abbr = abbr .. string.sub(words[i], 1, 1) end; return string.upper(abbr)
        else if #toolName > 4 then return string.upper(string.sub(toolName, 1, 4)) end; return toolName end
    end
    
    -- ========== UI ==========
    local ScreenGui = Instance.new("ScreenGui"); ScreenGui.Name = "pisunRustUI_v2"; ScreenGui.Parent = gethui and gethui() or game:GetService("CoreGui"); ScreenGui.ResetOnSpawn = false
    
    local TopHUD = Instance.new("Frame"); TopHUD.Size = UDim2.new(0, 220, 0, 85); TopHUD.Position = UDim2.new(0, 20, 0, 20); TopHUD.BackgroundColor3 = Color3.fromRGB(10, 10, 15); TopHUD.BackgroundTransparency = 0.4; TopHUD.BorderSizePixel = 0; TopHUD.Parent = ScreenGui
    local TopHUDCorner = Instance.new("UICorner"); TopHUDCorner.CornerRadius = UDim.new(0, 6); TopHUDCorner.Parent = TopHUD
    local TopHUDStroke = Instance.new("UIStroke"); TopHUDStroke.Color = Color3.fromRGB(50, 50, 65); TopHUDStroke.Thickness = 1; TopHUDStroke.Parent = TopHUD
    local TitleLabel = Instance.new("TextLabel"); TitleLabel.Size = UDim2.new(1, -10, 0, 25); TitleLabel.Position = UDim2.new(0, 5, 0, 5); TitleLabel.BackgroundTransparency = 1; TitleLabel.Text = "pisunRust v2"; TitleLabel.Font = Enum.Font.GothamBlack; TitleLabel.TextSize = 18; TitleLabel.TextXAlignment = Enum.TextXAlignment.Left; TitleLabel.Parent = TopHUD
    local FPSLabel = Instance.new("TextLabel"); FPSLabel.Size = UDim2.new(1, -10, 0, 20); FPSLabel.Position = UDim2.new(0, 5, 0, 25); FPSLabel.BackgroundTransparency = 1; FPSLabel.Text = "FPS: 60"; FPSLabel.Font = Enum.Font.GothamBold; FPSLabel.TextSize = 14; FPSLabel.TextXAlignment = Enum.TextXAlignment.Left; FPSLabel.Parent = TopHUD
    local FeaturesLabel = Instance.new("TextLabel"); FeaturesLabel.Size = UDim2.new(1, -10, 0, 35); FeaturesLabel.Position = UDim2.new(0, 5, 0, 45); FeaturesLabel.BackgroundTransparency = 1; FeaturesLabel.Text = "All Features OFF"; FeaturesLabel.Font = Enum.Font.GothamSemibold; FeaturesLabel.TextSize = 12; FeaturesLabel.TextXAlignment = Enum.TextXAlignment.Left; FeaturesLabel.TextYAlignment = Enum.TextYAlignment.Top; FeaturesLabel.Parent = TopHUD
    
    local Main = Instance.new("Frame"); Main.Size = UDim2.new(0, 520, 0, 520); Main.Position = UDim2.new(0.5, -260, 0.5, -260); Main.BackgroundColor3 = Color3.fromRGB(18, 18, 24); Main.BorderSizePixel = 0; Main.Active = true; Main.Draggable = true; Main.Parent = ScreenGui
    local MainCorner = Instance.new("UICorner"); MainCorner.CornerRadius = UDim.new(0, 8); MainCorner.Parent = Main
    local MainStroke = Instance.new("UIStroke"); MainStroke.Color = Color3.fromRGB(45, 45, 60); MainStroke.Thickness = 2; MainStroke.Parent = Main
    local Header = Instance.new("Frame"); Header.Size = UDim2.new(1, 0, 0, 45); Header.BackgroundColor3 = Color3.fromRGB(25, 25, 35); Header.Parent = Main
    local HeaderCorner = Instance.new("UICorner"); HeaderCorner.CornerRadius = UDim.new(0, 8); HeaderCorner.Parent = Header
    local Title = Instance.new("TextLabel"); Title.Size = UDim2.new(1, -20, 1, 0); Title.Position = UDim2.new(0, 15, 0, 0); Title.BackgroundTransparency = 1; Title.Text = "pisunRust v2 | Menu"; Title.TextColor3 = Color3.fromRGB(230, 230, 250); Title.Font = Enum.Font.GothamBold; Title.TextSize = 16; Title.TextXAlignment = Enum.TextXAlignment.Left; Title.Parent = Header
    
    local TabContainer = Instance.new("ScrollingFrame"); TabContainer.Size = UDim2.new(0, 130, 1, -45); TabContainer.Position = UDim2.new(0, 0, 0, 45); TabContainer.BackgroundColor3 = Color3.fromRGB(22, 22, 30); TabContainer.BorderSizePixel = 0; TabContainer.ScrollBarThickness = 3; TabContainer.ScrollBarImageColor3 = Color3.fromRGB(80, 120, 255); TabContainer.CanvasSize = UDim2.new(0, 0, 0, 0); TabContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y; TabContainer.Parent = Main
    local TabLayout = Instance.new("UIListLayout"); TabLayout.Padding = UDim.new(0, 5); TabLayout.SortOrder = Enum.SortOrder.LayoutOrder; TabLayout.Parent = TabContainer
    local TabPadding = Instance.new("UIPadding"); TabPadding.PaddingTop = UDim.new(0, 5); TabPadding.PaddingLeft = UDim.new(0, 5); TabPadding.PaddingRight = UDim.new(0, 5); TabPadding.Parent = TabContainer
    
    local ContentContainer = Instance.new("Frame"); ContentContainer.Size = UDim2.new(1, -150, 1, -65); ContentContainer.Position = UDim2.new(0, 140, 0, 55); ContentContainer.BackgroundTransparency = 1; ContentContainer.Parent = Main
    local Tabs, Pages = {}, {}
    
    local function CreateTab(name)
        local btn = Instance.new("TextButton"); btn.Size = UDim2.new(1, -10, 0, 35); btn.BackgroundColor3 = Color3.fromRGB(30, 30, 45); btn.Text = "  " .. name; btn.TextColor3 = Color3.fromRGB(180, 180, 200); btn.Font = Enum.Font.GothamSemibold; btn.TextSize = 14; btn.TextXAlignment = Enum.TextXAlignment.Left; btn.Parent = TabContainer
        local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 6); corner.Parent = btn
        local page = Instance.new("ScrollingFrame"); page.Size = UDim2.new(1, 0, 1, 0); page.BackgroundTransparency = 1; page.BorderSizePixel = 0; page.ScrollBarThickness = 4; page.ScrollBarImageColor3 = Color3.fromRGB(80, 120, 255); page.CanvasSize = UDim2.new(0, 0, 0, 0); page.AutomaticCanvasSize = Enum.AutomaticSize.Y; page.Visible = false; page.Parent = ContentContainer
        local pageLayout = Instance.new("UIListLayout"); pageLayout.Padding = UDim.new(0, 5); pageLayout.SortOrder = Enum.SortOrder.LayoutOrder; pageLayout.Parent = page
        local pagePadding = Instance.new("UIPadding"); pagePadding.PaddingTop = UDim.new(0, 5); pagePadding.PaddingRight = UDim.new(0, 10); pagePadding.PaddingBottom = UDim.new(0, 5); pagePadding.Parent = page
        Tabs[name] = btn; Pages[name] = page
        btn.MouseButton1Click:Connect(function()
            for tName, tBtn in pairs(Tabs) do TweenService:Create(tBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(30, 30, 45), TextColor3 = Color3.fromRGB(180, 180, 200)}):Play(); Pages[tName].Visible = false end
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 50, 75), TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
            page.Visible = true; page.Position = UDim2.new(0, 20, 0, 0)
            TweenService:Create(page, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)}):Play()
        end)
        return page
    end
    
    local PageAimbot = CreateTab("Aimbot"); local PageVisuals = CreateTab("Visuals"); local PageOptimizer = CreateTab("Optimizer"); local PageBinds = CreateTab("Binds"); local PageMisc = CreateTab("Misc")
    
    local function CreateToggle(parent, text, default, callback)
        local frame = Instance.new("Frame"); frame.Size = UDim2.new(1, 0, 0, 30); frame.BackgroundTransparency = 1; frame.Parent = parent
        local label = Instance.new("TextLabel"); label.Size = UDim2.new(0.8, 0, 1, 0); label.BackgroundTransparency = 1; label.Text = text; label.TextColor3 = Color3.fromRGB(210, 210, 220); label.Font = Enum.Font.Gotham; label.TextSize = 14; label.TextXAlignment = Enum.TextXAlignment.Left; label.Parent = frame
        local btn = Instance.new("TextButton"); btn.Size = UDim2.new(0, 36, 0, 18); btn.Position = UDim2.new(1, -36, 0.5, -9); btn.BackgroundColor3 = default and Color3.fromRGB(0, 170, 100) or Color3.fromRGB(60, 60, 70); btn.Text = ""; btn.Parent = frame
        local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(1, 0); corner.Parent = btn
        local circle = Instance.new("Frame"); circle.Size = UDim2.new(0, 14, 0, 14); circle.Position = default and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7); circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255); circle.Parent = btn
        local circleCorner = Instance.new("UICorner"); circleCorner.CornerRadius = UDim.new(1, 0); circleCorner.Parent = circle
        local state = default
        btn.MouseButton1Click:Connect(function()
            state = not state
            TweenService:Create(btn, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {BackgroundColor3 = state and Color3.fromRGB(0, 170, 100) or Color3.fromRGB(60, 60, 70)}):Play()
            TweenService:Create(circle, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)}):Play()
            callback(state)
        end)
    end
    
    local function CreateSlider(parent, text, min, max, default, callback)
        local frame = Instance.new("Frame"); frame.Size = UDim2.new(1, 0, 0, 45); frame.BackgroundTransparency = 1; frame.Parent = parent
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
            TweenService:Create(fill, TweenInfo.new(0.1), {Size = UDim2.new(percent, 0, 1, 0)}):Play()
            label.Text = text .. ": " .. val; callback(val)
        end
        bar.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; update(input) end end)
        UserInputService.InputChanged:Connect(function(input) if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then update(input) end end)
        UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
    end
    
    local function CreateButton(parent, text, callback, color)
        local btn = Instance.new("TextButton"); btn.Size = UDim2.new(1, 0, 0, 32); btn.BackgroundColor3 = color or Color3.fromRGB(35, 35, 50); btn.Text = text; btn.TextColor3 = Color3.fromRGB(200, 200, 220); btn.Font = Enum.Font.GothamSemibold; btn.TextSize = 14; btn.Parent = parent
        local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 6); corner.Parent = btn
        btn.MouseButton1Click:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(70, 70, 90)}):Play()
            task.wait(0.1)
            TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = color or Color3.fromRGB(35, 35, 50)}):Play()
            callback()
        end)
        return btn
    end
    
    local function CreateTextBox(parent, placeholder, defaultText, callback)
        local frame = Instance.new("Frame"); frame.Size = UDim2.new(1, 0, 0, 30); frame.BackgroundTransparency = 1; frame.Parent = parent
        local box = Instance.new("TextBox"); box.Size = UDim2.new(1, 0, 1, 0); box.BackgroundColor3 = Color3.fromRGB(35, 35, 50); box.TextColor3 = Color3.fromRGB(255, 255, 255); box.PlaceholderText = placeholder; box.PlaceholderColor3 = Color3.fromRGB(150, 150, 150); box.Text = defaultText; box.Font = Enum.Font.Gotham; box.TextSize = 14; box.Parent = frame
        local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 6); corner.Parent = box
        box.FocusLost:Connect(function() callback(box.Text) end)
    end
    
    -- ========== POPULATE ==========
    CreateToggle(PageAimbot, "Aimbot Enabled", Config.AimbotEnabled, function(v) Config.AimbotEnabled = v end)
    CreateToggle(PageAimbot, "Visible Aim", Config.VisibleAim, function(v) Config.VisibleAim = v end)
    CreateToggle(PageAimbot, "Wallshot (Сквозь стены)", Config.WallshotEnabled, function(v) Config.WallshotEnabled = v end)
    CreateSlider(PageAimbot, "FOV Size", 30, 400, Config.FOV, function(v) Config.FOV = v end)
    CreateSlider(PageAimbot, "Smoothness", 1, 100, Config.Smoothness * 100, function(v) Config.Smoothness = v / 100 end)
    local methodBtn; methodBtn = CreateButton(PageAimbot, "Method: " .. Config.AimbotMethod, function() Config.AimbotMethod = (Config.AimbotMethod == "Camera") and "Mouse" or "Camera"; methodBtn.Text = "Method: " .. Config.AimbotMethod end)
    
    CreateToggle(PageVisuals, "Player ESP Boxes", Config.ESPEnabled, function(v) Config.ESPEnabled = v end)
    CreateToggle(PageVisuals, "ESP Weapon Name", Config.ESPWeapon, function(v) Config.ESPWeapon = v end)
    CreateToggle(PageVisuals, "ESP Health Text", Config.ESPHealthText, function(v) Config.ESPHealthText = v end)
    CreateToggle(PageVisuals, "Player Chams (Green/Red)", Config.PlayerChamsEnabled, function(v) Config.PlayerChamsEnabled = v end)
    CreateSlider(PageVisuals, "ESP Color (Hue)", 0, 360, Config.ESPBoxHue, function(v) Config.ESPBoxHue = v end)
    CreateToggle(PageVisuals, "Item ESP", Config.ItemESPEnabled, function(v) Config.ItemESPEnabled = v end)
    CreateTextBox(PageVisuals, "Фильтр (ak, crate, пусто=все)", Config.ItemESPFilter, function(text) Config.ItemESPFilter = text end)
    CreateSlider(PageVisuals, "Item ESP Distance", 50, 1000, Config.ItemESPMaxDist, function(v) Config.ItemESPMaxDist = v end)
    CreateToggle(PageVisuals, "X-Ray Walls", Config.XRayEnabled, function(v) Config.XRayEnabled = v; ApplyXRay() end)
    CreateSlider(PageVisuals, "Wall Transparency", 0, 100, Config.XRayValue, function(v) Config.XRayValue = v; if Config.XRayEnabled then ApplyXRay() end end)
    CreateToggle(PageVisuals, "Head Expander", Config.HeadSizeEnabled, function(v) Config.HeadSizeEnabled = v; if not v then for head, origSize in pairs(OriginalHeadSizes) do if head and head.Parent then pcall(function() head.Size = origSize end) end end end end)
    CreateSlider(PageVisuals, "Head Size Mult", 1, 5, Config.HeadSizeValue, function(v) Config.HeadSizeValue = v end)
    
    CreateToggle(PageOptimizer, "GREY TEXTURES", Config.UltraShakalMode, function(v) Config.UltraShakalMode = v; if v then ApplyGreyTextures() else RestoreGreyTextures() end end)
    
    CreateToggle(PageMisc, "Auto Sprint", Config.AutoSprint, function(v) Config.AutoSprint = v end)
    CreateToggle(PageMisc, "Fullbright", Config.Fullbright, function(v) Config.Fullbright = v; ApplyLighting() end)
    CreateSlider(PageMisc, "Max ESP Distance", 100, 2000, Config.ESPMaxDist, function(v) Config.ESPMaxDist = v end)
    
    local bindBtns = {}
    local function CreateBindButton(parent, text, bindName)
        local btn = CreateButton(parent, text .. ": " .. tostring(Binds[bindName]):gsub("Enum.UserInputType.", ""):gsub("Enum.KeyCode.", ""), function()
            State.WaitingForKey = bindName; btn.Text = "Нажми клавишу..."; btn.TextColor3 = Color3.fromRGB(255, 100, 100)
        end)
        bindBtns[bindName] = btn
    end
    CreateBindButton(PageBinds, "Aimbot Key", "Aimbot")
    CreateBindButton(PageBinds, "ESP Toggle", "ESP")
    
    Tabs["Aimbot"].BackgroundColor3 = Color3.fromRGB(50, 50, 75); Tabs["Aimbot"].TextColor3 = Color3.fromRGB(255, 255, 255); Pages["Aimbot"].Visible = true
    
    -- ========== UNLOAD ==========
    local function FullCleanup()
        State.Unloaded = true
        for _, conn in pairs(Connections) do pcall(function() conn:Disconnect() end) end
        Connections = {}
        if ScreenGui then pcall(function() ScreenGui:Destroy() end) end
        pcall(function() FOVCircle:Remove() end)
        for p, esp in pairs(ESPObjects) do pcall(function() esp.Box1:Remove(); esp.Box2:Remove(); esp.Box3:Remove(); esp.Box4:Remove(); esp.Name:Remove(); esp.Dist:Remove(); esp.HealthText:Remove(); esp.Weapon:Remove() end) end
        ESPObjects = {}
        for p, chams in pairs(ChamsObjects) do pcall(function() chams:Destroy() end) end
        ChamsObjects = {}
        for item, esp in pairs(ItemESPObjects) do pcall(function() esp.Box:Remove(); esp.Text:Remove() end) end
        ItemESPObjects = {}
        for _, popup in pairs(DamagePopups) do pcall(function() popup.Text:Remove() end) end
        DamagePopups = {}
        for obj, origMod in pairs(OriginalTransparencies) do if obj and obj.Parent then pcall(function() obj.LocalTransparencyModifier = origMod end) end end
        OriginalTransparencies = {}
        for head, origSize in pairs(OriginalHeadSizes) do if head and head.Parent then pcall(function() head.Size = origSize end) end end
        OriginalHeadSizes = {}
        RestoreGreyTextures()
        pcall(function() keyrelease(Enum.KeyCode.LeftShift) end)
        pcall(function() Lighting.ClockTime = 14; Lighting.Brightness = 1; Lighting.Ambient = Color3.fromRGB(70, 70, 70); Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128); Lighting.GlobalShadows = true; Lighting.FogEnd = 1000 end)
    end
    CreateButton(PageMisc, "UNLOAD CHEAT (PANIC)", FullCleanup, Color3.fromRGB(150, 30, 30))
    
    -- ========== ESP ==========
    local FOVCircle = Drawing.new("Circle"); FOVCircle.Thickness = 2; FOVCircle.NumSides = 100; FOVCircle.Radius = Config.FOV; FOVCircle.Color = Color3.fromRGB(80, 120, 255); FOVCircle.Filled = false; FOVCircle.Visible = false
    local function IsVisible(targetChar)
        local myChar = LocalPlayer.Character; local targetPart = targetChar:FindFirstChild("Head") or targetChar:FindFirstChild("HumanoidRootPart")
        if not myChar or not myChar:FindFirstChild("Head") or not targetPart then return false end
        local RayParams = RaycastParams.new(); RayParams.FilterType = Enum.RaycastFilterType.Exclude; RayParams.FilterDescendantsInstances = {myChar, targetChar}
        return workspace:Raycast(Camera.CFrame.Position, targetPart.Position - Camera.CFrame.Position, RayParams) == nil
    end
    local function RemoveESP(p) if ESPObjects[p] then local esp = ESPObjects[p]; pcall(function() esp.Box1:Remove(); esp.Box2:Remove(); esp.Box3:Remove(); esp.Box4:Remove(); esp.Name:Remove(); esp.Dist:Remove(); esp.HealthText:Remove(); esp.Weapon:Remove() end); ESPObjects[p] = nil end end
    local function CreateESP(p)
        RemoveESP(p)
        local esp = {}
        for i=1, 4 do esp["Box"..i] = Drawing.new("Line"); esp["Box"..i].Thickness = 1.5; esp["Box"..i].Visible = false end
        esp.Name = Drawing.new("Text"); esp.Name.Size = 15; esp.Name.Center = true; esp.Name.Outline = true; esp.Name.Font = 2; esp.Name.Color = Color3.fromRGB(255, 255, 255); esp.Name.Visible = false
        esp.Dist = Drawing.new("Text"); esp.Dist.Size = 13; esp.Dist.Center = true; esp.Dist.Outline = true; esp.Dist.Color = Color3.fromRGB(255, 200, 0); esp.Dist.Visible = false
        esp.Weapon = Drawing.new("Text"); esp.Weapon.Size = 14; esp.Weapon.Center = true; esp.Weapon.Outline = true; esp.Weapon.Color = Color3.fromRGB(255, 150, 50); esp.Weapon.Visible = false
        esp.HealthText = Drawing.new("Text"); esp.HealthText.Size = 14; esp.HealthText.Center = true; esp.HealthText.Outline = true; esp.HealthText.Color = Color3.fromRGB(0, 255, 0); esp.HealthText.Visible = false
        ESPObjects[p] = esp
    end
    local function CleanupChams(p) if ChamsObjects[p] then ChamsObjects[p]:Destroy(); ChamsObjects[p] = nil end end
    Players.PlayerRemoving:Connect(function(p) RemoveESP(p); CleanupChams(p); if p.Character and p.Character:FindFirstChild("Head") then OriginalHeadSizes[p.Character.Head] = nil end end)
    for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then CreateESP(p); p.CharacterAdded:Connect(function() CreateESP(p); CleanupChams(p) end) end end
    Players.PlayerAdded:Connect(function(p) if p ~= LocalPlayer then CreateESP(p); p.CharacterAdded:Connect(function() CreateESP(p); CleanupChams(p) end) end end)
    
    local function UpdateESP()
        if State.Unloaded then return end
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("Humanoid") or LocalPlayer.Character.Humanoid.Health <= 0 then
            for _, esp in pairs(ESPObjects) do esp.Box1.Visible = false; esp.Box2.Visible = false; esp.Box3.Visible = false; esp.Box4.Visible = false; esp.Name.Visible = false; esp.Dist.Visible = false; esp.HealthText.Visible = false; esp.Weapon.Visible = false end
            for _, chams in pairs(ChamsObjects) do chams.Enabled = false end
            return
        end
        local espColor = Color3.fromHSV(Config.ESPBoxHue / 360, 1, 1)
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                local char = p.Character
                if char and char:FindFirstChild("Humanoid") and char:FindFirstChild("Head") then
                    local hum = char.Humanoid; local hrp = char:FindFirstChild("HumanoidRootPart"); local head = char:FindFirstChild("Head")
                    if hum.Health > 0 and hrp and head then
                        local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"); local dist = (myRoot and hrp) and math.floor((myRoot.Position - hrp.Position).Magnitude) or 0
                        if dist <= Config.ESPMaxDist then
                            if Config.PlayerChamsEnabled then
                                if not ChamsObjects[p] or ChamsObjects[p].Parent ~= char then CleanupChams(p); local chams = Instance.new("Highlight"); chams.FillTransparency = 0.5; chams.OutlineTransparency = 0; chams.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; chams.Parent = char; ChamsObjects[p] = chams end
                                local chams = ChamsObjects[p]; chams.Enabled = true
                                if tick() - (chams:GetAttribute("LastCheck") or 0) > 0.1 then chams:SetAttribute("LastCheck", tick()); if IsVisible(char) then chams.FillColor = Color3.fromRGB(0, 255, 0); chams.OutlineColor = Color3.fromRGB(0, 255, 0) else chams.FillColor = Color3.fromRGB(255, 0, 0); chams.OutlineColor = Color3.fromRGB(255, 255, 255) end end
                            else CleanupChams(p) end
                            if Config.ESPEnabled then
                                if not ESPObjects[p] then CreateESP(p) end
                                local esp = ESPObjects[p]; local screenHead, onScreen = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0)); local screenRoot = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 2.5, 0))
                                if onScreen and screenHead.Z > 0 then
                                    local height = math.abs(screenHead.Y - screenRoot.Y); local width = height * 0.55; local x, y = screenHead.X - (width / 2), screenHead.Y; local length = width * 0.25
                                    for i=1, 4 do esp["Box"..i].Color = espColor end
                                    esp.Box1.From = Vector2.new(x, y); esp.Box1.To = Vector2.new(x + length, y); esp.Box2.From = Vector2.new(x, y); esp.Box2.To = Vector2.new(x, y + length); esp.Box3.From = Vector2.new(x + width, y + height); esp.Box3.To = Vector2.new(x + width - length, y + height); esp.Box4.From = Vector2.new(x + width, y + height); esp.Box4.To = Vector2.new(x + width, y + height - length)
                                    esp.Box1.Visible = true; esp.Box2.Visible = true; esp.Box3.Visible = true; esp.Box4.Visible = true
                                    esp.Name.Text = p.Name; esp.Name.Position = Vector2.new(screenHead.X, y - 45); esp.Name.Visible = true; esp.Dist.Text = "[" .. dist .. "m]"; esp.Dist.Position = Vector2.new(screenHead.X, y - 30); esp.Dist.Visible = true
                                    if Config.ESPWeapon then local weaponName = GetWeaponName(char); if weaponName then esp.Weapon.Text = "[" .. GetShortWeaponName(weaponName) .. "]"; esp.Weapon.Position = Vector2.new(screenHead.X, y - 15); esp.Weapon.Visible = true else esp.Weapon.Visible = false end else esp.Weapon.Visible = false end
                                    if Config.ESPHealthText then esp.HealthText.Text = "HP: " .. math.floor(hum.Health); esp.HealthText.Position = Vector2.new(screenHead.X, y + height + 5); if hum.Health > 50 then esp.HealthText.Color = Color3.fromRGB(0, 255, 0) elseif hum.Health > 25 then esp.HealthText.Color = Color3.fromRGB(255, 200, 0) else esp.HealthText.Color = Color3.fromRGB(255, 50, 50) end; esp.HealthText.Visible = true else esp.HealthText.Visible = false end
                                else esp.Box1.Visible = false; esp.Box2.Visible = false; esp.Box3.Visible = false; esp.Box4.Visible = false; esp.Name.Visible = false; esp.Dist.Visible = false; esp.HealthText.Visible = false; esp.Weapon.Visible = false end
                            elseif ESPObjects[p] then ESPObjects[p].Box1.Visible = false; ESPObjects[p].Box2.Visible = false; ESPObjects[p].Box3.Visible = false; ESPObjects[p].Box4.Visible = false; ESPObjects[p].Name.Visible = false; ESPObjects[p].Dist.Visible = false; ESPObjects[p].HealthText.Visible = false; ESPObjects[p].Weapon.Visible = false end
                        else if ESPObjects[p] then ESPObjects[p].Box1.Visible = false; ESPObjects[p].Box2.Visible = false; ESPObjects[p].Box3.Visible = false; ESPObjects[p].Box4.Visible = false; ESPObjects[p].Name.Visible = false; ESPObjects[p].Dist.Visible = false; ESPObjects[p].HealthText.Visible = false; ESPObjects[p].Weapon.Visible = false end; CleanupChams(p) end
                    end
                end
            end
        end
    end
    
    -- ========== AIMBOT ==========
    local function GetTarget()
        if State.Unloaded or not Config.AimbotEnabled or not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("Humanoid") or LocalPlayer.Character.Humanoid.Health <= 0 then return nil end
        local closest = nil; local shortestDist = Config.FOV; local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Humanoid") then
                local hum = p.Character.Humanoid; local hrp = p.Character:FindFirstChild("HumanoidRootPart"); local head = p.Character:FindFirstChild("Head")
                if hum.Health > 0 and hrp and head then
                    local targetPos = head.Position; local screenPos, onScreen = Camera:WorldToViewportPoint(targetPos)
                    if onScreen and screenPos.Z > 0 then
                        local dist = (screenCenter - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
                        if dist < shortestDist then
                            if Config.VisibleAim and not IsVisible(p.Character) then continue end
                            shortestDist = dist; local finalPos = targetPos; if Config.Prediction then finalPos = finalPos + (hrp.AssemblyLinearVelocity * 0.15) end
                            closest = { player = p, pos = finalPos }
                        end
                    end
                end
            end
        end
        return closest
    end
    
    -- ========== INPUT ==========
    local menuTweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    table.insert(Connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if State.Unloaded then return end
        if input.KeyCode == Config.PanicKey then FullCleanup(); return end
        if input.KeyCode == Config.MenuKey then
            State.MenuOpen = not State.MenuOpen
            if State.MenuOpen then Main.Visible = true; Main.Position = UDim2.new(0.5, -260, 0.7, -260); TweenService:Create(Main, menuTweenInfo, {Position = UDim2.new(0.5, -260, 0.5, -260)}):Play()
            else local hideTween = TweenService:Create(Main, menuTweenInfo, {Position = UDim2.new(0.5, -260, 0.7, -260)}); hideTween:Play(); hideTween.Completed:Connect(function() if not State.MenuOpen then Main.Visible = false end end) end
            return
        end
        if State.WaitingForKey then
            local keyName = ""
            if input.UserInputType == Enum.UserInputType.Keyboard then Binds[State.WaitingForKey] = input.KeyCode; keyName = tostring(input.KeyCode):gsub("Enum.KeyCode.", "")
            else Binds[State.WaitingForKey] = input.UserInputType; keyName = tostring(input.UserInputType):gsub("Enum.UserInputType.", "") end
            bindBtns[State.WaitingForKey].Text = State.WaitingForKey .. ": " .. keyName; bindBtns[State.WaitingForKey].TextColor3 = Color3.fromRGB(200, 200, 220)
            State.WaitingForKey = nil
            return
        end
        if gameProcessed then return end
        if input.UserInputType == Binds.Aimbot or input.KeyCode == Binds.Aimbot then State.HoldingKey = true
        elseif input.UserInputType == Binds.ESP or input.KeyCode == Binds.ESP then Config.ESPEnabled = not Config.ESPEnabled
        elseif input.UserInputType == Binds.Sprint or input.KeyCode == Binds.Sprint then Config.AutoSprint = not Config.AutoSprint end
    end))
    table.insert(Connections, UserInputService.InputEnded:Connect(function(input, gameProcessed) if State.Unloaded then return end; if input.UserInputType == Binds.Aimbot or input.KeyCode == Binds.Aimbot then State.HoldingKey = false end end))
    table.insert(Connections, RunService.RenderStepped:Connect(function(deltaTime)
        if State.Unloaded then return end
        ApplyLighting()
        if Config.HeadSizeEnabled then pcall(UpdateHeadSize) end
        if Config.ItemESPEnabled then pcall(UpdateItemESP) end
        State.Frames = State.Frames + 1; State.Time = State.Time + deltaTime
        if State.Time >= 1 then State.FPS = math.floor(State.Frames / State.Time); State.Frames = 0; State.Time = 0 end
        State.RainbowHue = (State.RainbowHue + 0.005) % 1; local RainbowColor = Color3.fromHSV(State.RainbowHue, 1, 1)
        TitleLabel.TextColor3 = RainbowColor; FPSLabel.Text = "FPS: " .. State.FPS; FPSLabel.TextColor3 = RainbowColor; FeaturesLabel.TextColor3 = RainbowColor
        FeaturesLabel.Text = string.format("Aimbot: %s | ESP: %s\nGrey: %s | Item: %s", Config.AimbotEnabled and "ON" or "OFF", Config.ESPEnabled and "ON" or "OFF", Config.UltraShakalMode and "ON" or "OFF", Config.ItemESPEnabled and "ON" or "OFF")
        FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2); FOVCircle.Radius = Config.FOV; FOVCircle.Visible = Config.AimbotEnabled and (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") and LocalPlayer.Character.Humanoid.Health > 0)
        if Config.ESPEnabled or Config.PlayerChamsEnabled then pcall(UpdateESP) end
        for i = #DamagePopups, 1, -1 do local popup = DamagePopups[i]; popup.Life = popup.Life - 0.02; popup.CurrentY = popup.CurrentY - 1.5; popup.Text.Position = Vector2.new(popup.Text.Position.X, popup.CurrentY); popup.Text.Transparency = popup.Life; if popup.Life <= 0 then pcall(function() popup.Text:Remove() end); table.remove(DamagePopups, i) end end
        if Config.AutoSprint then if not State.IsSprinting then keypress(Enum.KeyCode.LeftShift); State.IsSprinting = true end else if State.IsSprinting then keyrelease(Enum.KeyCode.LeftShift); State.IsSprinting = false end end
    end))
    table.insert(Connections, RunService.Heartbeat:Connect(function()
        if State.Unloaded or not Config.AimbotEnabled or not State.HoldingKey then return end
        local target = GetTarget()
        if target then
            if Config.AimbotMethod == "Camera" then local camPos = Camera.CFrame.Position; local targetCFrame = CFrame.new(camPos, target.pos); Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, Config.Smoothness)
            elseif Config.AimbotMethod == "Mouse" and mousemoverel then local screenPos = Camera:WorldToViewportPoint(target.pos); local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2); mousemoverel((screenPos.X - center.X) * Config.Smoothness, (screenPos.Y - center.Y) * Config.Smoothness) end
        end
    end))
end

-- ============================================================================
-- START
-- ============================================================================
ShowKeyUI(function()
    StartCheat()
end)
