/// A Stone never leaves the board: tapped, it slides to the first obstacle
/// (or the edge) and turns into a permanent wall there.
/// A Gear turns 90° clockwise after every move, so which way it points
/// depends on how many moves have been played.
enum ArrowType { normal, rotator, frozen, bomb, stone, gear }

extension ArrowTypeX on ArrowType {
  String get badge => switch (this) {
    ArrowType.normal => '',
    ArrowType.rotator => '↻',
    ArrowType.frozen => '❄',
    ArrowType.bomb => '●',
    ArrowType.stone => '■',
    ArrowType.gear => '✷',
  };
}
