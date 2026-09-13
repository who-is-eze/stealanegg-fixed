local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/who-is-eze/stealanegg-fixed/refs/heads/main/vaehzlibCustom.lua"))() -- this is a modded version of vaehzlib for better compatibility with text labels
local Window = Library:CreateWindow({ Title = "Steal an Egg", Accent = Color3.fromRGB(100,160,255) })

local FarmTab = Window:CreateTab({ Name = "Autofarms", Icon = "wheat" })
local CredTab = Window:CreateTab({ Name = "Credits", Icon = "circle-i"})

local RunService = game:GetService("RunService")

getgenv().FarmEggs = false
getgenv().AutoPlace = false
getgenv().AutoFarm = false
getgenv().AutoHatch = false
getgenv().AutoEquip = false
getgenv().ChosenArea = "Automatic"

local Player = game:GetService("Players").LocalPlayer
local SpeedVal = Player.leaderstats.Speed
local PlayerBase
for i, base in pairs(workspace.Plots:GetChildren()) do
    if base.PlotSign.PlayerPlotSign.Frame.PlayerIcon.Image:find(tostring(Player.UserId)) then
        PlayerBase = base
    end
end

local GuardAreas = workspace.__OBJECTS.Areas.GuardAreas
local SpawnedEggs = workspace.AreaEggSlotsClient
local PlacedEggs
for i, v in pairs(workspace:GetChildren()) do
    if v.Name == "PlacedEggRenders" and #v:GetChildren() >= 1 then
        PlacedEggs = v
    end
end

local AreasList = {
    "Automatic"
}
for i, v in pairs(GuardAreas:GetChildren()) do
    table.insert(AreasList, v.Name)
end

local StealEvent = game:GetService("ReplicatedStorage").Packages.Networking["RF/EggWorld/AskFieldEggCarry"]
local PlaceEvent = game:GetService("ReplicatedStorage").Packages.Networking["RF/EggWorld/AskPlaceEgg"]
local HatchEvent = game:GetService("ReplicatedStorage").Packages.Networking["RF/EggWorld/AskHatch"]
local EquipEvent = game:GetService("ReplicatedStorage").Packages.Networking["RF/EggWorld/AskWearTool"]
local CompleteHatchEvent = game:GetService("ReplicatedStorage").Packages.Networking["RF/EggWorld/AskFinishHatch"]

local InventoryEvent = game:GetService("ReplicatedStorage").Packages.Networking["RE/EggWorld/OwnerShifted"]

local Areas = {
    ["Forest"] = {
        Speed = 0
    },
    ["Lake"] = {
        Speed = 900
    },
    ["Desert"] = {
        Speed = 10000
    },
    ["Jungle"] = {
        Speed = 40000
    },
    ["Snow"] = {
        Speed = 450000
    },
    ["Volcano"] = {
        Speed = 700000
    },
    ["Abyss Ocean"] = {
        Speed = 2500000
    },
    ["Prehistoric"] = {
        Speed = 17000000
    },
    ["Cosmic"] = {
        Speed = 700000000
    },
    ["Cherry Blossom"] = {
        Speed = 2500000000
    },
    ["Titan Temple"] = {
        Speed = 7000000000
    },
    ["Light Dark"] = {
        Speed = 20000000000
    }
}

local Waypoints = {
    SafeArea = Vector3.new(542, 71, -363)
}

local LastInventory

local function GetBestArea()
    local currentSpeed = SpeedVal.Value
    local bestName, bestSpeed = nil, -1

    if ChosenArea == "Automatic" then
        for name, data in pairs(Areas) do
            if data.Speed <= currentSpeed and data.Speed > bestSpeed then
                bestName = name
                bestSpeed = data.Speed
            end
        end
    else
        bestName = ChosenArea
    end

    return bestName
end

local function walkTo(hum, pos)
    local hrp = hum.RootPart
    while true do
        hum:MoveTo(pos)
        local reached = hum.MoveToFinished:Wait()

        if reached then
            return true
        end

        if hrp and hrp.Parent then
            local flat = (Vector2.new(hrp.Position.X, hrp.Position.Z)
                        - Vector2.new(pos.X, pos.Z)).Magnitude
            if flat <= 4 then
                return true
            end
        else
            return false
        end
    end
end

InventoryEvent.OnClientEvent:Connect(function(data)
    if data.OwnerUserId == Player.UserId then
        LastInventory = data.Records
    end
end)

FarmTab:CreateToggle({
    Name = "Auto Farm",
    Default = false,
    Callback = function(v)
        AutoFarm = v

        if AutoFarm then
            while AutoFarm do
                pcall(function()
                    local NoclipParts = {}
                    local Noclipping

                    local Character = Player.Character
                    local Humanoid = Character:FindFirstChildOfClass("Humanoid")

                    Noclipping = RunService.Stepped:Connect(function()
                        if AutoFarm and Player.Character ~= nil then
                            for _, child in pairs(Player.Character:GetDescendants()) do
                                if child:IsA("BasePart") and child.CanCollide == true then
                                    child.CanCollide = false
                                    NoclipParts[child] = true
                                end
                            end
                        end
                    end)
                    
                    if FarmEggs then
                        local bestArea = GuardAreas[GetBestArea()]

                        Humanoid.HipHeight = 20
                        task.wait(0.1)
                        walkTo(Humanoid, Waypoints.SafeArea)
                        Humanoid.HipHeight = 2
                        task.wait(0.1)
                        walkTo(Humanoid, bestArea.Bounds.Position)

                        local closestEgg, closestDist
                        for _, v in pairs(SpawnedEggs:GetChildren()) do
                            local primaryPart = v.PrimaryPart
                            if primaryPart then
                                local dist = (primaryPart.Position - Character.HumanoidRootPart.Position).Magnitude
                                if not closestDist or dist < closestDist then
                                    closestDist = dist
                                    closestEgg = v
                                end
                            end
                        end

                        walkTo(Humanoid, closestEgg.PrimaryPart.Position)

                        task.wait(0.5)

                        walkTo(Humanoid, closestEgg.PrimaryPart.Position)
                        task.wait()

                        StealEvent:InvokeServer(
                            {
                                Uid = closestEgg.Name
                            }
                        )

                        walkTo(Humanoid, Waypoints.SafeArea)
                    end

                    task.wait(0.5)

                    if AutoPlace then
                        if LastInventory ~= nil then
                            Humanoid.HipHeight = 20
                            task.wait(0.1)
                            walkTo(Humanoid, PlayerBase.CenterPoint.Position)

                            for i, v in pairs(LastInventory) do
                                local randomArea = CFrame.new(math.random(-23, 23), -0.5001220703125, math.random(-29, 29), 0, 0, 1, 0, 1, 0, -1, 0, 0)

                                PlaceEvent:InvokeServer(
                                    {
                                        Uid = i,
                                        LocalCFrame = randomArea
                                    }
                                )

                                task.wait()
                            end
                        end
                    end

                    if AutoHatch then
                        for i, v in pairs(PlacedEggs:GetChildren()) do
                            local splitString = v.Name:split("_")
                            if splitString[1] == tostring(Player.UserId) then
                                Humanoid.HipHeight = 20
                                task.wait(0.1)
                                walkTo(Humanoid, v.PrimaryPart.Position)

                                local res = HatchEvent:InvokeServer(
                                    splitString[2]
                                )

                                if res then
                                    CompleteHatchEvent:InvokeServer(splitString[2])
                                end

                                task.wait(0.1)
                            end
                        end
                    end

                    if AutoEquip then
                        EquipEvent:InvokeServer()
                    end

                    if Noclipping then
                        Noclipping:Disconnect()
                        Noclipping = nil
                    end
                    for part in pairs(NoclipParts) do
                        if part and part.Parent then
                            part.CanCollide = true
                        end
                    end
                    NoclipParts = {}

                    task.wait(1)
                end)

                task.wait()
            end
        end
    end
})

FarmTab:CreateLabel("Settings")

FarmTab:CreateToggle({
    Name = "Auto Collect",
    Default = false,
    Callback = function(v)
        FarmEggs = v
    end
})

FarmTab:CreateDropdown({
    Name = "Area",
    Options = AreasList,
    Multi = false,
    Callback = function(v)
        ChosenArea = v
    end
})

FarmTab:CreateToggle({
    Name = "Auto Place",
    Default = false,
    Callback = function(v)
        AutoPlace = v
    end
})

FarmTab:CreateToggle({
    Name = "Auto Hatch",
    Default = false,
    Callback = function(v)
        AutoHatch = v
    end
})

FarmTab:CreateToggle({
    Name = "Disable 3D Rendering",
    Default = false,
    Callback = function(v)
        RunService:Set3dRenderingEnabled(not v)
    end
})

CredTab:CreateLabel("Script Credits")

CredTab:CreateLabel({
    Text = "Script Owner & Developer: Vaehz",
    Size = 24,
    Color = Color3.fromRGB(100,160,255),
    Font = FONT_TITLE
})

CredTab:CreateLabel({
    Text = "Script Fixed by: Eze",
    Size = 24,
    Color = Color3.fromRGB(275,160,125),
    Font = FONT_TITLE
})

CredTab:CreateLabel("on robloxscripts.com")

Library:Notify({
    Title = "Loaded",
    Content = "Original by Vaehz | Fixed by Eze",
    Duration = 5
})
