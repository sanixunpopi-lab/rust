--[[
    pisunRust v3 - BLUE NEON EDITION (V55)
    Menu: RightShift
    Panic: END
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Config = {
    AimbotEnabled = false, AimbotMethod = "Camera", FOV = 150, Smoothness = 0.25,
    VisibleAim = false, Prediction = false, WallshotEnabled = false,
    ESPEnabled = false, ESPMaxDist = 1000, ESPWeapon = false, ESPHealthText = true,
    DamageNumbers = false, ShowDamageLog = false, PlayerChamsEnabled = false,
    ESPBoxColor = Color3.fromRGB(80, 120, 255), -- Blue Neon Default
    ItemESPEnabled = false, ItemESPMaxDist = 300, ItemESPFilter = "", ItemESPColor = Color3.fromRGB(0, 255, 255),
    XRayEnabled = false, XRayValue = 50, XRayDistance = 500,
    HeadSizeEnabled = false, HeadSizeValue = 1,
    OptTextures = false, OptParticles = false, OptGraphics = false, UltraShakalMode = false,
    AutoSprint = false, Fullbright = false,
    MenuKey = Enum.KeyCode.RightShift, PanicKey = Enum.KeyCode.End
}

local Binds = { Aimbot = Enum.UserInputType.MouseButton2, ESP = Enum.KeyCode.E, Sprint = Enum.KeyCode.Z }
local State = { MenuOpen = true, HoldingKey = false, IsSprinting = false, WaitingForKey = nil, Unloaded = false, FPS = 60, Frames = 0, Time = 0, LastItemScan = 0 }
local ESPObjects, ChamsObjects, ItemESPObjects = {}, {}, {}
local DamagePopups, ActiveNotifications, Connections = {}, {}, {}
local OriginalTransparencies, OriginalHeadSizes, OriginalProps, OriginalUltraProps = {}, {}, {}, {}

-- ============================================================================
-- WALLSHOT
-- ============================================================================
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

-- ============================================================================
-- FULLBRIGHT & GREY TEXTURES
-- ============================================================================
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

-- ============================================================================
-- ESP & UTILS
-- ============================================================================
local function GetWeaponName(character)
    local tool = character:FindFirstChildOfClass("Tool")
    if tool then return tool.Name end
    return nil
end
local function GetShortWeaponName(toolName)
    local mappings = {["Assault Rifle"] = "AR", ["Semi-Automatic Rifle"] = "SAR", ["Bolt Action Rifle"] = "Bolt", ["Custom SMG"] = "SMG", ["Thompson"] = "Tommy", ["Pump Shotgun"] = "Pump", ["Double Barrel Shotgun"] = "DB"}
    if mappings[toolName] then return mappings[toolName] end
    return string.sub(toolName, 1, 4)
end

local function IsVisible(targetChar)
    local myChar = LocalPlayer.Character; local targetPart = targetChar:FindFirstChild("Head")
    if not myChar or not myChar:FindFirstChild("Head") or not targetPart then return false end
    local RayParams = RaycastParams.new(); RayParams.FilterType = Enum.RaycastFilterType.Exclude; RayParams.FilterDescendantsInstances = {myChar, targetChar}
    return workspace:Raycast(Camera.CFrame.Position, targetPart.Position - Camera.CFrame.Position, RayParams) == nil
end

local function CreateESP(p)
    if ESPObjects[p] then
        for _, obj in pairs(ESPObjects[p]) do pcall(function() obj:Remove() end) end
    end
    local esp = {}
    for i=1, 4 do esp["Box"..i] = Drawing.new("Line"); esp["Box"..i].Thickness = 1.5; esp["Box"..i].Visible = false end
    esp.Name = Drawing.new("Text"); esp.Name.Size = 14; esp.Name.Center = true; esp.Name.Outline = true; esp.Name.Font = 2; esp.Name.Color = Color3.fromRGB(255, 255, 255); esp.Name.Visible = false
    esp.Dist = Drawing.new("Text"); esp.Dist.Size = 12; esp.Dist.Center = true; esp.Dist.Outline = true; esp.Dist.Color = Color3.fromRGB(200, 200, 200); esp.Dist.Visible = false
    esp.Weapon = Drawing.new("Text"); esp.Weapon.Size = 13; esp.Weapon.Center = true; esp.Weapon.Outline = true; esp.Weapon.Color = Color3.fromRGB(255, 200, 50); esp.Weapon.Visible = false
    esp.HealthText = Drawing.new("Text"); esp.HealthText.Size = 13; esp.HealthText.Center = true; esp.HealthText.Outline = true; esp.HealthText.Color = Color3.fromRGB(0, 255, 0); esp.HealthText.Visible = false
    ESPObjects[p] = esp
end
for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then CreateESP(p) end end
Players.PlayerAdded:Connect(function(p) if p ~= LocalPlayer then CreateESP(p) end end)
Players.PlayerRemoving:Connect(function(p) if ESPObjects[p] then for _, obj in pairs(ESPObjects[p]) do pcall(function() obj:Remove() end) end; ESPObjects[p] = nil end end)

local function UpdateESP()
    if State.Unloaded then return end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and ESPObjects[p] then
            local char = p.Character
            if char and char:FindFirstChild("Humanoid") and char:FindFirstChild("Head") and char.Humanoid.Health > 0 and Config.ESPEnabled then
                local head = char.Head; local hrp = char:FindFirstChild("HumanoidRootPart")
                local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                local dist = (myRoot and hrp) and math.floor((myRoot.Position - hrp.Position).Magnitude) or 0
                
                if dist <= Config.ESPMaxDist then
                    local screenHead, onScreen = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                    local screenRoot = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 2.5, 0))
                    if onScreen and screenHead.Z > 0 then
                        local height = math.abs(screenHead.Y - screenRoot.Y); local width = height * 0.55
                        local x, y = screenHead.X - (width / 2), screenHead.Y; local length = width * 0.25
                        local esp = ESPObjects[p]
                        for i=1, 4 do esp["Box"..i].Color = Config.ESPBoxColor end
                        esp.Box1.From = Vector2.new(x, y); esp.Box1.To = Vector2.new(x + length, y)
                        esp.Box2.From = Vector2.new(x, y); esp.Box2.To = Vector2.new(x, y + length)
                        esp.Box3.From = Vector2.new(x + width, y + height); esp.Box3.To = Vector2.new(x + width - length, y + height)
                        esp.Box4.From = Vector2.new(x + width, y + height); esp.Box4.To = Vector2.new(x + width, y + height - length)
                        esp.Box1.Visible = true; esp.Box2.Visible = true; esp.Box3.Visible = true; esp.Box4.Visible = true
                        
                        esp.Name.Text = p.Name; esp.Name.Position = Vector2.new(screenHead.X, y - 40); esp.Name.Visible = true
                        esp.Dist.Text = "[" .. dist .. "m]"; esp.Dist.Position = Vector2.new(screenHead.X, y - 25); esp.Dist.Visible = true
                        
                        if Config.ESPWeapon then local wName = GetWeaponName(char); if wName then esp.Weapon.Text = "[" .. GetShortWeaponName(wName) .. "]"; esp.Weapon.Position = Vector2.new(screenHead.X, y - 10); esp.Weapon.Visible = true else esp.Weapon.Visible = false end else esp.Weapon.Visible = false end
                        if Config.ESPHealthText then esp.HealthText.Text = "HP: " .. math.floor(char.Humanoid.Health); esp.HealthText.Position = Vector2.new(screenHead.X, y + height + 5); esp.HealthText.Visible = true else esp.HealthText.Visible = false end
                    else
                        for _, v in pairs(esp) do if typeof(v) == "Instance" and v.Remove then v.Visible = false end end
                    end
                else
                    for _, v in pairs(esp) do if typeof(v) == "Instance" and v.Remove then v.Visible = false end end
                end
            elseif ESPObjects[p] then
                for _, v in pairs(ESPObjects[p]) do if typeof(v) == "Instance" and v.Remove then v.Visible = false end end
            end
        end
    end
end

-- ============================================================================
-- AIMBOT TARGET
-- ============================================================================
local function GetTarget()
    if State.Unloaded or not Config.AimbotEnabled then return nil end
    local closest = nil; local shortestDist = Config.FOV; local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
            local head = p.Character:FindFirstChild("Head")
            if head then
                local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen and screenPos.Z > 0 then
                    local dist = (screenCenter - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
                    if dist < shortestDist then
                        if Config.VisibleAim and not IsVisible(p.Character) then continue end
                        shortestDist = dist; local finalPos = head.Position
                        if Config.Prediction then finalPos = finalPos + (p.Character.HumanoidRootPart.AssemblyLinearVelocity * 0.15) end
                        closest = { player = p, pos = finalPos }
                    end
                end
            end
        end
    end
    return closest
end

-- ============================================================================
-- UI CREATION (BLUE NEON EDITION)
-- ============================================================================
local ScreenGui = Instance.new("ScreenGui"); ScreenGui.Name = "pisunRustUI_v3"; ScreenGui.Parent = gethui and gethui() or game:GetService("CoreGui"); ScreenGui.ResetOnSpawn = false

-- HUD
local TopHUD = Instance.new("Frame"); TopHUD.Size = UDim2.new(0, 220, 0, 85); TopHUD.Position = UDim2.new(0, 20, 0, 20); TopHUD.BackgroundColor3 = Color3.fromRGB(15, 15, 20); TopHUD.BackgroundTransparency = 0.3; TopHUD.BorderSizePixel = 0; TopHUD.Parent = ScreenGui
local TopHUDCorner = Instance.new("UICorner"); TopHUDCorner.CornerRadius = UDim.new(0, 6); TopHUDCorner.Parent = TopHUD
local TopHUDStroke = Instance.new("UIStroke"); TopHUDStroke.Color = Color3.fromRGB(80, 120, 255); TopHUDStroke.Thickness = 1.5; TopHUDStroke.Transparency = 0.2; TopHUDStroke.Parent = TopHUD
local TopHUDGrad = Instance.new("UIGradient"); TopHUDGrad.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 120, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 30, 60))}); TopHUDGrad.Rotation = 45; TopHUDGrad.Parent = TopHUDStroke

local TitleLabel = Instance.new("TextLabel"); TitleLabel.Size = UDim2.new(1, -10, 0, 25); TitleLabel.Position = UDim2.new(0, 10, 0, 5); TitleLabel.BackgroundTransparency = 1; TitleLabel.Text = "pisunRust v3"; TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255); TitleLabel.Font = Enum.Font.GothamBlack; TitleLabel.TextSize = 18; TitleLabel.TextXAlignment = Enum.TextXAlignment.Left; TitleLabel.Parent = TopHUD
local FPSLabel = Instance.new("TextLabel"); FPSLabel.Size = UDim2.new(1, -10, 0, 20); FPSLabel.Position = UDim2.new(0, 10, 0, 25); FPSLabel.BackgroundTransparency = 1; FPSLabel.Text = "FPS: 60"; FPSLabel.TextColor3 = Color3.fromRGB(80, 120, 255); FPSLabel.Font = Enum.Font.GothamBold; FPSLabel.TextSize = 14; FPSLabel.TextXAlignment = Enum.TextXAlignment.Left; FPSLabel.Parent = TopHUD
local FeaturesLabel = Instance.new("TextLabel"); FeaturesLabel.Size = UDim2.new(1, -10, 0, 35); FeaturesLabel.Position = UDim2.new(0, 10, 0, 45); FeaturesLabel.BackgroundTransparency = 1; FeaturesLabel.Text = "All Features OFF"; FeaturesLabel.TextColor3 = Color3.fromRGB(200, 200, 220); FeaturesLabel.Font = Enum.Font.GothamSemibold; FeaturesLabel.TextSize = 12; FeaturesLabel.TextXAlignment = Enum.TextXAlignment.Left; FeaturesLabel.TextYAlignment = Enum.TextYAlignment.Top; FeaturesLabel.Parent = TopHUD

-- MAIN WINDOW
local Main = Instance.new("Frame"); Main.Size = UDim2.new(0, 560, 0, 540); Main.Position = UDim2.new(0.5, -280, 0.5, -270); Main.BackgroundColor3 = Color3.fromRGB(12, 12, 16); Main.BackgroundTransparency = 0.1; Main.BorderSizePixel = 0; Main.Active = true; Main.Draggable = true; Main.Parent = ScreenGui
local MainCorner = Instance.new("UICorner"); MainCorner.CornerRadius = UDim.new(0, 8); MainCorner.Parent = Main
local MainStroke = Instance.new("UIStroke"); MainStroke.Color = Color3.fromRGB(80, 120, 255); MainStroke.Thickness = 1.5; MainStroke.Transparency = 0.3; MainStroke.Parent = Main

local Header = Instance.new("Frame"); Header.Size = UDim2.new(1, 0, 0, 45); Header.BackgroundColor3 = Color3.fromRGB(18, 18, 25); Header.BackgroundTransparency = 0.2; Header.Parent = Main
local HeaderCorner = Instance.new("UICorner"); HeaderCorner.CornerRadius = UDim.new(0, 8); HeaderCorner.Parent = Header
local HeaderLine = Instance.new("Frame"); HeaderLine.Size = UDim2.new(1, 0, 0, 1); HeaderLine.Position = UDim2.new(0, 0, 1, -1); HeaderLine.BackgroundColor3 = Color3.fromRGB(80, 120, 255); HeaderLine.BackgroundTransparency = 0.5; HeaderLine.Parent = Header

local Title = Instance.new("TextLabel"); Title.Size = UDim2.new(1, -20, 1, 0); Title.Position = UDim2.new(0, 15, 0, 0); Title.BackgroundTransparency = 1; Title.Text = "pisunRust v3 | Menu"; Title.TextColor3 = Color3.fromRGB(255, 255, 255); Title.Font = Enum.Font.GothamBold; Title.TextSize = 16; Title.TextXAlignment = Enum.TextXAlignment.Left; Title.Parent = Header

-- TABS
local TabContainer = Instance.new("ScrollingFrame"); TabContainer.Size = UDim2.new(0, 140, 1, -45); TabContainer.Position = UDim2.new(0, 0, 0, 45); TabContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 20); TabContainer.BackgroundTransparency = 0.5; TabContainer.BorderSizePixel = 0; TabContainer.ScrollBarThickness = 0; TabContainer.CanvasSize = UDim2.new(0, 0, 0, 0); TabContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y; TabContainer.Parent = Main
local TabLayout = Instance.new("UIListLayout"); TabLayout.Padding = UDim.new(0, 5); TabLayout.SortOrder = Enum.SortOrder.LayoutOrder; TabLayout.Parent = TabContainer
local TabPadding = Instance.new("UIPadding"); TabPadding.PaddingTop = UDim.new(0, 10); TabPadding.PaddingLeft = UDim.new(0, 10); TabPadding.PaddingRight = UDim.new(0, 10); TabPadding.Parent = TabContainer

local ContentContainer = Instance.new("Frame"); ContentContainer.Size = UDim2.new(1, -160, 1, -65); ContentContainer.Position = UDim2.new(0, 150, 0, 55); ContentContainer.BackgroundTransparency = 1; ContentContainer.Parent = Main
local Tabs, Pages = {}, {}

local function CreateTab(name)
    local btn = Instance.new("TextButton"); btn.Size = UDim2.new(1, 0, 0, 35); btn.BackgroundColor3 = Color3.fromRGB(25, 25, 35); btn.Text = "  " .. name; btn.TextColor3 = Color3.fromRGB(150, 150, 170); btn.Font = Enum.Font.GothamBold; btn.TextSize = 14; btn.TextXAlignment = Enum.TextXAlignment.Left; btn.Parent = TabContainer
    local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 6); corner.Parent = btn
    local stroke = Instance.new("UIStroke"); stroke.Color = Color3.fromRGB(80, 120, 255); stroke.Thickness = 1; stroke.Transparency = 1; stroke.Parent = btn
    
    local page = Instance.new("ScrollingFrame"); page.Size = UDim2.new(1, 0, 1, 0); page.BackgroundTransparency = 1; page.BorderSizePixel = 0; page.ScrollBarThickness = 2; page.ScrollBarImageColor3 = Color3.fromRGB(80, 120, 255); page.CanvasSize = UDim2.new(0, 0, 0, 0); page.AutomaticCanvasSize = Enum.AutomaticSize.Y; page.Visible = false; page.Parent = ContentContainer
    local pageLayout = Instance.new("UIListLayout"); pageLayout.Padding = UDim.new(0, 8); pageLayout.SortOrder = Enum.SortOrder.LayoutOrder; pageLayout.Parent = page
    local pagePadding = Instance.new("UIPadding"); pagePadding.PaddingTop = UDim.new(0, 5); pagePadding.PaddingRight = UDim.new(0, 10); pagePadding.Parent = page
    
    Tabs[name] = btn; Pages[name] = page
    btn.MouseButton1Click:Connect(function()
        for tName, tBtn in pairs(Tabs) do 
            TweenService:Create(tBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(25, 25, 35), TextColor3 = Color3.fromRGB(150, 150, 170)}):Play()
            TweenService:Create(tBtn:FindFirstChild("UIStroke"), TweenInfo.new(0.2), {Transparency = 1}):Play()
            Pages[tName].Visible = false 
        end
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(35, 45, 70), TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
        TweenService:Create(stroke, TweenInfo.new(0.2), {Transparency = 0}):Play()
        page.Visible = true
    end)
    return page
end

local PageAimbot = CreateTab("Aimbot")
local PageVisuals = CreateTab("Visuals")
local PageOptimizer = CreateTab("Optimizer")
local PageBinds = CreateTab("Binds")
local PageMisc = CreateTab("Misc")

-- PREVIEW UI
local PreviewFrame = Instance.new("Frame"); PreviewFrame.Size = UDim2.new(1, 0, 0, 180); PreviewFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 28); PreviewFrame.Parent = PageVisuals
local PreviewCorner = Instance.new("UICorner"); PreviewCorner.CornerRadius = UDim.new(0, 6); PreviewCorner.Parent = PreviewFrame
local PreviewStroke = Instance.new("UIStroke"); PreviewStroke.Color = Color3.fromRGB(80, 120, 255); PreviewStroke.Thickness = 1; PreviewStroke.Transparency = 0.5; PreviewStroke.Parent = PreviewFrame
local PreviewText = Instance.new("TextLabel"); PreviewText.Size = UDim2.new(1, 0, 0, 20); PreviewText.Position = UDim2.new(0, 0, 0, 5); PreviewText.BackgroundTransparency = 1; PreviewText.Text = "ESP PREVIEW"; PreviewText.TextColor3 = Color3.fromRGB(80, 120, 255); PreviewText.Font = Enum.Font.GothamBold; PreviewText.TextSize = 12; PreviewText.Parent = PreviewFrame

local PBoxTop = Instance.new("Frame"); PBoxTop.Size = UDim2.new(0, 30, 0, 2); PBoxTop.Position = UDim2.new(0.5, -15, 0.5, -40); PBoxTop.BackgroundColor3 = Config.ESPBoxColor; PBoxTop.Parent = PreviewFrame
local PBoxBottom = Instance.new("Frame"); PBoxBottom.Size = UDim2.new(0, 30, 0, 2); PBoxBottom.Position = UDim2.new(0.5, -15, 0.5, 40); PBoxBottom.BackgroundColor3 = Config.ESPBoxColor; PBoxBottom.Parent = PreviewFrame
local PBoxLeft = Instance.new("Frame"); PBoxLeft.Size = UDim2.new(0, 2, 0, 80); PBoxLeft.Position = UDim2.new(0.5, -15, 0.5, -40); PBoxLeft.BackgroundColor3 = Config.ESPBoxColor; PBoxLeft.Parent = PreviewFrame
local PBoxRight = Instance.new("Frame"); PBoxRight.Size = UDim2.new(0, 2, 0, 80); PBoxRight.Position = UDim2.new(0.5, 13, 0.5, -40); PBoxRight.BackgroundColor3 = Config.ESPBoxColor; PBoxRight.Parent = PreviewFrame
local PName = Instance.new("TextLabel"); PName.Size = UDim2.new(0, 100, 0, 15); PName.Position = UDim2.new(0.5, -50, 0.5, -60); PName.BackgroundTransparency = 1; PName.Text = "PlayerName"; PName.TextColor3 = Color3.fromRGB(255,255,255); PName.Font = Enum.Font.GothamBold; PName.TextSize = 12; PName.Parent = PreviewFrame
local PDist = Instance.new("TextLabel"); PDist.Size = UDim2.new(0, 100, 0, 15); PDist.Position = UDim2.new(0.5, -50, 0.5, -45); PDist.BackgroundTransparency = 1; PDist.Text = "[25m]"; PDist.TextColor3 = Color3.fromRGB(200,200,200); PDist.Font = Enum.Font.Gotham; PDist.TextSize = 11; PDist.Parent = PreviewFrame
local PHealth = Instance.new("TextLabel"); PHealth.Size = UDim2.new(0, 100, 0, 15); PHealth.Position = UDim2.new(0.5, -50, 0.5, 45); PHealth.BackgroundTransparency = 1; PHealth.Text = "HP: 100"; PHealth.TextColor3 = Color3.fromRGB(0,255,0); PHealth.Font = Enum.Font.GothamBold; PHealth.TextSize = 11; PHealth.Parent = PreviewFrame

-- ELEMENTS
local function CreateToggle(parent, text, default, callback)
    local frame = Instance.new("Frame"); frame.Size = UDim2.new(1, 0, 0, 35); frame.BackgroundColor3 = Color3.fromRGB(20, 20, 28); frame.Parent = parent
    local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 6); corner.Parent = frame
    local stroke = Instance.new("UIStroke"); stroke.Color = Color3.fromRGB(40, 40, 55); stroke.Thickness = 1; stroke.Parent = frame
    
    local label = Instance.new("TextLabel"); label.Size = UDim2.new(0.8, 0, 1, 0); label.Position = UDim2.new(0, 10, 0, 0); label.BackgroundTransparency = 1; label.Text = text; label.TextColor3 = Color3.fromRGB(220, 220, 230); label.Font = Enum.Font.GothamSemibold; label.TextSize = 13; label.TextXAlignment = Enum.TextXAlignment.Left; label.Parent = frame
    local btn = Instance.new("TextButton"); btn.Size = UDim2.new(0, 40, 0, 20); btn.Position = UDim2.new(1, -50, 0.5, -10); btn.BackgroundColor3 = default and Color3.fromRGB(80, 120, 255) or Color3.fromRGB(40, 40, 50); btn.Text = ""; btn.Parent = frame
    local btnCorner = Instance.new("UICorner"); btnCorner.CornerRadius = UDim.new(1, 0); btnCorner.Parent = btn
    local circle = Instance.new("Frame"); circle.Size = UDim2.new(0, 16, 0, 16); circle.Position = default and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8); circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255); circle.Parent = btn
    local circleCorner = Instance.new("UICorner"); circleCorner.CornerRadius = UDim.new(1, 0); circleCorner.Parent = circle
    
    local state = default
    btn.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = state and Color3.fromRGB(80, 120, 255) or Color3.fromRGB(40, 40, 50)}):Play()
        TweenService:Create(circle, TweenInfo.new(0.2), {Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)}):Play()
        callback(state)
    end)
end

local function CreateSlider(parent, text, min, max, default, callback)
    local frame = Instance.new("Frame"); frame.Size = UDim2.new(1, 0, 0, 50); frame.BackgroundColor3 = Color3.fromRGB(20, 20, 28); frame.Parent = parent
    local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 6); corner.Parent = frame
    local stroke = Instance.new("UIStroke"); stroke.Color = Color3.fromRGB(40, 40, 55); stroke.Thickness = 1; stroke.Parent = frame
    
    local label = Instance.new("TextLabel"); label.Size = UDim2.new(1, -20, 0, 20); label.Position = UDim2.new(0, 10, 0, 5); label.BackgroundTransparency = 1; label.Text = text .. ": " .. default; label.TextColor3 = Color3.fromRGB(220, 220, 230); label.Font = Enum.Font.GothamSemibold; label.TextSize = 13; label.TextXAlignment = Enum.TextXAlignment.Left; label.Parent = frame
    local bar = Instance.new("Frame"); bar.Size = UDim2.new(1, -20, 0, 6); bar.Position = UDim2.new(0, 10, 0, 30); bar.BackgroundColor3 = Color3.fromRGB(40, 40, 50); bar.Parent = frame
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

local function CreateButton(parent, text, callback)
    local btn = Instance.new("TextButton"); btn.Size = UDim2.new(1, 0, 0, 35); btn.BackgroundColor3 = Color3.fromRGB(25, 35, 55); btn.Text = text; btn.TextColor3 = Color3.fromRGB(200, 220, 255); btn.Font = Enum.Font.GothamBold; btn.TextSize = 13; btn.Parent = parent
    local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 6); corner.Parent = btn
    local stroke = Instance.new("UIStroke"); stroke.Color = Color3.fromRGB(80, 120, 255); stroke.Thickness = 1; stroke.Transparency = 0.5; stroke.Parent = btn
    btn.MouseButton1Click:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(40, 60, 100)}):Play()
        task.wait(0.1)
        TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(25, 35, 55)}):Play()
        callback()
    end)
    return btn
end

local function CreateTextBox(parent, placeholder, defaultText, callback)
    local frame = Instance.new("Frame"); frame.Size = UDim2.new(1, 0, 0, 35); frame.BackgroundColor3 = Color3.fromRGB(20, 20, 28); frame.Parent = parent
    local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 6); corner.Parent = frame
    local stroke = Instance.new("UIStroke"); stroke.Color = Color3.fromRGB(40, 40, 55); stroke.Thickness = 1; stroke.Parent = frame
    
    local box = Instance.new("TextBox"); box.Size = UDim2.new(1, -20, 1, 0); box.Position = UDim2.new(0, 10, 0, 0); box.BackgroundTransparency = 1; box.TextColor3 = Color3.fromRGB(255, 255, 255); box.PlaceholderText = placeholder; box.PlaceholderColor3 = Color3.fromRGB(100, 100, 120); box.Text = defaultText; box.Font = Enum.Font.Gotham; box.TextSize = 13; box.TextXAlignment = Enum.TextXAlignment.Left; box.Parent = frame
    box.FocusLost:Connect(function() callback(box.Text) end)
end

-- FILL UI
CreateToggle(PageAimbot, "Aimbot Enabled", Config.AimbotEnabled, function(v) Config.AimbotEnabled = v end)
CreateToggle(PageAimbot, "Visible Aim", Config.VisibleAim, function(v) Config.VisibleAim = v end)
CreateToggle(PageAimbot, "Wallshot (Through Walls)", Config.WallshotEnabled, function(v) Config.WallshotEnabled = v end)
CreateSlider(PageAimbot, "FOV Size", 30, 400, Config.FOV, function(v) Config.FOV = v end)
CreateSlider(PageAimbot, "Smoothness", 1, 100, Config.Smoothness * 100, function(v) Config.Smoothness = v / 100 end)

CreateToggle(PageVisuals, "Player ESP", Config.ESPEnabled, function(v) Config.ESPEnabled = v end)
CreateToggle(PageVisuals, "ESP Weapon", Config.ESPWeapon, function(v) Config.ESPWeapon = v end)
CreateToggle(PageVisuals, "ESP Health", Config.ESPHealthText, function(v) Config.ESPHealthText = v end)
CreateToggle(PageVisuals, "Player Chams", Config.PlayerChamsEnabled, function(v) Config.PlayerChamsEnabled = v end)
CreateTextBox(PageVisuals, "Item ESP Filter (ak, crate)", Config.ItemESPFilter, function(text) Config.ItemESPFilter = text end)
CreateSlider(PageVisuals, "Item ESP Dist", 50, 1000, Config.ItemESPMaxDist, function(v) Config.ItemESPMaxDist = v end)
CreateToggle(PageVisuals, "Item ESP", Config.ItemESPEnabled, function(v) Config.ItemESPEnabled = v end)
CreateSlider(PageVisuals, "Max ESP Distance", 100, 2000, Config.ESPMaxDist, function(v) Config.ESPMaxDist = v end)

CreateToggle(PageOptimizer, "Grey Textures (FPS Boost)", Config.UltraShakalMode, function(v) Config.UltraShakalMode = v; if v then ApplyGreyTextures() else RestoreGreyTextures() end end)
CreateToggle(PageMisc, "Fullbright", Config.Fullbright, function(v) Config.Fullbright = v; ApplyLighting() end)
CreateToggle(PageMisc, "Auto Sprint", Config.AutoSprint, function(v) Config.AutoSprint = v end)

-- CLEANUP
local function FullCleanup()
    State.Unloaded = true
    for _, conn in pairs(Connections) do pcall(function() conn:Disconnect() end) end
    Connections = {}
    if ScreenGui then pcall(function() ScreenGui:Destroy() end) end
    for p, esp in pairs(ESPObjects) do pcall(function() for _, v in pairs(esp) do v:Remove() end end) end
    ESPObjects = {}
    RestoreGreyTextures()
    pcall(function() Lighting.ClockTime = 14; Lighting.Brightness = 1; Lighting.Ambient = Color3.fromRGB(70, 70, 70); Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128); Lighting.GlobalShadows = true; Lighting.FogEnd = 1000 end)
end
CreateButton(PageMisc, "UNLOAD CHEAT (PANIC)", FullCleanup)

-- INITIAL TAB
if Tabs["Aimbot"] then
    Tabs["Aimbot"].BackgroundColor3 = Color3.fromRGB(35, 45, 70)
    Tabs["Aimbot"].TextColor3 = Color3.fromRGB(255, 255, 255)
    Tabs["Aimbot"]:FindFirstChild("UIStroke").Transparency = 0
    Pages["Aimbot"].Visible = true
end

-- ============================================================================
-- LOOP & INPUT
-- ============================================================================
local FOVCircle = Drawing.new("Circle"); FOVCircle.Thickness = 1.5; FOVCircle.NumSides = 100; FOVCircle.Radius = Config.FOV; FOVCircle.Color = Config.ESPBoxColor; FOVCircle.Filled = false; FOVCircle.Visible = false

table.insert(Connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if State.Unloaded then return end
    if input.KeyCode == Config.PanicKey then FullCleanup(); return end
    if input.KeyCode == Config.MenuKey then
        State.MenuOpen = not State.MenuOpen
        if State.MenuOpen then Main.Visible = true; Main.Position = UDim2.new(0.5, -280, 0.7, -270); TweenService:Create(Main, TweenInfo.new(0.3), {Position = UDim2.new(0.5, -280, 0.5, -270)}):Play()
        else local hideTween = TweenService:Create(Main, TweenInfo.new(0.3), {Position = UDim2.new(0.5, -280, 0.7, -270)}); hideTween:Play(); hideTween.Completed:Connect(function() if not State.MenuOpen then Main.Visible = false end end) end
        return
    end
    if State.WaitingForKey then
        local keyName = ""
        if input.UserInputType == Enum.UserInputType.Keyboard then Binds[State.WaitingForKey] = input.KeyCode; keyName = tostring(input.KeyCode):gsub("Enum.KeyCode.", "")
        else Binds[State.WaitingForKey] = input.UserInputType; keyName = tostring(input.UserInputType):gsub("Enum.UserInputType.", "") end
        State.WaitingForKey = nil
        return
    end
    if gameProcessed then return end
    if input.UserInputType == Binds.Aimbot or input.KeyCode == Binds.Aimbot then State.HoldingKey = true
    elseif input.UserInputType == Binds.ESP or input.KeyCode == Binds.ESP then Config.ESPEnabled = not Config.ESPEnabled
    elseif input.UserInputType == Binds.Sprint or input.KeyCode == Binds.Sprint then Config.AutoSprint = not Config.AutoSprint end
end))

table.insert(Connections, UserInputService.InputEnded:Connect(function(input) if State.Unloaded then return end; if input.UserInputType == Binds.Aimbot or input.KeyCode == Binds.Aimbot then State.HoldingKey = false end end))

table.insert(Connections, RunService.RenderStepped:Connect(function(deltaTime)
    if State.Unloaded then return end
    ApplyLighting()
    State.Frames = State.Frames + 1; State.Time = State.Time + deltaTime
    if State.Time >= 1 then State.FPS = math.floor(State.Frames / State.Time); State.Frames = 0; State.Time = 0 end
    FPSLabel.Text = "FPS: " .. State.FPS
    FeaturesLabel.Text = string.format("Aimbot: %s | ESP: %s\nGrey: %s | Item: %s", Config.AimbotEnabled and "ON" or "OFF", Config.ESPEnabled and "ON" or "OFF", Config.UltraShakalMode and "ON" or "OFF", Config.ItemESPEnabled and "ON" or "OFF")
    
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2); FOVCircle.Radius = Config.FOV; FOVCircle.Visible = Config.AimbotEnabled and (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") and LocalPlayer.Character.Humanoid.Health > 0)
    if Config.ESPEnabled then pcall(UpdateESP) end
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

print("[pisunRust v3] Successfully loaded. Menu: RightShift")
