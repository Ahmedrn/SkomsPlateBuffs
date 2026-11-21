# Skom's Plate Buffs (Forever edition)

Port of [Skom's Plate Buffs](https://github.com/Ahmedrn/SkomsPlateBuffs) for the WoW Forever server: a 12.x client running 1.x spell data.

Same rows, categories and profiles as the Warmane (3.3.5a) version, drawn with the client's own AuraContainer frames, because in combat Forever hides aura spell ids and the combat log from addons.

- **Enemy debuffs** (crowd control, roots, snares, disarms, healing reduction, my debuffs) by spell list. The lists in `data.lua` are built from Forever's own spell data.
- **Enemy buffs** by the game's own tags (big defensive, external defensive, important), plus short buffs and any other aura.
- **Friendly buffs** by spell list (immunities, defensives, offensives, shields, speed boosts, other).
- **Interrupt lockouts** from cast-interrupted events.
- **Aura library**: every aura met on nameplates out of combat, by class, with a block switch and right-click "Move to".

`/skpb` opens the settings, `/skpb test` toggles the preview on your target.

The `main` branch is the Warmane version.
