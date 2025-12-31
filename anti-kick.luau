--[[
    Enhanced Anti-Kick Script
    Prevents unwanted kicks from the game
    Author: Improved version
]]

-- Prevent multiple loads
if getgenv().ED_AntiKick then
    warn("[Anti-Kick] Script already loaded!")
    return
end

--// Utility Functions
local function safeCloneRef(obj)
    return (cloneref or function(x) return x end)(obj)
end

local function safeCloneFunc(func)
    return (clonefunction or function(x) return x end)(func)
end

--// Services & References
local Players = safeCloneRef(game:GetService("Players"))
local LocalPlayer = safeCloneRef(Players.LocalPlayer)
local StarterGui = safeCloneRef(game:GetService("StarterGui"))

--// Cached Functions
local SetCore = safeCloneFunc(StarterGui.SetCore)
local FindFirstChild = safeCloneFunc(game.FindFirstChild)

--// Instance Comparison
local function compareInstances(inst1, inst2)
    if typeof(inst1) ~= "Instance" or typeof(inst2) ~= "Instance" then
        return false
    end
    
    if CompareInstances then
        return CompareInstances(inst1, inst2)
    end
    
    -- Fallback comparison
    return inst1 == inst2
end

--// String Validation
local function canCastToString(value)
    local success = pcall(function()
        FindFirstChild(game, value)
    end)
    return success
end

--// Notification System
local function sendNotification(title, text, icon, duration)
    if not getgenv().ED_AntiKick.SendNotifications then
        return
    end
    
    pcall(function()
        SetCore(StarterGui, "SendNotification", {
            Title = title or "Anti-Kick",
            Text = text or "",
            Icon = icon or "rbxassetid://6238540373",
            Duration = duration or 3
        })
    end)
end

--// Configuration
getgenv().ED_AntiKick = {
    Enabled = true,              -- Enable/disable anti-kick protection
    SendNotifications = true,     -- Show notifications for intercepted kicks
    CheckCaller = true,           -- Only block kicks from non-user scripts
    Debug = false,                -- Enable debug logging
    
    -- Statistics
    Stats = {
        InterceptedKicks = 0,
        LastKickAttempt = nil
    }
}

local config = getgenv().ED_AntiKick

--// Debug Logger
local function debugLog(message)
    if config.Debug then
        print("[Anti-Kick Debug]", message)
    end
end

--// Kick Interceptor
local function shouldInterceptKick(caller, message)
    -- Check if anti-kick is enabled
    if not config.Enabled then
        debugLog("Anti-kick disabled, allowing kick")
        return false
    end
    
    -- Check caller if option is enabled
    if config.CheckCaller and checkcaller and checkcaller() then
        debugLog("Kick from user script, allowing")
        return false
    end
    
    -- Validate message
    if not canCastToString(message) then
        debugLog("Invalid kick message, allowing")
        return false
    end
    
    return true
end

local function handleKickIntercept(kickMessage)
    config.Stats.InterceptedKicks = config.Stats.InterceptedKicks + 1
    config.Stats.LastKickAttempt = os.time()
    
    debugLog(string.format("Intercepted kick #%d: %s", 
        config.Stats.InterceptedKicks, 
        tostring(kickMessage)))
    
    sendNotification(
        "Anti-Kick",
        "Successfully intercepted kick attempt!",
        "rbxassetid://6238540373",
        2
    )
end

--// Hook: __namecall metamethod
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(...)
    local self, message = ...
    local method = getnamecallmethod()
    
    -- Check if this is a Kick call on LocalPlayer
    if compareInstances(self, LocalPlayer) and 
       method:lower() == "kick" and 
       shouldInterceptKick(nil, message) then
        
        handleKickIntercept(message)
        return -- Block the kick
    end
    
    return oldNamecall(...)
end))

--// Hook: LocalPlayer.Kick function
local oldKickFunction
oldKickFunction = hookfunction(LocalPlayer.Kick, newcclosure(function(...)
    local self, message = ...
    
    -- Check if this is a kick on LocalPlayer
    if compareInstances(self, LocalPlayer) and 
       shouldInterceptKick(nil, message) then
        
        handleKickIntercept(message)
        return -- Block the kick
    end
    
    return oldKickFunction(...)
end))

--// Initialization
sendNotification(
    "Anti-Kick Loaded",
    "Protection active!",
    "rbxassetid://6238537240",
    3
)

debugLog("Anti-kick script initialized successfully")

--// API Functions
function getgenv().ED_AntiKick:Toggle(state)
    self.Enabled = state
    sendNotification(
        "Anti-Kick",
        state and "Enabled" or "Disabled",
        "rbxassetid://6238537240",
        2
    )
end

function getgenv().ED_AntiKick:GetStats()
    return self.Stats
end

function getgenv().ED_AntiKick:Reset()
    self.Stats.InterceptedKicks = 0
    self.Stats.LastKickAttempt = nil
    debugLog("Statistics reset")
end
