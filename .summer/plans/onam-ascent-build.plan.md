---
name: onam-ascent-build
overview: >-
  Build Onam Ascent: Maveli's Journey - a two-act 3D mobile action game
  (vertical staircase runner, then Vamana stomp standoff) in five milestones.
createdAt: '2026-09-06T15:30:59.796Z'
todos:
  - id: level1-runner-base
    content: >-
      Build the Level 1 vertical lane-runner base in res://main.tscn:
      auto-climb, 3 lanes, jump, rolling coconut obstacles, hearts, umbrella
      power meter, distance score, game-over/restart
    status: completed
  - id: level1-feedback
    content: >-
      Add runner feedback and depth: obstacle patterns, close-call chimes/speed
      trails/point popups, mobile swipe/tap input
    status: completed
  - id: maveli-env-assets
    content: >-
      Create and wire Maveli character plus Kerala festival environment assets
      (temple stone, marigolds, palms, gold, coconut/umbrella)
    status: in_progress
  - id: level2-standoff
    content: >-
      Build Level 2 Vamana stomp standoff: telegraphs, shield vs umbrella-spear
      choice, power economy, hearts, timer win/lose
    status: pending
  - id: flow-audio-polish
    content: >-
      Finish flow: title/intro, level transition, gilded ceremonial HUD theme,
      Onam audio, mobile export settings
    status: pending
---
## Spine decision

No examples-library slice fits a vertical 3D lane-runner with a tactical second act, so this build is freeform (Kerala festival aesthetic, -Z world forward). Milestone 1 proves the Level 1 core loop in one scene; each later milestone wraps around the working base.

## Design decisions (from GameSoul vision)

- 3D, mobile-first (swipe/tap final) but keyboard-playable in the editor for testing: A/D = lane switch, Space = jump, R = restart. Mobile swipe/tap arrives in milestone 2.
- Level 1: Maveli auto-runs upward a 3-lane sacred staircase; coconuts roll down toward him. Dodge by lane switch or jump. Close dodges, umbrella pickups, point popups later.
- Camera: third-person chase behind and above Maveli, looking forward down the run (-Z forward). No mouse orbit.
- Milestone 1 accepts primitive placeholders (capsule player, box/cylinder coconuts, flat gold/stone colors). Character + festive environment assets come in milestone 3 via the asset pipeline.
- Core loop to prove first: auto-climb, dodge-or-die, collect umbrella power, climb the score, restart.

## Scene architecture notes (milestone 1)

- res://main.tscn root Node3D: World (staircase/run surface), Player (CharacterBody3D, capsule placeholder), ObstacleSpawner, PickupSpawner, Camera3D chase rig, HUD CanvasLayer (hearts, umbrella power bar, distance label, game-over overlay).
- Axis alignment: run direction -Z; lanes on X; obstacles spawn ahead (-Z) and travel toward the player, freed after passing behind (+Z threshold). Jump on Y.
- Input actions bound via InputMap: move_left, move_right, jump, restart.
- application/run/main_scene = res://main.tscn. No autoloads, no menus beyond a game-over restart overlay.
- Hearts 3, hit = lose heart + brief invulnerability + feedback; 0 hearts = game over + restart. Umbrella pickup fills power meter (used in Level 2 later; UI bar now).

## Milestones

1. Level 1 vertical runner base (this turn) - main.tscn, auto-climb, 3 lanes, jump, rolling coconut obstacles, hearts, umbrella power meter, distance score, game-over/restart. Primitive visuals, warm directional light.
2. Runner feedback and depth - obstacle pattern variety, close-call chimes + speed trails + point popups, mobile swipe/tap input, game-over flow polish.
3. Maveli character + festival environment assets via asset pipeline (character with idle/walk/run/jump, coconut obstacle, glowing umbrella pickup, temple stone/marigold/palm dressing, gold accents), wired over the working runner.
4. Level 2: Vamana standoff - telegraphs with ground shake, shield vs umbrella-spear choice driven by the power meter, hearts, 5-minute win condition.
5. Flow and finish - title/intro, level transition, gilded ceremonial HUD theme, Onam audio, mobile export settings, balance pass.

## Verification

After each milestone: diagnostics clean (no script/parse errors), input actions bound, main scene set. Playtest by the user; never claim runtime correctness from a build receipt.
