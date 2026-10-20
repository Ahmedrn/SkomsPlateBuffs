# SkomsPlateBuffs 1.3.0 (WoW 3.3.5a)

Enemy nameplate auras, laid out the way you decide. Based on PlateBuffs (see Credits), inspired by the retail addon MiniCC.

## Rows
- **Left row** and **right row**: one row each, 3 icons by default.
- **Up to four rows above the plate**, each with its own number of icons and size.
- Every row picks what it shows: crowd control, roots, interrupt lockouts, immunities, defensive buffs, offensive buffs,
  other buffs, and "everything the classic filters allow" (the PlateBuffs filters and its spell list), optionally
  **only your own auras**.
- An aura goes to the first row that takes it (left, right, then the top rows in order).

Default set-up: left = immunities, defensive and offensive cooldowns; right = crowd control, roots, interrupts;
top 1 = your own auras; top 2 = everyone else's (a rogue's Wound Poison, for example).
The classic PlateBuffs bars are gone: the rows replace them.

## Options (`/spb`)
- **Main settings:** Rows (per row: on/off, max icons, size, glow, only mine, categories), Display conditions, Appearance
  (border, duration and stack text, clock, blink, fade).
- **Position:** left/right and top offsets and spacing, test mode.
- **Spells:** a tree by category, like the BigDebuffs spells tab. Each category has its priority and glow; each spell has
  show on/off, category, custom priority and its own glow. Add spells by ID, remove them, reset. The last group, *Other tracked
  auras*, is the classic PlateBuffs list (DoTs, poisons, ...) with its Always / Mine only / Never choice.
- **Profiles** and **About**.

## Glow
Per category and per spell: none, border (optionally pulsing), pixel glow, autocast shine, action button glow, proc glow
(the same styles as WeakAuras). The last four need `LibCustomGlow-1.0`, which comes with WeakAuras; without it they are drawn
as the border.

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
- Rows, spell categories, glow and the Spells tab by **Skom**. The category list started from the BigDebuffs WotLK spell
  list (Jordon, Tsoukie). The idea follows MiniCC / MiniAuras by Verubato; no code was copied from it.
- Glow styles from LibCustomGlow-1.0 (used if present).
