# SkomsPlateBuffs 1.2.0 (WoW 3.3.5a)

Enemy nameplate auras, laid out the way you decide. Based on PlateBuffs (see Credits), inspired by the retail addon MiniCC.

## Rows
- **Left row** (one row, 3 icons by default) and **right row** (one row, 3 icons by default).
- **Up to four rows above the plate**, each with its own number of icons and size.
- Every row picks what it shows: crowd control, roots, interrupt lockouts, immunities, defensive buffs, offensive buffs,
  other buffs, and "everything the classic filters allow" (the classic PlateBuffs filters and *Bar spells* list), optionally
  **only your own auras**.
- An aura goes to the first row that takes it (left, right, then the top rows in order).

Default set-up: left = immunities, defensive and offensive cooldowns; right = crowd control, roots, interrupts;
top 1 = your own auras; top 2 = everyone else's classic auras (a rogue's Wound Poison, for example).
Everything is in the **Rows** tab of the options (`/spb`): per row on/off, max icons, size, glow, only mine, categories;
plus spacing and offsets, glow pulse, and category priority (higher = closer to the plate / first in the row).

## Side spells
The **Side spells** tab lists every spell the rows know, grouped by category (like the BigDebuffs spells tab).
For each spell: show on/off, category, custom priority, reset. Add spells by ID (with an optional duration), remove them,
reset the whole list. An option prints each aura added to a category row in chat (name, ID, category) so an icon you do not
recognise can be identified.

## Install
1. Delete or disable the original **PlateBuffs** (two copies would draw on the same plates).
2. Put the `SkomsPlateBuffs` folder in `Interface\AddOns`.
3. Log in. Settings from the original PlateBuffs (`PB_DB`) are copied over once, to `SkomsPlateBuffsDB`.

No client patches are needed. Nameplates are found with LibNameplates, auras come from the combat log and from `UnitAura`
on your target, focus and mouseover. A plate whose unit the addon cannot identify yet shows nothing until you target or
mouse over it.

## Credits
- **PlateBuffs** by **Cyprias**.
- 3.3.5a backport by **Kader**, WotLK modifications and fixes by **Khal**: https://github.com/KhalGH/PlateBuffs-WoTLK
  Almost all of the nameplate code is their work.
- Rows, spell categories and the Side spells tab by **Skom**. The category list started from the BigDebuffs WotLK spell
  list (Jordon, Tsoukie). The idea follows MiniCC / MiniAuras by Verubato; no code was copied from it.
