import 'package:equatable/equatable.dart';

class PPGSample extends Equatable {
  const PPGSample({
    required this.timestamp,
    required this.red,
    required this.green,
    required this.blue,
  });
  final double timestamp;
  final double red;
  final double green;
  final double blue;

  @override
  List<Object> get props => [timestamp, red, green, blue];
}
