--[[
    LocalScript Compatible Version
    Note: This will NOT prevent server-side kicks
    Only works with client-side kick attempts
]]

-- Prevent multiple loads
if _G.AntiKickLoaded then
    warn("[Anti-Kick] Already loaded!")
    return
end

--// Services
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer

--// Configuration
_G.AntiKick = {
    Enabled = true,
    SendNotifications = true,
    
    Stats = {
        InterceptedKicks = 0,
        LastKickAttempt = nil
    }
}

local config = _G.AntiKick

--// Notification Function
local function sendNotification(title, text, duration)
    if not config.SendNotifications then return end
    
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title or "Anti-Kick",
            Text = text or "",
            Duration = duration or 3
        })
    end)
end

--// Monitor for kick attempts (limited in LocalScript)
local function setupProtection()
    -- Hook LocalPlayer.Kick if possible (very limited in Studio)
    local oldKick = LocalPlayer.Kick
    
    LocalPlayer.Kick = function(self, message)
        if config.Enabled then
            config.Stats.InterceptedKicks = config.Stats.InterceptedKicks + 1
            config.Stats.LastKickAttempt = tick()
            
            sendNotification(
                "Anti-Kick",
                "Blocked kick attempt!",
                2
            )
            
            warn("[Anti-Kick] Intercepted kick:", message)
            return -- Block the kick
        end
        
        return oldKick(self, message)
    end
end

--// API Functions
function _G.AntiKick.Toggle(state)
    config.Enabled = state
    sendNotification(
        "Anti-Kick",
        state and "Enabled" or "Disabled",
        2
    )
end

function _G.AntiKick.GetStats()
    return config.Stats
end

function _G.AntiKick.Reset()
    config.Stats.InterceptedKicks = 0
    config.Stats.LastKickAttempt = nil
end

--// Initialize
pcall(setupProtection)

sendNotification(
    "Anti-Kick",
    "LocalScript version loaded!",
    3
)

_G.AntiKickLoaded = true

print("[Anti-Kick] Loaded successfully!")
