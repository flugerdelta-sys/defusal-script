-- =========================================================
-- Defusal Mobile: Speed + Fast Aim + Rapid Fire (Multi-Method)
-- FOV Angle = 190 + Фиксы (мёртвые, стены)
-- =========================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ================= НАСТРОЙКИ =================
local FOV_ANGLE = 190
local ENEMY_COLOR = Color3.fromRGB(160, 0, 255)

-- Скорость
local WALKSPEED = 50
local JUMP_POWER = 55

-- Аим + Триггербот
local AIM_ENABLED = true
local AUTO_SHOOT = true
local TRIGGER_DELAY = 0
local MAX_TARGET_DISTANCE = 99999
local PREDICT_ENABLED = true
local PREDICT_MULT = 0.15

-- ================= АНТИ-КИК =================
pcall(function()
    local mt = getrawmetatable(game)
    local oldNamecall = mt.__namecall
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if self == LocalPlayer and (method == "Kick" or method == "kick") then
            return nil
        end
        return oldNamecall(self, ...)
    end)
    setreadonly(mt, true)
    print("[ANTI-KICK] Установлен")
end)

-- ================= ОЧИСТКА =================
pcall(function()
    for _, g in ipairs(LocalPlayer.PlayerGui:GetChildren()) do
        if g.Name == "Defusal_Notif" then g:Destroy() end
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then
            for _, c in ipairs(p.Character:GetChildren()) do
                if c.Name == "CheatHighlight" or c.Name == "CheatNameTag" then c:Destroy() end
            end
        end
    end
end)

-- ================= КОМАНДА =================
local function getTeamColorStr(player)
    if not player then return nil end
    if player.Character then
        local v = player.Character:GetAttribute("TeamColor")
        if v ~= nil then return tostring(v) end
    end
    local v2 = player:GetAttribute("TeamColor")
    if v2 ~= nil then return tostring(v2) end
    return nil
end

local function isTeammate(player)
    if player == LocalPlayer then return true end
    if LocalPlayer.Team and player.Team and LocalPlayer.Team == player.Team then return true end
    local myT = getTeamColorStr(LocalPlayer)
    local hisT = getTeamColorStr(player)
    if myT and hisT and myT == hisT then return true end
    local myStats = LocalPlayer:FindFirstChild("leaderstats")
    local hisStats = player:FindFirstChild("leaderstats")
    if myStats and hisStats then
        local mt = myStats:FindFirstChild("Team")
        local ht = hisStats:FindFirstChild("Team")
        if mt and ht and mt.Value ~= nil and ht.Value ~= nil and mt.Value == ht.Value then return true end
    end
    return false
end

-- ================= ПРОВЕРКА ВИДИМОСТИ (СТРОГАЯ) =================
local function isVisible(targetPart, targetChar, myPos)
    local dir = targetPart.Position - myPos
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    
    local ray = workspace:Raycast(myPos, dir, rayParams)
    
    if not ray then return true end
    if ray.Instance:IsDescendantOf(targetChar) then return true end
    
    local hitPart = ray.Instance
    local hitName = string.lower(hitPart.Name or "")
    
    local isSmoke = hitName:find("smoke") or hitName:find("cloud") 
                 or hitName:find("gas") or hitName:find("fog")
    
    local isVeryTransparent = (hitPart.Transparency and hitPart.Transparency >= 0.7)
    
    if isSmoke then return true end
    if isVeryTransparent and not hitPart.CanCollide then return true end
    
    return false
end

-- ================= УПРЕЖДЕНИЕ =================
local function predictPosition(targetPart, myPos)
    if not PREDICT_ENABLED then return targetPart.Position end
    local velocity = targetPart.Velocity
    local distance = (targetPart.Position - myPos).Magnitude
    local travelTime = distance / 600
    return targetPart.Position + velocity * travelTime * PREDICT_MULT * 10
end

-- ================= ESP =================
local function clearESP(character)
    if not character then return end
    for _, obj in ipairs(character:GetChildren()) do
        if obj.Name == "CheatNameTag" or obj.Name == "CheatHighlight" then obj:Destroy() end
    end
end

local function createESP(player, character)
    if not character or player == LocalPlayer then return end
    pcall(function()
        clearESP(character)
        if isTeammate(player) then return end
        local hl = Instance.new("Highlight")
        hl.Name = "CheatHighlight"
        hl.FillColor = ENEMY_COLOR
        hl.FillTransparency = 0.5
        hl.OutlineColor = ENEMY_COLOR
        hl.OutlineTransparency = 0
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = character

        local bb = Instance.new("BillboardGui")
        bb.Name = "CheatNameTag"
        bb.Size = UDim2.new(0, 100, 0, 25)
        bb.StudsOffset = Vector3.new(0, 3, 0)
        bb.AlwaysOnTop = true
        bb.Parent = character

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.TextColor3 = ENEMY_COLOR
        lbl.TextStrokeTransparency = 0
        lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 12
        lbl.Text = player.Name
        lbl.Parent = bb
    end)
end

local function setupPlayer(player)
    if player == LocalPlayer then return end
    if player.Character then createESP(player, player.Character) end
    player.CharacterAdded:Connect(function(char) task.wait(0.5); createESP(player, char) end)
end

for _, p in ipairs(Players:GetPlayers()) do setupPlayer(p) end
Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(function(p) if p.Character then clearESP(p.Character) end end)

task.spawn(function()
    while task.wait(3) do
        pcall(function()
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local hasESP = player.Character:FindFirstChild("CheatHighlight")
                    local isTeam = isTeammate(player)
                    if not hasESP and not isTeam then createESP(player, player.Character)
                    elseif hasESP and isTeam then clearESP(player.Character) end
                end
            end
        end)
    end
end)

-- ================= СКОРОСТЬ =================
task.spawn(function()
    while task.wait(0.2) do
        if LocalPlayer.Character then
            local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                if hum.WalkSpeed ~= WALKSPEED then hum.WalkSpeed = WALKSPEED end
                if hum.UseJumpPower and hum.JumpPower ~= JUMP_POWER then hum.JumpPower = JUMP_POWER end
            end
        end
    end
end)

-- ================= ФУНКЦИЯ ПОИСКА ЦЕЛИ =================
local function getAllTargets()
    local targets = {}
    local myPos = Camera.CFrame.Position
    local myLook = Camera.CFrame.LookVector
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and not isTeammate(player) then
            local char = player.Character
            if char and char.Parent == workspace then
                local hum = char:FindFirstChildOfClass("Humanoid")
                local head = char:FindFirstChild("Head")
                local hrp = char:FindFirstChild("HumanoidRootPart")
                
                local isAlive = hum 
                    and hum.Health > 0 
                    and hum:GetState() ~= Enum.HumanoidStateType.Dead
                    and hrp ~= nil

                if isAlive and head then
                    local dist = (head.Position - myPos).Magnitude
                    if dist <= MAX_TARGET_DISTANCE then
                        local toTarget = (head.Position - myPos).Unit
                        local dot = myLook:Dot(toTarget)
                        local angleDeg = math.deg(math.acos(math.clamp(dot, -1, 1)))

                        if angleDeg <= FOV_ANGLE then
                            if isVisible(head, char, myPos) then
                                local sp = Camera:WorldToViewportPoint(head.Position)
                                if sp.Z > 0 then
                                    local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                                    table.insert(targets, {head = head, distance = d, char = char})
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    table.sort(targets, function(a, b) return a.distance < b.distance end)
    return targets
end

-- ================= АИМ + ТРИГГЕРБОТ (МУЛЬТИ-МЕТОД) =================
local lastTriggerTime = 0
local lastTarget = nil

RunService.RenderStepped:Connect(function()
    if not AIM_ENABLED then return end
    pcall(function()
        local targets = getAllTargets()
        if #targets == 0 then return end

        local closest = targets[1].head
        local myPos = Camera.CFrame.Position

        -- Наводим камеру на голову
        local aimPos = predictPosition(closest, myPos)
        Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, aimPos)

        -- Сброс таймера при смене цели
        if closest ~= lastTarget then
            lastTriggerTime = 0
            lastTarget = closest
        end

        -- Стрельба (мульти-метод)
        if AUTO_SHOOT then
            local now = tick()
            if now - lastTriggerTime >= TRIGGER_DELAY then
                lastTriggerTime = now
                local char = LocalPlayer.Character
                if char then
                    -- МЕТОД 1: Activate у Tool
                    local tool = char:FindFirstChildOfClass("Tool")
                    if tool then
                        pcall(function() tool:Activate() end)
                    end
                    
                    -- МЕТОД 2: mouse1click (симуляция клика)
                    pcall(function() mouse1click() end)
                    
                    -- МЕТОД 3: mouse1press + mouse1release
                    pcall(function()
                        mouse1press()
                        mouse1release()
                    end)
                end
            end
        end
    end)
end)

-- ================= УВЕДОМЛЕНИЕ =================
pcall(function()
    local Notif = Instance.new("ScreenGui")
    Notif.Name = "Defusal_Notif"
    Notif.ResetOnSpawn = false
    Notif.Parent = LocalPlayer:WaitForChild("PlayerGui")
    local F = Instance.new("Frame")
    F.Size = UDim2.new(0, 340, 0, 60)
    F.Position = UDim2.new(0.5, -170, 0.15, 0)
    F.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    F.BorderSizePixel = 0
    F.Parent = Notif
    Instance.new("UICorner", F).CornerRadius = UDim.new(0, 10)
    local T = Instance.new("TextLabel")
    T.Size = UDim2.new(1, 0, 1, 0)
    T.BackgroundTransparency = 1
    T.Text = "✅ Загружено! (Aim + Trigger + Speed)"
    T.TextColor3 = ENEMY_COLOR
    T.Font = Enum.Font.GothamBold
    T.TextScaled = true
    T.Parent = F
    task.delay(5, function() pcall(function() Notif:Destroy() end) end)
end)

print("Defusal Script загружен!")
