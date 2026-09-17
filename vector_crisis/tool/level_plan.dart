import 'dart:math';

typedef Specials = ({int rotators, int frozen, int bombs, int stones});

/// The shape of the campaign, expressed as a rule per level rather than as a
/// hand-tuned table, so the ramp cannot quietly develop a step backwards.
abstract final class LevelPlan {
  static const firstGeneratedLevel = 4;
  static const lastLevel = 300;

  /// Must match `LevelPlanMarks.firstStoneLevel` in the game, which shows
  /// the Stone hint on this level.
  static const firstStoneLevel = 12;

  /// Optimum-move floor. Non-decreasing by construction: every level must
  /// cost at least as much as the one before it. Length climbs quickly over
  /// the first hundred levels and then flattens, because from there on the
  /// difficulty comes from Stone traps rather than from more taps.
  static int movesFloor(int id) {
    if (id < firstGeneratedLevel) return 1;
    if (id <= 100) return _lerp(id, firstGeneratedLevel, 100, 5, 28);
    if (id <= 200) return _lerp(id, 100, 200, 28, 33);
    return _lerp(id, 200, lastLevel, 33, 36);
  }

  static int _lerp(int id, int from, int to, int low, int high) =>
      low + ((id - from) * (high - low) / (to - from)).round();

  /// Boards grow so later levels read as a bigger problem, not just a longer
  /// one. Cells shrink to fit, which is what keeps an 8x8 legible on a phone.
  static int grid(int id) => switch (id) {
    <= 8 => 4,
    <= 16 => 5,
    <= 30 => 6,
    <= 50 => 7,
    _ => 8,
  };

  /// Most exits a board may offer on move one. A bigger board needs a few
  /// more to avoid reading as a single forced corridor; the difficulty gates,
  /// not this cap, are what keep a wide opening from being easy.
  static int maxOpenings(int id) => switch (grid(id)) {
    <= 6 => 4,
    7 => 5,
    _ => 6,
  };

  /// Mechanics arrive on the same schedule the in-game hints announce:
  /// Rotator at 6, Frozen at 8, Bomb at 10, Stone at 12.
  static Specials specials(int id, int arrows) {
    if (id < 6) return (rotators: 0, frozen: 0, bombs: 0, stones: 0);
    if (id < 8) return (rotators: 1, frozen: 0, bombs: 0, stones: 0);
    // A second Rotator turns the lesson into a choice: which one is worth
    // turning now, and which one is worth waiting for.
    if (id < 10) return (rotators: 2, frozen: 1, bombs: 0, stones: 0);

    final rotators = (1 + (id - 10) * 4 / 90).round().clamp(1, 5);
    final frozen = (1 + (id - 10) * 3 / 90).round().clamp(1, 4);
    final bombs = (1 + (id - 10) * 2 / 90).round().clamp(1, 3);
    // Stones are the only source of real dead ends, so they carry the
    // difficulty past level 100 where board size has stopped growing.
    final stones = id < firstStoneLevel
        ? 0
        : id < 20
        ? 1
        : (1 + (id - 20) / 40).floor().clamp(1, 4);
    final total = rotators + frozen + bombs + stones;

    // Normal arrows must stay the majority or the board stops reading clearly.
    final room = arrows * 2 / 5;
    if (total > room) {
      final scale = room / total;
      return (
        rotators: max(1, (rotators * scale).floor()),
        frozen: max(1, (frozen * scale).floor()),
        bombs: max(1, (bombs * scale).floor()),
        stones: stones == 0 ? 0 : max(1, (stones * scale).floor()),
      );
    }
    return (rotators: rotators, frozen: frozen, bombs: bombs, stones: stones);
  }

  /// Ceiling on how often an unplanned run still lands the optimum.
  static double maxUnplannedOptimalRate(int id) => switch (id) {
    <= 7 => 1.0,
    <= 9 => 0.90,
    <= 20 => 0.55,
    <= 40 => 0.40,
    <= 60 => 0.28,
    <= 80 => 0.18,
    _ => 0.12,
  };

  /// Floor on how often an unplanned run fails outright, by overrunning the
  /// move budget or jamming the board.
  static double minUnplannedFailureRate(int id) => switch (id) {
    <= 9 => 0.0,
    <= 20 => 0.05,
    <= 40 => 0.12,
    <= 60 => 0.20,
    <= 80 => 0.28,
    <= 150 => 0.40,
    _ => 0.50,
  };

  /// Floor on how often a player who checks where each Stone lands still
  /// fails. This is what needs more than one move of lookahead, and it is the
  /// gate that makes late levels take minutes rather than seconds.
  static double minCarefulFailureRate(int id) => switch (id) {
    < firstStoneLevel => 0.0,
    <= 30 => 0.08,
    <= 80 => 0.18,
    <= 150 => 0.28,
    <= 220 => 0.36,
    _ => 0.42,
  };

  /// Floor on how often an unplanned run jams the board for good. Without it
  /// a Stone can sit on a board as decoration and the level plays itself.
  static double minUnplannedStuckRate(int id) => switch (id) {
    < firstStoneLevel => 0.0,
    <= 30 => 0.15,
    <= 80 => 0.25,
    <= 150 => 0.35,
    _ => 0.45,
  };

  static bool isChallenge(int id) => id % 10 == 0;

  static int difficulty(int id) =>
      (1 + (id - 1) * 9 / (lastLevel - 1)).floor().clamp(1, 10);

  static String focus(int id) => switch (id) {
    <= 5 => 'reading dependencies',
    <= 7 => 'rotator turns cost moves',
    <= 9 => 'frozen arrows need a neighbour to leave',
    <= 11 => 'blast timing',
    <= 20 => 'where a stone lands',
    <= 40 => 'stones wait for their path to clear',
    <= 70 => 'rotator patience around walls',
    <= 100 => 'competing dependency chains',
    <= 150 => 'two stones, one safe order',
    <= 200 => 'dense board, scarce moves',
    <= 250 => 'layered traps',
    _ => 'mastery',
  };
}
