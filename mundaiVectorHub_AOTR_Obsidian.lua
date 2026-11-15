--// Vector Hub : AOTR  (Obsidian UI version)
getgenv().LPH_NO_VIRTUALIZE = getgenv().LPH_NO_VIRTUALIZE or function(f) return f end

_G.save = {
    AutoFarmTitan = false, Retry = false, Leave = false, AutoPrestige = false,
    M1Click = false, M1Delay = 0.1,
    HookKey = "Q + E", AttackRange = 60, MaxTitanTime = 10, AssistPull = true, RemoteHit = true,
    GlideHover = false, GlideHeight = 150,
    Noclip = false, BlackScreen = false, WhiteScreen = false,
    FPSLOCK = false, FPS = 60,
}

--// Services
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local VIM = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")
local LP = Players.LocalPlayer
local PlayerGui = LP:WaitForChild("PlayerGui")
local IsLobby = (game.PlaceId == 14916516914)
local GET = RS.Assets.Remotes.GET

--// Save / Load
local SAVE_FILE = "VectorHub/AOTR/" .. LP.Name .. ".json"
local canFile = readfile and writefile and isfile and isfolder and makefolder
local function LoadSettings()
    if not canFile then return end
    if not isfolder("VectorHub") then makefolder("VectorHub") end
    if not isfolder("VectorHub/AOTR") then makefolder("VectorHub/AOTR") end
    if not isfile(SAVE_FILE) then
        writefile(SAVE_FILE, HttpService:JSONEncode(_G.save))
    else
        local ok, data = pcall(function() return HttpService:JSONDecode(readfile(SAVE_FILE)) end)
        if ok and data then for k, v in pairs(data) do _G.save[k] = v end end
    end
end
local function Save()
    if canFile then pcall(writefile, SAVE_FILE, HttpService:JSONEncode(_G.save)) end
end
LoadSettings()

--// Obsidian UI
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local GameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
local Window = Library:CreateWindow({
    Title = "Vector Hub",
    Footer = GameName .. " | Made by Ryuenz",
    Icon = 120282400245939,
    NotifySide = "Right",
    ShowCustomCursor = false,
})

local Tabs = {
    Info = Window:AddTab("Info", "info"),
    Mission = Window:AddTab("Missions", "mail-open"),
    Raid = Window:AddTab("Raids", "swords"),
    Wave = Window:AddTab("Waves", "waves"),
    Main = Window:AddTab("General", "house"),
    Prestige = Window:AddTab("Prestiger", "star"),
    Misc = Window:AddTab("Misc", "settings"),
    Server = Window:AddTab("Servers", "server"),
    UI = Window:AddTab("UI Settings", "palette"),
}

local function toList(v)
    local t = {}
    for k, on in pairs(v) do if on then table.insert(t, k) end end
    return t
end

--// Helpers
local function PressButton(d)
    GuiService.SelectedObject = d
    VIM:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
    task.wait(0.05)
    VIM:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
end

local Difficulties = {"Best For You", "Easy", "Normal", "Hard", "Severe", "Aberrant"}
local DifficultiesRaids = {"Best For You", "Hard", "Severe", "Aberrant"}
local ModifiersList = {"No Perks", "No Skills", "No Memories", "Nightmare", "Oddball", "Injury Prone",
    "Chronic Injuries", "Fog", "Glass Cannon", "Time Trial", "Boring", "Simple"}

local function resolveDifficultyFromUI()
    if not IsLobby then return "Easy" end
    local text = PlayerGui.Interface.Equipment.Categories.Upgrades.Main.Title.Text
    if text == "UPGRADES" then
        PressButton(PlayerGui.Interface.Topbar.Main.Categories.Equipment.Interact)
    end
    local raw = text:match("%[(.-)%]")
    local map = {["E- GRADE"] = "Easy", ["E+ GRADE"] = "Normal", ["D+ GRADE"] = "Hard",
        ["B- GRADE"] = "Severe", ["A- GRADE"] = "Aberrant"}
    if not raw or raw == "Best For You" then
        if _G.save.AutoJoinMission or _G.save.AutoJoinMissionBoost then return _G.save.SelectMissionDifficulty
        elseif _G.save.AutoJoinRaid then return _G.save.SelectRaidDifficulty
        else return "Easy" end
    end
    if not raw:find("%+") and not raw:find("%-") then raw = raw:gsub(" GRADE", "- GRADE") end
    return map[raw] or "Easy"
end

local function CreateAndStart(data)
    if not IsLobby then return false end
    local ok, res = pcall(function() return GET:InvokeServer("S_Missions", "Create", data) end)
    if ok and typeof(res) == "Instance" then
        task.wait(1)
        pcall(function() GET:InvokeServer("S_Missions", "Start") end)
        return true
    end
    return false
end

--==================== INFO ====================
local InfoBox = Tabs.Info:AddLeftGroupbox("Profile")
local infoLabel = InfoBox:AddLabel("Loading...", true)
task.spawn(function()
    while task.wait(1) do
        pcall(function()
            local t = math.floor(workspace.DistributedGameTime + 0.5)
            infoLabel:SetText(("Username: %s\nTime: %dh %dm %ds\nFPS: %d\nPing: %s"):format(
                LP.Name, math.floor(t / 3600) % 24, math.floor(t / 60) % 60, t % 60,
                math.floor(workspace:GetRealPhysicsFPS()),
                game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValueString()))
        end)
    end
end)

local StatusBox = Tabs.Info:AddRightGroupbox("Game Status")
local statusLabel = StatusBox:AddLabel("Waiting...", true)
task.spawn(function()
    while task.wait(0.25) do
        local s = workspace:GetAttribute("Seconds") or 0
        statusLabel:SetText(("Mode: %s\nDifficulty: %s\nTarget: %s\nTime: %02d:%02d"):format(
            workspace:GetAttribute("Type") or "Waiting...",
            workspace:GetAttribute("Difficulty") or "N/A",
            workspace:GetAttribute("Objective") or "None",
            math.floor(s / 60), s % 60))
    end
end)

local CreditBox = Tabs.Info:AddLeftGroupbox("Credit")
CreditBox:AddLabel("Script made by Ryuenz#6264")
CreditBox:AddButton({Text = "Copy Discord Link", Func = function()
    setclipboard("https://discord.gg/977JQXX82w")
    Library:Notify({Title = "Vector Hub", Description = "Copied Discord link!", Time = 3})
end})
CreditBox:AddButton({Text = "Protect Name", Func = function()
    loadstring(game:HttpGet("https://api.luarmor.net/files/v3/loaders/3fe82db790953de0da11d9a70008ffea.lua"))()
end})

--==================== MISSIONS ====================
local MissionMaps = {"Shiganshina", "Trost", "Outskirts", "Forest", "Utgard", "Docks", "Stohess", "Chapel"}
local MissionObjectives = {
    Shiganshina = {"Skirmish", "Breach", "Random"}, Trost = {"Skirmish", "Protect", "Random"},
    Outskirts = {"Skirmish", "Escort", "Random"}, Forest = {"Skirmish", "Guard", "Random"},
    Utgard = {"Skirmish", "Defend", "Random"}, Docks = {"Skirmish", "Stall", "Random"},
    Stohess = {"Skirmish", "Random"}, Chapel = {"Skirmish", "Random"},
}
_G.save.SelectMissionMap = _G.save.SelectMissionMap or MissionMaps[1]
_G.save.SelectMissionObjective = _G.save.SelectMissionObjective or MissionObjectives[_G.save.SelectMissionMap][1]
_G.save.SelectMissionDifficulty = _G.save.SelectMissionDifficulty or "Easy"
_G.save.SelectMissionModifiers = _G.save.SelectMissionModifiers or {}

local MBox = Tabs.Mission:AddLeftGroupbox("Auto Join Missions")
local MissionObjDD
MBox:AddDropdown("MissionMap", {Text = "Select Map", Values = MissionMaps, Default = _G.save.SelectMissionMap,
    Callback = function(v)
        _G.save.SelectMissionMap = v
        local objs = MissionObjectives[v]
        if objs and MissionObjDD then
            _G.save.SelectMissionObjective = objs[1]
            MissionObjDD:SetValues(objs)
            MissionObjDD:SetValue(objs[1])
        end
        Save()
    end})
MissionObjDD = MBox:AddDropdown("MissionObjective", {Text = "Select Objective",
    Values = MissionObjectives[_G.save.SelectMissionMap], Default = _G.save.SelectMissionObjective,
    Callback = function(v) _G.save.SelectMissionObjective = v; Save() end})
MBox:AddDropdown("MissionDifficulty", {Text = "Select Difficulty", Values = Difficulties,
    Default = _G.save.SelectMissionDifficulty,
    Callback = function(v) _G.save.SelectMissionDifficulty = v; Save() end})
MBox:AddDropdown("MissionModifiers", {Text = "Select Modifiers", Values = ModifiersList, Multi = true,
    Default = _G.save.SelectMissionModifiers,
    Callback = function(v) _G.save.SelectMissionModifiers = toList(v); Save() end})
MBox:AddToggle("AutoJoinMission", {Text = "Auto Join Mission", Default = _G.save.AutoJoinMission or false,
    Callback = function(v) _G.save.AutoJoinMission = v; Save() end})
MBox:AddToggle("AutoJoinMissionBoost", {Text = "Auto Join Mission (Rewards Boost)",
    Default = _G.save.AutoJoinMissionBoost or false,
    Callback = function(v) _G.save.AutoJoinMissionBoost = v; Save() end})

--==================== RAIDS ====================
local RaidMaps = {"Shiganshina", "Trost", "Stohess"}
local RaidObjectives = {Shiganshina = {"Armored Titan", "Colossal Titan"}, Trost = {"Attack Titan"}, Stohess = {"Female Titan"}}
_G.save.SelectRaidMap = _G.save.SelectRaidMap or RaidMaps[1]
_G.save.SelectRaidObjective = _G.save.SelectRaidObjective or RaidObjectives[_G.save.SelectRaidMap][1]
_G.save.SelectRaidDifficulty = _G.save.SelectRaidDifficulty or "Hard"
_G.save.SelectRaidModifiers = _G.save.SelectRaidModifiers or {}

local RBox = Tabs.Raid:AddLeftGroupbox("Auto Join Raids")
local RaidObjDD
RBox:AddDropdown("RaidMap", {Text = "Select Raid Map", Values = RaidMaps, Default = _G.save.SelectRaidMap,
    Callback = function(v)
        _G.save.SelectRaidMap = v
        local objs = RaidObjectives[v]
        if objs and RaidObjDD then
            _G.save.SelectRaidObjective = objs[1]
            RaidObjDD:SetValues(objs)
            RaidObjDD:SetValue(objs[1])
        end
        Save()
    end})
RaidObjDD = RBox:AddDropdown("RaidBoss", {Text = "Select Raid Boss", Values = RaidObjectives[_G.save.SelectRaidMap],
    Default = _G.save.SelectRaidObjective,
    Callback = function(v) _G.save.SelectRaidObjective = v; Save() end})
RBox:AddDropdown("RaidDifficulty", {Text = "Select Difficulty", Values = DifficultiesRaids,
    Default = _G.save.SelectRaidDifficulty,
    Callback = function(v) _G.save.SelectRaidDifficulty = v; Save() end})
RBox:AddDropdown("RaidModifiers", {Text = "Select Modifiers", Values = ModifiersList, Multi = true,
    Default = _G.save.SelectRaidModifiers,
    Callback = function(v) _G.save.SelectRaidModifiers = toList(v); Save() end})
RBox:AddToggle("AutoJoinRaid", {Text = "Auto Join Raid", Default = _G.save.AutoJoinRaid or false,
    Callback = function(v) _G.save.AutoJoinRaid = v; Save() end})

--==================== WAVES ====================
local WBox = Tabs.Wave:AddLeftGroupbox("Auto Join Waves")
WBox:AddDropdown("WaveMap", {Text = "Select Wave Map", Values = {"Trost"}, Default = "Trost",
    Callback = function(v) _G.save.SelectWaveMap = v; Save() end})
WBox:AddToggle("AutoJoinWaves", {Text = "Auto Join Waves", Default = _G.save.AutoJoinWaves or false,
    Callback = function(v) _G.save.AutoJoinWaves = v; Save() end})
_G.save.SelectWaveMap = _G.save.SelectWaveMap or "Trost"

--// Lobby join loop
task.spawn(function()
    while task.wait() do
        local s = _G.save
        if s.AutoJoinMission then
            CreateAndStart({Name = s.SelectMissionMap, Type = "Missions", Difficulty = resolveDifficultyFromUI(),
                Objective = s.SelectMissionObjective, Modifiers = s.SelectMissionModifiers, Limit = 8})
        elseif s.AutoJoinMissionBoost then
            CreateAndStart({Name = workspace:GetAttribute("Boosted_Map"), Type = "Missions",
                Difficulty = resolveDifficultyFromUI(), Objective = s.SelectMissionObjective,
                Modifiers = s.SelectMissionModifiers, Limit = 8})
        elseif s.AutoJoinRaid then
            CreateAndStart({Name = s.SelectRaidMap, Type = "Raids", Difficulty = resolveDifficultyFromUI(),
                Objective = s.SelectRaidObjective, Modifiers = s.SelectRaidModifiers, Limit = 8})
        elseif s.AutoJoinWaves then
            CreateAndStart({Name = s.SelectWaveMap, Type = "Waves", Difficulty = "Easy", Objective = "Waves", Limit = 8})
        end
    end
end)

--// Leave wrong lobby loop
task.spawn(function()
    while task.wait() do
        local s = _G.save
        if s.AutoJoinMission or s.AutoJoinMissionBoost or s.AutoJoinRaid or s.AutoJoinWaves then
            pcall(function()
                for _, v in pairs(RS.Missions:GetChildren()) do
                    if v.Leader.Value == LP.Name then
                        local target
                        if s.AutoJoinMission then target = s.SelectMissionMap
                        elseif s.AutoJoinMissionBoost then target = workspace:GetAttribute("Boosted_Map")
                        elseif s.AutoJoinRaid then target = s.SelectRaidMap
                        elseif s.AutoJoinWaves then target = s.SelectWaveMap end
                        if v.Name ~= target then GET:InvokeServer("S_Missions", "Leave") end
                    end
                end
            end)
        end
    end
end)

--==================== GENERAL / FARM ====================
local FarmBox = Tabs.Main:AddLeftGroupbox("Farming Options")
FarmBox:AddToggle("AutoFarmTitan", {Text = "Auto Farm Titan", Default = _G.save.AutoFarmTitan,
    Callback = function(v) _G.save.AutoFarmTitan = v; Save() end})
FarmBox:AddToggle("Retry", {Text = "Auto Vote Retry", Default = _G.save.Retry,
    Callback = function(v) _G.save.Retry = v; Save() end})
FarmBox:AddToggle("Leave", {Text = "Auto Vote Leave", Default = _G.save.Leave,
    Callback = function(v) _G.save.Leave = v; Save() end})

--// Auto M1 click
local M1Box = Tabs.Main:AddRightGroupbox("Auto M1 Click")
M1Box:AddToggle("M1Click", {Text = "Auto Click (M1)", Default = _G.save.M1Click,
    Callback = function(v) _G.save.M1Click = v; Save() end})
M1Box:AddSlider("M1Delay", {Text = "Click Delay (sec)", Default = _G.save.M1Delay, Min = 0.01, Max = 1,
    Rounding = 2, Callback = function(v) _G.save.M1Delay = v; Save() end})

--// Standalone Auto M1: only clicks when a living titan's nape is within range.
--// (Auto Farm Titan does its own clicking, so this stays quiet while farming.)
task.spawn(function()
    while task.wait() do
        if _G.save.M1Click and not _G.save.AutoFarmTitan then
            pcall(function()
                local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                local titans = workspace:FindFirstChild("Titans")
                if not hrp or not titans then return end
                local target
                for _, t in pairs(titans:GetChildren()) do
                    local hum = t:FindFirstChild("Humanoid")
                    local hit = t:FindFirstChild("Hitboxes") and t.Hitboxes:FindFirstChild("Hit")
                    local nape = hit and hit:FindFirstChild("Nape")
                    if hum and hum.Health > 0 and nape
                        and (hrp.Position - nape.Position).Magnitude <= (_G.save.AttackRange or 60) then
                        target = nape
                        break
                    end
                end
                if not target then return end
                local cam = workspace.CurrentCamera
                local p, vis = cam:WorldToScreenPoint(target.Position)
                local x, y = cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2
                if vis then x, y = p.X, p.Y end
                VIM:SendMouseButtonEvent(x, y, 0, true, game, 0)
                VIM:SendMouseButtonEvent(x, y, 0, false, game, 0)
            end)
            task.wait(_G.save.M1Delay or 0.1)
        end
    end
end)

local ChestBox = Tabs.Main:AddLeftGroupbox("Chest Options")
ChestBox:AddDropdown("SelectChests", {Text = "Select Chests", Values = {"Red Chest", "Purple Chest"},
    Multi = true, Default = _G.save.SelectChests or {"Red Chest"},
    Callback = function(v) _G.save.SelectChests = toList(v); Save() end})
ChestBox:AddToggle("AutoOpenChests", {Text = "Auto Open Chests", Default = _G.save.AutoOpenChests or false,
    Callback = function(v) _G.save.AutoOpenChests = v; Save() end})

--// Auto Glide UI
local GlideBox = Tabs.Main:AddLeftGroupbox("Auto Glide")
GlideBox:AddToggle("GlideHover", {Text = "Keep Gliding Above Ground", Default = _G.save.GlideHover,
    Callback = function(v) _G.save.GlideHover = v; Save() end})
GlideBox:AddSlider("GlideHeight", {Text = "Height Above Ground (studs)", Default = _G.save.GlideHeight, Min = 20,
    Max = 400, Rounding = 0, Callback = function(v) _G.save.GlideHeight = v; Save() end})

--// Hook farm settings UI
local HookBox = Tabs.Main:AddRightGroupbox("Auto Hook Farm")
HookBox:AddDropdown("HookKey", {Text = "Hook Key", Values = {"Q", "E", "Q + E"}, Default = _G.save.HookKey,
    Callback = function(v) _G.save.HookKey = v; Save() end})
HookBox:AddSlider("AttackRange", {Text = "Attack Range (studs)", Default = _G.save.AttackRange, Min = 10, Max = 200,
    Rounding = 0, Callback = function(v) _G.save.AttackRange = v; Save() end})
HookBox:AddSlider("MaxTitanTime", {Text = "Max Time Per Titan (sec)", Default = _G.save.MaxTitanTime, Min = 3, Max = 30,
    Rounding = 0, Callback = function(v) _G.save.MaxTitanTime = v; Save() end})
HookBox:AddToggle("AssistPull", {Text = "Assist Pull (if hook is slow)", Default = _G.save.AssistPull,
    Callback = function(v) _G.save.AssistPull = v; Save() end})
HookBox:AddToggle("RemoteHit", {Text = "Remote Hit Backup", Default = _G.save.RemoteHit,
    Callback = function(v) _G.save.RemoteHit = v; Save() end})
HookBox:AddLabel("Click delay uses the M1 Delay slider.", true)

--// Auto hook -> kill -> next titan farm (works anywhere a titan exists)
do
    local Camera = workspace.CurrentCamera
    local hooked = false
    local aimTarget = nil
    local skipped = {}

    local function GetHRP()
        local char = LP.Character
        if not char then return nil end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChild("Humanoid")
        if not hrp or not hum or hum.Health <= 0 then return nil end
        return hrp
    end

    --// Hook (hold key to hook, release to unhook)
    local function SetHook(on)
        if on then
            local k = _G.save.HookKey
            if k == "Q" or k == "Q + E" then VIM:SendKeyEvent(true, Enum.KeyCode.Q, false, game) end
            if k == "E" or k == "Q + E" then VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game) end
        else
            VIM:SendKeyEvent(false, Enum.KeyCode.Q, false, game)
            VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game)
        end
        hooked = on
    end

    --// Camera auto-aim on the nape
    RunService:BindToRenderStep("VectorAim", Enum.RenderPriority.Camera.Value + 1, function()
        if aimTarget and aimTarget.Parent and _G.save.AutoFarmTitan then
            local cam = workspace.CurrentCamera
            cam.CFrame = CFrame.lookAt(cam.CFrame.Position, aimTarget.Position)
        end
    end)

    local function ScreenPos(part)
        local cam = workspace.CurrentCamera
        local p, vis = cam:WorldToScreenPoint(part.Position)
        if vis then return p.X, p.Y end
        local vp = cam.ViewportSize
        return vp.X / 2, vp.Y / 2
    end

    local function ClickM1(part)
        local x, y = ScreenPos(part)
        VIM:SendMouseButtonEvent(x, y, 0, true, game, 0)
        VIM:SendMouseButtonEvent(x, y, 0, false, game, 0)
    end

    local function RemoteHit(titan)
        local POST = RS.Assets.Remotes.POST
        POST:FireServer("Attacks", "Slash", true)
        local hit = titan:FindFirstChild("Hitboxes") and titan.Hitboxes:FindFirstChild("Hit")
        local nape = hit and hit:FindFirstChild("Nape")
        if nape then
            POST:FireServer("Hitboxes", "Register", nape, (titan:GetAttribute("Distance") or 0) + 1000, 1)
        end
        POST:FireServer("Attacks", "Slash", false)
    end

    --// Blades
    local function GetBladeUI()
        local ok, blades = pcall(function() return PlayerGui.Interface.HUD.Main.Top["7"].Blades end)
        if ok and blades then
            local g = blades:FindFirstChild("Inner") and blades.Inner:FindFirstChild("Bar")
                and blades.Inner.Bar:FindFirstChild("Gradient")
            return g, blades:FindFirstChild("Sets")
        end
    end

    local function Refill()
        local refillPart
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") and (v.Name:lower():find("refill") or v.Name:lower():find("fill")) then
                local display = v:FindFirstChild("Display")
                if display then
                    local ok, title = pcall(function() return display.Main.Top.Title.Text end)
                    if ok and title ~= "REFILLS: 0 / 3 [R]" then refillPart = v; break end
                end
            end
        end
        if not refillPart then return end
        local hrp = GetHRP()
        if hrp then hrp.CFrame = refillPart.CFrame end
        pcall(function() RS.Assets.Remotes.POST:FireServer("Attacks", "Reload", refillPart) end)
    end

    local function ChangeBlade()
        pcall(function() GET:InvokeServer("Blades", "Reload") end)
    end

    local function CheckBlade()
        local gradient, sets = GetBladeUI()
        if not gradient then return false end
        if gradient.Offset.X < 0 then
            local bladeOk = false
            pcall(function()
                local rig = workspace.Characters[LP.Name]["Rig" .. LP.Name]
                if rig.LeftHand.Blade_1.Transparency == 0 then bladeOk = true end
            end)
            if bladeOk then return false end
            if sets and sets.Text == "0 / 3" then Refill() else ChangeBlade() end
            return true
        end
        return false
    end

    --// Nearest living titan (to the player)
    local function GetClosestTitan()
        local titans = workspace:FindFirstChild("Titans")
        local hrp = GetHRP()
        if not titans or not hrp then return end
        local best, bestNape, bestDist = nil, nil, math.huge
        for _, Titan in pairs(titans:GetChildren()) do
            if Titan:IsA("Model") and not (skipped[Titan] and skipped[Titan] > tick()) then
                local humanoid = Titan:FindFirstChild("Humanoid")
                local hit = Titan:FindFirstChild("Hitboxes") and Titan.Hitboxes:FindFirstChild("Hit")
                local nape = hit and hit:FindFirstChild("Nape")
                if humanoid and humanoid.Health > 0 and nape and nape:IsA("BasePart") then
                    local d = (hrp.Position - nape.Position).Magnitude
                    if d < bestDist then best, bestNape, bestDist = Titan, nape, d end
                end
            end
        end
        return best, bestNape
    end

    local function IsAlive(titan, nape)
        local hum = titan.Parent and titan:FindFirstChild("Humanoid")
        return hum and hum.Health > 0 and nape.Parent ~= nil
    end

    --// Hook one titan, hit its nape until it dies
    local function KillTitan(titan, nape)
        local startT, lastHook, lastClick, lastBlade = tick(), 0, 0, 0
        aimTarget = nape
        while _G.save.AutoFarmTitan and IsAlive(titan, nape) do
            if tick() - startT > _G.save.MaxTitanTime then
                skipped[titan] = tick() + 10 -- unreachable/stuck, try others first
                break
            end
            local hrp = GetHRP()
            if not hrp then break end

            if tick() - lastBlade > 0.5 then
                lastBlade = tick()
                if CheckBlade() then
                    SetHook(false)
                    task.wait(0.4)
                    lastHook = 0
                end
            end

            local dist = (hrp.Position - nape.Position).Magnitude
            if dist > _G.save.AttackRange then
                -- not close yet: (re)fire hook at the nape
                if not hooked or tick() - lastHook > 1.2 then
                    SetHook(false)
                    task.wait(0.03)
                    local x, y = ScreenPos(nape)
                    VIM:SendMouseMoveEvent(x, y, game)
                    SetHook(true)
                    lastHook = tick()
                end
                -- hook slow/blocked: gently drag toward the titan
                if _G.save.AssistPull and tick() - startT > 2.5 then
                    local dir = (hrp.Position - nape.Position)
                    local goal = nape.Position + dir.Unit * (_G.save.AttackRange * 0.6)
                    hrp.CFrame = hrp.CFrame + (goal - hrp.Position) * 0.15
                    hrp.AssemblyLinearVelocity = Vector3.zero
                end
            else
                -- in range: stay hooked and slash the nape (clicks only here, only while it's alive)
                if not hooked then SetHook(true); lastHook = tick() end
                if IsAlive(titan, nape) and tick() - lastClick >= (_G.save.M1Delay or 0.1) then
                    lastClick = tick()
                    ClickM1(nape)
                    if _G.save.RemoteHit then pcall(RemoteHit, titan) end
                end
            end
            task.wait()
        end
        SetHook(false)
        aimTarget = nil
    end

    local lastWarn = 0
    task.spawn(function()
        while task.wait(0.05) do
            if _G.save.AutoFarmTitan then
                local ok, err = pcall(function()
                    pcall(function()
                        if PlayerGui.Interface.Skip.Visible then PressButton(PlayerGui.Interface.Skip.Interact) end
                    end)
                    if not GetHRP() then return end
                    local titan, nape = GetClosestTitan()
                    if not titan then
                        if hooked then SetHook(false) end
                        return -- no titan, idle
                    end
                    KillTitan(titan, nape)
                end)
                if not ok then
                    SetHook(false)
                    aimTarget = nil
                    if tick() - lastWarn > 3 then
                        lastWarn = tick()
                        warn("[VectorHub] farm error: " .. tostring(err))
                    end
                end
            elseif hooked or aimTarget then
                SetHook(false)
                aimTarget = nil
            end
        end
    end)

    --// Auto Glide: hover N studs above the ground (pauses while hooked onto a titan)
    local glideRay = RaycastParams.new()
    glideRay.FilterType = Enum.RaycastFilterType.Exclude
    local lastGround
    RunService.Heartbeat:Connect(function()
        if not _G.save.GlideHover or aimTarget then return end
        local hrp = GetHRP()
        if not hrp then return end
        local ex = {LP.Character}
        local titans = workspace:FindFirstChild("Titans")
        if titans then table.insert(ex, titans) end
        glideRay.FilterDescendantsInstances = ex
        local r = workspace:Raycast(hrp.Position, Vector3.new(0, -3000, 0), glideRay)
        if r then lastGround = r.Position.Y end
        if not lastGround then return end
        local targetY = lastGround + _G.save.GlideHeight
        local vel = hrp.AssemblyLinearVelocity
        local vy = math.clamp((targetY - hrp.Position.Y) * 3, -100, 100)
        hrp.AssemblyLinearVelocity = Vector3.new(vel.X, vy, vel.Z)
    end)

    GuiService.GuiNavigationEnabled = false
    local reqs = {[0] = 100, [1] = 125, [2] = 150, [3] = 175, [4] = 200}
    local function CheckPrestige()
        if not _G.save.AutoPrestige then return false end
        return reqs[LP:GetAttribute("Prestige")] == LP:GetAttribute("Level")
    end

    task.spawn(function()
        while task.wait() do
            pcall(function()
                local rewards = PlayerGui.Interface:FindFirstChild("Rewards")
                if not rewards or not rewards.Visible then return end
                local Buttons = rewards.Main.Info.Main.Buttons
                local ButtonRetry, ButtonLeave = Buttons.Retry, Buttons.Leave_2
                if _G.save.Retry then
                    if _G.save.AutoPrestige and CheckPrestige() then
                        PressButton(ButtonLeave)
                    elseif _G.save.AutoJoinMissionBoost then
                        if rewards.Main.Info.Main.Boost.Visible then PressButton(ButtonRetry)
                        else PressButton(ButtonLeave) end
                    else
                        PressButton(ButtonRetry)
                    end
                elseif _G.save.Leave then
                    PressButton(ButtonLeave)
                end
            end)
        end
    end)

    --// Highlight while farming
    RunService.Stepped:Connect(function()
        pcall(function()
            local char = LP.Character
            if not char then return end
            if _G.save.AutoFarmTitan then
                if char:FindFirstChild("HumanoidRootPart") and not char:FindFirstChild("Highlight") then
                    local hl = Instance.new("Highlight")
                    hl.FillColor = Color3.fromRGB(0, 9, 255)
                    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                    hl.FillTransparency = 0.8
                    hl.OutlineTransparency = 0
                    hl.Parent = char
                end
            elseif char:FindFirstChild("Highlight") then
                char.Highlight:Destroy()
            end
        end)
    end)
end

--==================== PRESTIGER ====================
local ListMemories = {"Overslash", "Gambler", "Afterimages", "Marksman", "Amputation", "Assassin", "Furyforge",
    "Quakestrike", "Stormcharged", "Stalwart", "Surgeshot", "Swiftshot", "Blitzblade", "Crescendo", "Guardian",
    "Deflectra", "Aegisurge", "Riposte", "Resilience", "Vengeflare", "Steel", "Frame", "Necromantic",
    "Thanatophobia", "Mendmaster", "Cooldown Blitz", "Lifefeed", "Vitalize", "Gem", "Fiend", "Omnirange",
    "Flashstep", "Tactician", "Bloodthief", "Apotheosis"}
_G.save.SelectMemories = _G.save.SelectMemories or {ListMemories[1]}
_G.save.SelectBoost = _G.save.SelectBoost or "Luck Boost"

local PBox = Tabs.Prestige:AddLeftGroupbox("Prestiger Options")
PBox:AddDropdown("SelectMemories", {Text = "Select Memories", Values = ListMemories, Multi = true,
    Default = _G.save.SelectMemories, Callback = function(v) _G.save.SelectMemories = toList(v); Save() end})
PBox:AddDropdown("SelectBoost", {Text = "Select Boost", Values = {"Luck Boost", "Gold Boost", "EXP Boost"},
    Default = _G.save.SelectBoost, Callback = function(v) _G.save.SelectBoost = v; Save() end})
PBox:AddToggle("AutoPrestige", {Text = "Auto Prestige", Default = _G.save.AutoPrestige,
    Callback = function(v) _G.save.AutoPrestige = v; Save() end})

task.spawn(function()
    local reqs = {[0] = 100, [1] = 125, [2] = 150, [3] = 175, [4] = 200}
    while task.wait() do
        if _G.save.AutoPrestige and reqs[LP:GetAttribute("Prestige")] == LP:GetAttribute("Level") then
            pcall(function()
                local I = PlayerGui.Interface
                if not IsLobby then
                    PressButton(I.Rewards.Main.Info.Main.Buttons.Leave_2)
                    return
                end
                local mem = workspace.Objects.Blackout.Memories
                local confirm = I.Memories_Buttons.M_Confirm
                if mem:FindFirstChild(_G.save.SelectBoost) then
                    if confirm.Visible then PressButton(confirm)
                    else fireclickdetector(mem[_G.save.SelectBoost].Click) end
                else
                    local hasMemory = false
                    for _, name in ipairs(ListMemories) do
                        if mem:FindFirstChild(name) then hasMemory = true; break end
                    end
                    local hasSelected = false
                    if hasMemory then
                        for _, v in pairs(mem:GetChildren()) do
                            if table.find(_G.save.SelectMemories, v.Name) then
                                hasSelected = true
                                if confirm.Visible then PressButton(confirm) else fireclickdetector(v.Click) end
                                break
                            end
                        end
                        if not hasSelected then PressButton(I.Memories_Buttons.M_Reroll) end
                    end
                    if not hasSelected then
                        local eq = I.Topbar.Main.Categories.Equipment
                        if eq.Move.Offset.Y == 1 then
                            PressButton(eq.Interact)
                        elseif eq.Move.Offset.Y == 0 and not I.Equipment.Prestige.Visible then
                            PressButton(I.Equipment.Categories.Prestige.Main.Interact)
                        elseif I.Equipment.Prestige.Visible then
                            if I.Warning.Prompt.Visible then PressButton(I.Warning.Prompt.Main.Yes)
                            else PressButton(I.Equipment.Prestige.B_Prestige) end
                        end
                    end
                end
            end)
        end
    end
end)

--==================== MISC ====================
local CharBox = Tabs.Misc:AddLeftGroupbox("Character")
local tpConn1, tpConn2
local altDown = false
CharBox:AddToggle("ClickTP", {Text = "Click Teleport (Alt + Click)", Default = false, Callback = function(on)
    if tpConn1 then tpConn1:Disconnect() end
    if tpConn2 then tpConn2:Disconnect() end
    if not on then return end
    local UIS = game:GetService("UserInputService")
    tpConn1 = UIS.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.LeftAlt then altDown = true
        elseif input.UserInputType == Enum.UserInputType.MouseButton1 and altDown and not IsLobby then
            local char = LP.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            local mouse = LP:GetMouse()
            local ray = workspace.CurrentCamera:ScreenPointToRay(mouse.X, mouse.Y)
            local params = RaycastParams.new()
            params.FilterDescendantsInstances = {char}
            params.FilterType = Enum.RaycastFilterType.Exclude
            local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
            if result then hrp.CFrame = CFrame.new(result.Position + Vector3.new(0, 3, 0)) end
        end
    end)
    tpConn2 = UIS.InputEnded:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.LeftAlt then altDown = false end
    end)
end})
CharBox:AddToggle("Noclip", {Text = "Noclip", Default = _G.save.Noclip,
    Callback = function(v) _G.save.Noclip = v; Save() end})
RunService.Stepped:Connect(function()
    if _G.save.Noclip and LP.Character then
        for _, p in pairs(LP.Character:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end
end)

local QoF = Tabs.Misc:AddRightGroupbox("Quality of Life")
QoF:AddToggle("BlackScreen", {Text = "Black Screen (reduce load)", Default = _G.save.BlackScreen,
    Callback = function(value)
        _G.save.BlackScreen = value; Save()
        local gui = PlayerGui:FindFirstChild("BlackScreenOverlay")
        if value then
            if not gui then
                gui = Instance.new("ScreenGui")
                gui.Name = "BlackScreenOverlay"
                gui.IgnoreGuiInset = true
                gui.DisplayOrder = 9999
                gui.ResetOnSpawn = false
                gui.Parent = PlayerGui
            end
            local f = gui:FindFirstChild("BlackFrame")
            if not f then
                f = Instance.new("Frame")
                f.Name = "BlackFrame"
                f.BackgroundColor3 = Color3.new(0, 0, 0)
                f.BorderSizePixel = 0
                f.Size = UDim2.new(1, 0, 1, 0)
                f.ZIndex = 10
                f.Parent = gui
            end
            f.Visible = true
            RunService:Set3dRenderingEnabled(false)
        else
            if gui and gui:FindFirstChild("BlackFrame") then gui.BlackFrame.Visible = false end
            RunService:Set3dRenderingEnabled(true)
        end
    end})
QoF:AddToggle("WhiteScreen", {Text = "White Screen (reduce load)", Default = _G.save.WhiteScreen,
    Callback = function(v)
        _G.save.WhiteScreen = v; Save()
        RunService:Set3dRenderingEnabled(not v)
    end})
QoF:AddSlider("FPS", {Text = "FPS Cap", Default = _G.save.FPS, Min = 1, Max = 240, Rounding = 0,
    Callback = function(v) _G.save.FPS = v; Save() end})
QoF:AddToggle("FPSLOCK", {Text = "Set FPS", Default = _G.save.FPSLOCK,
    Callback = function(v) _G.save.FPSLOCK = v; Save() end})
task.spawn(LPH_NO_VIRTUALIZE(function()
    while task.wait() do
        pcall(function() setfpscap(_G.save.FPSLOCK and _G.save.FPS or 0) end)
    end
end))

--==================== SERVERS ====================
local SBox = Tabs.Server:AddLeftGroupbox("Server")
local jobId = ""
SBox:AddInput("JobID", {Text = "JobID", Default = "", Placeholder = "Paste JobID",
    Callback = function(v) jobId = v end})
SBox:AddToggle("AutoJoinJobID", {Text = "Auto Join JobID", Default = false, Callback = function(v)
    if v then
        task.spawn(function()
            while Toggles.AutoJoinJobID.Value do
                if jobId ~= "" then
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, LP)
                    Library:Notify({Title = "VectorHub", Description = "Joining JobID, please wait", Time = 3})
                else
                    Library:Notify({Title = "VectorHub", Description = "Enter a JobID first", Time = 3})
                    Toggles.AutoJoinJobID:SetValue(false)
                    break
                end
                task.wait(1)
            end
        end)
    end
end})
SBox:AddButton({Text = "Join JobID", Func = function()
    if jobId ~= "" then TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, LP) end
end})
SBox:AddButton({Text = "Copy JobID", Func = function()
    setclipboard(game.JobId)
    Library:Notify({Title = "VectorHub", Description = "Copied JobID", Time = 3})
end})

local function fetchServers()
    return HttpService:JSONDecode(game:HttpGet(
        "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")).data or {}
end

local BBox = Tabs.Server:AddRightGroupbox("Basic")
BBox:AddButton({Text = "Rejoin", Func = function() TeleportService:Teleport(game.PlaceId, LP) end})
BBox:AddButton({Text = "Server Hop", Func = function()
    for _, v in ipairs(fetchServers()) do
        if v.playing < v.maxPlayers and v.id ~= game.JobId then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, v.id, LP)
            return
        end
    end
end})

local SmartBox = Tabs.Server:AddRightGroupbox("Smart Server")
local maxPlayers = 5
SmartBox:AddSlider("MaxPlayers", {Text = "Max Players Filter", Default = 5, Min = 1,
    Max = tonumber(Players.MaxPlayers) or 50, Rounding = 0, Callback = function(v) maxPlayers = v end})
SmartBox:AddButton({Text = "Smart Hop (few players)", Func = function()
    for _, v in ipairs(fetchServers()) do
        if v.playing <= maxPlayers and v.id ~= game.JobId then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, v.id, LP)
            break
        end
    end
end})
SmartBox:AddButton({Text = "Low Ping Hop", Func = function()
    pcall(function()
        local best, lowest = nil, math.huge
        for _, v in ipairs(fetchServers()) do
            local ping = tonumber(v.ping)
            if ping and ping < lowest and v.id ~= game.JobId then lowest = ping; best = v.id end
        end
        if best then TeleportService:TeleportToPlaceInstance(game.PlaceId, tostring(best), LP) end
    end)
end})

--==================== UI SETTINGS ====================
local MenuBox = Tabs.UI:AddLeftGroupbox("Menu")
MenuBox:AddToggle("KeybindMenuOpen", {Default = Library.KeybindFrame.Visible, Text = "Open Keybind Menu",
    Callback = function(v) Library.KeybindFrame.Visible = v end})
MenuBox:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", {Default = "F1", NoUI = true, Text = "Menu keybind"})
MenuBox:AddButton({Text = "Unload", Func = function() Library:Unload() end})
Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({"MenuKeybind"})
ThemeManager:SetFolder("VectorHub")
SaveManager:SetFolder("VectorHub/AOTR")
SaveManager:BuildConfigSection(Tabs.UI)
ThemeManager:ApplyToTab(Tabs.UI)
SaveManager:LoadAutoloadConfig()

if LP.GameplayPaused then LP.GameplayPaused = false end
LP:GetPropertyChangedSignal("GameplayPaused"):Connect(function()
    if LP.GameplayPaused then LP.GameplayPaused = false end
end)
