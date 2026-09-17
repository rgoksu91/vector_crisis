/// A Stone never leaves the board: tapped, it slides to the first obstacle
/// (or the edge) and turns into a permanent wall there.
enum ArrowType { normal, rotator, frozen, bomb, stone }

extension ArrowTypeX on ArrowType {
  String get badge => switch (this) {
    ArrowType.normal => '',
    ArrowType.rotator => '↻',
    ArrowType.frozen => '❄',
    ArrowType.bomb => '●',
    ArrowType.stone => '■',
  };
}
