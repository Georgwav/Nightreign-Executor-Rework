# Building a Release

A release is a main zip with the mod files in the game's folder layout, which players drop
into their mod setup, plus three optional zips: a standalone and a Seamless Co-op version
with me3 profiles, for players without a setup, and the param rows for merging (see the
player install in the [README](../README.md#install-players)). The main zip holds the mod files from this
repository plus the `regulation.bin` built by the Smithbox project, since the params can
only be built there.

## 1. Update the params

In the Smithbox project, import the latest `mod/params/SpEffectParam.csv` and
`mod/params/HeroParam.csv` (see [INSTALL.md](INSTALL.md#2-import-the-balance-data-in-smithbox))
and save. This writes `%USERPROFILE%\ExecutorRework\regulation.bin`, the build script's
default (otherwise pass `-Regulation`).

Only the rework's rows may differ from vanilla: start the project from an unmodified game
copy and don't edit other params in it.

## 2. Build the zips

Download the repository (**Code → Download ZIP**, a fresh copy each time), then in
PowerShell (any folder):

```powershell
Expand-Archive "$env:USERPROFILE\Downloads\Nightreign-Executor-Rework-main.zip" "$env:USERPROFILE\Downloads" -Force
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\Downloads\Nightreign-Executor-Rework-main\tools\build_release.ps1" -Version 1.0.0
```

The script takes the mod files from the repository folder it sits in. If `regulation.bin`
is somewhere else, add `-Regulation <path to regulation.bin>`.

It writes four zips to `Downloads` and lists the files in each (all at the top level of the
zip):
- `ExecutorRework-v1.0.0.zip` (main): `regulation.bin`, `action\script\c0000.hks`,
  `chr\c0000.anibnd.dcx`, `msg\engus\menu_dlc01.msgbnd.dcx` (the English texts) and
  `ExecutorRework-README.txt` (the player notes, from `release/README.txt`);
- `ExecutorRework-Standalone-v1.0.0.zip`: the same plus `executor-rework.me3` (package path
  `.`);
- `ExecutorRework-SeamlessCoop-v1.0.0.zip`: the same plus `executor-rework-coop.me3`
  (package path `.`, `SeamlessCoop/nrsc.dll` loaded early) and `copy-save-to-coop.bat`;
- `ExecutorRework-merge-params-v1.0.0.zip`: `ExecutorRework_SpEffectParam.csv` and
  `ExecutorRework_HeroParam.csv`.

## 3. Test like a player

Extract the Standalone zip into a new folder (not the Smithbox project), double-click
`executor-rework.me3` and check the passive, the skill, the Ultimate Art and the texts.
Then try the main zip the way players with a setup will: as a package in an existing me3
profile, listed after the other packages. For co-op, set up the SeamlessCoop zip as its
README says and play a run together.

## 4. Publish

For Nexus Mods (Elden Ring Nightreign), the page fields and description are in
[NEXUS.md](NEXUS.md). Note on the page the Nightreign version the release was built and
tested on: a game update that changes `regulation.bin`, `c0000.hks`, `c0000.anibnd.dcx` or
`menu_dlc01.msgbnd.dcx` needs a new build (see below).

## After a game update

The repository holds no vanilla game files. Export the ones a rebuild needs from the updated
game with Smithbox: **File Browser**, select the file, **Tools → File Exporter → Export
Container File** (set the output directory first):

- `chr/c0000.anibnd.dcx`: rebuild `mod/chr/c0000.anibnd.dcx` with
  `python3 tools/patch_anibnd.py <vanilla c0000.anibnd.dcx> <ooz_dcx> mod/chr/c0000.anibnd.dcx`.
- `msg/engus/menu_dlc01.msgbnd.dcx`: rebuild the texts with
  `python3 tools/patch_msg.py <vanilla menu_dlc01.msgbnd.dcx> <ooz_dcx> mod/msg/engus/menu_dlc01.msgbnd.dcx`.
  It stops if a vanilla text it replaces has changed.
- `action/script/c0000.hks`: compare with the previous vanilla script and carry the changes
  over to `mod/action/script/c0000.hks`.

Then re-import the CSVs into a Smithbox project made from the updated game, and build and
test the release again.
