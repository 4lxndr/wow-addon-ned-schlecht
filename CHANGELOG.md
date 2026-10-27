# Changelog — NedSchlechtBossSounds

## [1.0.0] — 2026-10-27 (Initial Release)

Spielt bei jedem erfolgreichen Boss-Kill einen "Brudi ned schlecht!"-Sound —
inspiriert von Brudivoeller_TV (Twitch).

### Features

- **Boss-Kill-Erkennung** über das `ENCOUNTER_END`-Event: löst bei jedem
  erfolgreich beendeten Dungeon-/Raid-Encounter aus, bei Wipes bleibt es still.
- **9 Sounds im Pool**, alle auf einheitliche Lautstärke (−12 LUFS) gemastert:
  Original, NNN Flüssig, Stadion Panorama, Dub Echo Bounce, Echo sowie vier
  Chat-Varianten (Chat Original, NNN Chat Flüssig, Chat Stadion Panorama,
  Chat Dub Echo Bounce).
- **Chat-Ansagen-Schalter:** Die Chat-Varianten sind standardmäßig aus und
  lassen sich im Optionsmenü global zuschalten.
- **Shuffle-Wiedergabe:** Jeder aktivierte Sound kommt genau einmal pro Runde
  dran, danach wird neu gemischt — nie derselbe Sound zweimal hintereinander.
- **Optionsmenü** (ESC → Optionen → AddOns): pro Sound eine Checkbox zum
  Deaktivieren und ein Play-Button zum Vorhören. Die Auswahl wird accountweit
  gespeichert.
- **Eigenes Addon-Icon** in der Addon-Liste.
- **Robustheit:** Nicht abspielbare Sounddateien werden übersprungen (einmalige
  Chat-Warnung statt Lua-Fehler); sind alle Sounds deaktiviert, bleibt der Kill
  einfach still.

### Unterstützte Clients

- WoW Forever (`_forever_`, 1.60.x)
- WoW Classic Era (`_classic_era_`, 1.15.x)
- WoW Retail (12.1.5) über eigene `_Mainline.toc`

### Technik

- Testgetrieben entwickelt: 20 Headless-Tests mit gemockter WoW-API laufen
  ohne Spielclient unter Lua 5.4 (`lua tests/test_core.lua`).
