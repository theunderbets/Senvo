import 'package:equatable/equatable.dart';

enum RoiPosition { center }

class RoiConfig extends Equatable {
  const RoiConfig({
    this.width = 64,
    this.height = 64,
    this.position = RoiPosition.center,
  });
  final int width;
  final int height;
  final RoiPosition position;
  @override
  List<Object> get props => [width, height, position];
}
