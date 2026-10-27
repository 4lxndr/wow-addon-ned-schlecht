-- Options panel: one checkbox per sound (on/off) plus a preview button.
-- Called from core.lua after ADDON_LOADED once the saved variables exist.

function BKS_SetupOptions(core, db, playFile)
    local panel = CreateFrame("Frame")
    panel.name = "NedSchlechtBossSounds"

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("NedSchlechtBossSounds")

    local hint = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    hint:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    hint:SetText("Haken raus = Sound wird beim Boss-Kill nicht mehr gespielt. |cffffd100Play|r = vorhören.")

    local y = -64
    for _, s in ipairs(BKS_SOUNDS) do
        local cb = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
        cb:SetPoint("TOPLEFT", 16, y)
        cb:SetSize(26, 26)
        cb:SetChecked(not db.disabled[s.file])
        cb:SetScript("OnClick", function(self)
            if self:GetChecked() then
                db.disabled[s.file] = nil
            else
                db.disabled[s.file] = true
            end
            core.ResetBag()
        end)

        local label = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        label:SetPoint("LEFT", cb, "RIGHT", 6, 0)
        label:SetText(s.name)

        local play = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        play:SetSize(50, 22)
        play:SetPoint("LEFT", cb, "RIGHT", 240, 0)
        play:SetText("Play")
        play:SetScript("OnClick", function()
            playFile(s.file)
        end)

        y = y - 30
    end

    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(category)
        BKS_OpenOptions = function()
            Settings.OpenToCategory(category:GetID())
        end
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
        BKS_OpenOptions = function()
            InterfaceOptionsFrame_OpenToCategory(panel)
        end
    end
end
