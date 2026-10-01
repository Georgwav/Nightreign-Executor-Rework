# Nexus Mods Page

Everything for the Elden Ring Nightreign page on Nexus Mods. The description is Nexus BBCode:
paste it into the description editor's BBCode view.

Before publishing, finish the release and weapon coating tests in [TODO.md](TODO.md).

## Page fields

| Field | Value |
|---|---|
| Name | Executor Rework |
| Version | 1.0.0 |
| Category | Gameplay (or the closest character / class category) |
| Brief overview (max. 350 characters) | A rework of the Executor built around deflects: deflect with almost any weapon, with the window set by weapon class; Cursed Sword becomes a Suncatcher dash slash that four deflects empower; the Beast Ultimate keeps your health. Drop-in mod files for any me3 setup; Seamless Co-op ready. |
| Requirements | A mod loader that loads loose files, e.g. me3 (https://github.com/garyttierney/me3/releases/latest); optional: Seamless Co-op for Nightreign, for co-op |
| Main file | `ExecutorRework-v1.0.0.zip`: "Executor Rework", the mod files to drop into a mod folder |
| Optional file | `ExecutorRework-Standalone-v1.0.0.zip`: "Standalone (me3)", the mod files plus a me3 profile, for players without a mod setup |
| Optional file | `ExecutorRework-SeamlessCoop-v1.0.0.zip`: "Seamless Co-op (me3)", the mod files plus a me3 profile that loads Seamless Co-op, and the save copy helper |
| Optional file | `ExecutorRework-merge-params-v1.0.0.zip`: "Merge params", the param rows as CSV for merging with another `regulation.bin` mod in Smithbox |
| Tags | Gameplay, Overhaul, Characters, Combat |
| Images | Deflect sparks on a katana, a dagger and a greatsword; the awakened Suncatcher slash; the character select screen with the new texts |
| Permissions | Your choice. Common for gameplay mods: credit required, no re-uploads, ask before using assets |

## Description (BBCode)

```
[size=5][b]Executor Rework[/b][/size]

The Executor keeps his cursed blade, Suncatcher, but his whole kit is built around perfect deflects. Deflect with almost any weapon, empower Suncatcher with four deflects, and fight as the Beast at the health you really have.

[line]
[size=4][b]Passive: Deflection[/b][/size] (replaces Tenacity)

Block right as an attack lands to deflect it with your own weapon:
[list]
[*]no damage and no status buildup
[*]only 10% of the usual block stamina
[*]no guard break or knock-back
[*]your weapon's own guard animation, with Suncatcher's deflect sparks and sound
[/list]

The deflect window depends on the weapon you block with (share of the Cursed Sword window):
[list]
[*][b]100%[/b]: katanas, daggers, straight / curved / thrusting swords, twinblades, fists, claws
[*][b]65%[/b]: greatswords, curved greatswords, heavy thrusting swords, axes, greataxes, hammers, great hammers, flails, spears, great spears, halberds, reapers
[*][b]30%[/b]: colossal swords, colossal weapons
[*][b]Cannot deflect[/b]: whips, bows, crossbows, ballistae, staves, seals, shields, torches
[/list]
Mashing block never deflects: a new window only opens 0.5 s after the last one. A successful deflect resets that, so every hit of a combo can be deflected.

[size=4][b]Character Skill: Cursed Sword[/b][/size]
[list]
[*]A single dash slash with Suncatcher; no stance, and your grip stays as it was
[*]12 s cooldown
[*]Four deflects imbue Suncatcher with holy light for 20 s: the next slash is the empowered one
[/list]

[size=4][b]Ultimate Art: Aspects of the Crucible: Beast[/b][/size]
[list]
[*]The Beast keeps your health percentage; there is no free heal
[*]When the form ends or the Beast falls, you return with the health you had before
[/list]

[size=4][b]Relics[/b][/size]
The Executor's Character Skill relics trigger on the empowered slash (13 s).

The in-game texts (English) describe the new abilities.

[line]
[size=4][b]Installation[/b][/size]
[b]Offline only.[/b] Mod loaders start the game without Easy Anti-Cheat and without the official online servers. Never play online with modified files.

The main file holds only the mod files, in the game's folder layout:
[code]regulation.bin
action\script\c0000.hks
chr\c0000.anibnd.dcx
msg\engus\menu_dlc01.msgbnd.dcx[/code]
[b]Existing mod setup:[/b] drop them into your mod folder like any other mod. With me3, extract them into their own folder and add it to your profile as a package (listed last), or into a package folder you already use.

[b]No mod setup yet:[/b] download the optional [b]Standalone (me3)[/b] file instead.
[list=1]
[*]Install [url=https://github.com/garyttierney/me3/releases/latest]me3[/url] (me3_installer.exe).
[*]Extract the zip into a new folder, e.g. C:\Games\ExecutorRework.
[*]Double-click [b]executor-rework.me3[/b] to start the modded game.
[/list]
To uninstall, remove the files. Starting the game from Steam is always vanilla.

[size=4][b]Co-op[/b][/size]
Co-op runs through [b]Seamless Co-op for Nightreign[/b] (download it separately). Every player needs the same version of Executor Rework and of Seamless Co-op. Download the optional [b]Seamless Co-op (me3)[/b] file:
[list=1]
[*]Install [url=https://github.com/garyttierney/me3/releases/latest]me3[/url] and extract the zip into a new folder.
[*]Copy the SeamlessCoop folder from the Seamless Co-op download (nrsc.dll, nrsc_settings.ini) into that folder.
[*]Optional, to keep your progress: with the game closed, run [b]copy-save-to-coop.bat[/b] (copies your NR0000.sl2 save to the co-op save NR0000.co2).
[*]Double-click [b]executor-rework-coop.me3[/b]. Don't use nrsc_launcher.exe, it starts the game without this mod.
[/list]
Own me3 profile: add Seamless Co-op as a native with [b]load_early = true[/b] (without it Seamless Co-op stops with "Method SignIn is not available").

[size=4][b]Other mods[/b][/size]
A me3 profile can load several mods: one [[natives]] block per DLL mod and one [[packages]] block per mod folder. When two packages contain the same file, the one listed last is used; keep Executor Rework last. In one shared mod folder, the copy you extracted last stays.

[code]profileVersion = "v1"

[[supports]]
game = "nightreign"

[[natives]]
path = 'SeamlessCoop/nrsc.dll'
load_early = true

[[packages]]
id = "other-mod"
path = 'OtherMod'

[[packages]]
id = "executor-rework"
path = 'ExecutorRework'[/code]

Executor Rework replaces these files and needs all of them:
[list]
[*][b]regulation.bin[/b]: merge it with another balance mod in Smithbox by importing the optional [b]merge params[/b] CSVs into the other mod's params (steps in ExecutorRework-README.txt)
[*][b]action\script\c0000.hks[/b] and [b]chr\c0000.anibnd.dcx[/b]: not compatible with other player behavior or player animation mods
[*][b]msg\engus\menu_dlc01.msgbnd.dcx[/b]: English menu texts; not compatible with other English menu text mods
[/list]

[line]
[size=4][b]Credits[/b][/size]
[list]
[*][url=https://github.com/garyttierney/me3]me3[/url] by garyttierney and contributors
[*][url=https://github.com/vawser/Smithbox]Smithbox[/url] by vawser and contributors
[*][url=https://github.com/katalash/DSLuaDecompiler]DSLuaDecompiler[/url] by katalash ([url=https://github.com/nex3/DSLuaDecompiler]nex3's fork[/url])
[*]The Kraken decoder from [url=https://github.com/powzix/ooz]ooz[/url]
[*][url=https://github.com/Nordgaren/UXM-Selective-Unpack]UXM Selective Unpack[/url] by Nordgaren
[/list]

Elden Ring Nightreign is (c) FromSoftware / Bandai Namco. This is an unofficial fan mod.
```

## Changelog entry

```
1.0.0: first release.
```
