# Executor Rework

**An Elden Ring Nightreign mod that turns the Executor into a deflect duelist with any
dexterity weapon.**

The Executor keeps his cursed blade, Suncatcher, but his whole kit is built around perfect
deflects:
- **Passive:** deflecting now works with your own weapons, not only inside the Cursed Sword stance.
- **Skill:** a single dash slash with Suncatcher.
- **Ultimate:** the Beast form keeps your health instead of refilling it.

---

## What changes

### Passive: Deflection (replaces Tenacity)

Block right as an attack lands to deflect it with your equipped weapon:
- no damage and no status buildup;
- 10% of the usual block stamina;
- no guard break or knock-back;
- your weapon's own guard animation, plus Suncatcher's deflect sparks and sound;
- no stance damage to the attacker.

The deflect window is a share of the vanilla Cursed Sword window (0.333 s), by the weapon
you block with:

| Weapons | Window |
|---|---|
| Katanas, daggers, straight / curved / thrusting swords, twinblades, fists, claws | 100% |
| Greatswords, curved greatswords, heavy thrusting swords, axes, greataxes, hammers, great hammers, flails, spears, great spears, halberds, reapers | 65% |
| Colossal swords, colossal weapons | 30% |
| Whips, bows, crossbows, ballistae, staves, seals, shields, torches | cannot deflect |

Mashing block never deflects: a press only opens a window if the previous one was at least
0.5 s ago. A successful deflect resets that, so every hit of a combo can be deflected.

### Character Skill: Cursed Sword

- A single dash slash with Suncatcher in hand.
- No stance, and your grip (one-handed or two-handed) stays as it was.
- 12 s cooldown.
- Four deflects imbue Suncatcher with golden light for 20 s. The next skill use is the
  empowered slash, which uses it up.

### Ultimate Art: Aspects of the Crucible: Beast

- You transform at your current health percentage; there is no free heal.
- When the form ends, or the Beast is "killed", you turn back with the health you had
  before transforming.

### Relics

The Executor skill relics trigger on the empowered slash instead of the stance:
- **Attack boost / damage negation penalty:** both apply together, for 13 s.
- **HP regeneration on ability use:** 13 s.
- **HP restore on unlocking the cursed sword:** triggers when Suncatcher awakens.

The full rules are in [docs/DESIGN.md](docs/DESIGN.md).

---

## Install (players)

**Offline only.** Mod loaders like [me3](https://github.com/garyttierney/me3) start the game
without Easy Anti-Cheat and without the official online servers. Never play online with
modified files.

A release has a main download and three optional ones. Players pick one of the first three:

| Download | For | Contents |
|---|---|---|
| `ExecutorRework-v<version>.zip` (main) | An existing mod setup | The mod files in the game's folder layout: `regulation.bin`, `action/script/c0000.hks`, `chr/c0000.anibnd.dcx`, `msg/engus/menu_dlc01.msgbnd.dcx` (English ability texts), plus `ExecutorRework-README.txt` |
| `ExecutorRework-Standalone-v<version>.zip` | No mod setup | The mod files plus `executor-rework.me3` |
| `ExecutorRework-SeamlessCoop-v<version>.zip` | Co-op | The mod files plus `executor-rework-coop.me3` (Seamless Co-op, loaded early) and `copy-save-to-coop.bat` |
| `ExecutorRework-merge-params-v<version>.zip` | Merging with another `regulation.bin` mod | The rework's param rows as CSV |

**Existing mod setup (main download):** the zip goes into a mod folder as it is.
- me3: extract it into its own folder and add that folder to your profile as a package
  (see [Other mods](#other-mods)), or extract it into a package folder you already use.
- Other loaders: extract it into the folder they load loose game files from.

**No mod setup (Standalone download):**
1. Install me3: download `me3_installer.exe` from the
   [me3 releases](https://github.com/garyttierney/me3/releases/latest) and run it.
2. Extract the zip into a new folder, e.g. `C:\Games\ExecutorRework`.
3. Double-click `executor-rework.me3` to start the modded game.

To uninstall, remove the files or the package; starting the game from Steam is always vanilla.

### Co-op

Co-op runs through Seamless Co-op for Nightreign. Every player needs the same version of
Executor Rework and of Seamless Co-op. With the SeamlessCoop download:
1. Install me3 and extract the zip into a new folder.
2. Copy the `SeamlessCoop` folder from the Seamless Co-op download (`nrsc.dll`,
   `nrsc_settings.ini`) into that folder and set the co-op password in `nrsc_settings.ini`.
3. Optional, to keep your progress: with the game closed, run `copy-save-to-coop.bat`. It
   copies your save (`%APPDATA%\Nightreign\<Steam ID>\NR0000.sl2`) to the Seamless Co-op save
   `NR0000.co2` next to it, unless one exists. Never copy a co-op save back to `.sl2`.
4. Start the game with `executor-rework-coop.me3`, not `nrsc_launcher.exe` (that one starts
   the game without Executor Rework).

me3 loads `nrsc.dll` as a native DLL mod. It needs `load_early = true`: loaded later,
Seamless Co-op stops with "Method SignIn is not available". It doesn't need the official
servers. In your own profile:

```toml
[[natives]]
path = 'SeamlessCoop/nrsc.dll'
load_early = true
```

### Other mods

me3 starts one profile (`.me3` file), and a profile can load several mods: one
`[[natives]]` block per DLL mod and one `[[packages]]` block per mod folder. Paths are
relative to the profile. For example, `C:\Games\NightreignMods\my-mods.me3` with the mods in
folders next to it:

```toml
profileVersion = "v1"

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
path = 'ExecutorRework'
```

When two packages contain the same file, the one that loads **last** is used, as a whole
file. Keep Executor Rework last (or give it `load_after = [{ id = "other-mod", optional = true }]`).
In a single shared mod folder, the copy you extracted last is the one that stays.

Executor Rework replaces four files and needs all of them:

| File | Conflicts with | Combining |
|---|---|---|
| `regulation.bin` | most balance mods | Merge in Smithbox with the merge params download: open a project with the other mod's `regulation.bin`, import `ExecutorRework_SpEffectParam.csv` into SpEffectParam and `ExecutorRework_HeroParam.csv` into HeroParam (Param Editor → Tools → Data Transfer → Import, Selected Param, Ignore Existing Rows off), save |
| `action/script/c0000.hks` | player behavior mods | Only by merging the scripts by hand |
| `chr/c0000.anibnd.dcx` | player animation mods | Only by merging the animation files by hand |
| `msg/engus/menu_dlc01.msgbnd.dcx` | English menu text mods | One or the other |

A game update that changes these files needs an updated release.

---

## Development

| Path | What |
|---|---|
| `mod/action/script/c0000.hks` | Player behavior script (all rework logic) |
| `mod/chr/c0000.anibnd.dcx` | Player animation file with the deflect effects and the skill grip fix, built by `tools/patch_anibnd.py` from the vanilla file |
| `mod/msg/engus/menu_dlc01.msgbnd.dcx` | English ability names and descriptions (see [docs/TEXT.md](docs/TEXT.md)), built by `tools/patch_msg.py` from the vanilla file |
| `mod/params/*.csv` | SpEffectParam / HeroParam rows, imported into a Smithbox project that saves `regulation.bin` |
| `tests/script_test.lua` | Runs the whole modded script against a fake engine: `lua5.1 tests/script_test.lua mod/action/script/c0000.hks` |
| `tools/build_release.ps1` | Builds the release zips on Windows |

- [docs/INSTALL.md](docs/INSTALL.md): setting up a development copy and the in-game test list
- [docs/RELEASE.md](docs/RELEASE.md): building a release
- [docs/DESIGN.md](docs/DESIGN.md): full design
- [docs/RESEARCH.md](docs/RESEARCH.md): game research notes
- [docs/TEXT.md](docs/TEXT.md): in-game texts
- [docs/NEXUS.md](docs/NEXUS.md): the Nexus Mods page
- [docs/TODO.md](docs/TODO.md): open items

Built with [Smithbox](https://github.com/vawser/Smithbox), [me3](https://github.com/garyttierney/me3),
[DSLuaDecompiler](https://github.com/katalash/DSLuaDecompiler) ([nex3's fork](https://github.com/nex3/DSLuaDecompiler))
and the Kraken decoder from [ooz](https://github.com/powzix/ooz).

Elden Ring Nightreign is © FromSoftware / Bandai Namco. This is an unofficial fan mod.
