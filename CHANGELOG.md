# Changelog

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
