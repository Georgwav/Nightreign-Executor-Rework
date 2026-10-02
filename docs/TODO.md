# To Do

## Next up

### 1. Test the fixes from the second co-op run

Re-import `mod/params/SpEffectParam.csv` in Smithbox (it changes 707000 and 707115 and adds
707014), save, rebuild, then check (list in [INSTALL.md](INSTALL.md#4-what-to-test)):
- a weapon coating stays through blocking and through the skill;
- attacking right out of the Beast transformation, then letting the Beast fall or the gauge
  run out, brings you back with your HP from before (not 1 HP), protected for 1.5 s;
- no deathblight buildup in Beast form.

Co-op is tested (a full run with Seamless Co-op 1.1.3 through `executor-rework-coop.me3`),
and so is the coating staying on through blocking.

### 2. Publish

- Nexus Mods page: see [NEXUS.md](NEXUS.md).
- GitHub release on the public repository with the four zips.

## Also open

- Check in game that deflects no longer deal stance damage to enemies; if they still do, it
  comes from the deflect animation's events.
- Relic regen is now 13 s at the vanilla rate (about 3.5% + 39 HP in total); raise the rate if
  it should heal more.
- The deflect flinch still applies the vanilla accumulator effect 707053 (+5 to the vanilla
  Cursed Sword meter). The rework awakens the sword from its own counter, so this should do
  nothing; if the sword ever awakens before 4 deflects, remove that event too.
- The relic texts (in `item_dlc01.msgbnd.dcx`) still describe the vanilla triggers.
