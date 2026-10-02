# Install and Test

The mod has four parts:

- `mod/action/script/c0000.hks`: the player behavior script (loaded as a loose file).
- `mod/chr/c0000.anibnd.dcx`: the player animation timelines, with the deflect effects
  patched in (loaded as a loose file; built by `tools/patch_anibnd.py`).
- `mod/msg/engus/menu_dlc01.msgbnd.dcx`: the English ability texts (loaded as a loose file;
  built by `tools/patch_msg.py`).
- `mod/params/*.csv`: balance data, imported into a Smithbox project that saves a
  modded `regulation.bin`.

me3 loads them from one folder and starts the game without Easy Anti-Cheat and without
the official online servers. **Never play online with modified files.**

The steps below use the Smithbox project folder `%USERPROFILE%\ExecutorRework` (for example
`C:\Users\<you>\ExecutorRework`) as the mod folder; change the path if yours is elsewhere.

## 1. Get the files

On the [repository page](https://github.com/Georgwav/Nightreign-Executor-Rework) click
**Code → Download ZIP**. It saves `Nightreign-Executor-Rework-main.zip` to your Downloads folder.

Then in PowerShell:

```powershell
$dir = "$env:USERPROFILE\ExecutorRework"
Expand-Archive "$env:USERPROFILE\Downloads\Nightreign-Executor-Rework-main.zip" "$env:USERPROFILE\Downloads" -Force
$src = "$env:USERPROFILE\Downloads\Nightreign-Executor-Rework-main\mod"
New-Item -ItemType Directory -Force "$dir\action\script", "$dir\chr", "$dir\msg\engus" | Out-Null
Copy-Item "$src\action\script\c0000.hks" "$dir\action\script\c0000.hks" -Force
Copy-Item "$src\chr\c0000.anibnd.dcx" "$dir\chr\c0000.anibnd.dcx" -Force
Copy-Item "$src\msg\engus\menu_dlc01.msgbnd.dcx" "$dir\msg\engus\menu_dlc01.msgbnd.dcx" -Force
Copy-Item "$src\params\SpEffectParam.csv" "$dir\SpEffectParam_rework.csv" -Force
Copy-Item "$src\params\HeroParam.csv" "$dir\HeroParam_rework.csv" -Force
```

## 2. Import the balance data in Smithbox

1. Open the `Executor Rework` project in Smithbox and go to the **Param Editor**.
2. Open `SpEffectParam` in the Params list.
3. In **Tools → Data Transfer → Import**: set **Import Mode** to **Selected Param**,
   make sure **Ignore Existing Rows** is **off**, then click **Import from File** and
   pick `SpEffectParam_rework.csv`. It adds 26 new rows (707001–707009, 707012–707014,
   707301–707307, 707311–707317) and updates 707000, 707051, 707070, 707071, 707115, 7034401
   and 7500701.
   Importing it again after an update is safe; rows that are already there are just updated.
4. Open `HeroParam` and import `HeroParam_rework.csv` the same way.
5. Save the project (**File → Save**, or Ctrl+S). This writes `regulation.bin` into
   `%USERPROFILE%\ExecutorRework`.

## 3. Install me3 and create the profile

1. Download `me3_installer.exe` from the
   [me3 releases page](https://github.com/garyttierney/me3/releases/latest) and run it.
2. Create the profile in PowerShell:

```powershell
@'
profileVersion = "v1"

[[supports]]
game = "nightreign"

[[packages]]
id = "executor-rework"
path = '.'
'@ | Set-Content "$env:USERPROFILE\ExecutorRework\executor-rework.me3"
```

3. Double-click `executor-rework.me3` to start the modded game.

If me3 doesn't accept `path = '.'`, make a `mod` folder next to the profile, copy
`regulation.bin` and the `action` and `chr` folders into it, and change the line to `path = 'mod'`.

To play normally again, start the game from Steam as usual; the mod is only loaded
through the `.me3` profile.

## 4. What to test

Play as the Executor, solo first.

**Passive: deflect**
- [ ] Block with a katana right before a hit: no damage, very little stamina used, and the
      katana's own guard animation (no Cursed Sword).
- [ ] On a deflect, the Cursed Sword's full deflect sparks appear on the blocking weapon's
      blade (where the hit lands) and its full deflect sound plays, with a small extra flinch.
- [ ] Same with the weapon two-handed: the sparks are on that weapon.
- [ ] Claws or fists two-handed: the sparks are at the left hand, in front of the face,
      where the claw blocks.
- [ ] A dagger (e.g. Reduvia) deflect plays the sparks (at the hand) and the deflect sound.
- [ ] Every deflect plays the weapon's light guard reaction, and a deflected attack never
      knocks you back.
- [ ] A normal block (no deflect) has no Cursed Sword sparks.
- [ ] Holding block and taking the same hit (no deflect) costs the normal block stamina.
- [ ] Deflecting an attack that would break your guard: no guard break and no heavy stagger.
- [ ] Same with a greatsword (shorter window) and a colossal weapon (much shorter).
- [ ] Whips, staffs, seals, bows and shields only block normally.
- [ ] Mashing block never deflects; a single well-timed press does.
- [ ] Each hit of a combo can be deflected with a well-timed press per hit.
- [ ] Tenacity no longer triggers after recovering from a status effect.

**Relics**
- [ ] "Character Skill boosts attack": the awakened slash gives the attack buff and the
      damage negation penalty together for 13 s; a normal skill use gives neither. Hits deal
      more damage (e.g. a katana hit above its normal number) while the buff is on.
- [ ] "Unlocking use of cursed sword restores HP": awakening the sword heals.
- [ ] "Slowly restores HP upon ability activation": the awakened slash starts a 13 s
      regeneration; a normal skill use doesn't.
- [ ] Deflecting an enemy's attack deals no stance damage to it.

**Character Skill**
- [ ] Pressing the skill does the dash slash right away, with the Cursed Sword in hand, and
      no draw or put-away animation.
- [ ] After the slash your grip is the same as before: one-handed stays one-handed, a
      two-handed right or left weapon stays two-handed.
- [ ] Mashing R1/R2 during and right after the slash never gives a Cursed Sword (katana)
      attack; the first attack uses your weapon's own moveset (e.g. a colossal weapon's R1).
- [ ] With the relics equipped, a normal skill use gives no attack buff and no regeneration.
- [ ] The skill goes on a 12 s cooldown after use.
- [ ] After 4 deflects the sword glows (awakened); the next skill use is the awakened slash.
- [ ] The awakening wears off after 20 s if not used, and is gone after the awakened slash.

**Ultimate Art**
- [ ] Transform at around half HP: the Beast also starts at around half HP (no full heal).
- [ ] Let the transformation end normally: HP goes back to what it was before transforming.
- [ ] Let the Beast get "killed": you turn back into the Executor instead of dying, with
      the HP from before transforming. Enemies can't hurt or stagger you until you can move
      or roll again, and for 1 s after; attacking right away ends that.
- [ ] Attack right out of the transformation, then let the Beast get "killed" or the gauge
      run out: same as above (you don't come out at 1 HP).
- [ ] In a deathblight area, the Beast gets no deathblight buildup.

**Weapon coatings**
- [ ] Coat a weapon (e.g. frost), block a few times and use the skill: the coating stays.

## Script test

`tests/script_test.lua` loads the whole modded script with a fake engine and plays deflect
and skill scenarios through it (deflect windows per weapon, spam protection, stamina refund,
guard reactions, awakening, the skill's sword layer):

```
lua5.1 tests/script_test.lua mod/action/script/c0000.hks
```

It only checks the script's logic; animations, effects and stance damage still need testing
in game.

## Known risks

These could not be checked outside the game:

- **Script loading:** the game has to accept the decompiled script as text. If the game
  crashes on load or all characters act strangely, the script is the cause.
- **Animation file:** `chr/c0000.anibnd.dcx` is written with uncompressed Kraken blocks
  (about 57 MB), since no Kraken compressor is available here. If the game crashes when
  loading or characters stand in a T-pose, delete `chr\c0000.anibnd.dcx` from the mod folder
  and report it. After a game update that changes this file, it has to be rebuilt from the
  new one with `tools/patch_anibnd.py`.
- **Cooldown:** probably started by the skill animation, not the script. It may not trigger
  at all.
- **Deflect sparks:** come from the Cursed Sword's deflect flinch layered on the guard
  reaction. If it shows no sparks, or the flinch looks wrong on other weapons, it goes
  back out and the sparks need the IDs from the animation files instead.
- **Stamina refund:** if the game does apply the windows' `guardStaminaMult` after all,
  the refund comes on top and a deflect costs about 1% instead of 10%.
- **Removing effects:** ending the awakening early and ending the Beast form both use a
  script command (`act(9001, id)`) that vanilla Nightreign never uses.
- **HP change effects:** their sign is assumed (positive = damage). If HP moves the wrong
  way when transforming, the `changeHpRate` values in 707301–707317 need their signs
  flipped.
