# Changelog

## 1.1.0 (2026-10-22)

- An About tab in the options: how to get help (GitHub issues, Warperia, Discord) and the other addons by Skom, with what is installed. ArenaLFG is marked as Warmane only.
- **Friendly nameplates:** a new option, Main settings > Rows > Friendly nameplates. Off (default): friendly plates get the same rows as the enemy ones. On: friendly plates get only one top row, with the categories you pick (crowd control, roots, interrupts and disarms by default), its own icon size, number of icons and glow. Enemy plates are not changed. Friendly nameplates must be switched on in Display conditions, Unit reaction.

## 1.0.0 (2026-10-21)

First release.

**Rows around the nameplate**
- A left row and a right row (3 icons each by default), a top row, and up to five extra top rows. Every row has its own size, number of icons and glow.
- Each row picks what it shows: crowd control, disarms, roots, snares, healing reduction, interrupt lockouts, immunities, defensive buffs, shields, offensive buffs, speed boosts, other buffs, or any other aura. A row can be limited to buffs or debuffs, and to your own auras.
- An aura goes to the first row that takes it. Rows set to "only my auras" are filled first.
- **My debuffs:** a switch on the top row. It shows your own debuffs on enemies (hard crowd control stays on the right row). In the Spells tab you choose which ones to show, their size, priority and glow. The list starts with your class's debuffs and grows with every debuff you apply.
- Default set-up: left = immunities and defensive / offensive cooldowns, right = crowd control, roots, interrupts, disarms, snares and healing reduction, top = my debuffs, extra top row = other buffs.

**Spells tab**
- A tree by category, like BigDebuffs: hundreds of spells, each with show on/off, category, priority, icon size multiplier and its own glow. Hover a spell to see what it does.
- Add spells by ID to any category. Everything is stored by spell name, so all ranks follow.
- Durations and dispel types were checked against the 3.3.5a client's own spell data.

**Glow**
- Per category and per spell: none, border (optionally pulsing), pixel glow, autocast shine, action button glow or proc glow. The last four need LibCustomGlow-1.0 (it comes with WeakAuras); without it a border is used.
- Glow colour: the style's native yellow (default is by category), by spell type or by category. Border colour: by spell type, by category, or one custom colour (dark by default).
- Magic buffs you can dispel (priest, shaman, mage, warlock, warrior) get a glow of their own.
- A glow showcase (Position tab, or `/spb glow`) shows every style on a sample icon.

**Also**
- One options window: Main settings, Position, Spells, Profiles, About (`/spb`).
- Settings from the original PlateBuffs (`PB_DB`) are copied over once to `SkomsPlateBuffsDB`. Disable the original PlateBuffs first.
- Built on the PlateBuffs engine by Cyprias (3.3.5a backport by Kader, WotLK changes by Khal). See the README for the credits and inspirations.
