local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

local LANGS = {
    tl="tl", jp="ja", kr="ko", zh="zh",
    en="en", es="es", fr="fr", de="de",
    it="it", pt="pt", ru="ru", ar="ar",
    hi="hi", tr="tr", vi="vi", th="th",
    id="id", ms="ms", pl="pl", nl="nl",
}

local activeLang = nil

local function translate(text, code)
    local ok, res = pcall(function()
        local url = ("https://api.mymemory.translated.net/get?q=%s&langpair=autodetect|%s")
            :format(HttpService:UrlEncode(text), code)
        local data = HttpService:JSONDecode(HttpService:GetAsync(url, true))
        if data and data.responseStatus == 200 then
            return data.responseData.translatedText
        end
    end)
    return (ok and res) or nil
end

local function notify(msg)
    for _, ch in ipairs(TextChatService:GetChildren()) do
        if ch:IsA("TextChannel") then
            pcall(function() ch:DisplaySystemMessage("[Translator] " .. msg) end)
        end
    end
end

TextChatService.MessageReceived:Connect(function(msg)
    if not activeLang then return end
    if msg.TextSource and msg.TextSource.UserId == LocalPlayer.UserId then return end

    local original = msg.Text
    if not original or original == "" then return end

    local sender = "?"
    if msg.TextSource then
        local p = Players:GetPlayerByUserId(msg.TextSource.UserId)
        sender = p and p.DisplayName or "?"
    end

    task.spawn(function()
        local translated = translate(original, activeLang)
        if translated and translated ~= original then
            for _, ch in ipairs(TextChatService:GetChildren()) do
                if ch:IsA("TextChannel") then
                    pcall(function()
                        ch:DisplaySystemMessage(("🟡 %s: %s"):format(sender, translated))
                    end)
                end
            end
        end
    end)
end)

local hooked = false

local function hookSend(ch)
    if hooked then return end
    hooked = true

    local orig = ch.SendAsync
    ch.SendAsync = function(self, msg, ...)
        local clean = msg:match("^%s*(.-)%s*$")
        local cmd = clean:lower():match("^>(%S+)$")

        if cmd then
            if cmd == "off" then
                activeLang = nil
                notify("OFF")
            elseif LANGS[cmd] then
                activeLang = LANGS[cmd]
                notify("ON -> " .. cmd:upper() .. " | player messages will appear gold translated")
            else
                notify("Unknown language: " .. cmd)
            end
            return
        end

        return orig(self, msg, ...)
    end

    notify("Ready! Type >tl / >jp / >kr / >en etc. | >off to stop")
end

local function init()
    for _, ch in ipairs(TextChatService:GetChildren()) do
        if ch:IsA("TextChannel") then
            hookSend(ch)
            return
        end
    end
    TextChatService.ChildAdded:Connect(function(ch)
        if ch:IsA("TextChannel") and not hooked then
            task.wait(1)
            hookSend(ch)
        end
    end)
end

task.defer(function()
    task.wait(2)
    init()
end)
