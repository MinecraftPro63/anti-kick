--[[
    Enhanced Anti-Kick Script
    Prevents unwanted kicks from the game
    Compatible with exploit executors
]]

--// Cache exploit functions
local getgenv = getgenv
local getnamecallmethod = getnamecallmethod
local hookmetamethod = hookmetamethod
local hookfunction = hookfunction
local newcclosure = newcclosure
local checkcaller = checkcaller

--// Prevent multiple loads
if getgenv().ED_AntiKick then
    warn("[Anti-Kick] Already loaded!")
    return
end

--// Utility functions with fallbacks
local cloneref = cloneref or function(obj)
    return obj
end

local clonefunction = clonefunction or function(func)
    return func
end

--// Services and references
local Players = cloneref(game:GetService("Players"))
local LocalPlayer = cloneref(Players.LocalPlayer)
local StarterGui = cloneref(game:GetService("StarterGui"))

--// Cached functions
local SetCore = clonefunction(StarterGui.SetCore)
local FindFirstChild = clonefunction(game.FindFirstChild)

--// Instance comparison with fallback
local function CompareInstances(inst1, inst2)
    if typeof(inst1) ~= "Instance" or typeof(inst2) ~= "Instance" then
        return false
    end
    
    -- Use built-in comparison if available
    if _G.CompareInstances then
        return _G.CompareInstances(inst1, inst2)
    end
    
    return inst1 == inst2
end

--// String validation
local function CanCastToSTDString(value)
    return pcall(FindFirstChild, game, value)
end

--// Configuration
getgenv().ED_AntiKick = {
    Enabled = true,
    SendNotifications = true,
    CheckCaller = false, -- Changed to false to allow your own scripts
    
    -- Whitelist specific kick messages (won't block these)
    Whitelist = {
        -- Add kick messages you want to allow
        -- Example: ["Restarting..."] = true,
    },
    
    -- Statistics tracking
    Stats = {
        TotalKicksBlocked = 0,
        LastBlockedTime = nil,
        LastBlockedReason = nil
    }
}

local config = getgenv().ED_AntiKick

--// Notification helper
local function SendNotification(title, text, icon, duration)
    if not config.SendNotifications then
        return
    end
    
    local success, err = pcall(function()
        SetCore(StarterGui, "SendNotification", {
            Title = title,
            Text = text,
            Icon = icon or "rbxassetid://6238540373",
            Duration = duration or 3
        })
    end)
    
    if not success then
        warn("[Anti-Kick] Notification failed:", err)
    end
end

--// Kick interception handler
local function HandleKickAttempt(kickReason)
    -- Check whitelist
    if config.Whitelist and config.Whitelist[tostring(kickReason)] then
        warn("[Anti-Kick] Whitelisted kick, allowing:", kickReason)
        return false -- Don't block
    end
    
    config.Stats.TotalKicksBlocked = config.Stats.TotalKicksBlocked + 1
    config.Stats.LastBlockedTime = os.time()
    config.Stats.LastBlockedReason = tostring(kickReason)
    
    SendNotification(
        "Anti-Kick Protection",
        "Blocked kick attempt #" .. config.Stats.TotalKicksBlocked,
        "rbxassetid://6238540373",
        2
    )
    
    warn(string.format(
        "[Anti-Kick] Blocked kick #%d | Reason: %s",
        config.Stats.TotalKicksBlocked,
        tostring(kickReason)
    ))
    
    return true -- Block the kick
end

--// Hook: __namecall metamethod
local OldNamecall
OldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(...)
    local self, message = ...
    local method = getnamecallmethod()
    
    -- Check if this is a Kick namecall on LocalPlayer
    local isKickCall = method:lower():gsub("^%l", string.upper) == "Kick"
    local shouldBlock = config.Enabled and 
                       CompareInstances(self, LocalPlayer) and 
                       isKickCall
    
    -- Check caller if enabled
    if shouldBlock and config.CheckCaller then
        shouldBlock = not checkcaller()
    end
    
    -- Validate and block kick
    if shouldBlock and CanCastToSTDString(message) then
        HandleKickAttempt(message)
        return
    end
    
    return OldNamecall(...)
end))

--// Hook: LocalPlayer.Kick function
local OldKickFunction
OldKickFunction = hookfunction(LocalPlayer.Kick, newcclosure(function(...)
    local self, message = ...
    
    -- Check if blocking is needed
    local shouldBlock = config.Enabled and 
                       CompareInstances(self, LocalPlayer)
    
    -- Check caller if enabled
    if shouldBlock and config.CheckCaller then
        shouldBlock = not checkcaller()
    end
    
    -- Validate and block kick
    if shouldBlock and CanCastToSTDString(message) then
        HandleKickAttempt(message)
        return
    end
    
    return OldKickFunction(...)
end))

--// Load notification
SendNotification(
    "Anti-Kick Active",
    "Protection successfully loaded!",
    "rbxassetid://6238537240",
    3
)

--// Console confirmation
print("[Anti-Kick] Successfully loaded and active!")
print("[Anti-Kick] Config: Enabled=" .. tostring(config.Enabled) .. 
      " | Notifications=" .. tostring(config.SendNotifications) ..
      " | CheckCaller=" .. tostring(config.CheckCaller))
