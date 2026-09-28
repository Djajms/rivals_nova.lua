-- language: Luau, file: nova_rivals.lua
-- NOVA — Rivals cheat | self-contained UI, no external deps
-- executor: Delta

-- ═══════════════════════════════════════════════════════════════════════
-- SERVICES
-- ═══════════════════════════════════════════════════════════════════════
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace        = game:GetService("Workspace")
local Lighting         = game:GetService("Lighting")
local SoundService     = game:GetService("SoundService")
local TweenService     = game:GetService("TweenService")
local CoreGui          = game:GetService("CoreGui")
local LP = Players.LocalPlayer

-- ── camera извлекаем каждый раз, не кешируем
local function getCam() return Workspace.CurrentCamera end

-- ── Drawing API — проверка
local HAS_DRAWING = (typeof(Drawing) ~= "nil" and typeof(Drawing.new) == "function")

-- ═══════════════════════════════════════════════════════════════════════
-- PALETTE — sakura, no green
-- ═══════════════════════════════════════════════════════════════════════
local C = {
    bg        = Color3.fromRGB(255, 244, 248),
    bgDeep    = Color3.fromRGB(250, 226, 234),
    bgSoft    = Color3.fromRGB(255, 236, 242),
    glass     = Color3.fromRGB(255, 250, 252),
    stroke    = Color3.fromRGB(240, 190, 210),
    strokeDeep= Color3.fromRGB(220, 140, 172),
    accent    = Color3.fromRGB(228, 130, 168),
    accentDeep= Color3.fromRGB(178, 88, 128),
    accentSoft= Color3.fromRGB(248, 180, 202),
    rose      = Color3.fromRGB(232, 112, 152),
    peach     = Color3.fromRGB(255, 196, 170),
    cream     = Color3.fromRGB(255, 240, 224),
    lavender  = Color3.fromRGB(214, 180, 220),
    text      = Color3.fromRGB(82, 52, 66),
    textMuted = Color3.fromRGB(160, 130, 146),
    textLight = Color3.fromRGB(255, 250, 252),
    shadow    = Color3.fromRGB(150, 100, 128),
    off       = Color3.fromRGB(230, 214, 222),
    sun       = Color3.fromRGB(255, 232, 190),
}

-- ═══════════════════════════════════════════════════════════════════════
-- CONFIG
-- ═══════════════════════════════════════════════════════════════════════
local CFG = {
    ESP = {
        Enabled=true, Box=true, Name=true, Distance=true, Health=true,
        Snapline=false, MaxDist=1000,
        ColEnemy=C.rose, ColTeam=C.lavender, ColVis=C.sun,
    },
    AIM = {
        Enabled=false, Key="MouseButton2", Wallbang=false, VisibleOnly=true,
        IgnoreTeam=true, Smooth=0.18, FOV=150, MaxDist=1000, Bone="Head",
    },
    TRIG = {
        Enabled=false, AutoFire=false, DelayMs=40, FOV=22, Bone="UpperTorso",
    },
    SND = {
        Hit = {on=true, vol=1.0, ids={"rbxassetid://9114132802","rbxassetid://9120386436"}},
        Kill= {on=true, vol=1.0, ids={"rbxassetid://9125402232"}},
        HS  = {on=true, vol=1.2, ids={"rbxassetid://5810753582"}},
    },
    SKY = {Current="default"},
}

-- ── keymap
local KEYMAP = {
    ["MouseButton1"]=Enum.UserInputType.MouseButton1,
    ["MouseButton2"]=Enum.UserInputType.MouseButton2,
    ["LeftShift"]=Enum.KeyCode.LeftShift, ["RightShift"]=Enum.KeyCode.RightShift,
    ["LeftControl"]=Enum.KeyCode.LeftControl, ["LeftAlt"]=Enum.KeyCode.LeftAlt,
    ["E"]=Enum.KeyCode.E, ["Q"]=Enum.KeyCode.Q, ["F"]=Enum.KeyCode.F,
    ["C"]=Enum.KeyCode.C, ["V"]=Enum.KeyCode.V, ["X"]=Enum.KeyCode.X,
    ["Z"]=Enum.KeyCode.Z, ["G"]=Enum.KeyCode.G, ["H"]=Enum.KeyCode.H,
    ["T"]=Enum.KeyCode.T, ["R"]=Enum.KeyCode.R,
}
local function matchesKey(i,k)
    local t = KEYMAP[k]; if not t then return false end
    return i.UserInputType == t or i.KeyCode == t
end

-- ═══════════════════════════════════════════════════════════════════════
-- SKY
-- ═══════════════════════════════════════════════════════════════════════
local SKY = {
    default = {ct=14, br=2, amb=0.5, fog=500, fc=Color3.fromRGB(200,180,210), oa=Color3.fromRGB(128,128,128)},
    dawn    = {ct=6,  br=2.5, amb=0.75, fog=900, fc=Color3.fromRGB(255,186,148), oa=Color3.fromRGB(206,158,136)},
    sunset  = {ct=17.6,br=2.5,amb=0.8, fog=1200,fc=Color3.fromRGB(255,164,124), oa=Color3.fromRGB(240,152,116)},
    pink    = {ct=5.6,br=2.3, amb=0.85,fog=1500,fc=Color3.fromRGB(255,196,218), oa=Color3.fromRGB(250,196,214)},
    purple  = {ct=19, br=1.9, amb=0.65,fog=1000,fc=Color3.fromRGB(196,158,220), oa=Color3.fromRGB(168,132,196)},
    night   = {ct=0,  br=0.8, amb=0.2, fog=350, fc=Color3.fromRGB(36,32,68),    oa=Color3.fromRGB(56,50,88)},
}
local function applySky(n)
    local s = SKY[n]; if not s then return end
    Lighting.ClockTime = s.ct
    Lighting.Brightness = s.br
    Lighting.Ambient = Color3.new(s.amb,s.amb,s.amb)
    Lighting.OutdoorAmbient = s.oa
    Lighting.FogEnd = s.fog
    Lighting.FogColor = s.fc
    CFG.SKY.Current = n
end

-- ═══════════════════════════════════════════════════════════════════════
-- SOUNDS
-- ═══════════════════════════════════════════════════════════════════════
local function playSnd(ids, vol)
    if not ids or #ids == 0 then return end
    local s = Instance.new("Sound")
    s.SoundId = ids[math.random(#ids)]
    s.Volume = vol or 1
    s.Parent = SoundService
    s:Play()
    game:GetService("Debris"):AddItem(s, 3)
end

local lastHP, watched = {}, {}

local function hookHum(plr, hum)
    if not hum then return end
    lastHP[plr] = hum.Health
    hum.HealthChanged:Connect(function(n)
        local o = lastHP[plr] or n
        if o > n and o > 0 then
            local dmg = o - n
            if plr ~= LP then
                if n <= 0 then
                    if CFG.SND.Kill.on then playSnd(CFG.SND.Kill.ids, CFG.SND.Kill.vol) end
                elseif CFG.SND.Hit.on then
                    if dmg > 80 and CFG.SND.HS.on then
                        playSnd(CFG.SND.HS.ids, CFG.SND.HS.vol)
                    else
                        playSnd(CFG.SND.Hit.ids, CFG.SND.Hit.vol)
                    end
                end
            end
        end
        lastHP[plr] = n
    end)
end

local function attach(plr)
    if plr == LP or watched[plr] then return end
    watched[plr] = true
    -- ФИКС: если персонаж уже есть — хук сразу, не ждём CharacterAdded
    if plr.Character then
        local hum = plr.Character:FindFirstChildOfClass("Humanoid")
        if hum then hookHum(plr, hum) end
    end
    plr.CharacterAdded:Connect(function(ch)
        local hum = ch:WaitForChild("Humanoid", 5)
        if hum then hookHum(plr, hum) end
    end)
end

for _, p in ipairs(Players:GetPlayers()) do attach(p) end
Players.PlayerAdded:Connect(attach)
Players.PlayerRemoving:Connect(function(p) watched[p]=nil; lastHP[p]=nil end)

-- ═══════════════════════════════════════════════════════════════════════
-- ESP (Drawing) — только если Drawing есть
-- ═══════════════════════════════════════════════════════════════════════
local espO = {}

local function w2s(p)
    local cam = getCam()
    if not cam then return nil end
    local sp, on = cam:WorldToViewportPoint(p)
    if not on or sp.Z <= 0 then return nil end
    return Vector2.new(sp.X, sp.Y)
end

local function createESP(plr)
    if not HAS_DRAWING then return end
    if plr == LP or espO[plr] then return end
    espO[plr] = {
        box=Drawing.new("Square"), name=Drawing.new("Text"),
        dist=Drawing.new("Text"), snap=Drawing.new("Line"),
        hpBg=Drawing.new("Line"), hpFg=Drawing.new("Line"),
    }
    local o = espO[plr]
    o.box.Filled=false; o.box.Thickness=1.5; o.box.Transparency=1; o.box.Visible=false
    o.name.Size=13; o.name.Center=true; o.name.Outline=true; o.name.Visible=false
    o.dist.Size=12; o.dist.Center=true; o.dist.Outline=true; o.dist.Visible=false
    o.snap.Thickness=1; o.snap.Visible=false
    o.hpBg.Thickness=4; o.hpBg.Visible=false
    o.hpFg.Thickness=4; o.hpFg.Visible=false
end

local function removeESP(plr)
    if espO[plr] then
        for _,o in pairs(espO[plr]) do pcall(function() o:Remove() end) end
        espO[plr]=nil
    end
end

local function updateESP()
    if not HAS_DRAWING then return end
    if not CFG.ESP.Enabled then
        for _,o in pairs(espO) do
            o.box.Visible,o.name.Visible,o.dist.Visible,o.snap.Visible=false,false,false,false
            o.hpBg.Visible,o.hpFg.Visible=false,false
        end
        return
    end
    local lpCh = LP.Character
    local lpHRP = lpCh and lpCh:FindFirstChild("HumanoidRootPart")
    if not lpHRP then return end
    local lTeam = LP.Team

    for plr, o in pairs(espO) do
        local ch = plr.Character
        local hum = ch and ch:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then
            o.box.Visible,o.name.Visible,o.dist.Visible,o.snap.Visible=false,false,false,false
            o.hpBg.Visible,o.hpFg.Visible=false,false
            continue
        end
        local hrp = ch:FindFirstChild("HumanoidRootPart")
        local head = ch:FindFirstChild("Head")
        if not hrp or not head then continue end

        local d = (hrp.Position - lpHRP.Position).Magnitude
        if d > CFG.ESP.MaxDist then
            o.box.Visible,o.name.Visible,o.dist.Visible,o.snap.Visible=false,false,false,false
            o.hpBg.Visible,o.hpFg.Visible=false,false
            continue
        end

        local hp = w2s(head.Position + Vector3.new(0,1,0))
        local fp = w2s(hrp.Position - Vector3.new(0,3,0))
        if not hp or not fp then
            o.box.Visible,o.name.Visible,o.dist.Visible,o.snap.Visible=false,false,false,false
            o.hpBg.Visible,o.hpFg.Visible=false,false
            continue
        end

        local hh = math.abs(hp.Y - fp.Y)
        local ww = hh / 1.8
        local isEnemy = (not lTeam) or (plr.Team ~= lTeam)
        local col = isEnemy and CFG.ESP.ColEnemy or CFG.ESP.ColTeam

        if CFG.ESP.Box then
            o.box.Size = Vector2.new(ww, hh)
            o.box.Position = Vector2.new(hp.X - ww/2, hp.Y)
            o.box.Color = col; o.box.Visible = true
        end
        if CFG.ESP.Name then
            o.name.Text = plr.Name
            o.name.Position = Vector2.new(hp.X, hp.Y - 16)
            o.name.Color = col; o.name.Visible = true
        end
        if CFG.ESP.Distance then
            o.dist.Text = string.format("[%.0fm]", d)
            o.dist.Position = Vector2.new(hp.X, fp.Y + 2)
            o.dist.Color = col; o.dist.Visible = true
        end
        if CFG.ESP.Snapline then
            local vp = getCam().ViewportSize
            o.snap.From = Vector2.new(vp.X/2, vp.Y)
            o.snap.To = Vector2.new(fp.X, fp.Y)
            o.snap.Color = col; o.snap.Visible = true
        end
        if CFG.ESP.Health and hum then
            local pct = hum.Health / hum.MaxHealth
            local bx = hp.X - ww/2 - 6
            o.hpBg.From = Vector2.new(bx, hp.Y)
            o.hpBg.To = Vector2.new(bx, fp.Y)
            o.hpBg.Color = Color3.new(0,0,0); o.hpBg.Visible = true
            local c2 = pct > 0.6 and C.peach or pct > 0.3 and C.sun or C.rose
            o.hpFg.From = Vector2.new(bx, fp.Y - (fp.Y-hp.Y)*pct)
            o.hpFg.To = Vector2.new(bx, fp.Y)
            o.hpFg.Color = c2; o.hpFg.Visible = true
        end
    end
end

for _, p in ipairs(Players:GetPlayers()) do createESP(p) end
Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function() task.wait(0.3); createESP(p) end)
end)
Players.PlayerRemoving:Connect(removeESP)
RunService.RenderStepped:Connect(function() pcall(updateESP) end)

-- ═══════════════════════════════════════════════════════════════════════
-- AIM + TRIGGER
-- ═══════════════════════════════════════════════════════════════════════
local aimActive = false
UserInputService.InputBegan:Connect(function(i, g)
    if g then return end
    if matchesKey(i, CFG.AIM.Key) then aimActive = true end
end)
UserInputService.InputEnded:Connect(function(i)
    if matchesKey(i, CFG.AIM.Key) then aimActive = false end
end)

local function getTargets(bone)
    local out = {}
    local cam = getCam(); if not cam then return out end
    local lpCh = LP.Character
    local lpHRP = lpCh and lpCh:FindFirstChild("HumanoidRootPart")
    if not lpHRP then return out end
    local center = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LP then continue end
        local ch = plr.Character
        local hum = ch and ch:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then continue end
        if CFG.AIM.IgnoreTeam and LP.Team and plr.Team == LP.Team then continue end

        local hrp = ch:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end

        local pos = (ch:FindFirstChild(bone) or hrp).Position
        local dist = (hrp.Position - lpHRP.Position).Magnitude
        if dist > CFG.AIM.MaxDist then continue end

        if CFG.AIM.VisibleOnly and not CFG.AIM.Wallbang then
            local p = RaycastParams.new()
            p.FilterType = Enum.RaycastFilterType.Exclude
            p.FilterDescendantsInstances = {lpCh, cam}
            local r = Workspace:Raycast(cam.CFrame.Position, pos - cam.CFrame.Position, p)
            if r and not r.Instance:IsDescendantOf(ch) then continue end
        end

        local screen = w2s(pos)
        if not screen then continue end

        table.insert(out, {
            plr=plr, ch=ch, pos=pos, screen=screen,
            screenD=(screen-center).Magnitude, dist=dist,
        })
    end
    return out
end

local function bestTarget(fov, bone)
    local best, bd = nil, fov
    for _, t in ipairs(getTargets(bone)) do
        if t.screenD < bd then best, bd = t, t.screenD end
    end
    return best
end

RunService.RenderStepped:Connect(function(dt)
    if not CFG.AIM.Enabled or not aimActive then return end
    local cam = getCam(); if not cam then return end
    local t = bestTarget(CFG.AIM.FOV, CFG.AIM.Bone)
    if not t then return end
    local from = cam.CFrame.Position
    local dir = (t.pos - from).Unit
    cam.CFrame = cam.CFrame:Lerp(CFrame.lookAt(from, from + dir), CFG.AIM.Smooth)
end)

local lastFire = 0
RunService.Heartbeat:Connect(function()
    if not CFG.TRIG.Enabled then return end
    local t = bestTarget(CFG.TRIG.FOV, CFG.TRIG.Bone)
    if not t then return end
    local now = tick() * 1000
    if now - lastFire < CFG.TRIG.DelayMs then return end
    lastFire = now
    if CFG.TRIG.AutoFire then
        pcall(function()
            local tool = LP.Character and LP.Character:FindFirstChildOfClass("Tool")
            if tool then tool:Activate() end
        end)
    end
end)

-- ═══════════════════════════════════════════════════════════════════════
-- UI — self-contained, no external deps
-- ═══════════════════════════════════════════════════════════════════════

-- удалить старую копию если есть
pcall(function()
    local old = CoreGui:FindFirstChild("NOVA_Sakura")
    if old then old:Destroy() end
end)

local gui = Instance.new("ScreenGui")
gui.Name = "NOVA_Sakura"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.IgnoreGuiInset = true
pcall(function() gui.Parent = CoreGui end)
if not gui.Parent then gui.Parent = LP:WaitForChild("PlayerGui") end

-- ─── ГЛАВНОЕ ОКНО ────────────────────────────────────────────────────
local win = Instance.new("Frame")
win.Name = "Main"
win.Size = UDim2.new(0, 400, 0, 500)
win.Position = UDim2.new(0, 60, 0, 100)
win.BackgroundColor3 = C.bg
win.BackgroundTransparency = 0.05
win.BorderSizePixel = 0
win.Visible = true
win.Active = true
win.Draggable = true
win.Parent = gui

local winCorner = Instance.new("UICorner")
winCorner.CornerRadius = UDim.new(0, 14)
winCorner.Parent = win

local winStroke = Instance.new("UIStroke")
winStroke.Color = C.stroke
winStroke.Thickness = 1.5
winStroke.Transparency = 0.2
winStroke.Parent = win

local winGrad = Instance.new("UIGradient")
winGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, C.bg),
    ColorSequenceKeypoint.new(0.5, C.bgSoft),
    ColorSequenceKeypoint.new(1, C.bgDeep),
})
winGrad.Rotation = 135
winGrad.Parent = win

-- ─── HEADER ──────────────────────────────────────────────────────────
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 48)
header.BackgroundColor3 = C.accent
header.BackgroundTransparency = 0.15
header.BorderSizePixel = 0
header.Parent = win

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 14)
headerCorner.Parent = header

local headerFix = Instance.new("Frame")
headerFix.Size = UDim2.new(1, 0, 0, 14)
headerFix.Position = UDim2.new(0, 0, 1, -14)
headerFix.BackgroundColor3 = C.accent
headerFix.BackgroundTransparency = 0.15
headerFix.BorderSizePixel = 0
headerFix.Parent = header

local headerGrad = Instance.new("UIGradient")
headerGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, C.accentSoft),
    ColorSequenceKeypoint.new(1, C.accentDeep),
})
headerGrad.Rotation = 0
headerGrad.Parent = header

local title = Instance.new("TextLabel")
title.Text = "❀  NOVA"
title.Size = UDim2.new(1, -50, 0, 24)
title.Position = UDim2.new(0, 16, 0, 8)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextColor3 = C.textLight
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local subtitle = Instance.new("TextLabel")
subtitle.Text = "sakura edition  ·  by eumov"
subtitle.Size = UDim2.new(1, -50, 0, 14)
subtitle.Position = UDim2.new(0, 16, 0, 28)
subtitle.BackgroundTransparency = 1
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 11
subtitle.TextColor3 = C.textLight
subtitle.TextTransparency = 0.15
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = header

local closeBtn = Instance.new("TextButton")
closeBtn.Text = "✕"
closeBtn.Size = UDim2.new(0, 28, 0, 24)
closeBtn.Position = UDim2.new(1, -36, 0, 12)
closeBtn.BackgroundColor3 = C.accentDeep
closeBtn.BackgroundTransparency = 0.4
closeBtn.BorderSizePixel = 0
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.TextColor3 = C.textLight
closeBtn.Parent = header

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeBtn

-- ─── TABS ────────────────────────────────────────────────────────────
local tabNames = {"ESP","Aim","Trig","Sound","Sky","Misc"}
local tabBar = Instance.new("Frame")
tabBar.Name = "Tabs"
tabBar.Size = UDim2.new(1, -16, 0, 34)
tabBar.Position = UDim2.new(0, 8, 0, 54)
tabBar.BackgroundColor3 = C.bgDeep
tabBar.BackgroundTransparency = 0.4
tabBar.BorderSizePixel = 0
tabBar.Parent = win

local tabBarCorner = Instance.new("UICorner")
tabBarCorner.CornerRadius = UDim.new(0, 8)
tabBarCorner.Parent = tabBar

local tabBarLayout = Instance.new("UIListLayout")
tabBarLayout.FillDirection = Enum.FillDirection.Horizontal
tabBarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
tabBarLayout.VerticalAlignment = Enum.VerticalAlignment.Center
tabBarLayout.Padding = UDim.new(0, 2)
tabBarLayout.Parent = tabBar

local tabButtons = {}
local currentTab = 1

local contentHolder = Instance.new("ScrollingFrame")
contentHolder.Name = "Content"
contentHolder.Size = UDim2.new(1, -16, 1, -110)
contentHolder.Position = UDim2.new(0, 8, 0, 94)
contentHolder.BackgroundColor3 = C.glass
contentHolder.BackgroundTransparency = 0.7
contentHolder.BorderSizePixel = 0
contentHolder.ScrollBarThickness = 3
contentHolder.ScrollBarImageColor3 = C.accent
contentHolder.CanvasSize = UDim2.new(0, 0, 0, 0)
contentHolder.AutomaticCanvasSize = Enum.AutomaticSize.Y
contentHolder.Parent = win

local contentCorner = Instance.new("UICorner")
contentCorner.CornerRadius = UDim.new(0, 8)
contentCorner.Parent = contentHolder

local contentPad = Instance.new("UIPadding")
contentPad.PaddingTop = UDim.new(0, 6)
contentPad.PaddingBottom = UDim.new(0, 6)
contentPad.PaddingLeft = UDim.new(0, 6)
contentPad.PaddingRight = UDim.new(0, 6)
contentPad.Parent = contentHolder

local contentLayout = Instance.new("UIListLayout")
contentLayout.Padding = UDim.new(0, 4)
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Parent = contentHolder

-- создаём кнопки табов
for i, name in ipairs(tabNames) do
    local tb = Instance.new("TextButton")
    tb.Text = name
    tb.Size = UDim2.new(0, 58, 0, 26)
    tb.BackgroundColor3 = C.bgSoft
    tb.BackgroundTransparency = 0.5
    tb.BorderSizePixel = 0
    tb.Font = Enum.Font.GothamSemibold
    tb.TextSize = 12
    tb.TextColor3 = C.text
    tb.Parent = tabBar

    local tbCorner = Instance.new("UICorner")
    tbCorner.CornerRadius = UDim.new(0, 6)
    tbCorner.Parent = tb

    tb.MouseButton1Click:Connect(function()
        currentTab = i
        for j, b in ipairs(tabButtons) do
            if j == i then
                b.BackgroundColor3 = C.accent
                b.BackgroundTransparency = 0.15
                b.TextColor3 = C.textLight
            else
                b.BackgroundColor3 = C.bgSoft
                b.BackgroundTransparency = 0.5
                b.TextColor3 = C.text
            end
        end
        -- перерисовка контента
        for _, ch in ipairs(contentHolder:GetChildren()) do
            if ch:IsA("Frame") then ch:Destroy() end
        end
        if buildTab then buildTab(i) end
    end)

    table.insert(tabButtons, tb)
end

-- ─── UI HELPERS ──────────────────────────────────────────────────────
local function mkRow(parent, label, height)
    local row = Instance.new("Frame")
    row.Name = label or "row"
    row.Size = UDim2.new(1, -12, 0, height or 28)
    row.BackgroundColor3 = C.bgSoft
    row.BackgroundTransparency = 0.55
    row.BorderSizePixel = 0
    row.Parent = parent

    local rc = Instance.new("UICorner")
    rc.CornerRadius = UDim.new(0, 6)
    rc.Parent = row

    local lbl = Instance.new("TextLabel")
    lbl.Text = label or ""
    lbl.Size = UDim2.new(1, -70, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 13
    lbl.TextColor3 = C.text
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    return row, lbl
end

local function mkToggle(parent, label, getter, setter)
    local row = mkRow(parent, label, 28)

    local tgl = Instance.new("TextButton")
    tgl.Text = ""
    tgl.Size = UDim2.new(0, 36, 0, 18)
    tgl.Position = UDim2.new(1, -46, 0.5, -9)
    tgl.BorderSizePixel = 0
    tgl.Parent = row

    local tCorner = Instance.new("UICorner")
    tCorner.CornerRadius = UDim.new(1, 0)
    tCorner.Parent = tgl

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = UDim2.new(0, 2, 0.5, -7)
    knob.BackgroundColor3 = C.textLight
    knob.BorderSizePixel = 0
    knob.Parent = tgl

    local kCorner = Instance.new("UICorner")
    kCorner.CornerRadius = UDim.new(1, 0)
    kCorner.Parent = knob

    local function refresh()
        local v = getter()
        tgl.BackgroundColor3 = v and C.accent or C.off
        TweenService:Create(knob, TweenInfo.new(0.15), {
            Position = v and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7),
            BackgroundColor3 = v and C.textLight or C.textMuted,
        }):Play()
    end
    refresh()

    tgl.MouseButton1Click:Connect(function()
        setter(not getter())
        refresh()
    end)
    return row
end

local function mkButton(parent, label, action)
    local row = mkRow(parent, label, 28)
    local btn = Instance.new("TextButton")
    btn.Text = "▶"
    btn.Size = UDim2.new(0, 30, 0, 20)
    btn.Position = UDim2.new(1, -40, 0.5, -10)
    btn.BackgroundColor3 = C.accentSoft
    btn.BackgroundTransparency = 0.3
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.TextColor3 = C.text
    btn.Parent = row

    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, 5)
    bc.Parent = btn

    btn.MouseButton1Click:Connect(function()
        pcall(action)
        btn.BackgroundColor3 = C.accent
        task.wait(0.12)
        btn.BackgroundColor3 = C.accentSoft
    end)
    return row
end

local function mkSlider(parent, label, min, max, getter, setter)
    local row = mkRow(parent, label, 36)

    local valLbl = Instance.new("TextLabel")
    valLbl.Text = tostring(getter())
    valLbl.Size = UDim2.new(0, 50, 0, 14)
    valLbl.Position = UDim2.new(1, -60, 0, 2)
    valLbl.BackgroundTransparency = 1
    valLbl.Font = Enum.Font.GothamBold
    valLbl.TextSize = 11
    valLbl.TextColor3 = C.accentDeep
    valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.Parent = row

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -20, 0, 6)
    bar.Position = UDim2.new(0, 10, 1, -14)
    bar.BackgroundColor3 = C.off
    bar.BorderSizePixel = 0
    bar.Parent = row

    local barC = Instance.new("UICorner")
    barC.CornerRadius = UDim.new(1, 0)
    barC.Parent = bar

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((getter()-min)/(max-min), 0, 1, 0)
    fill.BackgroundColor3 = C.accent
    fill.BorderSizePixel = 0
    fill.Parent = bar

    local fillC = Instance.new("UICorner")
    fillC.CornerRadius = UDim.new(1, 0)
    fillC.Parent = fill

    local dragging = false
    local function applyFromX(mx)
        local abs = bar.AbsolutePosition.X
        local absSize = bar.AbsoluteSize.X
        local t = math.clamp((mx - abs) / absSize, 0, 1)
        local v = min + (max - min) * t
        fill.Size = UDim2.new(t, 0, 1, 0)
        valLbl.Text = string.format("%.2f", v)
        setter(v)
    end

    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            applyFromX(input.Position.X)
        end
    end)
    bar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            applyFromX(input.Position.X)
        end
    end)

    return row
end

-- ─── BUILD TABS ──────────────────────────────────────────────────────
function buildTab(idx)
    local order = 0
    local function add(fr) fr.LayoutOrder = order; order = order + 1 end

    local name = tabNames[idx]

    if name == "ESP" then
        add(mkToggle(contentHolder, "Enable ESP", function() return CFG.ESP.Enabled end, function(v) CFG.ESP.Enabled=v end))
        add(mkToggle(contentHolder, "Box", function() return CFG.ESP.Box end, function(v) CFG.ESP.Box=v end))
        add(mkToggle(contentHolder, "Name", function() return CFG.ESP.Name end, function(v) CFG.ESP.Name=v end))
        add(mkToggle(contentHolder, "Distance", function() return CFG.ESP.Distance end, function(v) CFG.ESP.Distance=v end))
        add(mkToggle(contentHolder, "Health bar", function() return CFG.ESP.Health end, function(v) CFG.ESP.Health=v end))
        add(mkToggle(contentHolder, "Snapline", function() return CFG.ESP.Snapline end, function(v) CFG.ESP.Snapline=v end))
        add(mkSlider(contentHolder, "Max dist", 50, 3000, function() return CFG.ESP.MaxDist end, function(v) CFG.ESP.MaxDist=v end))
    elseif name == "Aim" then
        add(mkToggle(contentHolder, "Enable aim", function() return CFG.AIM.Enabled end, function(v) CFG.AIM.Enabled=v end))
        add(mkToggle(contentHolder, "Wallbang", function() return CFG.AIM.Wallbang end, function(v) CFG.AIM.Wallbang=v end))
        add(mkToggle(contentHolder, "Visible only", function() return CFG.AIM.VisibleOnly end, function(v) CFG.AIM.VisibleOnly=v end))
        add(mkToggle(contentHolder, "Ignore team", function() return CFG.AIM.IgnoreTeam end, function(v) CFG.AIM.IgnoreTeam=v end))
        add(mkSlider(contentHolder, "FOV", 10, 600, function() return CFG.AIM.FOV end, function(v) CFG.AIM.FOV=v end))
        add(mkSlider(contentHolder, "Smooth", 0.02, 1, function() return CFG.AIM.Smooth end, function(v) CFG.AIM.Smooth=v end))
        add(mkSlider(contentHolder, "Max dist", 50, 3000, function() return CFG.AIM.MaxDist end, function(v) CFG.AIM.MaxDist=v end))
    elseif name == "Trig" then
        add(mkToggle(contentHolder, "Enable trigger", function() return CFG.TRIG.Enabled end, function(v) CFG.TRIG.Enabled=v end))
        add(mkToggle(contentHolder, "Auto fire", function() return CFG.TRIG.AutoFire end, function(v) CFG.TRIG.AutoFire=v end))
        add(mkSlider(contentHolder, "Delay ms", 0, 500, function() return CFG.TRIG.DelayMs end, function(v) CFG.TRIG.DelayMs=v end))
        add(mkSlider(contentHolder, "Trigger FOV", 5, 100, function() return CFG.TRIG.FOV end, function(v) CFG.TRIG.FOV=v end))
    elseif name == "Sound" then
        add(mkToggle(contentHolder, "Hit sounds", function() return CFG.SND.Hit.on end, function(v) CFG.SND.Hit.on=v end))
        add(mkToggle(contentHolder, "Kill sounds", function() return CFG.SND.Kill.on end, function(v) CFG.SND.Kill.on=v end))
        add(mkToggle(contentHolder, "Headshot snd", function() return CFG.SND.HS.on end, function(v) CFG.SND.HS.on=v end))
        add(mkButton(contentHolder, "Test hit", function() playSnd(CFG.SND.Hit.ids, CFG.SND.Hit.vol) end))
        add(mkButton(contentHolder, "Test kill", function() playSnd(CFG.SND.Kill.ids, CFG.SND.Kill.vol) end))
    elseif name == "Sky" then
        for _, preset in ipairs({"default","dawn","sunset","pink","purple","night"}) do
            add(mkButton(contentHolder, "Sky: " .. preset, function() applySky(preset) end))
        end
    elseif name == "Misc" then
        add(mkSlider(contentHolder, "WalkSpeed", 16, 200, function()
            local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            return h and h.WalkSpeed or 16
        end, function(v)
            local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            if h then h.WalkSpeed = v end
        end))
        add(mkSlider(contentHolder, "JumpPower", 50, 300, function()
            local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            return h and h.JumpPower or 50
        end, function(v)
            local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            if h then h.JumpPower = v end
        end))
    end
end

-- запуск первого таба
tabButtons[1].BackgroundColor3 = C.accent
tabButtons[1].BackgroundTransparency = 0.15
tabButtons[1].TextColor3 = C.textLight
buildTab(1)

-- ─── CLOSE ───────────────────────────────────────────────────────────
closeBtn.MouseButton1Click:Connect(function()
    gui.Enabled = false
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        gui.Enabled = not gui.Enabled
    end
end)

print("[NOVA] loaded. RightShift — toggle menu.")
