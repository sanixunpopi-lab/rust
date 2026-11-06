--[[
    Hook Fust - OMNIX FRAMEWORK (V108 - Fixed & Expanded)
    Меню: RightShift
    Panic: END
]]

-- Безопасная загрузка WindUI
local WindUI
local success, err = pcall(function()
    WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
end)

if not success or not WindUI then
    WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
end

if not WindUI then
    warn("[Hook Fust] Ошибка: Не удалось загрузить WindUI. Проверь интернет.")
    return
end

local cloneref = (cloneref or clonereference or function(instance) return instance end)
local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local TweenService = cloneref(game:GetService("TweenService"))
local Lighting = cloneref(game:GetService("Lighting"))
local HttpService = cloneref(game:GetService("HttpService"))

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ============================================================================
-- НАСТРОЙКИ И ПАПКА КОНФИГОВ
-- ============================================================================
local CONFIG_FOLDER = "HookFust_Configs"
if not isfolder(CONFIG_FOLDER) then
    pcall(function() makefolder(CONFIG_FOLDER) end)
end

local Config = {
    AimbotEnabled = false, AimbotMethod = "Camera", FOV = 150, Smoothness = 0.25,
    Prediction = true, VisibleAim = false,
    ESPEnabled = false, ESPMaxDist = 1000, ESPWeapon = false, ESPHealthText = true,
    ESPColor = Color3.fromRGB(80, 120, 255), 
    ChamsEnabled = false,
    ItemESPEnabled = false, ItemESPMaxDist = 300, ItemESPFilter = "",
    DroneESPEnabled = false, XRayEnabled = false, XRayValue = 50, XRayDistance = 500,
    HeadSizeEnabled = false, HeadSizeValue = 1, 
    Fullbright = false, PotatoGraphics = false, RemoveGrass = false, AntiShader = false,
    ShowDeathMarkers = true, 
    CrosshairEnabled = false, CrosshairType = 1,
    HUDEnabled = true,
    PanicKey = Enum.KeyCode.End
}

local Binds = { Aimbot = Enum.UserInputType.MouseButton2, Prediction = Enum.KeyCode.P, AddFriend = Enum.KeyCode.F }
local State = { HoldingKey = false, Unloaded = false, FPS = 60, Frames = 0, Time = 0 }
local ESPObjects, ChamsObjects, ItemESPObjects, DroneESPObjects = {}, {}, {}, {}
local OriginalTransparencies, OriginalHeadSizes, OriginalUltraProps = {}, {}, {}
local OriginalAntiShaderProps = {}
local OriginalTerrainColors = {}
local Friends, DeathMarkers, Connections = {}, {}, {}
local currentConfigName = "default"

-- ============================================================================
-- СИСТЕМА КОНФИГОВ (JSON)
-- ============================================================================
local function SerializeValue(v)
    local t = typeof(v)
    if t == "Color3" then return {__type = "Color3", r = v.R, g = v.G, b = v.B}
    elseif t == "EnumItem" then return {__type = "EnumItem", enumType = tostring(v.EnumType):match("[%w_]+$"), name = v.Name}
    end
    return v
end

local function DeserializeValue(v)
    if type(v) == "table" and v.__type then
        if v.__type == "Color3" then return Color3.new(v.r, v.g, v.b) end
        if v.__type == "EnumItem" then 
            local et = Enum[v.enumType]
            if et and et[v.name] then return et[v.name] end
        end
    end
    return v
end

local function SaveConfig(name)
    if not name or name == "" then return end
    local data = {}
    for k, v in pairs(Config) do data[k] = SerializeValue(v) end
    local path = CONFIG_FOLDER .. "/" .. name .. ".json"
    local success, err = pcall(function() writefile(path, HttpService:JSONEncode(data)) end)
    if success then 
        WindUI:Notify({ Title = "Config Saved", Content = "Сохранено: " .. name, Icon = "check" })
    else 
        WindUI:Notify({ Title = "Error", Content = "Ошибка сохранения!", Icon = "x" }) 
    end
end

local function LoadConfig(name)
    if not name or name == "" then return end
    local path = CONFIG_FOLDER .. "/" .. name .. ".json"
    if not isfile(path) then 
        WindUI:Notify({ Title = "Error", Content = "Конфиг не найден!", Icon = "x" })
        return 
    end
    local success, decoded = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
    if success and decoded then
        for k, v in pairs(decoded) do 
            if Config[k] ~= nil then Config[k] = DeserializeValue(v) end 
        end
        SetFullbright(Config.Fullbright)
        SetRemoveGrass(Config.RemoveGrass)
        SetAntiShader(Config.AntiShader)
        if Config.PotatoGraphics then ApplyPotatoGraphics() else RestorePotatoGraphics() end
        WindUI:Notify({ Title = "Config Loaded", Content = "Загружен: " .. name, Icon = "check" })
    else 
        WindUI:Notify({ Title = "Error", Content = "Ошибка чтения файла!", Icon = "x" }) 
    end
end

local function GetConfigList()
    local list = {}
    local success, files = pcall(function() return listfiles(CONFIG_FOLDER) end)
    if success and files then
        for _, file in pairs(files) do 
            local name = file:match("([^/\\]+)%.json$")
            if name then table.insert(list, name) end 
        end
    end
    return list
end

-- ============================================================================
-- FULLBRIGHT & ГРАФИКА
-- ============================================================================
local OriginalLighting, OriginalAtmosphere, GameEffects = nil, nil, {}
local function SetFullbright(enabled)
    if enabled then
        if not OriginalLighting then 
            OriginalLighting = { ClockTime = Lighting.ClockTime, Brightness = Lighting.Brightness, Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient, GlobalShadows = Lighting.GlobalShadows, FogEnd = Lighting.FogEnd, FogStart = Lighting.FogStart, FogColor = Lighting.FogColor, EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale, EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale, ShadowSoftness = Lighting.ShadowSoftness, ExposureCompensation = Lighting.ExposureCompensation } 
        end
        if not OriginalAtmosphere then 
            local atm = Lighting:FindFirstChildOfClass("Atmosphere")
            if atm then OriginalAtmosphere = {obj = atm, Density = atm.Density, Haze = atm.Haze, Glare = atm.Glare, Offset = atm.Offset, Color = atm.Color, Decay = atm.Decay} end 
        end
        GameEffects = {}
        for _, v in pairs(Lighting:GetChildren()) do
            if v:IsA("ColorCorrectionEffect") then 
                table.insert(GameEffects, {obj = v, enabled = v.Enabled, brightness = v.Brightness, contrast = v.Contrast, saturation = v.Saturation, tintColor = v.TintColor})
                v.Enabled = false
            elseif v:IsA("BlurEffect") or v:IsA("SunRaysEffect") then 
                table.insert(GameEffects, {obj = v, enabled = v.Enabled})
                v.Enabled = false
            elseif v:IsA("Atmosphere") then 
                v.Density = 0; v.Haze = 0; v.Glare = 0 
            end
        end
        pcall(function() 
            Lighting.ClockTime = 12; Lighting.Brightness = 3; Lighting.Ambient = Color3.fromRGB(255, 255, 255); Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
            Lighting.GlobalShadows = false; Lighting.FogEnd = 1000000; Lighting.FogStart = 0; Lighting.FogColor = Color3.fromRGB(255, 255, 255)
            Lighting.EnvironmentDiffuseScale = 1; Lighting.EnvironmentSpecularScale = 1; Lighting.ShadowSoftness = 0; Lighting.ExposureCompensation = 0 
        end)
    else
        for _, data in ipairs(GameEffects) do 
            if data.obj and data.obj.Parent then 
                pcall(function() 
                    if data.enabled ~= nil then data.obj.Enabled = data.enabled end
                    if data.brightness ~= nil then data.obj.Brightness = data.brightness end
                    if data.contrast ~= nil then data.obj.Contrast = data.contrast end
                    if data.saturation ~= nil then data.obj.Saturation = data.saturation end
                    if data.tintColor ~= nil then data.obj.TintColor = data.tintColor end 
                end) 
            end 
        end
        GameEffects = {}
        if OriginalAtmosphere and OriginalAtmosphere.obj and OriginalAtmosphere.obj.Parent then 
            pcall(function() 
                OriginalAtmosphere.obj.Density = OriginalAtmosphere.Density; OriginalAtmosphere.obj.Haze = OriginalAtmosphere.Haze; OriginalAtmosphere.obj.Glare = OriginalAtmosphere.Glare
                OriginalAtmosphere.obj.Offset = OriginalAtmosphere.Offset; OriginalAtmosphere.obj.Color = OriginalAtmosphere.Color; OriginalAtmosphere.obj.Decay = OriginalAtmosphere.Decay 
            end) 
        end
        OriginalAtmosphere = nil
        if OriginalLighting then 
            pcall(function() 
                Lighting.ClockTime = OriginalLighting.ClockTime; Lighting.Brightness = OriginalLighting.Brightness; Lighting.Ambient = OriginalLighting.Ambient
                Lighting.OutdoorAmbient = OriginalLighting.OutdoorAmbient; Lighting.GlobalShadows = OriginalLighting.GlobalShadows; Lighting.FogEnd = OriginalLighting.FogEnd
                Lighting.FogStart = OriginalLighting.FogStart; Lighting.FogColor = OriginalLighting.FogColor; Lighting.EnvironmentDiffuseScale = OriginalLighting.EnvironmentDiffuseScale
                Lighting.EnvironmentSpecularScale = OriginalLighting.EnvironmentSpecularScale; Lighting.ShadowSoftness = OriginalLighting.ShadowSoftness
                if OriginalLighting.ExposureCompensation then Lighting.ExposureCompensation = OriginalLighting.ExposureCompensation end 
            end)
            OriginalLighting = nil 
        end
    end
end

local OriginalTerrainDecoration = nil
local OriginalGrassParts = {}
local function SetRemoveGrass(enabled)
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if terrain then 
        if enabled then 
            if OriginalTerrainDecoration == nil then OriginalTerrainDecoration = terrain.Decoration end
            pcall(function() terrain.Decoration = false end) 
        else 
            if OriginalTerrainDecoration ~= nil then pcall(function() terrain.Decoration = OriginalTerrainDecoration end); OriginalTerrainDecoration = nil end 
        end 
    end
    if enabled then 
        for _, obj in pairs(workspace:GetDescendants()) do 
            if obj:IsA("BasePart") and obj.Material == Enum.Material.Grass then 
                if not OriginalGrassParts[obj] then OriginalGrassParts[obj] = obj.LocalTransparencyModifier end
                pcall(function() obj.LocalTransparencyModifier = 1 end) 
            end 
        end
    else 
        for obj, mod in pairs(OriginalGrassParts) do 
            if obj and obj.Parent then pcall(function() obj.LocalTransparencyModifier = mod end) end 
        end
        OriginalGrassParts = {} 
    end
end

local function SetAntiShader(enabled)
    if enabled then
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("MeshPart") and obj.TextureID ~= "" then 
                if not OriginalAntiShaderProps[obj] then OriginalAntiShaderProps[obj] = {TextureID = obj.TextureID} end
                obj.TextureID = ""
            elseif obj:IsA("SurfaceAppearance") or obj:IsA("Decal") or obj:IsA("Texture") then 
                if not OriginalAntiShaderProps[obj] then OriginalAntiShaderProps[obj] = {Parent = obj.Parent, ClassName = obj.ClassName} end
                obj:Destroy() 
            end
        end
        for _, v in pairs(Lighting:GetChildren()) do 
            if v:IsA("PostEffect") then 
                if not OriginalAntiShaderProps[v] then OriginalAntiShaderProps[v] = {Enabled = v.Enabled} end
                pcall(function() v.Enabled = false end) 
            end 
        end
    else
        for obj, data in pairs(OriginalAntiShaderProps) do 
            if data.TextureID and obj and obj.Parent then obj.TextureID = data.TextureID 
            elseif data.Enabled ~= nil and obj and obj.Parent then obj.Enabled = data.Enabled end 
        end
        OriginalAntiShaderProps = {}
    end
end

local isApplyingGrey = false
local function IsCharacterPart(obj)
    local parent = obj.Parent
    while parent do 
        if parent:IsA("Model") and parent:FindFirstChildOfClass("Humanoid") then return true end
        if parent:IsA("Tool") or parent:IsA("Accessory") then return true end
        parent = parent.Parent 
    end
    return false
end

local UNIFORM_GROUND_COLOR = Color3.fromRGB(85, 107, 47)
local function ApplyPotatoGraphics()
    if not Config.PotatoGraphics or isApplyingGrey then return end
    isApplyingGrey = true
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if terrain then 
        pcall(function() terrain.Decoration = false end)
        for _, mat in pairs({Enum.Material.Grass, Enum.Material.Ground, Enum.Material.LeafyGrass, Enum.Material.Mud, Enum.Material.Rock, Enum.Material.Sand, Enum.Material.Snow}) do 
            local ok, currentColor = pcall(function() return terrain:GetMaterialColor(mat) end)
            if ok then 
                if not OriginalTerrainColors[mat] then OriginalTerrainColors[mat] = currentColor end
                pcall(function() terrain:SetMaterialColor(mat, UNIFORM_GROUND_COLOR) end) 
            end 
        end 
    end
    task.spawn(function()
        local allObjects = workspace:GetDescendants()
        local batchSize = 500
        for i = 1, #allObjects, batchSize do
            if not Config.PotatoGraphics or State.Unloaded then break end
            local batchEnd = math.min(i + batchSize - 1, #allObjects)
            for j = i, batchEnd do
                local obj = allObjects[j]
                if obj:IsA("BasePart") and not IsCharacterPart(obj) then
                    if not OriginalUltraProps[obj] then OriginalUltraProps[obj] = {Material = obj.Material, TextureID = obj:IsA("MeshPart") and obj.TextureID or nil, Color = obj.Color} end
                    obj.Material = Enum.Material.SmoothPlastic
                    obj.Color = UNIFORM_GROUND_COLOR
                    if obj:IsA("MeshPart") then obj.TextureID = "" end
                elseif obj:IsA("Decal") or obj:IsA("Texture") then 
                    if not OriginalUltraProps[obj] then OriginalUltraProps[obj] = {Transparency = obj.Transparency} end
                    obj.Transparency = 1
                elseif obj:IsA("SurfaceAppearance") then 
                    if not OriginalUltraProps[obj] then OriginalUltraProps[obj] = {Enabled = obj.Enabled} end
                    obj.Enabled = false
                elseif obj:IsA("ParticleEmitter") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then 
                    if not OriginalUltraProps[obj] then OriginalUltraProps[obj] = {Enabled = obj.Enabled} end
                    obj.Enabled = false 
                end
            end
            task.wait() 
        end
        isApplyingGrey = false
    end)
end

local function RestorePotatoGraphics()
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if terrain then 
        if not Config.RemoveGrass then pcall(function() terrain.Decoration = true end) end
        for mat, color in pairs(OriginalTerrainColors) do pcall(function() terrain:SetMaterialColor(mat, color) end) end
        OriginalTerrainColors = {} 
    end
    task.spawn(function()
        local allProps = {}
        for obj, props in pairs(OriginalUltraProps) do table.insert(allProps, {obj, props}) end
        local batchSize = 500
        for i = 1, #allProps, batchSize do
            local batchEnd = math.min(i + batchSize - 1, #allProps)
            for j = i, batchEnd do
                local obj, props = allProps[j][1], allProps[j][2]
                if obj and obj.Parent then 
                    pcall(function() 
                        if props.Material ~= nil then obj.Material = props.Material end
                        if props.TextureID ~= nil then obj.TextureID = props.TextureID end
                        if props.Color ~= nil then obj.Color = props.Color end
                        if props.Transparency ~= nil then obj.Transparency = props.Transparency end
                        if props.Enabled ~= nil then obj.Enabled = props.Enabled end 
                    end) 
                end
            end
            task.wait()
        end
        OriginalUltraProps = {}
    end)
end

table.insert(Connections, workspace.DescendantAdded:Connect(function(obj) 
    if State.Unloaded then return end
    if Config.AntiShader then 
        if obj:IsA("MeshPart") and obj.TextureID ~= "" then 
            if not OriginalAntiShaderProps[obj] then OriginalAntiShaderProps[obj] = {TextureID = obj.TextureID} end
            obj.TextureID = "" 
        elseif obj:IsA("SurfaceAppearance") or obj:IsA("Decal") or obj:IsA("Texture") then 
            obj:Destroy() 
        end 
    end
    if Config.RemoveGrass and obj:IsA("BasePart") and obj.Material == Enum.Material.Grass then 
        if not OriginalGrassParts[obj] then OriginalGrassParts[obj] = obj.LocalTransparencyModifier end
        pcall(function() obj.LocalTransparencyModifier = 1 end) 
    end
    if Config.PotatoGraphics and not isApplyingGrey then 
        if obj:IsA("BasePart") and not IsCharacterPart(obj) then 
            if not OriginalUltraProps[obj] then OriginalUltraProps[obj] = {Material = obj.Material, Color = obj.Color} end
            obj.Material = Enum.Material.SmoothPlastic
            obj.Color = UNIFORM_GROUND_COLOR
            if obj:IsA("MeshPart") then obj.TextureID = "" end
        elseif obj:IsA("Decal") or obj:IsA("Texture") then 
            if not OriginalUltraProps[obj] then OriginalUltraProps[obj] = {Transparency = obj.Transparency} end
            obj.Transparency = 1
        elseif obj:IsA("SurfaceAppearance") then 
            if not OriginalUltraProps[obj] then OriginalUltraProps[obj] = {Enabled = obj.Enabled} end
            obj.Enabled = false
        elseif obj:IsA("ParticleEmitter") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then 
            if not OriginalUltraProps[obj] then OriginalUltraProps[obj] = {Enabled = obj.Enabled} end
            obj.Enabled = false 
        end
    end 
end))

-- ============================================================================
-- DRAWING (CROSSHAIR & FOV)
-- ============================================================================
local CrossLines = {}
for i=1, 8 do CrossLines[i] = Drawing.new("Line"); CrossLines[i].Thickness = 2; CrossLines[i].Color = Color3.fromRGB(0, 255, 255); CrossLines[i].Visible = false end
local CrossDot = Drawing.new("Circle"); CrossDot.Radius = 2; CrossDot.Filled = true; CrossDot.Color = Color3.fromRGB(0, 255, 255); CrossDot.Visible = false
local CrossCircle = Drawing.new("Circle"); CrossCircle.Radius = 8; CrossCircle.Thickness = 1.5; CrossCircle.Filled = false; CrossCircle.Color = Color3.fromRGB(0, 255, 255); CrossCircle.Visible = false
local FOVCircle = Drawing.new("Circle"); FOVCircle.Thickness = 2; FOVCircle.NumSides = 100; FOVCircle.Radius = Config.FOV; FOVCircle.Color = Color3.fromRGB(80, 120, 255); FOVCircle.Filled = false; FOVCircle.Visible = false

local function UpdateCrosshair()
    local cx, cy = Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2
    if not Config.CrosshairEnabled or State.Unloaded then 
        for i=1, 8 do CrossLines[i].Visible = false end
        CrossDot.Visible = false; CrossCircle.Visible = false
        return 
    end
    for i=1, 8 do CrossLines[i].Visible = false end
    CrossDot.Visible = false; CrossCircle.Visible = false
    if Config.CrosshairType == 1 then
        local gap = 4; local length = 6
        CrossLines[1].From = Vector2.new(cx - gap - length, cy); CrossLines[1].To = Vector2.new(cx - gap, cy); CrossLines[1].Visible = true
        CrossLines[2].From = Vector2.new(cx + gap, cy); CrossLines[2].To = Vector2.new(cx + gap + length, cy); CrossLines[2].Visible = true
        CrossLines[3].From = Vector2.new(cx, cy - gap - length); CrossLines[3].To = Vector2.new(cx, cy - gap); CrossLines[3].Visible = true
        CrossLines[4].From = Vector2.new(cx, cy + gap); CrossLines[4].To = Vector2.new(cx, cy + gap + length); CrossLines[4].Visible = true
    elseif Config.CrosshairType == 2 then 
        CrossDot.Position = Vector2.new(cx, cy); CrossDot.Visible = true
    elseif Config.CrosshairType == 3 then 
        CrossCircle.Position = Vector2.new(cx, cy); CrossCircle.Visible = true
    elseif Config.CrosshairType == 4 then
        local L = 8
        CrossLines[1].From = Vector2.new(cx, cy); CrossLines[1].To = Vector2.new(cx, cy - L); CrossLines[1].Visible = true
        CrossLines[2].From = Vector2.new(cx, cy); CrossLines[2].To = Vector2.new(cx + L/2, cy - L); CrossLines[2].Visible = true
        CrossLines[3].From = Vector2.new(cx, cy); CrossLines[3].To = Vector2.new(cx + L, cy); CrossLines[3].Visible = true
        CrossLines[4].From = Vector2.new(cx, cy); CrossLines[4].To = Vector2.new(cx + L, cy + L/2); CrossLines[4].Visible = true
        CrossLines[5].From = Vector2.new(cx, cy); CrossLines[5].To = Vector2.new(cx, cy + L); CrossLines[5].Visible = true
        CrossLines[6].From = Vector2.new(cx, cy); CrossLines[6].To = Vector2.new(cx - L/2, cy + L); CrossLines[6].Visible = true
        CrossLines[7].From = Vector2.new(cx, cy); CrossLines[7].To = Vector2.new(cx - L, cy); CrossLines[7].Visible = true
        CrossLines[8].From = Vector2.new(cx, cy); CrossLines[8].To = Vector2.new(cx - L, cy - L/2); CrossLines[8].Visible = true
    end
end

-- ============================================================================
-- СИСТЕМА ДРУЗЕЙ (ЛОГИКА)
-- ============================================================================
local RefreshFriendsUI

local function AddClosestToFriend()
    local closest = nil; local shortest = 150; local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
            local head = p.Character.Head; local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
            if onScreen and screenPos.Z > 0 then
                local dist = (screenCenter - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
                if dist < shortest then shortest = dist; closest = p end
            end
        end
    end
    if closest and not Friends[closest] then
        Friends[closest] = true
        WindUI:Notify({ Title = "Friend Added", Content = closest.Name .. " добавлен.", Icon = "user-plus" })
        if RefreshFriendsUI then RefreshFriendsUI() end
    end
end

local function RemoveFriend(player)
    if Friends[player] then
        Friends[player] = nil
        WindUI:Notify({ Title = "Friend Removed", Content = player.Name .. " удален.", Icon = "user-minus" })
        if RefreshFriendsUI then RefreshFriendsUI() end
    end
end

local function AddFriendByName(name)
    local target = Players:FindFirstChild(name)
    if target and target ~= LocalPlayer then
        if not Friends[target] then
            Friends[target] = true
            WindUI:Notify({ Title = "Friend Added", Content = target.Name .. " добавлен.", Icon = "user-plus" })
            if RefreshFriendsUI then RefreshFriendsUI() end
        else
            WindUI:Notify({ Title = "Error", Content = "Уже в друзьях!", Icon = "x" })
        end
    else
        WindUI:Notify({ Title = "Error", Content = "Игрок не найден!", Icon = "x" })
    end
end

local function AddDeathMarker(position, playerName)
    local marker = Drawing.new("Text"); marker.Text = "💀 " .. playerName; marker.Color = Color3.fromRGB(255, 50, 50); marker.Size = 16; marker.Center = true; marker.Outline = true; marker.OutlineColor = Color3.fromRGB(0, 0, 0); marker.Transparency = 1; marker.Position = Vector2.new(-1000, -1000); marker.Visible = false
    table.insert(DeathMarkers, {Text = marker, Position = position, Time = tick(), Duration = 120})
end

local function UpdateDeathMarkers()
    for i = #DeathMarkers, 1, -1 do
        local marker = DeathMarkers[i]; local elapsed = tick() - marker.Time
        if elapsed > marker.Duration or not Config.ShowDeathMarkers then marker.Text:Remove(); table.remove(DeathMarkers, i)
        else
            local screenPos, onScreen = Camera:WorldToViewportPoint(marker.Position)
            if onScreen and screenPos.Z > 0 then
                local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"); local dist = myRoot and math.floor((marker.Position - myRoot.Position).Magnitude) or 0
                marker.Text.Text = "💀 " .. dist .. "m"; marker.Text.Position = Vector2.new(screenPos.X, screenPos.Y); marker.Text.Visible = true; marker.Text.Color = Color3.fromRGB(255, 50, 50)
            else marker.Text.Visible = false end
        end
    end
end

table.insert(Connections, task.spawn(function()
    local function setup(p)
        if p ~= LocalPlayer then
            table.insert(Connections, p.CharacterAdded:Connect(function(char)
                local hum = char:WaitForChild("Humanoid", 5)
                if hum then table.insert(Connections, hum.Died:Connect(function() local hrp = char:FindFirstChild("HumanoidRootPart"); if hrp then AddDeathMarker(hrp.Position, p.Name) end end)) end
            end))
        end
    end
    for _, p in pairs(Players:GetPlayers()) do setup(p) end
    table.insert(Connections, Players.PlayerAdded:Connect(setup))
end))

local function UpdateItemESP()
    if not Config.ItemESPEnabled then return end
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"); if not myRoot then return end
    for item, esp in pairs(ItemESPObjects) do 
        if not item or not item.Parent then esp.Box:Remove(); esp.Text:Remove(); ItemESPObjects[item] = nil 
        else 
            local itemPart = item:IsA("BasePart") and item or item:FindFirstChildWhichIsA("BasePart")
            if itemPart and (itemPart.Position - myRoot.Position).Magnitude > Config.ItemESPMaxDist then esp.Box:Remove(); esp.Text:Remove(); ItemESPObjects[item] = nil end 
        end 
    end
    for item, esp in pairs(ItemESPObjects) do 
        if myRoot and esp.Part then 
            local screenPos, onScreen = Camera:WorldToViewportPoint(esp.Part.Position)
            if onScreen and screenPos.Z > 0 then 
                local dist = math.floor((esp.Part.Position - myRoot.Position).Magnitude)
                esp.Box.Size = Vector2.new(10, 10); esp.Box.Position = Vector2.new(screenPos.X - 5, screenPos.Y - 5); esp.Box.Visible = true
                esp.Text.Text = "[" .. dist .. "m] " .. item.Name; esp.Text.Position = Vector2.new(screenPos.X, screenPos.Y - 20); esp.Text.Visible = true
            else esp.Box.Visible = false; esp.Text.Visible = false end 
        end 
    end
    local filter = string.lower(Config.ItemESPFilter); local itemColor = Color3.fromRGB(80, 120, 255)
    for _, obj in pairs(workspace:GetChildren()) do 
        if obj:IsA("Tool") or obj:IsA("Model") then 
            local part = obj:FindFirstChildWhichIsA("BasePart")
            if part then 
                local dist = (part.Position - myRoot.Position).Magnitude
                if dist <= Config.ItemESPMaxDist then 
                    local objName = string.lower(obj.Name); local isLoot = false
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

local function UpdateDroneESP()
    if not Config.DroneESPEnabled then return end
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"); if not myRoot then return end
    for drone, esp in pairs(DroneESPObjects) do if not drone or not drone.Parent then pcall(function() esp.Box:Remove(); esp.Text:Remove() end); DroneESPObjects[drone] = nil end end
    for _, obj in pairs(workspace:GetChildren()) do 
        if (obj:IsA("Model") or obj:IsA("BasePart")) and string.find(string.lower(obj.Name), "drone") then 
            local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
            if part and not DroneESPObjects[obj] then 
                local box = Drawing.new("Square"); box.Thickness = 1; box.Color = Color3.fromRGB(255, 100, 255); box.Filled = false; box.Visible = false
                local text = Drawing.new("Text"); text.Size = 12; text.Center = true; text.Outline = true; text.Color = Color3.fromRGB(255, 100, 255); text.Visible = false
                DroneESPObjects[obj] = {Box = box, Text = text, Part = part} 
            end 
        end 
    end
    for drone, esp in pairs(DroneESPObjects) do 
        if esp.Part then 
            local screenPos, onScreen = Camera:WorldToViewportPoint(esp.Part.Position)
            if onScreen and screenPos.Z > 0 then 
                local dist = math.floor((esp.Part.Position - myRoot.Position).Magnitude)
                esp.Box.Size = Vector2.new(20, 20); esp.Box.Position = Vector2.new(screenPos.X - 10, screenPos.Y - 10); esp.Box.Visible = true
                esp.Text.Text = "[DRONE " .. dist .. "m]"; esp.Text.Position = Vector2.new(screenPos.X, screenPos.Y - 20); esp.Text.Visible = true
            else esp.Box.Visible = false; esp.Text.Visible = false end 
        end 
    end
end

local function UpdateHeadSize()
    if not Config.HeadSizeEnabled then return end
    for head, _ in pairs(OriginalHeadSizes) do if not head or not head.Parent then OriginalHeadSizes[head] = nil end end
    for _, p in pairs(Players:GetPlayers()) do 
        if p ~= LocalPlayer and not Friends[p] and p.Character then 
            local head = p.Character:FindFirstChild("Head")
            if head and head:IsA("BasePart") then 
                if not OriginalHeadSizes[head] then OriginalHeadSizes[head] = head.Size end
                local newSize = OriginalHeadSizes[head] * Config.HeadSizeValue
                if head.Size ~= newSize then pcall(function() head.Size = newSize end) end 
            end 
        end 
    end
end

local function ApplyXRay()
    if not Config.XRayEnabled then return end
    local targetModifier = 1 - (Config.XRayValue / 100); local myPos = Camera.CFrame.Position
    for _, obj in pairs(workspace:GetChildren()) do 
        if obj:IsA("BasePart") then 
            local dist = (obj.Position - myPos).Magnitude
            if dist <= Config.XRayDistance then 
                if not OriginalTransparencies[obj] then OriginalTransparencies[obj] = obj.LocalTransparencyModifier end
                pcall(function() obj.LocalTransparencyModifier = targetModifier end) 
            else 
                if OriginalTransparencies[obj] then pcall(function() obj.LocalTransparencyModifier = OriginalTransparencies[obj] end); OriginalTransparencies[obj] = nil end 
            end 
        end 
    end
end

local function GetWeaponName(character)
    local tool = character:FindFirstChildOfClass("Tool"); if tool then return tool.Name end
    local rightHand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm"); if rightHand then local toolInHand = rightHand:FindFirstChildOfClass("Tool"); if toolInHand then return toolInHand.Name end end
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

-- ============================================================================
-- UI (WINDUI)
-- ============================================================================
local Window = WindUI:CreateWindow({
    Title = "Hook Fust", Author = "OMNIX", Folder = "HookFust", Icon = "solar:folder-2-bold-duotone", Theme = "Dark", NewElements = true, HideSearchBar = false,
    OpenButton = { Title = "Open Hook Fust", CornerRadius = UDim.new(1, 0), StrokeThickness = 3, Enabled = true, Draggable = true, OnlyMobile = false, Scale = 0.5, Color = ColorSequence.new(Color3.fromHex("#30FF6A"), Color3.fromHex("#e7ff2f")) },
    Topbar = { Height = 44, ButtonsType = "Mac" },
})
Window:Tag({ Title = "v108", Icon = "github", Color = Color3.fromHex("#1c1c1c"), Border = true })

local Purple = Color3.fromHex("#7775F2")
local Yellow = Color3.fromHex("#ECA201")
local Green = Color3.fromHex("#10C550")
local Grey = Color3.fromHex("#83889E")
local Blue = Color3.fromHex("#257AF7")
local Red = Color3.fromHex("#EF4F1D")

-- === ВКЛАДКА: AIMBOT ===
local AimbotTab = Window:Tab({ Title = "Aimbot", Icon = "solar:home-2-bold", IconColor = Grey, IconShape = "Square", Border = true })
local AimSection = AimbotTab:Section({ Title = "Aimbot Settings" })
AimSection:Toggle({ Title = "Enable Aimbot", Flag = "AimbotEnabled", Value = Config.AimbotEnabled, Callback = function(v) Config.AimbotEnabled = v end })
AimSection:Space()
AimSection:Toggle({ Title = "Use Prediction", Flag = "Prediction", Value = Config.Prediction, Callback = function(v) Config.Prediction = v end })
AimSection:Space()
AimSection:Toggle({ Title = "Visible Check", Flag = "VisibleAim", Value = Config.VisibleAim, Callback = function(v) Config.VisibleAim = v end })
AimSection:Space()
AimSection:Slider({ Title = "FOV Limit", Flag = "FOV", Value = { Min = 30, Max = 400, Default = Config.FOV }, Callback = function(v) Config.FOV = v end })
AimSection:Space()
AimSection:Dropdown({ Title = "Aimbot Method", Flag = "AimbotMethod", Values = {"Camera", "Mouse"}, Value = Config.AimbotMethod, Callback = function(v) Config.AimbotMethod = v end })
AimSection:Space()
AimSection:Slider({ Title = "Smoothness", Flag = "Smoothness", Value = { Min = 1, Max = 100, Default = Config.Smoothness * 100 }, Callback = function(v) Config.Smoothness = v / 100 end })

-- === ВКЛАДКА: VISUALS ===
local VisualsTab = Window:Tab({ Title = "Visuals", Icon = "solar:check-square-bold", IconColor = Green, IconShape = "Square", Border = true })
local ESP_Section = VisualsTab:Section({ Title = "Player ESP" })
ESP_Section:Toggle({ Title = "Player ESP Boxes", Flag = "ESPEnabled", Value = Config.ESPEnabled, Callback = function(v) Config.ESPEnabled = v end })
ESP_Section:Space()
ESP_Section:Toggle({ Title = "Player Chams", Flag = "ChamsEnabled", Value = Config.ChamsEnabled, Callback = function(v) Config.ChamsEnabled = v end })
ESP_Section:Space()
ESP_Section:Toggle({ Title = "ESP Weapon Name", Flag = "ESPWeapon", Value = Config.ESPWeapon, Callback = function(v) Config.ESPWeapon = v end })
ESP_Section:Space()
ESP_Section:Toggle({ Title = "ESP Health Text", Flag = "ESPHealthText", Value = Config.ESPHealthText, Callback = function(v) Config.ESPHealthText = v end })

VisualsTab:Space()
local CrossSection = VisualsTab:Section({ Title = "Crosshair" })
CrossSection:Toggle({ Title = "Custom Crosshair", Flag = "CrosshairEnabled", Value = Config.CrosshairEnabled, Callback = function(v) Config.CrosshairEnabled = v end })
CrossSection:Space()
CrossSection:Dropdown({ Title = "Crosshair Style", Flag = "CrosshairType", Values = {"Cross", "Dot", "Circle", "Star"}, Value = "Cross", Callback = function(v) 
    if v == "Cross" then Config.CrosshairType = 1 elseif v == "Dot" then Config.CrosshairType = 2 elseif v == "Circle" then Config.CrosshairType = 3 elseif v == "Star" then Config.CrosshairType = 4 end 
end })

VisualsTab:Space()
local WorldSection = VisualsTab:Section({ Title = "World" })
WorldSection:Toggle({ Title = "Item ESP", Flag = "ItemESPEnabled", Value = Config.ItemESPEnabled, Callback = function(v) Config.ItemESPEnabled = v end })
WorldSection:Space()
WorldSection:Input({ Title = "Item Filter", Flag = "ItemESPFilter", Value = Config.ItemESPFilter, Placeholder = "ak, crate...", Callback = function(text) Config.ItemESPFilter = text end })
WorldSection:Space()
WorldSection:Slider({ Title = "Item ESP Distance", Flag = "ItemESPMaxDist", Value = { Min = 50, Max = 1000, Default = Config.ItemESPMaxDist }, Callback = function(v) Config.ItemESPMaxDist = v end })
WorldSection:Space()
WorldSection:Toggle({ Title = "Drone ESP", Flag = "DroneESPEnabled", Value = Config.DroneESPEnabled, Callback = function(v) Config.DroneESPEnabled = v end })
WorldSection:Space()
WorldSection:Toggle({ Title = "X-Ray Walls", Flag = "XRayEnabled", Value = Config.XRayEnabled, Callback = function(v) Config.XRayEnabled = v; ApplyXRay() end })
WorldSection:Space()
WorldSection:Slider({ Title = "Wall Transparency", Flag = "XRayValue", Value = { Min = 0, Max = 100, Default = Config.XRayValue }, Callback = function(v) Config.XRayValue = v; if Config.XRayEnabled then ApplyXRay() end end })
WorldSection:Space()
WorldSection:Toggle({ Title = "Head Expander", Flag = "HeadSizeEnabled", Value = Config.HeadSizeEnabled, Callback = function(v) 
    Config.HeadSizeEnabled = v
    if not v then for head, origSize in pairs(OriginalHeadSizes) do if head and head.Parent then pcall(function() head.Size = origSize end) end end end 
end })
WorldSection:Space()
WorldSection:Slider({ Title = "Head Size Mult", Flag = "HeadSizeValue", Value = { Min = 1, Max = 5, Default = Config.HeadSizeValue }, Callback = function(v) Config.HeadSizeValue = v end })

-- === ВКЛАДКА: FRIENDS ===
local FriendsTab = Window:Tab({ Title = "Friends", Icon = "solar:users-group-rounded-bold", IconColor = Yellow, IconShape = "Square", Border = true })
local FriendsSection = FriendsTab:Section({ Title = "Manage Friends" })

local friendNameInput = ""
FriendsSection:Input({ Title = "Player Name", Placeholder = "Введи ник", Callback = function(text) friendNameInput = text end })
FriendsSection:Space()

FriendsSection:Button({ Title = "ADD BY NAME", Icon = "user-plus", Color = Color3.fromHex("#10C550"), Callback = function()
    if friendNameInput and friendNameInput ~= "" then 
        AddFriendByName(friendNameInput) 
    else 
        WindUI:Notify({ Title = "Error", Content = "Введи ник!", Icon = "x" }) 
    end
end })
FriendsSection:Space()

FriendsSection:Button({ Title = "ADD CLOSEST PLAYER", Icon = "crosshair", Color = Color3.fromHex("#257AF7"), Callback = AddClosestToFriend })
FriendsSection:Space()

local selectedFriendName = nil
local friendsDropdown
friendsDropdown = FriendsSection:Dropdown({ Title = "Current Friends", Values = {}, Value = nil, Callback = function(v) selectedFriendName = v end })
FriendsSection:Space()

FriendsSection:Button({ Title = "REMOVE SELECTED", Icon = "user-minus", Color = Color3.fromHex("#EF4F1D"), Callback = function()
    if selectedFriendName then
        local target = Players:FindFirstChild(selectedFriendName)
        if target then RemoveFriend(target) end
    else
        WindUI:Notify({ Title = "Error", Content = "Выбери друга из списка!", Icon = "x" })
    end
end })

-- Функция обновления UI друзей
RefreshFriendsUI = function()
    local list = {}
    for p, _ in pairs(Friends) do 
        if p and p.Parent then table.insert(list, p.Name) end 
    end
    if friendsDropdown then friendsDropdown:Refresh(list) end
end

-- Удаление из друзей при выходе игрока
table.insert(Connections, Players.PlayerRemoving:Connect(function(p)
    if Friends[p] then Friends[p] = nil; RefreshFriendsUI() end
end))

-- === ВКЛАДКА: OPTIMIZER ===
local OptimizerTab = Window:Tab({ Title = "Optimizer", Icon = "solar:cursor-square-bold", IconColor = Blue, IconShape = "Square", Border = true })
local OptSection = OptimizerTab:Section({ Title = "Optimization" })
OptSection:Toggle({ Title = "Fullbright (Fixed)", Flag = "Fullbright", Value = Config.Fullbright, Callback = function(v) Config.Fullbright = v; SetFullbright(v) end })
OptSection:Space()
OptSection:Toggle({ Title = "Remove Grass", Flag = "RemoveGrass", Value = Config.RemoveGrass, Callback = function(v) Config.RemoveGrass = v; SetRemoveGrass(v) end })
OptSection:Space()
OptSection:Toggle({ Title = "Anti-Shader (Убрать все шейдеры)", Flag = "AntiShader", Value = Config.AntiShader, Callback = function(v) Config.AntiShader = v; SetAntiShader(v) end })
OptSection:Space()
OptSection:Toggle({ Title = "Potato Graphics (Однотонная земля)", Flag = "PotatoGraphics", Value = Config.PotatoGraphics, Callback = function(v) Config.PotatoGraphics = v; if v then ApplyPotatoGraphics() else RestorePotatoGraphics() end end })

-- === ВКЛАДКА: CONFIGS ===
local ConfigsTab = Window:Tab({ Title = "Configs", Icon = "solar:folder-with-files-bold", IconColor = Yellow, IconShape = "Square", Border = true })
local ConfigSection = ConfigsTab:Section({ Title = "Config Manager" })
ConfigSection:Input({ Title = "Config Name", Value = "default", Placeholder = "Введи имя", Callback = function(text) currentConfigName = text end })
ConfigSection:Space()
local ConfigsListDropdown
ConfigsListDropdown = ConfigSection:Dropdown({ Title = "Saved Configs", Values = GetConfigList(), Value = nil, Callback = function(v) if v then currentConfigName = v end end })
ConfigSection:Space()
ConfigSection:Button({ Title = "SAVE CONFIG", Icon = "save", Color = Color3.fromHex("#10C550"), Callback = function() SaveConfig(currentConfigName); if ConfigsListDropdown then ConfigsListDropdown:Refresh(GetConfigList()) end end })
ConfigSection:Space()
ConfigSection:Button({ Title = "LOAD CONFIG", Icon = "download", Color = Color3.fromHex("#257AF7"), Callback = function() LoadConfig(currentConfigName) end })

-- === ВКЛАДКА: MISC ===
local MiscTab = Window:Tab({ Title = "Misc", Icon = "solar:password-minimalistic-input-bold", IconColor = Purple, IconShape = "Square", Border = true })
local MiscSection = MiscTab:Section({ Title = "Miscellaneous" })
MiscSection:Toggle({ Title = "Show HUD (FPS + Functions)", Flag = "HUDEnabled", Value = Config.HUDEnabled, Callback = function(v) Config.HUDEnabled = v; if HUDGui then HUDGui.Enabled = v end end })
MiscSection:Space()
MiscSection:Toggle({ Title = "Death Markers", Flag = "ShowDeathMarkers", Value = Config.ShowDeathMarkers, Callback = function(v) Config.ShowDeathMarkers = v end })
MiscSection:Space()
MiscSection:Slider({ Title = "Max ESP Distance", Flag = "ESPMaxDist", Value = { Min = 100, Max = 2000, Default = Config.ESPMaxDist }, Callback = function(v) Config.ESPMaxDist = v end })

MiscTab:Space()
local BindsSection = MiscTab:Section({ Title = "Key Binds" })
BindsSection:Keybind({ Title = "Aimbot Key", Value = "MB2", Callback = function(v) if v then local success, enum = pcall(function() return Enum.UserInputType[v] or Enum.KeyCode[v] end); if success and enum then Binds.Aimbot = enum end end end })
BindsSection:Space()
BindsSection:Keybind({ Title = "Prediction Toggle", Value = "P", Callback = function(v) if v then local success, enum = pcall(function() return Enum.KeyCode[v] end); if success and enum then Binds.Prediction = enum end end end })
BindsSection:Space()
BindsSection:Keybind({ Title = "Add Friend (Closest)", Value = "F", Callback = function(v) if v then local success, enum = pcall(function() return Enum.KeyCode[v] end); if success and enum then Binds.AddFriend = enum end end end })

-- ============================================================================
-- HUD (WATERMARK)
-- ============================================================================
local HUDGui = Instance.new("ScreenGui"); HUDGui.Name = "HookFustHUD"; HUDGui.ResetOnSpawn = false; HUDGui.Enabled = Config.HUDEnabled
pcall(function() HUDGui.Parent = gethui and gethui() or game:GetService("CoreGui") end)
local Watermark = Instance.new("Frame"); Watermark.Size = UDim2.new(0, 240, 0, 220); Watermark.Position = UDim2.new(0, 20, 0, 20); Watermark.BackgroundColor3 = Color3.fromRGB(15, 15, 20); Watermark.BackgroundTransparency = 0.2; Watermark.BorderSizePixel = 0; Watermark.Parent = HUDGui
local WMCorner = Instance.new("UICorner"); WMCorner.CornerRadius = UDim.new(0, 6); WMCorner.Parent = Watermark
local WMStroke = Instance.new("UIStroke"); WMStroke.Color = Color3.fromRGB(80, 120, 255); WMStroke.Thickness = 1.5; WMStroke.Transparency = 0.2; WMStroke.Parent = Watermark
local WMStrokeGrad = Instance.new("UIGradient"); WMStrokeGrad.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromHex("#30FF6A")), ColorSequenceKeypoint.new(0.5, Color3.fromHex("#257AF7")), ColorSequenceKeypoint.new(1, Color3.fromHex("#EF4F1D")) }); WMStrokeGrad.Rotation = 45; WMStrokeGrad.Parent = WMStroke
local WMHeader = Instance.new("Frame"); WMHeader.Size = UDim2.new(1, 0, 0, 35); WMHeader.BackgroundColor3 = Color3.fromRGB(25, 25, 30); WMHeader.BackgroundTransparency = 0.5; WMHeader.BorderSizePixel = 0; WMHeader.Parent = Watermark
local WMHeaderCorner = Instance.new("UICorner"); WMHeaderCorner.CornerRadius = UDim.new(0, 6); WMHeaderCorner.Parent = WMHeader
local WMTitle = Instance.new("TextLabel"); WMTitle.Size = UDim2.new(1, -80, 1, 0); WMTitle.Position = UDim2.new(0, 15, 0, 0); WMTitle.BackgroundTransparency = 1; WMTitle.Text = "Hook Fust"; WMTitle.Font = Enum.Font.GothamBlack; WMTitle.TextSize = 16; WMTitle.TextXAlignment = Enum.TextXAlignment.Left; WMTitle.Parent = WMHeader
local WMTitleGrad = Instance.new("UIGradient"); WMTitleGrad.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 120, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 255, 255))}); WMTitleGrad.Parent = WMTitle; WMTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
local WMFPS = Instance.new("TextLabel"); WMFPS.Size = UDim2.new(0, 60, 1, 0); WMFPS.Position = UDim2.new(1, -65, 0, 0); WMFPS.BackgroundTransparency = 1; WMFPS.Text = "FPS: 60"; WMFPS.TextColor3 = Color3.fromRGB(200, 200, 210); WMFPS.Font = Enum.Font.GothamBold; WMFPS.TextSize = 12; WMFPS.TextXAlignment = Enum.TextXAlignment.Right; WMFPS.Parent = WMHeader
local WMList = Instance.new("Frame"); WMList.Size = UDim2.new(1, -20, 1, -45); WMList.Position = UDim2.new(0, 10, 0, 40); WMList.BackgroundTransparency = 1; WMList.Parent = Watermark
local WMListLayout = Instance.new("UIListLayout"); WMListLayout.Padding = UDim.new(0, 4); WMListLayout.SortOrder = Enum.SortOrder.LayoutOrder; WMListLayout.Parent = WMList

local dragging, dragInput, dragStart, startPos
WMHeader.InputBegan:Connect(function(input) 
    if input.UserInputType == Enum.UserInputType.MouseButton1 then 
        dragging = true; dragStart = input.Position; startPos = Watermark.Position; input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end) 
    end 
end)
WMHeader.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end end)
UserInputService.InputChanged:Connect(function(input) 
    if input == dragInput and dragging then 
        local delta = input.Position - dragStart; Watermark.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) 
    end 
end)

local hudElements = {}
local function UpdateHUD()
    local activeFeatures = {}
    if Config.AimbotEnabled then table.insert(activeFeatures, {name = "Aimbot", color = "#30FF6A"}) end
    if Config.ESPEnabled then table.insert(activeFeatures, {name = "ESP Boxes", color = "#257AF7"}) end
    if Config.ChamsEnabled then table.insert(activeFeatures, {name = "Chams", color = "#257AF7"}) end
    if Config.ItemESPEnabled then table.insert(activeFeatures, {name = "Item ESP", color = "#ECA201"}) end
    if Config.DroneESPEnabled then table.insert(activeFeatures, {name = "Drone ESP", color = "#ECA201"}) end
    if Config.XRayEnabled then table.insert(activeFeatures, {name = "X-Ray", color = "#7775F2"}) end
    if Config.Fullbright then table.insert(activeFeatures, {name = "Fullbright", color = "#FFD700"}) end
    if Config.RemoveGrass then table.insert(activeFeatures, {name = "No Grass", color = "#10C550"}) end
    if Config.AntiShader then table.insert(activeFeatures, {name = "No Shaders", color = "#FF4500"}) end
    if Config.PotatoGraphics then table.insert(activeFeatures, {name = "Potato GFX", color = "#83889E"}) end
    if Config.CrosshairEnabled then table.insert(activeFeatures, {name = "Crosshair", color = "#FF69B4"}) end
    
    for _, el in pairs(hudElements) do el:Destroy() end; hudElements = {}
    
    if #activeFeatures == 0 then 
        local noneLabel = Instance.new("TextLabel"); noneLabel.Size = UDim2.new(1, 0, 0, 20); noneLabel.BackgroundTransparency = 1; noneLabel.Text = "No features active"; noneLabel.TextColor3 = Color3.fromRGB(150, 150, 150); noneLabel.Font = Enum.Font.GothamMedium; noneLabel.TextSize = 13; noneLabel.TextXAlignment = Enum.TextXAlignment.Left; noneLabel.Parent = WMList; table.insert(hudElements, noneLabel)
    else 
        for _, feat in ipairs(activeFeatures) do 
            local label = Instance.new("TextLabel"); label.Size = UDim2.new(1, 0, 0, 18); label.BackgroundTransparency = 1; label.RichText = true; label.Text = string.format('<font color="%s">•</font> %s', feat.color, feat.name); label.TextColor3 = Color3.fromRGB(220, 220, 230); label.Font = Enum.Font.GothamMedium; label.TextSize = 13; label.TextXAlignment = Enum.TextXAlignment.Left; label.Parent = WMList; table.insert(hudElements, label) 
        end 
    end
end

-- ============================================================================
-- PANIC & CLEANUP
-- ============================================================================
local function FullCleanup()
    State.Unloaded = true
    for _, conn in pairs(Connections) do pcall(function() conn:Disconnect() end) end; Connections = {}
    Config.Fullbright = false; SetFullbright(false); Config.RemoveGrass = false; SetRemoveGrass(false); Config.AntiShader = false; SetAntiShader(false); Config.PotatoGraphics = false; RestorePotatoGraphics()
    pcall(function() Window:Destroy() end); if HUDGui then pcall(function() HUDGui:Destroy() end) end
    pcall(function() FOVCircle:Remove() end); for i=1, 8 do pcall(function() CrossLines[i]:Remove() end) end; pcall(function() CrossDot:Remove() end); pcall(function() CrossCircle:Remove() end)
    for p, esp in pairs(ESPObjects) do pcall(function() esp.Box1:Remove(); esp.Box2:Remove(); esp.Box3:Remove(); esp.Box4:Remove(); esp.Name:Remove(); esp.Dist:Remove(); esp.HealthText:Remove(); esp.Weapon:Remove() end) end; ESPObjects = {}
    for p, chams in pairs(ChamsObjects) do pcall(function() chams:Destroy() end) end; ChamsObjects = {}
    for item, esp in pairs(ItemESPObjects) do pcall(function() esp.Box:Remove(); esp.Text:Remove() end) end; ItemESPObjects = {}
    for drone, esp in pairs(DroneESPObjects) do pcall(function() esp.Box:Remove(); esp.Text:Remove() end) end; DroneESPObjects = {}
    for _, marker in pairs(DeathMarkers) do pcall(function() marker.Text:Remove() end) end; DeathMarkers = {}
    for obj, origMod in pairs(OriginalTransparencies) do if obj and obj.Parent then pcall(function() obj.LocalTransparencyModifier = origMod end) end end; OriginalTransparencies = {}
    for head, origSize in pairs(OriginalHeadSizes) do if head and head.Parent then pcall(function() head.Size = origSize end) end end; OriginalHeadSizes = {}
    print("[Hook Fust] Выгружен.")
end

local DangerSection = MiscTab:Section({ Title = "Danger Zone" })
DangerSection:Button({ Title = "UNLOAD CHEAT (PANIC)", Icon = "shredder", Justify = "Center", Color = Color3.fromHex("#ff4830"), Callback = FullCleanup })

-- ============================================================================
-- ESP ЛОГИКА (ФИКС: ПОЛНОЕ СКРЫТИЕ ДЛЯ ДРУЗЕЙ)
-- ============================================================================
local function IsVisible(targetChar)
    local myChar = LocalPlayer.Character; local targetPart = targetChar:FindFirstChild("Head") or targetChar:FindFirstChild("HumanoidRootPart")
    if not myChar or not myChar:FindFirstChild("Head") or not targetPart then return false end
    local RayParams = RaycastParams.new(); RayParams.FilterType = Enum.RaycastFilterType.Exclude; RayParams.FilterDescendantsInstances = {myChar, targetChar}
    return workspace:Raycast(Camera.CFrame.Position, targetPart.Position - Camera.CFrame.Position, RayParams) == nil
end

local function RemoveESP(p) 
    if ESPObjects[p] then 
        local esp = ESPObjects[p]
        pcall(function() esp.Box1:Remove(); esp.Box2:Remove(); esp.Box3:Remove(); esp.Box4:Remove(); esp.Name:Remove(); esp.Dist:Remove(); esp.HealthText:Remove(); esp.Weapon:Remove() end)
        ESPObjects[p] = nil 
    end 
end

local function CreateESP(p)
    RemoveESP(p)
    local esp = {}
    for i=1, 4 do 
        esp["Box"..i] = Drawing.new("Line"); esp["Box"..i].Thickness = 1.5; esp["Box"..i].Visible = false 
    end
    esp.Name = Drawing.new("Text"); esp.Name.Size = 15; esp.Name.Center = true; esp.Name.Outline = true; esp.Name.Font = 2; esp.Name.Color = Color3.fromRGB(255, 255, 255); esp.Name.Visible = false
    esp.Dist = Drawing.new("Text"); esp.Dist.Size = 13; esp.Dist.Center = true; esp.Dist.Outline = true; esp.Dist.Color = Color3.fromRGB(255, 200, 0); esp.Dist.Visible = false
    esp.Weapon = Drawing.new("Text"); esp.Weapon.Size = 14; esp.Weapon.Center = true; esp.Weapon.Outline = true; esp.Weapon.Color = Color3.fromRGB(255, 150, 50); esp.Weapon.Visible = false
    esp.HealthText = Drawing.new("Text"); esp.HealthText.Size = 14; esp.HealthText.Center = true; esp.HealthText.Outline = true; esp.HealthText.Color = Color3.fromRGB(0, 255, 0); esp.HealthText.Visible = false
    ESPObjects[p] = esp
end

local function CleanupChams(p) 
    if ChamsObjects[p] then ChamsObjects[p]:Destroy(); ChamsObjects[p] = nil end 
end

table.insert(Connections, Players.PlayerRemoving:Connect(function(p) RemoveESP(p); CleanupChams(p); if p.Character and p.Character:FindFirstChild("Head") then OriginalHeadSizes[p.Character.Head] = nil end end))
for _, p in pairs(Players:GetPlayers()) do 
    if p ~= LocalPlayer then 
        CreateESP(p)
        table.insert(Connections, p.CharacterAdded:Connect(function() CreateESP(p); CleanupChams(p) end)) 
    end 
end
table.insert(Connections, Players.PlayerAdded:Connect(function(p) 
    if p ~= LocalPlayer then 
        CreateESP(p)
        table.insert(Connections, p.CharacterAdded:Connect(function() CreateESP(p); CleanupChams(p) end)) 
    end 
end))

local function UpdateESP()
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("Humanoid") or LocalPlayer.Character.Humanoid.Health <= 0 then
        for _, esp in pairs(ESPObjects) do esp.Box1.Visible = false; esp.Box2.Visible = false; esp.Box3.Visible = false; esp.Box4.Visible = false; esp.Name.Visible = false; esp.Dist.Visible = false; esp.HealthText.Visible = false; esp.Weapon.Visible = false end
        for _, chams in pairs(ChamsObjects) do chams.Enabled = false end
        return
    end
    local espColor = Config.ESPColor
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local char = p.Character
            if char and char:FindFirstChild("Humanoid") and char:FindFirstChild("Head") then
                local hum = char.Humanoid; local hrp = char:FindFirstChild("HumanoidRootPart"); local head = char:FindFirstChild("Head")
                if hum.Health > 0 and hrp and head then
                    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"); local dist = (myRoot and hrp) and math.floor((myRoot.Position - hrp.Position).Magnitude) or 0
                    if dist <= Config.ESPMaxDist then
                        
                        -- ФИКС: Если это друг, ПОЛНОСТЬЮ отключаем ESP и Chams
                        if Friends[p] then
                            if Config.ChamsEnabled then CleanupChams(p) end 
                            if ESPObjects[p] then
                                local esp = ESPObjects[p]
                                esp.Box1.Visible = false; esp.Box2.Visible = false; esp.Box3.Visible = false; esp.Box4.Visible = false
                                esp.Name.Visible = false; esp.Dist.Visible = false; esp.HealthText.Visible = false; esp.Weapon.Visible = false
                            end
                            continue 
                        end
                        
                        if Config.ChamsEnabled then
                            if not ChamsObjects[p] or ChamsObjects[p].Parent ~= char then CleanupChams(p); local chams = Instance.new("Highlight"); chams.FillTransparency = 0.5; chams.OutlineTransparency = 0; chams.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; chams.Parent = char; ChamsObjects[p] = chams end
                            local chams = ChamsObjects[p]; chams.Enabled = true
                            if tick() - (chams:GetAttribute("LastCheck") or 0) > 0.1 then chams:SetAttribute("LastCheck", tick()); if IsVisible(char) then chams.FillColor = Color3.fromRGB(0, 255, 0); chams.OutlineColor = Color3.fromRGB(0, 255, 0) else chams.FillColor = Color3.fromRGB(255, 0, 0); chams.OutlineColor = Color3.fromRGB(255, 255, 255) end end
                        else CleanupChams(p) end
                        
                        if Config.ESPEnabled then
                            if not ESPObjects[p] then CreateESP(p) end
                            local esp = ESPObjects[p]; local screenHead, onScreen = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0)); local screenRoot, onScreenRoot = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 2.5, 0))
                            if onScreen and onScreenRoot and screenHead.Z > 0 and screenRoot.Z > 0 then
                                local height = math.abs(screenHead.Y - screenRoot.Y); if height < 15 then height = 15 end
                                local width = height * 0.55; local x, y = screenHead.X - (width / 2), screenHead.Y; local length = width * 0.25
                                for i=1, 4 do esp["Box"..i].Color = espColor end
                                esp.Box1.From = Vector2.new(x, y); esp.Box1.To = Vector2.new(x + length, y); esp.Box2.From = Vector2.new(x, y); esp.Box2.To = Vector2.new(x, y + length); esp.Box3.From = Vector2.new(x + width, y + height); esp.Box3.To = Vector2.new(x + width - length, y + height); esp.Box4.From = Vector2.new(x + width, y + height); esp.Box4.To = Vector2.new(x + width, y + height - length)
                                esp.Box1.Visible = true; esp.Box2.Visible = true; esp.Box3.Visible = true; esp.Box4.Visible = true
                                esp.Name.Text = p.Name; esp.Name.Position = Vector2.new(screenHead.X, y - 45); esp.Name.Visible = true; esp.Dist.Text = "[" .. dist .. "m]"; esp.Dist.Position = Vector2.new(screenHead.X, y - 30); esp.Dist.Visible = true
                                if Config.ESPWeapon then local weaponName = GetWeaponName(char); if weaponName then esp.Weapon.Text = "[" .. GetShortWeaponName(weaponName) .. "]"; esp.Weapon.Position = Vector2.new(screenHead.X, y - 15); esp.Weapon.Visible = true else esp.Weapon.Visible = false end else esp.Weapon.Visible = false end
                                if Config.ESPHealthText then esp.HealthText.Text = "HP: " .. math.floor(hum.Health); esp.HealthText.Position = Vector2.new(screenHead.X, y + height + 5); if hum.Health > 50 then esp.HealthText.Color = Color3.fromRGB(0, 255, 0) elseif hum.Health > 25 then esp.HealthText.Color = Color3.fromRGB(255, 200, 0) else esp.HealthText.Color = Color3.fromRGB(255, 50, 50) end; esp.HealthText.Visible = true else esp.HealthText.Visible = false end
                            else esp.Box1.Visible = false; esp.Box2.Visible = false; esp.Box3.Visible = false; esp.Box4.Visible = false; esp.Name.Visible = false; esp.Dist.Visible = false; esp.HealthText.Visible = false; esp.Weapon.Visible = false end
                        elseif ESPObjects[p] then ESPObjects[p].Box1.Visible = false; ESPObjects[p].Box2.Visible = false; ESPObjects[p].Box3.Visible = false; ESPObjects[p].Box4.Visible = false; ESPObjects[p].Name.Visible = false; ESPObjects[p].Dist.Visible = false; ESPObjects[p].HealthText.Visible = false; ESPObjects[p].Weapon.Visible = false end
                    else 
                        if ESPObjects[p] then ESPObjects[p].Box1.Visible = false; ESPObjects[p].Box2.Visible = false; ESPObjects[p].Box3.Visible = false; ESPObjects[p].Box4.Visible = false; ESPObjects[p].Name.Visible = false; ESPObjects[p].Dist.Visible = false; ESPObjects[p].HealthText.Visible = false; ESPObjects[p].Weapon.Visible = false end; CleanupChams(p) 
                    end
                end
            end
        end
    end
end

local function GetTarget()
    if not Config.AimbotEnabled or not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("Humanoid") or LocalPlayer.Character.Humanoid.Health <= 0 then return nil end
    local closest = nil; local shortestDist = Config.FOV; local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and not Friends[p] and p.Character and p.Character:FindFirstChild("Humanoid") then 
            local hum = p.Character.Humanoid; local hrp = p.Character:FindFirstChild("HumanoidRootPart"); local head = p.Character:FindFirstChild("Head")
            if hum.Health > 0 and hrp and head then
                local targetPos = (head.Position + hrp.Position) / 2 
                if Config.VisibleAim then
                    local rayParams = RaycastParams.new(); rayParams.FilterType = Enum.RaycastFilterType.Exclude; rayParams.FilterDescendantsInstances = {LocalPlayer.Character, p.Character}
                    local ray = workspace:Raycast(Camera.CFrame.Position, targetPos - Camera.CFrame.Position, rayParams)
                    if ray then continue end
                end
                local screenPos, onScreen = Camera:WorldToViewportPoint(targetPos)
                if onScreen and screenPos.Z > 0 then
                    local dist = (screenCenter - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
                    if dist < shortestDist then
                        shortestDist = dist; local finalPos = targetPos
                        if Config.Prediction then local velocity = hrp.AssemblyLinearVelocity; local worldDist = (Camera.CFrame.Position - targetPos).Magnitude; local bulletTravelTime = worldDist * 0.0006; finalPos = finalPos + (velocity * bulletTravelTime) end
                        closest = { player = p, pos = finalPos }
                    end
                end
            end
        end
    end
    return closest
end

-- ============================================================================
-- MAIN LOOPS
-- ============================================================================
table.insert(Connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if State.Unloaded then return end
    if input.KeyCode == Config.PanicKey then FullCleanup(); return end
    if input.UserInputType == Binds.Aimbot or input.KeyCode == Binds.Aimbot then State.HoldingKey = true
    elseif input.UserInputType == Binds.Prediction or input.KeyCode == Binds.Prediction then 
        Config.Prediction = not Config.Prediction
        WindUI:Notify({ Title = "Prediction", Content = Config.Prediction and "Enabled" or "Disabled", Icon = "check" })
    elseif input.UserInputType == Binds.AddFriend or input.KeyCode == Binds.AddFriend then AddClosestToFriend() end
end))

table.insert(Connections, UserInputService.InputEnded:Connect(function(input, gameProcessed) 
    if State.Unloaded then return end
    if input.UserInputType == Binds.Aimbot or input.KeyCode == Binds.Aimbot then State.HoldingKey = false end 
end))

local hudUpdateTimer = 0
table.insert(Connections, RunService.RenderStepped:Connect(function(deltaTime)
    if State.Unloaded then return end
    State.Frames = State.Frames + 1; State.Time = State.Time + deltaTime
    if State.Time >= 1 then 
        State.FPS = math.floor(State.Frames / State.Time); State.Frames = 0; State.Time = 0
        if Config.HUDEnabled then WMFPS.Text = "FPS: " .. State.FPS end 
    end
    if Config.HUDEnabled then 
        hudUpdateTimer = hudUpdateTimer + deltaTime
        if hudUpdateTimer > 0.5 then UpdateHUD(); hudUpdateTimer = 0 end 
    end
    pcall(function() 
        if Config.AimbotEnabled then 
            FOVCircle.Visible = true; FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2); FOVCircle.Radius = Config.FOV 
        else 
            FOVCircle.Visible = false 
        end 
    end)
    UpdateCrosshair()
    if Config.ESPEnabled or Config.ChamsEnabled then pcall(UpdateESP) end
end))

table.insert(Connections, task.spawn(function()
    while not State.Unloaded do
        if Config.HeadSizeEnabled then pcall(UpdateHeadSize) end
        if Config.ItemESPEnabled then pcall(UpdateItemESP) end
        if Config.DroneESPEnabled then pcall(UpdateDroneESP) end 
        if Config.ShowDeathMarkers then pcall(UpdateDeathMarkers) end
        if Config.XRayEnabled then pcall(ApplyXRay) end
        task.wait(0.2)
    end
end))

table.insert(Connections, RunService.Heartbeat:Connect(function()
    if State.Unloaded or not Config.AimbotEnabled or not State.HoldingKey then return end
    local target = GetTarget()
    if target and Config.AimbotMethod == "Camera" then 
        local camPos = Camera.CFrame.Position; local targetCFrame = CFrame.new(camPos, target.pos); Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, Config.Smoothness) 
    end
end))

UpdateHUD(); WMFPS.Text = "FPS: 60"
WindUI:Notify({ Title = "Hook Fust Loaded", Content = "Нажми RightShift для меню.", Icon = "check", Duration = 5 })
