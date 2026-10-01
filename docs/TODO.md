# To Do

## Next up

### 1. Release test

Test the release zips from a fresh folder and as a package in an existing me3 profile (see
[RELEASE.md](RELEASE.md#3-test-like-a-player)). Check the
new texts (see [TEXT.md](TEXT.md)) on the character select screen: the lines must not overflow
their boxes.

### 2. Weapon coating test

Coat a weapon (e.g. frost) and block a few times: the coating must stay. The deflect window
effects no longer use the vanilla "Remove Previous" category 162, which removed it. (Co-op
is tested: a full run with Seamless Co-op 1.1.3 through `executor-rework-coop.me3`.)

### 3. Publish

- Nexus Mods page: see [NEXUS.md](NEXUS.md).

## Also open

- Check in game that deflects no longer deal stance damage to enemies; if they still do, it
  comes from the deflect animation's events.
- Relic regen is now 13 s at the vanilla rate (about 3.5% + 39 HP in total); raise the rate if
  it should heal more.
- The deflect flinch still applies the vanilla accumulator effect 707053 (+5 to the vanilla
  Cursed Sword meter). The rework awakens the sword from its own counter, so this should do
  nothing; if the sword ever awakens before 4 deflects, remove that event too.
- The relic texts (in `item_dlc01.msgbnd.dcx`) still describe the vanilla triggers.
