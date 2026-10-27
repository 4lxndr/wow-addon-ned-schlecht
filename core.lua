-- NedSchlechtBossSounds: plays a sound from the pool when a boss encounter ends successfully.
-- Shuffle bag: every enabled sound plays exactly once per round, then the bag is reshuffled.
-- BKS_CreateCore is API-neutral and runs identically in-game and headless in the tests.

function BKS_CreateCore(deps)
    local sounds = deps.sounds
    local playSound = deps.playSound
    local random = deps.random
    local notify = deps.notify or function() end
    local isEnabled = deps.isEnabled or function() return true end

    local core = {}
    local bag = {}
    local lastFile = nil
    local warned = false

    local function refillBag()
        bag = {}
        for _, s in ipairs(sounds) do
            if isEnabled(s.file) then
                bag[#bag + 1] = s
            end
        end
        for i = #bag, 2, -1 do
            local j = random(i)
            bag[i], bag[j] = bag[j], bag[i]
        end
        -- Draws happen from the end: the new round must not start with the
        -- sound that was played last.
        if #bag > 1 and bag[#bag].file == lastFile then
            local j = random(#bag - 1)
            bag[#bag], bag[j] = bag[j], bag[#bag]
        end
    end

    -- Clears the current round so option changes take effect immediately.
    function core.ResetBag()
        bag = {}
    end

    function core.PlayRandom()
        local tries = #sounds + 1
        while tries > 0 do
            tries = tries - 1
            if #bag == 0 then
                refillBag()
                if #bag == 0 then return nil end -- all sounds disabled
            end
            local s = table.remove(bag)
            if isEnabled(s.file) then
                if playSound(s.file) then
                    lastFile = s.file
                    return s
                elseif not warned then
                    warned = true
                    notify("NedSchlechtBossSounds: Sound konnte nicht abgespielt werden: " .. s.file)
                end
            end
        end
        return nil
    end

    function core.OnEncounterEnd(encounterID, encounterName, difficultyID, groupSize, success)
        if success == 1 then
            return core.PlayRandom()
        end
    end

    return core
end

-- In-game bootstrap: only runs inside the WoW client, not in the headless tests.
if CreateFrame then
    local ADDON = "NedSchlechtBossSounds"
    local MEDIA_PATH = "Interface\\AddOns\\" .. ADDON .. "\\media\\"
    local db

    local chatFiles = {}
    for _, s in ipairs(BKS_SOUNDS) do
        if s.chat then chatFiles[s.file] = true end
    end

    local function playFile(file)
        return PlaySoundFile(MEDIA_PATH .. file, "Master")
    end

    local core = BKS_CreateCore({
        sounds = BKS_SOUNDS,
        random = math.random,
        playSound = playFile,
        notify = function(msg)
            DEFAULT_CHAT_FRAME:AddMessage(msg, 1, 0.4, 0.4)
        end,
        isEnabled = function(file)
            if not db then return true end
            if db.disabled[file] then return false end
            -- chat variants only play when the chat toggle is on (default: off)
            if chatFiles[file] and not db.chatEnabled then return false end
            return true
        end,
    })

    local frame = CreateFrame("Frame")
    frame:RegisterEvent("ADDON_LOADED")
    frame:RegisterEvent("ENCOUNTER_END")
    frame:SetScript("OnEvent", function(_, event, ...)
        if event == "ADDON_LOADED" then
            if ... == ADDON then
                NedSchlechtBossSoundsDB = NedSchlechtBossSoundsDB or {}
                NedSchlechtBossSoundsDB.disabled = NedSchlechtBossSoundsDB.disabled or {}
                NedSchlechtBossSoundsDB.chatEnabled = NedSchlechtBossSoundsDB.chatEnabled or false
                db = NedSchlechtBossSoundsDB
                if BKS_SetupOptions then
                    BKS_SetupOptions(core, db, playFile)
                end
                frame:UnregisterEvent("ADDON_LOADED")
            end
        elseif event == "ENCOUNTER_END" then
            core.OnEncounterEnd(...)
        end
    end)
end
