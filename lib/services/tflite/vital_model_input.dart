import 'dart:typed_data';

class VitalModelInput {
  const VitalModelInput(this.features);
  final List<double> features;

  Float32List get tensor {
    if (features.length != 23) {
      throw ArgumentError.value(
        features.length,
        'features',
        'Expected 23 model features',
      );
    }
    if (features.any((value) => !value.isFinite)) {
      throw ArgumentError.value(
        features,
        'features',
        'Features must be finite',
      );
    }
    return Float32List.fromList(features);
  }
}
