import '../models/arrow_direction.dart';

typedef BoardCell = ({int row, int column});

/// Geometry rules shared by the live game and the level solver.
abstract final class BoardRules {
  static bool isPathClear({
    required int row,
    required int column,
    required ArrowDirection direction,
    required int rows,
    required int columns,
    required Iterable<BoardCell> occupiedCells,
  }) {
    final occupied = occupiedCells.toSet();
    var nextRow = row + direction.rowDelta;
    var nextColumn = column + direction.columnDelta;

    while (isInside(nextRow, nextColumn, rows, columns)) {
      if (occupied.contains((row: nextRow, column: nextColumn))) {
        return false;
      }
      nextRow += direction.rowDelta;
      nextColumn += direction.columnDelta;
    }

    return true;
  }

  static bool isInside(int row, int column, int rows, int columns) =>
      row >= 0 && row < rows && column >= 0 && column < columns;

  static bool areAdjacent(int r1, int c1, int r2, int c2) =>
      (r1 - r2).abs() + (c1 - c2).abs() == 1;
}
