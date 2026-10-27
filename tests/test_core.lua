-- Headless tests for NedSchlechtBossSounds. Run with:  lua tests/test_core.lua

local here = arg[0]:match("^(.*[/\\])") or "./"
local root = here .. "../"

local failed, passed = 0, 0
local function check(ok, name, detail)
    if ok then
        passed = passed + 1
        print("PASS  " .. name)
    else
        failed = failed + 1
        print("FAIL  " .. name .. (detail and ("  -- " .. detail) or ""))
    end
end

-- Deterministic pseudo-random so tests are reproducible.
local function makeRng(seed)
    local state = seed
    return function(n)
        state = (state * 1103515245 + 12345) % 2147483648
        return (state % n) + 1
    end
end

dofile(root .. "sounds.lua")
dofile(root .. "core.lua") -- no CreateFrame global: bootstrap stays off

-- 1) pool is defined, entries have file + name
local poolOk = type(BKS_SOUNDS) == "table" and #BKS_SOUNDS >= 1
for _, s in ipairs(BKS_SOUNDS or {}) do
    if type(s.file) ~= "string" or type(s.name) ~= "string" then poolOk = false end
end
check(poolOk, "sounds.lua defines pool with file+name")

-- 2) every pool file actually exists in media/
local allExist = true
for _, s in ipairs(BKS_SOUNDS) do
    local fh = io.open(root .. "media/" .. s.file, "rb")
    if fh then fh:close() else allExist = false end
end
check(allExist, "all sound files exist in media/")

-- Synthetic pool for behavior tests — independent of the real pool.
local function syntheticPool(n)
    local pool = {}
    for i = 1, n do pool[i] = { file = "s" .. i .. ".ogg", name = "Sound " .. i } end
    return pool
end

local function makeCore(opts)
    opts = opts or {}
    local played, notices = {}, {}
    local core = BKS_CreateCore({
        sounds = opts.sounds or syntheticPool(4),
        random = opts.random or makeRng(42),
        isEnabled = opts.isEnabled,
        playSound = opts.playSound or function(file)
            table.insert(played, file)
            return true
        end,
        notify = function(msg) table.insert(notices, msg) end,
    })
    return core, played, notices
end

-- 3) boss kill (success=1) plays exactly one sound
local core, played = makeCore()
core.OnEncounterEnd(123, "Ragnaros", 9, 40, 1)
check(#played == 1, "kill plays exactly one sound", "played: " .. #played)

-- 4) wipe (success=0) plays nothing
core, played = makeCore()
core.OnEncounterEnd(123, "Ragnaros", 9, 40, 0)
check(#played == 0, "wipe plays no sound", "played: " .. #played)

-- 5) shuffle bag: every round of 4 kills plays each sound exactly once
core, played = makeCore()
local bagOk = true
for round = 0, 4 do
    local seen = {}
    for _ = 1, 4 do core.OnEncounterEnd(1, "Boss", 9, 40, 1) end
    for i = round * 4 + 1, round * 4 + 4 do
        if seen[played[i]] then bagOk = false end
        seen[played[i]] = true
    end
end
check(bagOk, "shuffle: each sound exactly once per round")

-- 6) no immediate repeat across round boundaries
local noRepeat = true
for i = 2, #played do
    if played[i] == played[i - 1] then noRepeat = false end
end
check(noRepeat, "no immediate repeat at round boundary")

-- 7) disabled sounds never play
local disabled = { ["s2.ogg"] = true }
core, played = makeCore({ isEnabled = function(file) return not disabled[file] end })
for _ = 1, 30 do core.OnEncounterEnd(1, "Boss", 9, 40, 1) end
local playedDisabled = false
for _, f in ipairs(played) do
    if f == "s2.ogg" then playedDisabled = true end
end
check(not playedDisabled and #played == 30, "disabled sound never plays")

-- 8) disabling mid-round takes effect right after ResetBag
disabled = {}
core, played = makeCore({ isEnabled = function(file) return not disabled[file] end })
core.OnEncounterEnd(1, "Boss", 9, 40, 1)
disabled["s1.ogg"] = true; disabled["s2.ogg"] = true; disabled["s3.ogg"] = true
core.ResetBag()
for _ = 1, 5 do core.OnEncounterEnd(1, "Boss", 9, 40, 1) end
local onlyS4 = true
for i = 2, #played do
    if played[i] ~= "s4.ogg" then onlyS4 = false end
end
check(onlyS4, "after disabling, only the active sound remains")

-- 9) all sounds disabled: no sound, no error
core, played = makeCore({ isEnabled = function() return false end })
local result = core.OnEncounterEnd(1, "Boss", 9, 40, 1)
check(result == nil and #played == 0, "all disabled: silent, without error")

-- 10) fallback: if one file fails, another plays + exactly one warning
local failFile
local playedOk = {}
local notices
core, _, notices = makeCore({
    playSound = function(file)
        if failFile == nil then failFile = file end
        if file == failFile then return false end
        table.insert(playedOk, file)
        return true
    end,
})
core.OnEncounterEnd(1, "Boss", 9, 40, 1)
core.OnEncounterEnd(1, "Boss", 9, 40, 1)
check(#playedOk >= 1, "fallback plays a substitute sound", "ok plays: " .. #playedOk)
check(#notices == 1, "exactly one warning for a broken file", "warnings: " .. #notices)

-- 11) in-game bootstrap through the mocked WoW API
local mock = dofile(here .. "wow_mock.lua")
local env = mock.install()
math.randomseed(7)
dofile(root .. "sounds.lua")
dofile(root .. "options.lua")
dofile(root .. "core.lua") -- CreateFrame exists now → bootstrap runs

env.FireEvent("ADDON_LOADED", "NedSchlechtBossSounds")
check(type(NedSchlechtBossSoundsDB) == "table" and type(NedSchlechtBossSoundsDB.disabled) == "table",
    "ADDON_LOADED initializes saved variables")
check(type(BKS_OpenOptions) == "function", "options panel registered")

env.FireEvent("ENCOUNTER_END", 672, "Testboss", 9, 40, 1)
check(#env.playedFiles == 1, "ENCOUNTER_END(success=1) calls PlaySoundFile", "calls: " .. #env.playedFiles)
check(#env.playedFiles > 0 and env.playedFiles[1].path:find("Interface\\AddOns\\NedSchlechtBossSounds\\media\\", 1, true) == 1,
    "sound path points at the addon media folder", #env.playedFiles > 0 and env.playedFiles[1].path or "no call")

env.FireEvent("ENCOUNTER_END", 672, "Testboss", 9, 40, 0)
check(#env.playedFiles == 1, "ENCOUNTER_END(success=0) plays nothing")

-- 12) sounds disabled via saved variables do not play in-game either
NedSchlechtBossSoundsDB.disabled = {}
for i = 1, #BKS_SOUNDS - 1 do
    NedSchlechtBossSoundsDB.disabled[BKS_SOUNDS[i].file] = true
end
local onlyLast = BKS_SOUNDS[#BKS_SOUNDS].file
local before = #env.playedFiles
for _ = 1, 5 do env.FireEvent("ENCOUNTER_END", 672, "Testboss", 9, 40, 1) end
local allLast = true
for i = before + 1, #env.playedFiles do
    if not env.playedFiles[i].path:find(onlyLast, 1, true) then allLast = false end
end
check(#env.playedFiles == before + 5 and allLast, "saved-variables disable works in-game")
NedSchlechtBossSoundsDB.disabled = {}

-- 13) no slash commands: configuration happens through the options menu only
check(SlashCmdList["NEDSCHLECHT"] == nil, "no slash commands registered")

print(string.format("\n%d passed, %d failed", passed, failed))
os.exit(failed == 0 and 0 or 1)
