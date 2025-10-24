-- Death Client v1.0.0 - All-in-one LocalScript
local startTime = tick()

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local plr = Players.LocalPlayer
local gui = plr:WaitForChild("PlayerGui")
local cam = Workspace.CurrentCamera
local mouse = plr:GetMouse()

-- Character refs (auto-update on respawn)
local char = plr.Character or plr.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")
local hrp = char:WaitForChild("HumanoidRootPart")
plr.CharacterAdded:Connect(function(c)
    char = c
    hum = char:WaitForChild("Humanoid")
    hrp = char:WaitForChild("HumanoidRootPart")
end)

-- Config
local config = {
    version = "1.0.0",
    normal = {
        movement = {
            speed = { enabled = false, default = 16, speed = 32 }, -- default set later to actual hum value
            jump = { enabled = false, defaultPower = 50, defaultHeight = 7, power = 70, height = 7.2 },
            infiniteJump = { enabled = false, mode = "state" },
            fly = { enabled = false, speed = 100 },
        },
        visual = {
            esp = { enabled = false, team = "any", player = "any", mode = "any", color = Color3.fromRGB(255,50,50) },
            tracers = { enabled = false, team = "any", player = "any", mode = "match", color = Color3.fromRGB(255,255,255) },
            wallhack = { enabled = false, transparency = 0.5 }
        },
        combat = {
            aimbot = { enabled = false, team = "any", player = "any", mode = "match", fov = 120 },
            dodge = { enabled = false, key = Enum.KeyCode.LeftControl, dist = 10 },
        },
        utility = {
            noclip = { enabled = false, mode = "nocollide" },
            clicktp = { enabled = false, maxdist = 200 },
            tps = {}
        }
    },
    keybinds = {
        speed = Enum.KeyCode.Z,
        jump = Enum.KeyCode.X,
        infJump = Enum.KeyCode.C,
        noclip = Enum.KeyCode.V,
        aimbot = Enum.KeyCode.B,
        esp = Enum.KeyCode.N,
        tracers = Enum.KeyCode.M,
        dodge = Enum.KeyCode.LeftControl,
        fly = Enum.KeyCode.F
    },
    theme = {
        textColor = Color3.fromRGB(255,255,255),
        backgroundColor = Color3.fromRGB(39,37,37),
        cornerRoundness = 3
    }
}

-- Initialize runtime defaults from humanoid
if hum then
    config.normal.movement.speed.default = hum.WalkSpeed or config.normal.movement.speed.default
    config.normal.movement.jump.defaultPower = hum.JumpPower or config.normal.movement.jump.defaultPower
end

-- GUI + Keybind system (auto-generates toggles and syncs)
local featureButtons = {}
local function createGui()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "DeathClientMenu"
    screenGui.Parent = gui

    local main = Instance.new("Frame")
    main.Size = UDim2.new(0,320,0,420)
    main.Position = UDim2.new(0.5,-160,0.5,-210)
    main.BackgroundColor3 = config.theme.backgroundColor
    main.BorderSizePixel = 0
    main.Active = true
    main.Draggable = true
    main.Parent = screenGui

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1,0,0,30)
    title.BackgroundTransparency = 1
    title.Text = "Death Client v"..config.version
    title.TextColor3 = config.theme.textColor
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 18
    title.Parent = main

    -- layout
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0,6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = main

    local function addToggle(name, feature)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1,-20,0,30)
        btn.Position = UDim2.new(0,10,0,40)
        btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
        btn.TextColor3 = config.theme.textColor
        btn.Font = Enum.Font.SourceSans
        btn.TextSize = 16
        btn.Text = (name:sub(1,1):upper()..name:sub(2)) .. ": OFF"
        btn.Parent = main
        featureButtons[name:lower()] = btn
        btn.MouseButton1Click:Connect(function()
            if feature.enabled ~= nil then
                feature.enabled = not feature.enabled
                btn.Text = (name:sub(1,1):upper()..name:sub(2)) .. (feature.enabled and " : ON" or " : OFF")
            end
        end)
    end

    -- auto-generate from config
    for name, feat in pairs(config.normal.movement) do addToggle(name, feat) end
    for name, feat in pairs(config.normal.visual) do addToggle(name, feat) end
    for name, feat in pairs(config.normal.combat) do addToggle(name, feat) end
    for name, feat in pairs(config.normal.utility) do addToggle(name, feat) end

    return screenGui
end

local MenuGui = createGui()

-- Utilities for state restore
local original = {
    bodyVelocityParent = nil,
    partsCanCollide = {},
    partsTransparency = {},
}

-- Movement: Speed & Jump (Heartbeat)
RunService.Heartbeat:Connect(function()
    if hum then
        -- Speed
        if config.normal.movement.speed.enabled then
            hum.WalkSpeed = config.normal.movement.speed.speed
        else
            hum.WalkSpeed = config.normal.movement.speed.default
        end
        -- Jump (JumpPower; JumpHeight isn't a property on Humanoid in all games)
        if config.normal.movement.jump.enabled then
            if hum.JumpPower then hum.JumpPower = config.normal.movement.jump.power end
        else
            if hum.JumpPower then hum.JumpPower = config.normal.movement.jump.defaultPower end
        end
    end
end)

-- Infinite Jump
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if config.normal.movement.infiniteJump.enabled and input.KeyCode == Enum.KeyCode.Space then
        if hum and hum:GetState() ~= Enum.HumanoidStateType.Dead then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- Fly (BodyVelocity controlled)
local flyBV = Instance.new("BodyVelocity")
flyBV.MaxForce = Vector3.new(1e5,1e5,1e5)
flyBV.Velocity = Vector3.new(0,0,0)
flyBV.P = 1e4
local isFlying = false

RunService.RenderStepped:Connect(function()
    if config.normal.movement.fly.enabled and hrp and cam then
        if not isFlying then
            flyBV.Parent = hrp
            isFlying = true
        end
        local move = Vector3.new(0,0,0)
        local cf = cam.CFrame
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move = move - Vector3.new(0,1,0) end
        if move.Magnitude > 0 then
            flyBV.Velocity = move.Unit * config.normal.movement.fly.speed
        else
            flyBV.Velocity = Vector3.new(0,0,0)
        end
    else
        if isFlying then
            flyBV.Parent = nil
            isFlying = false
        end
    end
end)

-- Noclip (toggle CanCollide on character parts; restore on disable)
local function applyNoclip(enabled)
    if not char then return end
    if enabled then
        original.partsCanCollide = {}
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                original.partsCanCollide[part] = part.CanCollide
                part.CanCollide = false
            end
        end
    else
        for part, prev in pairs(original.partsCanCollide) do
            if part and part.Parent then
                part.CanCollide = prev
            end
        end
        original.partsCanCollide = {}
    end
end

-- Click Teleport using mouse
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if config.normal.utility.clicktp.enabled and input.UserInputType == Enum.UserInputType.MouseButton1 then
        local x,y = UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y
        local ray = cam:ScreenPointToRay(x,y)
        local rayParams = RaycastParams.new()
        rayParams.FilterDescendantsInstances = {char}
        rayParams.FilterType = Enum.RaycastFilterType.Blacklist
        local result = Workspace:Raycast(ray.Origin, ray.Direction * config.normal.utility.clicktp.maxdist, rayParams)
        if result and result.Position then
            if hrp then hrp.CFrame = CFrame.new(result.Position + Vector3.new(0,3,0)) end
        end
    end
end)

-- Dodge (A/D teleport)
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if config.normal.combat.dodge.enabled and hrp then
        if input.KeyCode == Enum.KeyCode.A then
            hrp.CFrame = hrp.CFrame * CFrame.new(-config.normal.combat.dodge.dist,0,0)
        elseif input.KeyCode == Enum.KeyCode.D then
            hrp.CFrame = hrp.CFrame * CFrame.new(config.normal.combat.dodge.dist,0,0)
        end
    end
end)

-- Simple Aimbot: find closest player in FOV and lerp camera toward them while enabled
local function inFOV(screenPos, fov)
    local sx = screenPos.X - workspace.CurrentCamera.ViewportSize.X/2
    local sy = screenPos.Y - workspace.CurrentCamera.ViewportSize.Y/2
    local dist = math.sqrt(sx*sx + sy*sy)
    return dist <= fov/2
end

RunService.RenderStepped:Connect(function()
    if config.normal.combat.aimbot.enabled then
        local closest, closestDist = nil, math.huge
        for _, pl in pairs(Players:GetPlayers()) do
            if pl ~= plr and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") and pl.Character:FindFirstChild("Humanoid") then
                local hr = pl.Character.HumanoidRootPart
                local screenPos, onScreen = cam:WorldToViewportPoint(hr.Position)
                if onScreen and inFOV(screenPos, config.normal.combat.aimbot.fov) then
                    local d = (hr.Position - hrp.Position).Magnitude
                    if d < closestDist then
                        closestDist = d
                        closest = hr
                    end
                end
            end
        end
        if closest then
            local look = CFrame.lookAt(cam.CFrame.Position, closest.Position)
            cam.CFrame = CFrame.new(cam.CFrame.Position) * CFrame.Angles(0,0,0) -- keep pos
            cam.CFrame = CFrame.new(cam.CFrame.Position, closest.Position)
        end
    end
end)

-- ESP & Tracers using BillboardGui
local espGuis = {}
local tracerLines = {}
local function createEspForPlayer(pl)
    if not pl.Character or not pl.Character:FindFirstChild("HumanoidRootPart") then return end
    local hr = pl.Character.HumanoidRootPart
    local bb = Instance.new("BillboardGui")
    bb.Name = "DeathESP"
    bb.Adornee = hr
    bb.Size = UDim2.new(0,100,0,40)
    bb.AlwaysOnTop = true
    bb.Parent = plr:WaitForChild("PlayerGui")
    local frame = Instance.new("Frame", bb)
    frame.Size = UDim2.new(1,0,1,0)
    frame.BackgroundTransparency = 0.6
    frame.BackgroundColor3 = config.normal.visual.esp.color
    local label = Instance.new("TextLabel", bb)
    label.Size = UDim2.new(1,0,1,0)
    label.BackgroundTransparency = 1
    label.Text = pl.Name
    label.TextColor3 = Color3.new(1,1,1)
    label.Font = Enum.Font.SourceSans
    label.TextSize = 14
    espGuis[pl] = bb
    -- tracer: simple Drawing line (client-only)
    pcall(function()
        local RunService = game:GetService("RunService")
        -- use Drawing if available (Studio/Client) — fallback not required, we'll just skip if not.
        if Drawing then
            local line = Drawing.new("Line")
            line.Color = config.normal.visual.tracers.color
            line.Thickness = 1
            line.Visible = true
            tracerLines[pl] = line
        end
    end)
end

local function removeEspForPlayer(pl)
    if espGuis[pl] then espGuis[pl]:Destroy(); espGuis[pl] = nil end
    if tracerLines[pl] then
        pcall(function() tracerLines[pl]:Remove() end)
        tracerLines[pl] = nil
    end
end

RunService.RenderStepped:Connect(function()
    -- Update ESP
    if config.normal.visual.esp.enabled then
        for _, pl in pairs(Players:GetPlayers()) do
            if pl ~= plr then
                if not espGuis[pl] then createEspForPlayer(pl) end
            end
        end
    else
        for p,_ in pairs(espGuis) do removeEspForPlayer(p) end
    end

    -- Update tracers (Drawing)
    if config.normal.visual.tracers.enabled and Drawing then
        for pl, line in pairs(tracerLines) do
            if pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") then
                local screenPos = cam:WorldToViewportPoint(pl.Character.HumanoidRootPart.Position)
                if screenPos.Z > 0 then
                    line.From = Vector2.new(Workspace.CurrentCamera.ViewportSize.X/2, Workspace.CurrentCamera.ViewportSize.Y) -- bottom-center
                    line.To = Vector2.new(screenPos.X, screenPos.Y)
                    line.Visible = true
                else
                    line.Visible = false
                end
            else
                line.Visible = false
            end
        end
    else
        for _, line in pairs(tracerLines) do pcall(function() line.Visible = false end) end
    end
end)

-- Wallhack: store original transparencies then set
local function applyWallhack(enable)
    if enable then
        original.partsTransparency = {}
        for _, part in pairs(Workspace:GetDescendants()) do
            if part:IsA("BasePart") and not part:IsDescendantOf(char) then
                original.partsTransparency[part] = part.Transparency
                part.Transparency = config.normal.visual.wallhack.transparency
                part.CastShadow = false
            end
        end
    else
        for part, t in pairs(original.partsTransparency) do
            if part and part.Parent then
                part.Transparency = t
                -- can't always restore CastShadow reliably; leave default
            end
        end
        original.partsTransparency = {}
    end
end

-- Keybind handling (toggle features and update GUI)
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    -- Map keybind names to config paths
    for name, key in pairs(config.keybinds) do
        if input.KeyCode == key then
            local lname = name:lower()
            local feature = nil
            feature = feature or config.normal.movement[lname]
            feature = feature or config.normal.visual[lname]
            feature = feature or config.normal.combat[lname]
            feature = feature or config.normal.utility[lname]
            if feature and feature.enabled ~= nil then
                feature.enabled = not feature.enabled
                local btn = featureButtons[lname]
                if btn then
                    btn.Text = (lname:sub(1,1):upper()..lname:sub(2)) .. (feature.enabled and " : ON" or " : OFF")
                end
                -- apply immediate side effects for some features
                if lname == "noclip" then applyNoclip(feature.enabled) end
                if lname == "wallhack" then applyWallhack(feature.enabled) end
                print("[Death] "..name.." toggled -> "..tostring(feature.enabled))
            end
        end
    end
end)

for lname, btn in pairs(featureButtons) do
end

RunService.Heartbeat:Connect(function()
    if config.normal.utility.noclip.enabled then
        applyNoclip(true)
    else
        applyNoclip(false)
    end
    if config.normal.visual.wallhack.enabled then
        applyWallhack(true)
    else
        applyWallhack(false)
    end
end)

-- Cleanup on player leaving (remove ESP/tracers)
Players.PlayerRemoving:Connect(function(pl)
    removeEspForPlayer(pl)
end)

local endTime = tick()
print("Loaded Death Client "..config.version.." in "..(endTime - startTime).." seconds!")
