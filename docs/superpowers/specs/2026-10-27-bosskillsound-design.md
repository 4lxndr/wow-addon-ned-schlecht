# BossKillSound — Design

**Datum:** 2026-10-27 · **Ziel-Client:** WoW Forever (`wowf`, 1.60.x) · **Test-Client:** Classic Era (1.15.x)

## Zweck

WoW-Addon, das bei jedem erfolgreichen Boss-Kill (Dungeon-/Raid-Encounter) zufällig eine
Audiospur aus einem Pool abspielt.

## Boss-Kill-Erkennung

`ENCOUNTER_END`-Event (Ansatz A, vom Nutzer gewählt): feuert am Ende jedes
Instanz-Encounters mit `success`-Flag. Sound nur bei `success == 1`. Keine Weltbosse,
keine Boss-Listen, keine Combat-Log-Auswertung.

## Sound-Pool

4 Dateien in `media/` (`kill1.ogg` … `kill4.ogg`), definiert in `sounds.lua`.
Zufallsauswahl pro Kill; derselbe Sound wird nie zweimal direkt hintereinander gespielt
(sofern Pool > 1). Abspielen über `PlaySoundFile(pfad, "Master")`.

## Architektur

- `core.lua` — API-neutrale Factory `BKS_CreateCore(deps)`: bekommt `playSound`,
  `random`, `sounds`, `print` injiziert; liefert `OnEncounterEnd(...)` und `PlayRandom()`.
  Darunter In-Game-Bootstrap (nur wenn `CreateFrame` existiert): Frame, Event-Registrierung,
  Slash-Befehl `/bks test`.
- `sounds.lua` — reine Datenliste der Dateinamen.
- `BossKillSound.toc` — Manifest, Interface 11509 (Classic Era); für Forever beim
  Launch ggf. Nummer anpassen.
- `tests/wow_mock.lua` — minimale WoW-API-Nachbildung (CreateFrame, Events, PlaySoundFile-Recorder).
- `tests/test_core.lua` — Headless-Tests unter normalem Lua 5.4.

## Fehlerbehandlung

`PlaySoundFile` schlägt fehl (Datei fehlt) → Rückgabewert prüfen, nächste Datei aus dem
Pool versuchen, einmalige Chat-Warnung. Kein Lua-Error nach außen.

## Tests

1. Headless: Kill (success=1) spielt Sound; Wipe (success=0) nicht; alle 4 Sounds werden
   über viele Kills getroffen; kein Direkt-Repeat; Dateien in `media/` existieren wirklich;
   Fallback bei fehlgeschlagenem PlaySoundFile.
2. Live in Classic Era: Addon-Ordner kopieren, `/bks test` im Spiel, dann echter
   Dungeon-Boss.
3. Forever-Launch: Ordner nach `_forever_\Interface\AddOns` kopieren, TOC-Interface-Nummer
   prüfen.
