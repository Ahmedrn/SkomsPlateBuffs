# Changelog

## Unreleased
- New "Side spells" tab, modelled on the BigDebuffs spells tab: every spell the side rows know, grouped by category, each with Show on/off, category (which sets the row), custom priority and reset. Add spells by ID (with an optional duration), remove them, reset the whole list. Settings are stored by spell name, so all ranks follow.
- Old "Specific Spells" tab renamed "Bar spells" (it only controls the classic bars).
- Option to print each aura added to a side row in chat (name, ID, category), to identify an icon you do not recognise.

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
