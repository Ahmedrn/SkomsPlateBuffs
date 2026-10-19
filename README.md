# PlateBuffsMini

A variant of [PlateBuffs-WoTLK](https://github.com/KhalGH/PlateBuffs-WoTLK) (r238) for WoW 3.3.5a that adds two rows next to
the nameplate, MiniCC style, on top of the normal rows above it:

- **Right row:** crowd control, roots, interrupt lockouts
- **Left row:** important buffs (immunities, defensives, offensives)

Everything else (tracking from the combat log and `UnitAura`, durations, diminishing returns, nameplate detection, styling)
is the stock PlateBuffs. The new options are in the **Side rows** tab of the PlateBuffs options (`/pb`).

Use it **instead of** PlateBuffs (disable the original): it shares the `PB_DB` saved variables, so your settings carry over.

Changes against the original are in git: `git diff 17c7609` shows everything added.
The spell categories (`categories.lua`) come from the BigDebuffs WotLK spell list (Jordon, Tsoukie).
