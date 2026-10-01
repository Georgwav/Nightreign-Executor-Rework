# In-Game Texts

New English texts for the Executor's passive, Character Skill and Ultimate Art on the character
select screen. They are in the game's `msg/engus/menu_dlc01.msgbnd.dcx` (menu text table
`CL_MenuText`, FMG 200); `tools/patch_msg.py` writes them into the vanilla file and builds
`mod/msg/engus/menu_dlc01.msgbnd.dcx`, which ships in the release. Other languages keep the
vanilla texts.

Vanilla limits: summaries have at most 2 lines, details at most 3, of up to about 48 characters.
Entries ending in 17 are the variants after the Executor's Remembrance (golden sword); the
Ultimate Art and passive texts have no such variant apart from their names.

## Passive

| Entry | Vanilla | New |
|---|---|---|
| Name (415007, 415017) | Tenacity | Deflection |
| Summary (416007) | Receive boost after recovering / from status ailments. | Guard in time with a foe's attack to / deflect it with almost any weapon. |
| Details (416107) | Effect boosts attack and stamina recovery speed. | Deflect window by weapon: 100% swords, katanas, / daggers, fists, claws. 65% greatswords, axes, / hammers, polearms. 30% colossal weapons. |

## Character Skill

Name unchanged: Cursed Sword (411007, 411017); the sword: Suncatcher (411107, 411117).

| Entry | Vanilla | New |
|---|---|---|
| Summary (412007) | Draw a cursed sword that / can deflect enemy attacks. | Draw the cursed sword and / dash forward with a swift slash. |
| Summary (412017) | Draw the Executor's golden sword that / can deflect enemy attacks. | Draw the Executor's golden sword and / dash forward with a swift slash. |
| Details (412107) | Repeated deflections reveal blade, enabling / powerful attacks with the living sword. / Cannot run while at ready with enchanted blade. | Deflect four attacks to imbue the blade with / holy light for 20 seconds. The next slash / unleashes the living sword's power. |
| Details (412117) | Repeated deflections reveal blade, enabling / powerful attacks with the living sword. The blade / lost its voice, but is forever loyal to its master. | Deflect four attacks to imbue the blade with / holy light for 20 seconds. The blade lost its / voice, but is forever loyal to its master. |

## Ultimate Art

Name (Aspects of the Crucible: Beast) and summary unchanged; the details only change what they
say about health.

| Entry | Vanilla | New |
|---|---|---|
| Details (414107) | Use unique attacks in beast form that / drain the Ultimate Art gauge. Activate again / to quickly undo transformation. | Use unique attacks in beast form that / drain the Ultimate Art gauge. The beast keeps / your HP ratio; you return with your prior HP. |

`/` marks a line break.

## Not changed

- The relic names and effects in `item_dlc01.msgbnd.dcx` (for example "[Executor] While Character
  Skill is active, unlocking use of cursed sword restores HP").
- The status effect names in the menu texts ("Effect of Tenacity", "Cursed Sword Attacks
  Unlocked").
