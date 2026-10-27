-- Minimal recreation of the WoW addon API for headless tests under Lua 5.4.
-- Widgets answer unknown method calls with no-ops so UI code (options.lua)
-- runs without a real client.

local M = {}

local function makeWidget(env, kind)
    local w = { kind = kind, events = {}, scripts = {}, checked = nil, text = nil }
    setmetatable(w, {
        __index = function(t, k)
            local noop = function() end
            rawset(t, k, noop)
            return noop
        end,
    })
    function w:RegisterEvent(event) self.events[event] = true end
    function w:UnregisterEvent(event) self.events[event] = nil end
    function w:SetScript(name, handler) self.scripts[name] = handler end
    function w:GetScript(name) return self.scripts[name] end
    function w:SetChecked(v) self.checked = v end
    function w:GetChecked() return self.checked end
    function w:SetText(v) self.text = v end
    function w:GetText() return self.text end
    function w:CreateFontString() return makeWidget(env, "FontString") end
    return w
end

function M.install()
    local env = {
        playedFiles = {},      -- every PlaySoundFile call
        chatMessages = {},     -- everything printed to chat
        frames = {},           -- all CreateFrame results, in order
        playSoundResult = true,
        openedCategories = {}, -- Settings.OpenToCategory calls
    }

    _G.PlaySoundFile = function(path, channel)
        table.insert(env.playedFiles, { path = path, channel = channel })
        return env.playSoundResult
    end

    _G.DEFAULT_CHAT_FRAME = {
        AddMessage = function(_, msg)
            table.insert(env.chatMessages, msg)
        end,
    }

    _G.SlashCmdList = {}

    _G.CreateFrame = function(kind)
        local frame = makeWidget(env, kind)
        table.insert(env.frames, frame)
        return frame
    end

    _G.Settings = {
        RegisterCanvasLayoutCategory = function(panel, name)
            return { GetID = function() return 1 end, panel = panel, name = name }
        end,
        RegisterAddOnCategory = function() end,
        OpenToCategory = function(id)
            table.insert(env.openedCategories, id)
        end,
    }

    -- Simulates the client dispatching an event to all registered frames.
    function env.FireEvent(event, ...)
        for _, frame in ipairs(env.frames) do
            if frame.events[event] and frame.scripts.OnEvent then
                frame.scripts.OnEvent(frame, event, ...)
            end
        end
    end

    return env
end

return M
