import 'package:flutter_test/flutter_test.dart';
import 'package:vector_crisis/game/logic/board_rules.dart';
import 'package:vector_crisis/game/models/arrow_direction.dart';

void main() {
  group('BoardRules.isPathClear', () {
    for (final direction in ArrowDirection.values) {
      test('checks the full path toward ${direction.name}', () {
        const row = 2;
        const column = 2;
        final blocker = (
          row: row + direction.rowDelta * 2,
          column: column + direction.columnDelta * 2,
        );

        expect(
          BoardRules.isPathClear(
            row: row,
            column: column,
            direction: direction,
            rows: 5,
            columns: 5,
            occupiedCells: [blocker],
          ),
          isFalse,
        );
        expect(
          BoardRules.isPathClear(
            row: row,
            column: column,
            direction: direction,
            rows: 5,
            columns: 5,
            occupiedCells: [
              (
                row: row - direction.rowDelta,
                column: column - direction.columnDelta,
              ),
            ],
          ),
          isTrue,
        );
      });
    }
  });

  test('only orthogonal neighbours are adjacent', () {
    expect(BoardRules.areAdjacent(1, 1, 1, 2), isTrue);
    expect(BoardRules.areAdjacent(1, 1, 2, 1), isTrue);
    expect(BoardRules.areAdjacent(1, 1, 2, 2), isFalse);
    expect(BoardRules.areAdjacent(1, 1, 1, 1), isFalse);
  });
}
