# Research Notes — Vanilla Executor Internals

What is known about vanilla Executor from public sources, and what still has to
come from a local copy of the game.

Sources:

- [soulsmods/Paramdex](https://github.com/soulsmods/Paramdex) (`NR/`): param layouts and community row names.
- [LordExelot/EldenRingNightreignHKS](https://github.com/LordExelot/EldenRingNightreignHKS): community-decompiled
  `c0000.hks`, last updated July 2025. It may not match the current game version.
- Nexus Mods comments on "Always Perfect Deflect for Executor" (seen through search snippets only).

## Player behavior script (`c0000.hks`)

Executor is `HERO_TECHNICAL`.

| Thing | Where / ID | Notes |
|---|---|---|
| Cursed Sword stance active | SpEffect `707060` | `IsDemonSwordMode()` |
| Beast form active | SpEffect `707115` | `IsDemonBeastMode()` |
| Deflect window active | SpEffect `707000` | Guarding while it is on counts as a deflect (`is_demonsword_justguard`) |
| Dash-slash variant | SpEffect `707051` | On → `IndexDemonSwordArts = 0` (has 1.7× movement, the dash), off → `1`. Which one is the awakened slash is unverified |
| Stance animation layer | Variable `AddDemonSwordModeBlend` | 1 for the whole stance (set on stance start, cleared by the stance end). Nothing in the script applies `707060`, so the stance's effects and the Cursed Sword in hand most likely come from this layer's animations; unverified |
| Stance layer selector | SpEffect `707065` ("Move Cursed Sword to Left Hand") → `AddDemonSwordModeBlendSelector` | Picks the layer's left-hand variant while `707065` is on |
| Skill button | `ATTACK_REQUEST_SKILL` branch for `HERO_TECHNICAL` | Toggles the stance: `Event_DemonSwordStanceStart` / `Event_DemonSwordStanceEnd` |
| Dash slash | `ATTACK_REQUEST_DEMONSWORDARTS` → `W_DemonSwordArts` | Only reachable from inside the stance |
| Stance guard | `GUARD_STYLE_DEMONSWORD`, `IndexGuard = 4` | `IndexGuardTechnical`: 0 = deflect, 1 = normal block |
| Ultimate Art | `W_DemonBeastStart` | No explicit end event in the script |
| Stamina | `env(1001)` reads it, `act(1001, n)` changes it | Negative `n` spends (vanilla: `act(1001, -1)` per tick of a ride dash), positive gives back |
| Deflect during the dash slash | `ExecAddDamage(..., is_demonsword_justguard)` → `W_AddDamageGuardStartDemonSword` | Additive flinch on top of the slash, used when the guard hit level is 0 |
| Missing globals | End of `c0000.hks` | The script sets a metatable on `_G`, so an undefined name is a function that does nothing |

Available script calls: `env(GetHP)` (absolute HP), `env(GetEquipWeaponCategory, hand)`,
`env(GetGuardMotionCategory, hand)`, `env(GetSpEffectID, id)`, `act(AddSpEffect, id)`.
The weapon category constants live in a separate file that isn't in the community repo.

### The game's current script (`mod/action/script/c0000.hks`)

Decompiled with [DSLuaDecompiler](https://github.com/katalash/DSLuaDecompiler) (built for .NET 8).
It uses numeric IDs instead of names; the ones the rework relies on:

| ID | Name (from the community list) | Used in vanilla Nightreign |
|---|---|---|
| `env(371)` | GetHeroID | yes |
| `env(1000)` | GetHP | yes |
| `env(2013)` | GetMaxHP | no |
| `env(1106, button)` | ActionRequest | yes |
| `env(1116, id)` | GetSpEffectID | yes |
| `env(225, hand)` | GetEquipWeaponCategory | yes |
| `act(2002, id)` | AddSpEffect | yes |
| `act(9001, id)` | ClearSpEffect | no |

The decompiler garbled one table constructor (`heroFootOffsetTables`, foot IK offsets per
hero). It was rebuilt by hand from the same numbers; the first 8 heroes match the community
copy exactly. The rest of the file passes a Lua 5.1 syntax check.

## Params (`regulation.bin`)

| Param | Row / field | Use for the rework |
|---|---|---|
| `HeroParam` | row `8` = Executor, `characterAbilityCooldown` (f32, vanilla `0`) | Skill cooldown (set to 12) |
| `HeroOperationExplanationParam` | rows `800`–`802` | Passive / skill / Ultimate description entries |
| `SpEffectParam` | `noDead` | Beast cannot die |
| `SpEffectParam` | `maxHpRate`, `changeHpRate`, `changeHpPoint`, `bCurrHPIndependeMaxHP` | Beast HP percentage and restoring HP on exit |
| `SpEffectParam` | `conditionHp`, `conditionHpRate` | HP-threshold triggers (Beast reaching 0, HP snapshot steps) |
| `SpEffectParam` | `accumuVal`, `accumuOverVal`, `accumuOverFireId`, … | 4-deflect counter |
| `SpEffectParam` | `effectEndurance` | Deflect window lengths, 20 s awakened timer |
| `EquipParamWeapon` | `wepType`, `weaponCategory`, `guardmotionCategory` | Weapon groups for the passive |
| `SpEffectParam` names | `7999070` "Executor: Apply StateInfo 2255", `49370`, `707050`, `707051` | Names only; purpose unverified |

### Vanilla values (read from the game, Smithbox 2.2.6)

`SpEffectParam 707000` — "[Skill - Executor] Cursed Sword - Just Guard". Fields that differ from the usual defaults:

| Field | Value | Meaning |
|---|---|---|
| `stateInfo` | `606` | "Deflecting" — this is what makes a block count as a deflect |
| `effectEndurance` | `0` | No own duration; the animation event turns it on and off |
| `spCategory` | `162` | "Remove Previous": applying it removes other active effects of category 162. The rework's window copies (707001–707003) use `20` ("Reset on Apply") instead: they are applied on every block press, and with `162` a frost weapon coating disappeared on the first block (seen in game) |
| `guardStaminaMult` | `0.1` | Blocking costs 10% of the usual stamina while deflecting |

`accumu*`, `noDead`, `conditionHp*`, `maxHpRate` and `changeHp*` are all unused (defaults).

### All Executor SpEffects (row names from the game's Smithbox project)

| ID | Name |
|---|---|
| `707000` | [Skill] Cursed Sword - Just Guard (deflect window) |
| `707010` | [Skill] Prevent Guard End |
| `707030` | [Skill] Deflect Guard Hit |
| `707040` / `707041` | [Skill] Active During Unlocked Sword Skill / chain from it |
| `707050` | [Skill] Cursed Sword - Accumulator 10 |
| `707051` | [Skill] Cursed Sword - Art Active (awakened sword; HKS picks `IndexDemonSwordArts = 0` for it) |
| `707052`, `707057` | [Skill] Cursed Sword - Clear Accumulator 10 |
| `707053` | [Skill] Cursed Sword - AccumuVal 5 (Guard) |
| `707054` | [Skill] Cursed Sword - AccumuVal 10 |
| `707055` | [Skill] Cursed Sword - AccumuVal 15 (Deflect) |
| `707056` | [Skill] Cursed Sword - AccumuVal 20 (Deflect Knockback) |
| `707060` | [Skill] Cursed Sword Active (stance) |
| `707065` | [Skill] Move Cursed Sword to Left Hand |
| `707070` / `707071` | [Passive] Tenacity (Start) / Tenacity |
| `707100` | [Ultimate] Is Beast Form (HKS Identifier) |
| `707110` | [Ultimate] Immortality |
| `707115` | [Ultimate] Beast Health Boost |
| `707120` | [Ultimate] Prevent Untransform |
| `707130` | [Ultimate] Category 1002, Priority 254 |
| `707140` | [Ultimate] Skill Damage Negation and Prevent Death |
| `707200`–`707215` | [Ultimate] Beast Attack Boost - Level 0–15 |
| `707220`–`707224` | [Ultimate] Beast Depth 1–5 |
| `603070` / `603071` | [Character Guide] Skill Active / Ult Active |

Takeaways (from the exported values, `SpEffectParam.csv` / `HeroParam.csv`):

- **Awakening counter.** `707050` is an accumulator that fires `707051` (awakened sword)
  once it passes `50`. Contributions: guard `707053` +5, deflect `707055` +15, knockback
  deflect `707056` +20, `707054` +10; `707052` / `707057` clear it. Vanilla therefore needs
  4 plain deflects (45 after 3, 60 after 4), fewer if blocks or knockback deflects mix in.
  Rework: guard +0 and knockback deflect +15, so exactly 4 deflects awaken the sword.
- **Awakened duration.** `707051` has `effectEndurance = -1` (lasts until used). Rework: `20`.
- **Skill cooldown.** Executor's `characterAbilityCooldown` is `0` (the stance is a toggle).
  Other heroes use 8–14 s (Wylder 8, Ironeye 10, Duchess/Raider/Scholar 12, Guardian 13.5,
  Undertaker 14). Rework: `12`.
- **Deflect.** `707000` takes 0% damage and 0% status buildup while active and sets
  `stateInfo 606` (Deflecting); blocking costs 10% stamina.
- **Beast form.** `707100` (`stateInfo 2290`) marks Beast form; `707115` doubles max HP
  (`maxHpRate 2`); `707110` cuts damage taken to 30%; `707140` cuts it to 80% and is tied to
  state 2290. None of them heal or set `noDead`, so the vanilla full heal comes from somewhere
  else (animation event or HKS), still to be found. `noDead` is unused and free for the
  "Beast dies → back to Executor" rule.
- **Tenacity.** `707070` (1.5 s start) → `707071` (18.5 s): +20% attack, +15 stamina regen.
  Removing it is part of the passive rework.
- The community HKS checks `707115` for Beast form; the game names `707100` the HKS
  identifier. The current `c0000.hks` is needed to confirm which one is checked.

## Animations

From the game's `chr/c0000.anibnd.dcx` (Oodle Kraken DCX with a BND4 of `.tae` timelines,
`a00.tae` holds the `a000_*` animations):

| Animation | What | Relevant events |
|---|---|---|
| `a000_019070` | Stance guard start | `707000` (deflect window) 0–0.333 s, `707010` 0–0.467 s |
| `a000_019480`–`019488` | Stance deflect reactions (full body) | sparks `462800` at dummy poly 5110, sound `c809000` at 100, `707055` (accumulator +15), `707000` 0–0.167 s |
| `a000_019490`–`019496` | Stance block reactions | `707053` (accumulator +5), no sparks |
| `a000_010005` | Deflect flinch during the dash (`W_AddDamageGuardStartDemonSword`) | sparks `462801` at 5110, sound `c809001`, `707053` |
| `a907` `571000`–`571025` | Stance start / dash slash | `707000` windows, `707060` |
| `a907` `579000` / `579001` | Stance layer (`AddDemonSwordModeBlend`, selector 0/1) | `707060`, weapons to sheathed spots (712, every grip), Cursed Sword attached to dummy poly 20 / 21 (719), Set Weapon Style = right weapon two-handed (32) |
| `a907` `571010` | Stance end | Set Weapon Style = one-handed (32), which is why vanilla always ends the stance one-handed |

- Dummy poly 5110 is on the Executor's Cursed Sword model; while it is sheathed it sits at
  the hip, so its sparks float below a normal weapon's clash.
- Dummy polys from 10000 are on the right-hand weapon (10000 + id), from 11000 on the
  left-hand weapon; 10300 / 11300 are the points vanilla weapon effects use most. 20000+ is
  used too (e.g. 20300 next to 10300), but in game 20300 did not put effects on the left claw
  of two-handed claws. Body dummy polys 20 / 21 are the right / left hand (the stance layer
  attaches the Cursed Sword there).
- Every guard style's guard start (`a000_019000` and its overrides in `a02`, `a03`, `a10`,
  `a12`–`a16`) enables guarding at 0.0 s, so no weapon type has a slower guard.
- Timeline format notes (ER/NR `TAE `, 64-bit): animation header = events offset, event
  groups offset, times offset, file offset, event count, group count, times count; event
  header = start time offset, end time offset, data offset; event data = type, 0, params
  offset, params. Event groups are (count, index offset, group data offset, 0) with 4-byte
  event header offsets padded to 16 bytes. One-shot effect and sound events have a
  "state info" condition: they only play while a SpEffect with that `stateInfo` is on.
- Nightreign's DCX blocks each start fresh (restart flag), which older Kraken decoders
  (ooz) mishandle: every 256 KiB block must be decoded on its own.

## Only available from a local game copy

1. ~~The vanilla deflect window length~~ Found: 0.333 s (see Animations).
2. The vanilla values of SpEffects `707000`, `707051`, `707060`, `707065`, `707115`,
   the Tenacity effect and the Beast heal (Paramdex has layouts and names, not values).
3. `c0000.hks` for the current game version.
4. In-game testing (solo and co-op).
