# SkomsPlateBuffs 1.0.0 (WoW 3.3.5a)

PlateBuffs with two extra rows beside the enemy nameplate, in the style of the retail addon MiniCC:

- **Right of the plate:** crowd control, roots and interrupt lockouts
- **Left of the plate:** important buffs (immunities, defensive and offensive cooldowns)

The normal PlateBuffs rows above the plate keep working exactly as before. Everything about the side rows is in the
**Side rows** tab of the PlateBuffs options (`/pb`): on/off per side, icon size, icons per row, spacing, X/Y offsets,
anchoring (health bar or whole plate), glow (steady or pulsing, tinted by category), which categories go in the rows, and whether an aura shown on a side row is
hidden from the rows above the plate (default: yes).

## Install
1. Delete or disable the original **PlateBuffs** (two copies would draw on the same plates).
2. Put the `SkomsPlateBuffs` folder in `Interface\AddOns`.
3. Log in. Your existing PlateBuffs settings are kept (same saved variables, `PB_DB`).

No client patches are needed. It works the same way PlateBuffs does: nameplates are found with LibNameplates, auras come
from the combat log and from `UnitAura` on your target, focus and mouseover.
A plate whose unit PlateBuffs cannot identify yet shows nothing until you target or mouse over it.

## Credits
- **PlateBuffs** by **Cyprias**.
- 3.3.5a backport by **Kader**, WotLK modifications and fixes by **Khal**: https://github.com/KhalGH/PlateBuffs-WoTLK
  Almost all of this addon is their work.
- Side rows and spell categories by **Skom**. The spell category list is generated from the BigDebuffs WotLK spell
  list (Jordon, Tsoukie). The idea follows MiniCC / MiniAuras by Verubato; no code was copied from it.

## Changes from PlateBuffs r238
- New `categories.lua`: spell id -> category (crowd control, roots, interrupts, immunities, defensive, offensive).
- `combatlog.lua`: spells of those categories are always tracked, even when the normal filters would hide them.
- `frames.lua`: records are split into the normal rows and the two side rows; side rows are laid out left/right of the plate.
- `options.lua` and `locales/enUS.lua`: the Side rows tab.
- Start-up hardening: the settings table is set before the previous `OnEnable` runs.
- The addon folder is `SkomsPlateBuffs`; the media paths point there.
