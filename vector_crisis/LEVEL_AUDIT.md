# Arrow Chaos — 100-Level Audit

Audit source: `dart run tool/level_audit.dart`

## Final result

```text
Total Levels: 100
Solvable: 100
Unsolvable: 0
Invalid: 0
Exact Duplicates: 0
Mirror/Rotation Similarity Warnings (>= 0.80): 0
```

Levels 1–9 retain their original layouts. Their deterministic data fingerprint
is `1121777089`; an automated regression test protects this baseline. Levels
10–20 were explicitly rebalanced after playtest feedback found them too easy.

## Grid distribution

| Grid | Levels |
|---|---:|
| 3x3 | 5 |
| 4x4 | 9 |
| 5x5 | 41 |
| 6x6 | 45 |

No 7x7 board is used, preserving portrait-phone readability.

## Difficulty distribution

| Difficulty | Levels |
|---|---:|
| 1 | 9 |
| 2 | 3 |
| 3 | 8 |
| 4 | 18 |
| 5 | 23 |
| 6 | 21 |
| 7 | 14 |
| 8 | 4 |
| 9 | 0 |
| 10 | 0 |

The 9 unchanged baseline levels retain their default difficulty metadata.
Rebalanced and new levels use the 2–8 range and include deliberate difficulty
drops after milestones.

## Mechanic distribution

| Metric | Level count |
|---|---:|
| Contains Normal | 100 |
| Contains Rotator | 57 |
| Contains Frozen | 58 |
| Contains Bomb | 50 |
| Contains 2+ special types | 50 |

Normal arrows remain at least 60% of every new board. Rotators never exceed 4,
Frozen arrows never exceed 4, and Bombs never exceed 3 per level.

## Pacing

- Challenge levels: 20, 25, 30, 35, 40, 45, 50, 60, 70, 75, 80, 90, 100
- Breather levels: 21, 31, 55, 71, 81, 91
- Highest minimum solution: Level 100 — 24 actions
- Most special arrows: Level 100 — 8
- Densest board: Level 100 — 24/36 cells (66.7%)
- Most initial playable actions: Level 82 — 11
- Highest solver search observed during design: below the 100,000-state limit
- Total optimal state-changing actions across the catalog: 1,156
- Levels 21–45 optimal actions: 183

Level 82 intentionally exposes the largest opening choice set as part of its
misleading-symmetry focus. It should receive particular manual playtesting for
decision clarity.

## Rebalanced early curve

| Level | Minimum moves | Initial playable | Decision states | Max forced streak |
|---:|---:|---:|---:|---:|
| 10 | 6 | 4 | 4 | 2 |
| 11 | 7 | 3 | 5 | 2 |
| 12 | 10 | 2 | 9 | 1 |
| 13 | 8 | 3 | 5 | 2 |
| 14 | 11 | 4 | 8 | 2 |
| 15 | 12 | 4 | 12 | 0 |
| 16 | 11 | 4 | 8 | 3 |
| 17 | 12 | 4 | 9 | 3 |
| 18 | 13 | 4 | 12 | 1 |
| 19 | 13 | 4 | 11 | 2 |
| 20 | 14 | 4 | 13 | 1 |

`decision states` counts states on a shortest solution with at least two legal
actions. `max forced streak` is the longest consecutive run with exactly one
legal action. Levels 16–20 use 11–14 minimum actions plus sustained branching
as the solver-side proxy for the 45–90 second playtest target.

The catalog-wide scripted-path audit reports no warning from Levels 10–100:
every level has at least two decision states and no shortest-path segment stays
at one legal action for more than four consecutive states. Level 36's Bomb
introduction and Level 99's final cleanup were minimally adjusted to meet this
rule.

## Gameplay/solver parity

- Path checks use the same `BoardRules.isPathClear` implementation.
- Rotator direction is included in solver state hashing.
- Frozen state is included in solver state hashing and frozen arrows are not
  playable until an orthogonal neighbour is removed.
- Bombs remove their origin and orthogonal neighbours. A Bomb removed as a
  victim does not chain-trigger; both gameplay and solver follow this rule.
- Gameplay input is locked while a removal animation resolves, so runtime
  transitions remain atomic like solver transitions.
- Expensive catalog BFS is development-only; it is not run at game startup.
- Levels with `targetMoves` use an enforced budget of `targetMoves + 2`. Every
  tap consumes one move; clearing on the final allowed move is valid.
- Every authored `targetMoves` value is identical to the current solver minimum;
  the allowance therefore has the same meaning throughout the campaign.
- Automated validation confirms that every optimal solver path fits its level's
  runtime move budget.

## Recommended manual test set

Prioritize these introduction, mastery, and milestone levels:

```text
16, 17, 20, 25, 26, 30, 35, 36, 40, 45, 50, 60, 70, 75, 80, 90, 100
```

Levels 10–20 replace the original easy layouts after explicit playtest feedback.
Levels 1–9 remain unchanged.
