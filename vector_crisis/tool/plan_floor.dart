// ignore_for_file: avoid_print

import 'level_plan.dart';

/// Prints the optimum floor a generation range starting at `args[0]` should
/// be seeded with. A range can drift up to about four moves above the plan
/// (each level may overshoot its floor by one), so the next range starts
/// there to keep the ramp monotone across the boundary.
void main(List<String> args) {
  final from = int.parse(args.single);
  if (from <= LevelPlan.firstGeneratedLevel) {
    print(0);
    return;
  }
  print(LevelPlan.movesFloor(from - 1) + 4);
}
