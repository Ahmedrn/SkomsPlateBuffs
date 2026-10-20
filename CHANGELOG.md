# Changelog

## 1.8.1 (2026-10-20)
- **Default glows:** Proc glow for crowd control, disarms, interrupts and offensive buffs; Action button glow for immunities, spell immunities and defensive buffs. The other categories keep the border (or none). Colours are unchanged. Only applies to settings you have not changed yourself.

## 1.8.0 (2026-10-20)
- **New category: Shields** (absorbs): Power Word: Shield, Mana Shield, Ice Barrier, Fire / Frost / Shadow Ward, Sacred Shield, Stoneclaw Totem absorb, Divine Aegis (45 spell ids, all ranks). Priority 5; ticked on Extra top row 1 by default.
- **Unrelenting Assault** (all three ids) is Healing reduction, not Other buffs.

## 1.7.1 (2026-10-20)
- **Glow showcase:** a movable window with every glow style (none, border, pixel, autocast shine, action button, proc) on a sample icon, and a button to cycle the colour. Open it from Position > Glow showcase, or with `/spb glow`.

## 1.7.0 (2026-10-20)
- **New category: Speed boosts** (Sprint, Dash, Aspect of the Cheetah and the Pack, Ghost Wolf, Blazing Speed, Nitro Boosts, Shadowstep, Body and Soul). Sprint and the Dashes moved here from Offensive / Other buffs. Permanent ones (aspects, Ghost Wolf) show even without a duration. Ticked on Extra top row 1 by default.
- Icon size multiplier moves in steps of 0.25.

## 1.6.0 (2026-10-20)
- **"Other tracked auras" is gone.** Everything the old list knew now has a category: crowd control (bombs, Hungering Cold, Holy Wrath, Ravage, Sonic Blast), defensives (Free Action), offensives (Brutal/Focused Assault, Tidal Force, Sweeping Strikes, Bestial Wrath), The Beast Within, and Other buffs (flags, HoTs, Blessings, Speed). The class debuffs of the old list live in My debuffs. The tab, the row option and the default list are removed.
- **Disarms is its own category again, and counts as hard crowd control** (like stuns and fears): your own disarm stays on the right row and never goes to My debuffs. Snares are not hard CC. Disarms is ticked in the default right row.
- **Extra top row 1** shows Other buffs by default (28 px, buffs only).
- **Fixed** an error when "Print row auras in chat" was on.

## 1.5.0 (2026-10-20)
- **Top row = My debuffs.** A switch on the top row. It shows your own debuffs (hard crowd control stays on the right row) and hides the "Show in this row" section. In the Spells tab, a new **My debuffs** group lists them (your class's debuffs first, then every debuff you apply) with show/hide, size multiplier, priority and glow per spell.
- The right row shows other players' snares and healing reduction; yours go to the top row.
- Renamed: "Top row" and "Extra top row 1..5".
- Defaults: left and right rows 32 px, left = buffs only, right = debuffs only (snares and healing reduction included).
- Disarms are crowd control again (Disarms category removed); the warrior Disarm and Snatch - Bird of Prey were moved there.
- Spell tooltips in the Spells tab show what the spell does, not only the ID.

## 1.4.0 (2026-10-20)
- **Top rows on demand:** one top row by default, "Add a top row" for more (up to six), "Remove this row" on the last one.
- **Per row: Buffs and debuffs / Debuffs only / Buffs only, and Only my auras.** New content "Any other aura" (everything no earlier row took). Top row 1 by default is "my debuffs". The old Show Buffs / Show Debuffs / Show Interrupts settings are gone from Display conditions; the rows decide.
- **New categories:** Snares (Hamstring, Wing Clip, Frostbolt, Cone of Cold, Chains of Ice, ...; slows that were filed as roots moved here) and Healing reduction (Mortal Strike, Wound Poison, Aimed Shot, ...).
- **"Other tracked auras" no longer repeats spells that have a category** (about 125 duplicates), in the Spells tab and in the rows.
- **Icon size multiplier per spell** in the Spells tab (for example Hamstring at 1.5x). Rows size each icon individually; top rows share one bottom line.
- **Spells tab layout like BigDebuffs:** each category has its priority and glow and a small add-by-ID box; tools (print row auras, reset the list) are a separate group. Duration field for spells you add.
- **Rows set to "Only my auras" are filled first**, so "my debuffs" on top keeps your own Hamstring or Mortal Strike even when the right row also shows snares / healing reduction.
- **Fixed** an error in test mode (a plate refreshed itself while its icons were being laid out).

## 1.3.0 (2026-10-20)
- **Classic bars removed.** The rows are the only display. The unknown-plate question mark icon went with them.
- **One options window:** Main settings (Rows, Display conditions, Appearance), Position, Spells, Profiles, About. The old Position settings and Bar spells tabs are folded in.
- **Spells tab** is a category tree. Each category has its priority and glow; each spell has show, category, priority and glow. The old PlateBuffs spell list is the last group, "Other tracked auras".
- **Glow per category and per spell:** none, border, pixel glow, autocast shine, action button glow, proc glow (via LibCustomGlow-1.0 from WeakAuras, border fallback). Custom color per spell.
- Spell immunities have their own priority setting.

## 1.2.0 (2026-10-20)
- **Rows rework.** Left and right are one row each (3 icons by default); above the plate there are up to four rows. Every row chooses its categories, its size, its max icons, glow and "only my auras". An aura goes to the first row that takes it.
- New category "everything the classic filters allow" so a top row can show your own debuffs and another row everyone else's (a rogue's Wound Poison next to your Mortal Strike).
- The classic bars are off by default (the top rows replace them); "Also show the classic bars" shows whatever no row takes.
- The "Side rows" tab became "Rows"; the old per-side toggles and category switches are replaced by the per-row ones.
- New "Side spells" tab, modelled on the BigDebuffs spells tab: every spell grouped by category, each with show on/off, category, custom priority and reset. Add spells by ID (optional duration), remove them, reset the list. Settings are stored by spell name, so all ranks follow.
- Old "Specific Spells" tab renamed "Bar spells" (it controls the classic bars and the classic filter).
- Option to print each aura added to a category row in chat (name, ID, category).
- Fully renamed to SkomsPlateBuffs: options title, `/spb`, saved variables `SkomsPlateBuffsDB` (settings in the old `PB_DB` are copied over once).

## 1.1.0 (2026-10-20)
- Glow around side-row icons, tinted by category (CC red/orange, immunities blue, defensives green, offensives red), with an optional pulse.
- The left row is now limited to what matters: immunities, major defensive cooldowns and offensive cooldowns (about 70 spells).
  Everything else moved to the "Other buffs" category, which is off by default.
- New option: hide left-row auras that have no duration (forms, stances, permanent buffs). On by default.
- Added Unholy Frenzy, Ardent Defender and missing durations for a few kept spells.
- Adjustable priority per category (Side rows > Priority): the highest priority is shown closest to the nameplate, so an immunity such as Divine Shield always comes before other buffs. Lists are now sorted before they are cut to the icon limit.
- Entries with a known duration that were removed during the cleanup (pets, battleground buffs, drinks) are back in "Other buffs".

## 1.0.0 (2026-10-20)
- First release, based on PlateBuffs 1.19.5 (r238) by Cyprias / Kader / Khal.
- Added the left (important buffs) and right (crowd control) side rows and their options.
