# Executor Rework — Design Spec

Status: all three parts are implemented and tested in game; the latest changes are waiting
for in-game testing (see [INSTALL.md](INSTALL.md)).

The mod works solo and in co-op. In co-op every player needs the mod installed
and Easy Anti-Cheat turned off; each player's game handles their own Executor.

## Passive — Deflect with most weapons

Replaces Executor's vanilla passive (Tenacity).

Guarding at the right moment deflects the attack, with any weapon type listed below.
The deflect window is the vanilla Cursed Sword deflect window multiplied by the
weapon type's percentage. The window opens when the block button is pressed.

The window comes from the item you are guarding with. A shield in the left hand
means no deflect, even with a katana in the right hand.

| Group | Deflect window | Weapon types |
|---|---|---|
| Dex | 100% | Dagger, Straight Sword, Thrusting Sword, Curved Sword, Katana, Twinblade, Fist, Claw |
| Str | 65% | Greatsword, Curved Greatsword, Heavy Thrusting Sword, Axe, Greataxe, Hammer, Great Hammer, Flail (spiked ball on a chain), Spear, Great Spear, Halberd, Reaper |
| Colossal | 30% | Colossal Sword, Colossal Weapon |
| None | 0% (cannot deflect) | Whip, Light Bow, Bow, Greatbow, Crossbow, Ballista, Glintstone Staff, Sacred Seal, all Shields, Torch |

Windows are rounded to the nearest frame. Any group above 0% gets at least 1 frame.
The vanilla window is 0.333 s (10 frames at 30 fps; the stance guard animation `a000_019070`
applies `707000` for 0.333 s): 100% = 0.333 s, 65% = 7 frames (0.233 s), 30% = 3 frames (0.1 s).

A deflect takes no damage or status buildup, costs 10% of the usual block stamina and
cannot be guard-broken, like the vanilla Cursed Sword deflect. It also stops attacks that
knock you back through a guard (guard break blast / fling), which weak guards like daggers
get more often; the vanilla stance deflect doesn't. Unlike the vanilla deflect,
it deals **no stance damage** to the attacker: the window effects don't carry the
"Deflecting" state (`stateInfo 606`). Weapon coatings and other buffs stay on: the window
effects only replace themselves (`spCategory 20`, "Reset on Apply"), not the vanilla
category `162` ("Remove Previous"), which removed a frost coating on the first block.

- **Stamina:** without the "Deflecting" state the game charges the full block cost, so the
  script refunds 90% of it right after the hit (it reads stamina with `env(1001)` and
  gives it back with `act(1001, n)`). Each hit in a window is measured separately.
- **Animation:** the weapon's own light guard reaction (`W_GuardDamageSmall`), whatever the
  hit and the weapon's guard strength; a normal block keeps its usual reaction level.
- **Sparks and sound:** the Cursed Sword's small deflect flinch
  (`W_AddDamageGuardStartDemonSword`, animation `a000_010005`, the one vanilla plays for a
  deflect during the dash slash) is layered on top of the guard reaction. The mod ships a
  patched `chr/c0000.anibnd.dcx` in which that flinch plays the full Cursed Sword deflect
  effects (from its full-body deflect `a000_019480`): sparks `462800` where the blocking
  weapon takes the hit, and the deflect sound `c809000`. The script plays the flinch directly
  on every deflect (vanilla's `ExecAddDamage` skips it on some hits). The spark point comes
  from a marker effect the script applies with the deflect window, for the weapon that blocks
  (the right one when two-handing it, otherwise the left, like vanilla's guard animation):

  | Blocking weapon | Marker (state info) | Spark point |
  |---|---|---|
  | Right weapon, two-handed | 707008 (2195) | right weapon's blade, dummy poly 10300 |
  | Left weapon | 707009 (2196) | left weapon's blade, 11300 |
  | Dagger / fist / claw in the left hand; claws / fists two-handed (they block with the left hand) | 707012 (2197) | left hand, 21 |
  | Dagger two-handed | 707013 (2198) | right hand, 20 |

  Dummy polys 20 / 21 are the hand points the stance layer attaches the Cursed Sword to.
  During the stance (a deflect during the dash slash, state info 609) the flinch keeps its
  vanilla sparks on the Cursed Sword. See `tools/patch_anibnd.py`.

Block spam protection: after a block press there is a 0.5 s recovery. Pressing block again
during it opens no deflect window and restarts the recovery, so mashing block never deflects.
A successful deflect ends the recovery right away, so each hit of a combo can still be deflected.

## Character Skill — Cursed Sword

- No stance. Pressing the skill immediately performs the dash slash with the Cursed
  Sword in hand, without the draw and put-away animations. When the slash ends, the
  equipped weapon is back in hand right away.
- Your grip stays as it was: one-handed, the right weapon two-handed or the left weapon
  two-handed.
- Weapon coatings (e.g. frost) stay on through the skill: the dash slash animations
  (`a907_571020` / `571025`) apply the vanilla deflect window `707000`, whose category
  `162` ("Remove Previous") removed the coating; the rework's copy of `707000` uses
  category `20` like its own window effects.
- Implementation: the script plays the dash slash (`W_DemonSwordArts`) and turns on the
  stance's animation layer (`AddDemonSwordModeBlend`), which holds the Cursed Sword,
  only while the slash plays. The layer (`a907_579000` / `579001`) sheathes the weapons and
  attaches the Cursed Sword; its "Set Weapon Style: right weapon two-handed" event is
  disabled in the patched `chr/c0000.anibnd.dcx`, since it left the right weapon two-handed
  after every skill use. If the slash hasn't started after 30 frames, the layer is
  turned off again.
- No attacks during the slash and for 0.2 s after it (and while the stance state from the
  layer lingers): while the layer fades out, an attack would still use the Cursed Sword's
  moveset with the equipped weapon in hand. A buffered R1/R2 comes out once the layer is gone.
- Normal cooldown skill: **12 s** (default, allowed range 8–15 s).
- Every successful deflect from the passive adds 1 to a counter. Deflects count
  even while the skill is on cooldown (default).
- At **4** deflects the sword awakens for **20 s**. Using the skill while awakened
  performs the enhanced (awakened) dash slash and uses up the awakening.
- The counter starts again from 0 after awakening; deflects while awakened don't count.

## Ultimate Art — Aspects of the Crucible: Beast

Moveset, roar and Ultimate gauge use are unchanged from vanilla.

The Beast has its own health, based on percentages:

- On transforming, your current HP percentage is saved and the Beast starts at
  that same percentage of its max HP. There is **no heal** (vanilla fully restores
  HP here). Example: at 50% HP you become a 50% HP Beast.
- If the Beast dies, you don't die: you turn back into the Executor with the HP you
  had before using the Ultimate Art.
- The same happens when the transformation ends normally. Damage taken (or healing
  received) as the Beast does not carry over.
- When the form ends you can't die, take damage from enemies or be staggered until you
  can act again (roll), and for 1 s after that, so the rest of the combo that brought the
  Beast down can't kill you before you can get away.
- The Beast can't get deathblight.

Implementation: behavior script + special effects.

- The HP percentage is saved when the Ultimate Art is used, set on the Beast once the
  transformation is done, and restored when the form ends, in 1% steps (never below 1%).
  "Done" is the first of: the Beast idle, an attack straight out of the transformation
  (which skips the idle), or 3 s in Beast form. Before, attacking out of the transformation
  skipped the setup: the Beast kept the vanilla full heal, couldn't end at 1 HP, and the
  Executor came out of the form at 1 HP.
- The form's end is detected whether or not the setup ran.
- The Beast form has `noDead` set, so the killing blow leaves it at 1 HP; the script
  then ends the form instead.
- Exit protection: `SpEffectParam 707014` (1 s, `noDead`, enemy and object damage x0,
  poise damage x0 (`saReceiveDamageRate`), `disableCurse`), applied on both exits (when the
  Beast falls, before its form is cleared) and then every frame until the Executor is in
  the idle or move state again (`Idle_onUpdate` / `Move_onUpdate`), where it can act; then
  it runs out 1 s later. The refreshing stops after 5 s at the latest. There is no untransform
  animation with its own cancel window to tie this to: the Beast form is the `707115` effect
  that the Beast animations (`a907_670000` / `670010`) keep on.
- The Beast form (`707115`) has `disableCurse`: a deathblight proc that `noDead` lets the
  Beast survive can kill the Executor once the form ends (a likely cause of a death right
  after the form in a deathblight area).
- The Beast uses the normal HP bar; there is no separately drawn bar.

## Tunables

| Setting | Value | Where |
|---|---|---|
| Skill cooldown | 12 s (default, range 8–15 s) | `HeroParam` row 8 |
| Deflects to awaken | 4 | `EXECUTOR_DEFLECTS_TO_AWAKEN` in `c0000.hks` |
| Awakened duration | 20 s | `SpEffectParam` 707051 `effectEndurance` |
| Deflects count during cooldown | Yes (default) | — |
| Dex / Str / Colossal / None deflect window | 100% / 65% / 30% / 0% | `SpEffectParam` 707001–707003 `effectEndurance` |
| HP step | 1% | `SpEffectParam` 707301–707317 |
| Block spam recovery | 0.5 s | `SpEffectParam` 707004 `effectEndurance` |

## Relics

The Executor relics that vanilla ties to the stance are re-hooked. The skill itself can be
used every cooldown, so the skill relics only trigger on the awakened slash:

| Relic | Rework trigger |
|---|---|
| Character Skill boosts attack but lowers damage negation | Awakened slash: +35% attack on all attacks (707005; vanilla only boosts Cursed Sword attacks) and 40% more damage taken (707007) together, both 13 s |
| While Character Skill is active, unlocking use of cursed sword restores HP | The sword awakening after 4 deflects (7034501) |
| Slowly restores HP upon ability activation | Awakened slash: regeneration for 13 s (707006; vanilla chains to a 58.5 s regen). Re-applying refreshes it instead of stacking |
| Roaring restores HP while Art is active | Unchanged; heals the Beast's own HP |

The stance's animation layer is on during every dash slash and may turn on the stance's
effects, so the vanilla stance triggers of the first and third relic are turned off
(7034401 and 7500701); otherwise every skill use could trigger them.

## Open questions

Known issues and the next fixes are tracked in [TODO.md](TODO.md).

1. Confirm the skill cooldown (default 12 s).
2. Confirm deflects count while the skill is on cooldown (default yes).
3. ~~Measure the vanilla deflect window~~ Done: 0.333 s (`a000_019070`), as assumed.
4. Co-op: which unofficial co-op method to support with Easy Anti-Cheat off.
