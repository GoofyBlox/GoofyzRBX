-- open source 
repeat task.wait() until game:IsLoaded()

local LocalPlayer = game:GetService("Players").LocalPlayer


local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    if method == "Kick" or method == "kick" then
        return
    end

    if method == "FireServer" or method == "InvokeServer" then
        if typeof(args[1]) == "string" then
            local s = args[1]:lower()
            if s:find("detect") or s:find("cheat") or s:find("flag") 
            or s:find("kick") or s:find("adonis") or s:find("disconnect")
            or s:find("namecall") or s:find("instance") then
                return
            end
        end
    end

    return oldNamecall(self, ...)
end))


for _, obj in getgc(true) do
    if typeof(obj) == "table" then
        local detected = rawget(obj, "Detected")
        local kill = rawget(obj, "Kill")
        local disconnect = rawget(obj, "Disconnect")

        if typeof(detected) == "function" then
            hookfunction(detected, newcclosure(function()
                return true
            end))
        end

        if typeof(kill) == "function" then
            hookfunction(kill, newcclosure(function() end))
        end

        if typeof(disconnect) == "function" then
            hookfunction(disconnect, newcclosure(function() end))
        end
    end
end


for _, func in getgc() do
    if typeof(func) == "function" and islclosure(func) then
        local ok, constants = pcall(debug.getconstants, func)
        if ok then
            for _, c in constants do
                if typeof(c) == "string" then
                    if c:find("Tamper Protection") or c:find("0x") 
                    or c == "TableCheck" or c:find("namecallInstance") then
                        pcall(hookfunction, func, newcclosure(function() end))
                        break
                    end
                end
            end
        end
    end
end


local mt = getrawmetatable(LocalPlayer)
if mt then
    setreadonly(mt, false)
    local oldIndex = mt.__index
    mt.__index = newcclosure(function(self, key)
        if key == "Kick" then
            return function() end
        end
        return oldIndex(self, key)
    end)
    setreadonly(mt, true)
end

print("Vortex Hub | Bypass Anti Cheat Enabled")
