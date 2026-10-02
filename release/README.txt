EXECUTOR REWORK - Elden Ring Nightreign mod
===========================================

The Executor becomes a deflect duelist with any dexterity weapon:

- Passive "Deflection" (replaces Tenacity): block right as an attack lands to deflect it
  with your own weapon. No damage, little stamina, Suncatcher's deflect sparks and sound.
  Deflect window by weapon: katanas, daggers, swords, fists, claws 100%; heavy and great
  weapons, spears, halberds 65%; colossal weapons 30%; shields, whips, bows, staves and
  seals cannot deflect. Mashing block never deflects.
- Character Skill "Cursed Sword": a dash slash with Suncatcher (12 s cooldown). Four
  deflects imbue Suncatcher with golden light for 20 s; the next slash is the empowered one.
- Ultimate Art: the Beast keeps your health percentage (no free heal) and can't get
  deathblight; when it ends or falls you return with the health you had before, and
  enemies can't hurt or stagger you until you can act again (and 1 s more).
- The Executor skill relics trigger on the empowered slash.

OFFLINE ONLY. Mod loaders start the game without Easy Anti-Cheat and without the official
online servers. Never play online with modified files.

DOWNLOADS
---------
Pick one:
- ExecutorRework (main): only the mod files, for an existing mod setup.
- ExecutorRework-Standalone: the mod files plus a me3 profile, if you have no mod setup.
- ExecutorRework-SeamlessCoop: the mod files plus a me3 profile with Seamless Co-op.

The mod files (it needs all four):
  regulation.bin
  action\script\c0000.hks
  chr\c0000.anibnd.dcx
  msg\engus\menu_dlc01.msgbnd.dcx   (English ability texts)

INSTALL: EXISTING MOD SETUP (main download)
-------------------------------------------
- me3: extract the zip into its own folder, e.g. mods\ExecutorRework, and add it to your
  profile as a package:

      [[packages]]
      id = "executor-rework"
      path = 'mods/ExecutorRework'

  Or extract it into a package folder you already use.
- Other loaders: extract the zip into the mod folder they load loose game files from.

If another mod has one of the same files, only one of the two copies is used: with me3 the
package listed last, in a shared folder the file you copied last. Load Executor Rework
last. See CONFLICTS below.

For Seamless Co-op in your own me3 profile, add it as a native that loads early:

      [[natives]]
      path = 'SeamlessCoop/nrsc.dll'
      load_early = true

INSTALL: NO MOD SETUP (Standalone download)
-------------------------------------------
1. Install me3: https://github.com/garyttierney/me3/releases/latest (me3_installer.exe).
2. Extract the zip into a new folder, e.g. C:\Games\ExecutorRework.
3. Double-click executor-rework.me3 to start the modded game.

INSTALL: SEAMLESS CO-OP (SeamlessCoop download)
-----------------------------------------------
Every player needs this same download and the same Seamless Co-op version.
1. Install me3: https://github.com/garyttierney/me3/releases/latest (me3_installer.exe).
2. Extract the zip into a new folder, e.g. C:\Games\ExecutorReworkCoop.
3. Download Seamless Co-op for Nightreign and copy its SeamlessCoop folder (nrsc.dll,
   nrsc_settings.ini) into that folder.
4. Optional, to keep your progress: with the game closed, run copy-save-to-coop.bat. It
   copies your save (NR0000.sl2) to the Seamless Co-op save (NR0000.co2). Never copy a
   co-op save back to NR0000.sl2.
5. Double-click executor-rework-coop.me3. Don't use nrsc_launcher.exe: it starts the game
   without Executor Rework.

UNINSTALL: remove the files (or the package). Starting the game from Steam is always
vanilla.

CONFLICTS
---------
- regulation.bin (most balance mods): merge the two in Smithbox with the optional "merge
  params" download. Open a project with the other mod's regulation.bin, import
  ExecutorRework_SpEffectParam.csv into SpEffectParam and ExecutorRework_HeroParam.csv into
  HeroParam (Param Editor, Tools > Data Transfer > Import, Selected Param, Ignore Existing
  Rows off), save, and use that regulation.bin.
- action\script\c0000.hks (player behavior) and chr\c0000.anibnd.dcx (player animations):
  can't be combined with other mods that change them without merging the files by hand.
- msg\engus\menu_dlc01.msgbnd.dcx (English menu texts): the other mod's texts or these,
  not both.

A game update that changes these files needs an updated release.

Elden Ring Nightreign is (c) FromSoftware / Bandai Namco. Unofficial fan mod.
