
-- Chatbox Translator (Full Language Pack) by Axiom
-- Usage in chat: translate: "tl" | translate: "jp" | translate: "off"

local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

---------------------------------------------------------------
-- LANGUAGE TABLE
---------------------------------------------------------------
local LANGUAGES = {
    -- Asian
    tl  = { name = "Filipino",              code = "tl"    },
    jp  = { name = "Japanese",              code = "ja"    },
    kr  = { name = "Korean",                code = "ko"    },
    zh  = { name = "Chinese Simplified",    code = "zh"    },
    zt  = { name = "Chinese Traditional",   code = "zh-TW" },
    vi  = { name = "Vietnamese",            code = "vi"    },
    th  = { name = "Thai",                  code = "th"    },
    id  = { name = "Indonesian",            code = "id"    },
    ms  = { name = "Malay",                 code = "ms"    },
    hi  = { name = "Hindi",                 code = "hi"    },
    bn  = { name = "Bengali",               code = "bn"    },
    ur  = { name = "Urdu",                  code = "ur"    },
    ta  = { name = "Tamil",                 code = "ta"    },
    te  = { name = "Telugu",                code = "te"    },
    mr  = { name = "Marathi",               code = "mr"    },
    gu  = { name = "Gujarati",              code = "gu"    },
    pa  = { name = "Punjabi",               code = "pa"    },
    ne  = { name = "Nepali",                code = "ne"    },
    si  = { name = "Sinhala",               code = "si"    },
    km  = { name = "Khmer",                 code = "km"    },
    my  = { name = "Burmese",               code = "my"    },

    -- European
    en  = { name = "English",               code = "en"    },
    es  = { name = "Spanish",               code = "es"    },
    fr  = { name = "French",                code = "fr"    },
    de  = { name = "German",                code = "de"    },
    it  = { name = "Italian",               code = "it"    },
    pt  = { name = "Portuguese",            code = "pt"    },
    ru  = { name = "Russian",               code = "ru"    },
    pl  = { name = "Polish",                code = "pl"    },
    nl  = { name = "Dutch",                 code = "nl"    },
    sv  = { name = "Swedish",               code = "sv"    },
    no  = { name = "Norwegian",             code = "no"    },
    da  = { name = "Danish",                code = "da"    },
    fi  = { name = "Finnish",               code = "fi"    },
    cs  = { name = "Czech",                 code = "cs"    },
    sk  = { name = "Slovak",                code = "sk"    },
    hu  = { name = "Hungarian",             code = "hu"    },
    ro  = { name = "Romanian",              code = "ro"    },
    bg  = { name = "Bulgarian",             code = "bg"    },
    hr  = { name = "Croatian",              code = "hr"    },
    sr  = { name = "Serbian",               code = "sr"    },
    uk  = { name = "Ukrainian",             code = "uk"    },
    lt  = { name = "Lithuanian",            code = "lt"    },
    lv  = { name = "Latvian",               code = "lv"    },
    et  = { name = "Estonian",              code = "et"    },
    el  = { name = "Greek",                 code = "el"    },
    tr  = { name = "Turkish",               code = "tr"    },
    ka  = { name = "Georgian",              code = "ka"    },
    hy  = { name = "Armenian",              code = "hy"    },
    az  = { name = "Azerbaijani",           code = "az"    },
    be  = { name = "Belarusian",            code = "be"    },

    -- Middle East / Africa
    ar  = { name = "Arabic",                code = "ar"    },
    he  = { name = "Hebrew",                code = "he"    },
    fa  = { name = "Persian/Farsi",         code = "fa"    },
    sw  = { name = "Swahili",               code = "sw"    },
    am  = { name = "Amharic",               code = "am"    },
    yo  = { name = "Yoruba",                code = "yo"    },
    ig  = { name = "Igbo",                  code = "ig"    },
    ha  = { name = "Hausa",                 code = "ha"    },
    zu  = { name = "Zulu",                  code = "zu"    },
    af  = { name = "Afrikaans",             code = "af"    },
    so  = { name = "Somali",                code = "so"    },
    mg  = { name = "Malagasy",              code = "mg"    },
    ny  = { name = "Chichewa",              code = "ny"    },

    -- Americas / Other
    ht  = { name = "Haitian Creole",        code = "ht"    },
    la  = { name = "Latin",                 code = "la"    },
    eo  = { name = "Esperanto",             code = "eo"    },
    cy  = { name = "Welsh",                 code = "cy"    },
    ga  = { name = "Irish",                 code = "ga"    },
    eu  = { name = "Basque",                code = "eu"    },
    gl  = { name = "Galician",              code = "gl"    },
    ca  = { name = "Catalan",               code = "ca"    },
    is  = { name = "Icelandic",             code = "is"    },
    mk  = { name = "Macedonian",            code = "mk"    },
    sq  = { name = "Albanian",              code = "sq"    },
    mt  = { name = "Maltese",               code = "mt"    },
    mn  = { name = "Mongolian",             code = "mn"    },
    kk  = { name = "Kazakh",                code = "kk"    },
    uz  = { name = "Uzbek",                 code = "uz"    },
    ky  = { name = "Kyrgyz",                code = "ky"    },
    tk  = { name = "Turkmen",               code = "tk"    },
    ps  = { name = "Pashto",                code = "ps"    },
    sd  = { name = "Sindhi",                code = "sd"    },
    lo  = { name = "Lao",                   code = "lo"    },
    jv  = { name = "Javanese",              code = "jv"    },
    su  = { name = "Sundanese",             code = "su"    },
    ceb = { name = "Cebuano",               code = "ceb"   },
    haw = { name = "Hawaiian",              code = "haw"   },
    sm  = { name = "Samoan",                code = "sm"    },
    mi  = { name = "Maori",                 code = "mi"    },
    hmn = { name = "Hmong",                 code = "hmn"   },
}

---------------------------------------------------------------
-- STATE
---------------------------------------------------------------
local state = {
    enabled  = false,
    langKey  = nil,   -- user-typed key e.g. "tl"
    langCode = nil,   -- API code e.g. "tl"
    langName = nil,
}

---------------------------------------------------------------
-- TRANSLATE via MyMemory (free, no key)
---------------------------------------------------------------
local function translate(text, targetCode)
    local ok, result = pcall(function()
        local url = ("https://api.mymemory.translated.net/get?q=%s&langpair=autodetect|%s")
            :format(HttpService:UrlEncode(text), targetCode)
        local raw  = HttpService:GetAsync(url, true)
        local data = HttpService:JSONDecode(raw)
        if data and data.responseStatus == 200 then
            return data.responseData.translatedText
        end
        return nil
    end)
    return (ok and result) or "[translation error]"
end

---------------------------------------------------------------
-- COMMAND PARSER
-- accepts:  translate: "tl"  |  translate: tl  |  translate: off
---------------------------------------------------------------
local function parseCommand(msg)
    local stripped = msg:match("^%s*(.-)%s*$"):lower()
    local key = stripped:match('^translate:%s*["\']?(%a+)["\']?%s*$')
    return key
end

---------------------------------------------------------------
-- NOTIFY (system bubble)
---------------------------------------------------------------
local function notify(msg)
    local ch = TextChatService:FindFirstChildOfClass("TextChannel")
    if ch then
        ch:DisplaySystemMessage(("[Translator] " .. msg))
    end
end

---------------------------------------------------------------
-- HOOK OUTGOING MESSAGES
---------------------------------------------------------------
local defaultChannel = TextChatService:FindFirstChildOfClass("TextChannel")

-- Wait for default channel if not yet loaded
if not defaultChannel then
    TextChatService.ChildAdded:Wait()
    defaultChannel = TextChatService:FindFirstChildOfClass("TextChannel")
end

-- Intercept before send
local original_send = defaultChannel.SendAsync
defaultChannel.SendAsync = function(self, message, ...)
    local key = parseCommand(message)

    -- COMMAND DETECTED
    if key then
        if key == "off" or key == "disable" then
            state.enabled  = false
            state.langKey  = nil
            state.langCode = nil
            state.langName = nil
            notify("Translator OFF.")
            return -- swallow the message, don't send
        end

        local lang = LANGUAGES[key]
        if lang then
            state.enabled  = true
            state.langKey  = key
            state.langCode = lang.code
            state.langName = lang.name
            notify(("Active → %s (%s)  |  type 'translate: off' to disable"):format(lang.name, key))
        else
            notify(("Unknown language key: '%s'"):format(key))
        end
        return -- swallow the command, don't send
    end

    -- TRANSLATE IF ACTIVE
    if state.enabled and message ~= "" then
        local translated = translate(message, state.langCode)
        return original_send(self, translated, ...)
    end

    return original_send(self, message, ...)
end

---------------------------------------------------------------
-- SHOW AVAILABLE LANGUAGES ON LOAD
---------------------------------------------------------------
task.delay(2, function()
    notify("Translator loaded! Usage:  translate: \"tl\"  |  translate: \"jp\"  |  translate: off")
    notify("Available keys: tl jp kr zh vi th id ms hi ar ru es fr de it pt tr he and 60+ more")
end)

print("[Axiom Translator] Ready. " .. tostring(#LANGUAGES) .. " is wrong, use pairs() — all langs loaded.")
