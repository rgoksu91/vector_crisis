enum ArrowType { normal, rotator, frozen, bomb }

extension ArrowTypeX on ArrowType {
  String get badge => switch (this) {
    ArrowType.normal => '',
    ArrowType.rotator => '↻',
    ArrowType.frozen => '❄',
    ArrowType.bomb => '●',
  };
}
