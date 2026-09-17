# Vector Crisis: Arrow Puzzle — Level Design Specification

> **Durum (2026-09): Tarihsel belge.** Bu belge, elle tasarlanan ilk 100
> level'lık sürümü anlatır. Güncel oyunda 300 üretilmiş level, 8x8'e kadar
> board'lar ve taş (Stone) mekaniği vardır. Güncel kurallar için
> `tool/level_plan.dart`, metrikler için `LEVEL_AUDIT.md`, genel bakış için
> `README.md` dosyasına bakın.

## 1. Purpose

This document is the source of truth for Vector Crisis level design.

Current state:
- Levels 1–9 remain the unchanged original baseline.
- Levels 10–20 were explicitly reopened for difficulty balancing after playtest
  feedback found the early curve too easy.
- Levels 21–100 follow the progression defined here.
- A level is not considered good merely because it is solvable.

Primary design goal:

> Every level should present one clear problem, create a small moment of discovery, and make the player want to play one more level.

Priority order:
1. Readability
2. Clear mechanic focus
3. Short solution time
4. Satisfying board opening / cleanup
5. Controlled difficulty
6. Variety

---

## 2. Core Level Design Principles

A good Vector Crisis level should:
- be understandable at first glance without being instantly solved;
- contain at least one meaningful decision;
- progressively open the board as the player succeeds;
- avoid unnecessary move count;
- preferably end with a satisfying 3–7 arrow cleanup/combo;
- usually take 10–60 seconds to solve.

Avoid:
- random-looking boards;
- brute-force-only solutions;
- excessive empty space;
- repeated geometry for several consecutive levels;
- too many special arrows in one small region;
- long scripted chains with only one valid move at every state;
- difficulty that only comes from arrow count.

From Level 10 onward, a shipped board must expose at least two decision states
on a shortest solver path and must not contain more than four consecutive
states with only one legal action. Medium early-game boards should normally
open with 2–4 legal actions. The solver audit reports `minimumMoves`,
`initialPlayableMoves`, decision-state count, and maximum forced-move streak.

`targetMoves` is the solver-verified optimum and is enforced in gameplay with a
two-attempt allowance. Every tap
counts after Level 9, including blocked and Frozen arrows. This is intentional:
the player must read the dependency graph instead of clearing boards through
rapid trial-and-error tapping. Reaching the limit with arrows remaining fails
the attempt and offers an immediate restart.

---

## 3. Difficulty Scale

Use an internal 1–10 scale:

- 1 — tutorial
- 2 — very easy
- 3 — easy
- 4 — easy-medium
- 5 — medium
- 6 — medium-hard
- 7 — hard
- 8 — very hard
- 9 — expert
- 10 — special challenge

For the first 100 levels, most levels should remain in the 2–7 range.
Level 100 should be challenging but not frustrating.

Difficulty should NOT increase linearly. Use breather levels after difficult levels.

---

## 4. Difficulty Factors

Difficulty estimation may consider:

- arrow count;
- board density;
- dependency depth;
- number of special arrows;
- branching / number of valid choices;
- misleading but legal moves;
- number of state-changing actions such as rotators;
- minimum solution length.

Suggested rough heuristic:

```text
score =
  arrowCount * 0.10
  + specialArrowCount * 0.30
  + dependencyDepth * 0.50
  + branchingComplexity * 0.35
  + misleadingMoves * 0.25
  + density * 0.40
```

Normalize to 1–10.
This is only a comparative development metric, not a mathematically exact difficulty score.

---

## 5. Board Size Progression

Recommended progression:

```text
Levels 1–10    3x3 / 4x4
Levels 11–25   4x4 / 5x5
Levels 26–45   5x5
Levels 46–70   5x5 / 6x6
Levels 71–90   6x6
Levels 91–100  6x6; selective 7x7 only if mobile readability remains excellent
```

Do not use a larger grid simply to create difficulty.
Readability on a phone is more important than density.

---

## 6. Mechanic Introduction Pattern

Every newly introduced mechanic should follow:

```text
Introduce
→ Practice
→ Practice
→ Combine
→ Challenge
```

A mechanic's first level should be extremely clear and should not include another complex new mechanic.

---

# 7. Global Progression

## Levels 1–9 — Existing Baseline

Already tested by the user.

Rules:
- Preserve these levels.
- Do not regenerate them.
- Only change them for bugs, invalid data, or proven unsolvable states.

## Levels 10–15 — Difficulty Bridge

Goal: introduce boards with multiple meaningful choices, deeper dependencies,
and interactions between the already-known special arrows.

## Levels 16–25 — Rotator Arc

Goal: teach state manipulation instead of only finding currently open arrows.

## Levels 26–35 — Frozen Arc

Goal: introduce dependency and unlock logic.

## Levels 36–45 — Bomb Arc

Goal: introduce tactical board cleanup and chain-reaction satisfaction.

## Levels 46–60 — Mixed Mechanics

Goal: combine Rotator, Frozen, Bomb and Normal arrows while keeping one primary idea per level.

## Levels 61–75 — Dense Boards

Goal: increase visual and logical density without harming readability.

## Levels 76–90 — Advanced Logic

Goal: deeper dependencies, multiple solution orders and tactical use of specials.

## Levels 91–100 — Mastery

Goal: combine learned systems cleanly. No major new mechanic should be introduced here.

---

# 8. Levels 16–25 — Rotator Arc

## Level 16
- Grid: 4x4
- Difficulty: 2
- Focus: Rotator introduction
- Composition: 1 rotator, 3–4 normal arrows
- Requirement: one obvious rotation should open the intended route
- Tutorial: visually highlight the rotator if necessary

## Level 17
- Grid: 4x4
- Difficulty: 3
- Composition: 1 rotator + normal arrows
- Focus: reinforce the distinction between rotating and exiting

## Level 18
- Grid: 4x4
- Difficulty: 3
- Composition: 1 rotator + normal arrows
- Design: rotating the rotator opens a normal arrow's path

## Level 19
- Grid: 4x4
- Difficulty: 3
- Composition: 2 rotators
- Dependency: Rotator A helps enable Rotator B, then normal cleanup

## Level 20
- Grid: 5x5
- Difficulty: 5
- Milestone challenge
- Composition: 2 rotators, 6–8 normal arrows
- Ending: 4+ arrow cleanup opportunity

## Level 21
- Difficulty: 2
- Breather level with a quick rotator payoff

## Level 22
- Difficulty: 4
- Central rotator controls multiple directional dependencies

## Level 23
- Difficulty: 4
- Pattern: normal arrow → rotator becomes useful → cleanup chain

## Level 24
- Difficulty: 5
- Up to 3 rotators
- Avoid rotator spam; each rotator must have a clear purpose

## Level 25
- Grid: 5x5
- Difficulty: 5
- 10–13 arrows
- Rotator mastery challenge
- Strong combo opportunity near the end

---

# 9. Levels 26–35 — Frozen Arc

Frozen behavior used by level design must exactly match runtime game rules and the solver.

Recommended rule if current implementation supports it:
- Frozen arrow cannot be directly played.
- Removing an orthogonally adjacent relevant arrow unlocks it.

If the existing implementation differs, preserve the implementation and adapt level design to it.

## Level 26
- Grid: 4x4
- Difficulty: 2
- 1 frozen + 3–4 normal
- Obvious adjacent unlock

## Level 27
- Difficulty: 3
- 2 frozen arrows with separate unlock paths

## Level 28
- Difficulty: 3
- One action can help unlock two frozen arrows
- Create a satisfying reveal moment

## Level 29
- Difficulty: 4
- Dependency: Normal → Frozen A → Frozen B

## Level 30
- Grid: 5x5
- Difficulty: 4
- 8–10 arrows
- 2–3 frozen
- Milestone level

## Level 31
- Difficulty: 4
- First Rotator + Frozen combination

## Level 32
- Difficulty: 4
- Frozen arrow appears to have an open exit but cannot yet be played
- Reinforces state awareness

## Level 33
- Difficulty: 5
- 2 rotators + 2 frozen
- Dependency depth around 3–4

## Level 34
- Grid: 5x5
- Difficulty: 5
- 11–13 arrows
- Higher board density

## Level 35
- Difficulty: 5
- Frozen mastery
- End with at least 5 fast cleanup actions if possible

---

# 10. Levels 36–45 — Bomb Arc

Bombs should create tactical choices and satisfying board changes, not simply act as decoration.

The solver and gameplay must implement bomb behavior identically.

## Level 36
- Grid: 4x4
- Difficulty: 2
- Bomb tutorial
- 1 bomb + around 4 normal arrows
- Explosion should visibly simplify the board

## Level 37
- Difficulty: 3
- Bomb begins blocked
- Clear one normal arrow before using it

## Level 38
- Difficulty: 3
- Bomb gives a clearly more efficient route than clearing everything manually

## Level 39
- Difficulty: 4
- 2 bombs
- Their interaction must follow actual runtime rules

## Level 40
- Grid: 5x5
- Difficulty: 4
- 10–12 arrows
- 2 bombs
- Milestone bomb challenge

## Level 41
- Difficulty: 4
- Bomb + Frozen
- Bomb interaction with frozen arrows must match runtime exactly

## Level 42
- Difficulty: 4
- Bomb + Rotator
- Rotator should help open the bomb's exit path

## Level 43
- Difficulty: 5
- Dense central cluster
- Bomb dramatically opens the board

## Level 44
- Difficulty: 5
- Early bomb use is legal but suboptimal
- Correct timing produces better cleanup

## Level 45
- Grid: 5x5
- Difficulty: 5
- 12–15 arrows
- Bomb mastery

---

# 11. Levels 46–60 — Mixed Mechanics

From this point forward, tutorial behavior should be minimal.
The player is assumed to understand the mechanics.

Each level should still have one dominant design idea.

## Level 46
- Difficulty: 4
- Rotator + Frozen

## Level 47
- Difficulty: 4
- Rotator + Bomb

## Level 48
- Difficulty: 4
- Frozen + Bomb

## Level 49
- Difficulty: 5
- First low-density three-mechanic level
- 8–10 arrows

## Level 50
- Grid: 6x6
- Difficulty: 6
- 14–16 arrows
- Normal + Rotator + Frozen + Bomb
- Major milestone completion feedback

## Level 51
- Difficulty: 5
- Visually symmetrical board, asymmetrical solution

## Level 52
- Difficulty: 5
- Outer-ring geometry

## Level 53
- Difficulty: 5
- Center cluster locked by outer arrows

## Level 54
- Difficulty: 6
- 4+ apparently valid starting choices
- A subset gives the clean route
- Avoid irreversible unfair traps

## Level 55
- Difficulty: 5
- Breather / combo reward level
- One key move opens 6–8 straightforward exits

## Level 56
- Difficulty: 6
- Frozen-heavy cluster

## Level 57
- Difficulty: 6
- Rotator-heavy
- Maximum 4 rotators

## Level 58
- Difficulty: 5
- Bomb-chain satisfaction level

## Level 59
- Difficulty: 6
- Mixed preparation for Level 60

## Level 60
- Grid: 6x6
- Difficulty: 7
- 16–20 arrows
- Major challenge
- Must remain readable and logically understandable

---

# 12. Levels 61–75 — Dense Board Arc

Density increases, but visual clarity remains mandatory.

## Level 61
- 6x6
- Difficulty: 5
- Around 14 normal + 2 special arrows

## Level 62
- Difficulty: 5
- Horizontal dependency focus

## Level 63
- Difficulty: 5
- Vertical dependency focus

## Level 64
- Difficulty: 6
- Cross dependency

## Level 65
- Difficulty: 6
- Central rotator control

## Level 66
- Difficulty: 6
- Frozen outer ring

## Level 67
- Difficulty: 6
- Central bomb unlock

## Level 68
- Difficulty: 5
- 2–3 meaningfully different valid solution orders
- Player freedom level

## Level 69
- Difficulty: 6
- Narrow dependency chain, but not fully scripted

## Level 70
- Grid: 6x6
- Difficulty: 7
- 20–22 arrows
- Milestone challenge

## Level 71
- Difficulty: 4
- Breather level after Level 70
- Quick and satisfying

## Level 72
- Difficulty: 5
- Combo-focused

## Level 73
- Difficulty: 6
- Frozen + Rotator dependency

## Level 74
- Difficulty: 6
- Bomb optimization

## Level 75
- Difficulty: 7
- Dense mixed challenge

---

# 13. Levels 76–90 — Advanced Logic Arc

Do not add a major new special-arrow type in this range unless explicitly requested later.
Create variety from the established systems.

## Level 76
- Difficulty: 6
- Two-stage unlock: outer → middle → center

## Level 77
- Difficulty: 6
- Rotator dependency depth around 4

## Level 78
- Difficulty: 6
- Frozen cascade

## Level 79
- Difficulty: 6
- Bomb opportunity is not obvious initially but provides strong value at the correct time

## Level 80
- Grid: 6x6
- Difficulty: 7
- 20–24 arrows
- Challenge

## Level 81
- Difficulty: 4
- Breather / chain-reaction reward level

## Level 82
- Difficulty: 6
- Misleading symmetry

## Level 83
- Difficulty: 6
- Edge management

## Level 84
- Difficulty: 7
- Center congestion

## Level 85
- Difficulty: 6
- Multiple-solution puzzle

## Level 86
- Difficulty: 7
- Rotator + Bomb tactical level

## Level 87
- Difficulty: 7
- Frozen + Bomb tactical level

## Level 88
- Difficulty: 7
- Three-mechanic mix

## Level 89
- Difficulty: 7
- Pre-challenge

## Level 90
- Difficulty: 8
- 6x6 or carefully designed 7x7 only if readable
- Major challenge
- Give special milestone feedback

---

# 14. Levels 91–100 — Mastery Arc

No major new mechanic should be introduced here.
These levels test mastery without becoming unfair.

## Level 91
- Difficulty: 5
- Breather

## Level 92
- Difficulty: 7
- Rotator mastery

## Level 93
- Difficulty: 7
- Frozen mastery

## Level 94
- Difficulty: 7
- Bomb mastery

## Level 95
- Difficulty: 6
- Combo mastery
- Once the board opens, create a long cleanup sequence

## Level 96
- Difficulty: 7
- Dense mixed board

## Level 97
- Difficulty: 8
- Dependency-heavy

## Level 98
- Difficulty: 7
- At least two valid solution paths

## Level 99
- Difficulty: 8
- Final preparation

## Level 100
- Grid: preferably 6x6
- Difficulty: 8
- 20–26 arrows
- Normal arrows remain dominant
- Suggested special distribution:
  - Rotator: 2–4
  - Frozen: 2–4
  - Bomb: 1–3
- Multiple phases / reveal moments
- Final 5–7 arrows should ideally produce a satisfying cleanup
- Completion may display: `100 LEVELS CLEARED`

---

# 15. Difficulty Pacing

Difficulty must rise in waves, not a straight line.

Important breather candidates:
- 21 or nearby depending on current baseline
- 31
- 41
- 55
- 71
- 81
- 91

Hard milestone levels should be followed by easier or more satisfying levels.

---

# 16. Combo-Level Pattern

Some levels should deliberately create this structure:

```text
critical decision
→ board opens
→ easy exit
→ easy exit
→ easy exit
→ easy exit
→ combo payoff
```

Combo levels are valuable for pacing and retention.

---

# 17. Dependency Design

Avoid making an entire level one linear script:

Bad:

```text
A → B → C → D → E → F
```

Prefer small branches:

```text
      A
    /   \
   B     C
    \   /
      D
     / \
    E   F
```

Give the player meaningful but understandable choices.

---

# 18. Anti-Repetition Rules

Do not allow 3 consecutive levels to share all of the following:
- same grid size;
- same dominant mechanic;
- similar arrow count;
- same dominant direction;
- same board geometry.

Rotate patterns such as:
- horizontal-heavy;
- vertical-heavy;
- center cluster;
- outer ring;
- two islands;
- diagonal structure;
- cross structure;
- corner structure.

---

# 19. Geometry Templates

Templates are starting points, not copy-paste level layouts.

## Ring

```text
xxxxx
x...x
x...x
x...x
xxxxx
```

## Cross

```text
..x..
..x..
xxxxx
..x..
..x..
```

## Center Cluster

```text
.....
.xxx.
.xxx.
.xxx.
.....
```

## Corners

```text
xx.xx
x...x
.....
x...x
xx.xx
```

## Diagonal

```text
x....
.x...
..x..
...x.
....x
```

## Two Islands

```text
xx...
xx...
.....
...xx
...xx
```

Do not use the same template repeatedly without meaningful transformation.

---

# 20. Special Arrow Ratios

Normal arrows should usually remain at least 60% of a board.

Example for a 20-arrow board:
- 12–15 Normal
- 2–3 Rotator
- 2–3 Frozen
- 1–2 Bomb

Typical limits:
- Bomb: usually 0–2, challenge maximum around 3
- Rotator: usually 1–3, maximum around 4
- Frozen: usually 1–4

Do not pack all special arrows into the same small area unless the level's explicit design requires it and remains readable.

---

# 21. Good / Bad Level Signals

## Good signals
- 2–4 reasonable starting actions;
- one dominant design idea;
- visible progression as the board opens;
- short dependency chains;
- one reveal/payoff moment;
- satisfying final cleanup;
- typically 15–45 seconds to solve.

## Reject or redesign when
- zero playable initial actions;
- long level has exactly one possible action at nearly every state;
- too many initial playable arrows with no meaningful distinction;
- special mechanic exists but has no real impact;
- early-game minimum solution is excessively long;
- level depends on accidental trial-and-error rather than understandable logic;
- board is technically solvable but visually chaotic.

---

# 22. Level Metadata

Where compatible with the existing model, levels should expose metadata similar to:

```text
id
rows
columns
difficulty
mechanicFocus
targetMoves
isChallenge
isBreather
arrows
```

Do not rewrite the architecture only to add metadata.
Extend the existing model cleanly if useful.

---

# 23. Validation Pipeline

Every newly created level should conceptually pass:

```text
structural validation
→ solver validation
→ difficulty estimation
→ quality heuristics
→ repetition audit
→ accept/reject
```

Structural validation should detect:
- duplicate arrow positions;
- coordinates outside board;
- invalid direction/type;
- impossible special state;
- empty level;
- unacceptable density.

---

# 24. Solver Requirements

Every final catalog level must be solvable.

Gameplay and solver behavior must match for:
- movement/path checks;
- Rotator direction state;
- Frozen state/unlocking;
- Bomb destruction/effects;
- any future special arrow state.

State hashing must include all state required to distinguish puzzle configurations.

Prefer using the solver during development/tests rather than performing expensive searches every time a production level is loaded.

Useful solver metrics if practical:
- solvable;
- minimum moves;
- number of initial valid actions;
- dependency depth estimate;
- approximate number of solution paths.

---

# 25. Automated Level Tests

Create or maintain automated tests that iterate through the complete level catalog.

At minimum validate:

```dart
expect(levelSolver.isSolvable(level), true);
```

Also validate:
- unique positions;
- coordinates inside grid;
- valid directions/types;
- special state consistency.

Levels 1–9 should also be solver-tested even though they should not be redesigned.

---

# 26. Batch Generation / Implementation

Do NOT generate 85 random levels in one uncontrolled pass.

Preferred implementation sequence:

1. Inspect existing level model and rules.
2. Verify Levels 1–9 without redesigning them.
3. Ensure validation tests exist.
4. Ensure the solver matches all current special-arrow rules.
5. Implement Levels 16–25.
6. Run analyzer/tests/solver audit.
7. Implement Levels 26–50.
8. Run validation again.
9. Implement Levels 51–75.
10. Run validation again.
11. Implement Levels 76–100.
12. Run a final progression/repetition/difficulty audit.

If quality suffers, reduce batch size to 5–10 levels.

---

# 27. Final 100-Level Audit

After completion, produce a report containing:

```text
Total levels: 100
Solvable: 100
Unsolvable: 0
```

Also summarize:
- grid-size distribution;
- difficulty distribution;
- number of levels containing Normal / Rotator / Frozen / Bomb;
- challenge level spacing;
- breather level spacing;
- duplicate/similar board detection;
- any level changed from the original baseline and why.

---

# 28. Product Principle

The level generator's job is NOT to generate difficult boards.
Its job is to help create fun boards.

The solver is a technical validation tool.
Good level design still depends on:
- clarity;
- pacing;
- choice;
- reveal;
- payoff;
- variety.

Core principle:

> Core gameplay > level quality > polish > retention > monetization > infrastructure

---

# 29. Current Codex Task

Treat Levels 1–9 in the repository as the unchanged user-tested baseline.
Levels 10–20 are the first difficulty-rebalanced batch.

Use this document as the main level-design specification.

Implement Levels 16–100 according to this progression, preferably in controlled batches.

Start by:
1. Inspecting the existing level model, runtime game rules and solver.
2. Running `flutter analyze` and available tests.
3. Verifying Levels 1–9 are structurally valid and solvable.
4. Implementing Levels 16–25 (Rotator Arc).
5. Validating them with solver/tests.
6. Continuing with the remaining arcs only after validation passes.
7. Avoiding unnecessary architecture rewrites.
8. Producing the final 100-level audit when complete.
