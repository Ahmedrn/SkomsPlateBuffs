# Changelog (Forever edition)

## 0.11.0-forever (2026-11-21)

Fixes from a full code audit:

- Silence auras (Counterspell, Improved Kick, Improved Shield Bash) are crowd control.
- Sliders ignore the mouse wheel, so scrolling a settings page no longer changes them.
- Moving a row no longer builds new frames; frames are rebuilt only when sizes, categories or looks change. The preview reuses its frames.
- Interrupts inside instances no longer risk an error on hidden values.
- "Only my auras" works on a row while My debuffs is on.
- Unused libraries removed (AceGUI, AceConfig, AceDBOptions); the one-off Warmane import is no longer loaded.

## 0.10.x-forever (2026-11-21)

- Spell lists rebuilt from Forever's own spell data (426 auras), Warmane lists dropped.
- No more errors from hidden aura update fields in combat.
- Blocking spells only through the Aura library.

## 0.1.0 to 0.9.1-forever (2026-11-20)

- First port: rows on AuraContainer frames, Warmane settings import, custom settings window, test mode, interrupt lockouts, timer colours by % of the duration, Aura library with class database.
