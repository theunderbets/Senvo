import 'package:hive/hive.dart';
import '../../domain/entities/vital_record.dart';

class VitalRecordModel extends HiveObject {
  VitalRecordModel({
    required this.id,
    required this.timestamp,
    required this.heartRateBpm,
    required this.spo2Percent,
    required this.systolicBp,
    required this.diastolicBp,
    required this.signalQualityIndex,
    required this.measurementStatus,
    this.frameCount,
    this.samplingRate,
    this.algorithmVersion = 'senvo-ppg-1',
  });
  final String id;
  final DateTime timestamp;
  final double heartRateBpm;
  final double spo2Percent;
  final double systolicBp;
  final double diastolicBp;
  final double signalQualityIndex;
  final int? frameCount;
  final double? samplingRate;
  final String measurementStatus;
  final String algorithmVersion;

  VitalRecord toEntity() => VitalRecord(
    id: id,
    timestamp: timestamp,
    heartRateBpm: heartRateBpm,
    spo2Percent: spo2Percent,
    systolicBp: systolicBp,
    diastolicBp: diastolicBp,
    signalQualityIndex: signalQualityIndex,
    frameCount: frameCount,
    samplingRate: samplingRate,
    measurementStatus: measurementStatus,
    algorithmVersion: algorithmVersion,
  );
  factory VitalRecordModel.fromEntity(VitalRecord record) => VitalRecordModel(
    id: record.id,
    timestamp: record.timestamp,
    heartRateBpm: record.heartRateBpm,
    spo2Percent: record.spo2Percent,
    systolicBp: record.systolicBp,
    diastolicBp: record.diastolicBp,
    signalQualityIndex: record.signalQualityIndex,
    frameCount: record.frameCount,
    samplingRate: record.samplingRate,
    measurementStatus: record.measurementStatus,
    algorithmVersion: record.algorithmVersion,
  );
}

class VitalRecordAdapter extends TypeAdapter<VitalRecordModel> {
  @override
  final int typeId = 0;
  @override
  VitalRecordModel read(BinaryReader reader) => VitalRecordModel(
    id: reader.readString(),
    timestamp: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
    heartRateBpm: reader.readDouble(),
    spo2Percent: reader.readDouble(),
    systolicBp: reader.readDouble(),
    diastolicBp: reader.readDouble(),
    signalQualityIndex: reader.readDouble(),
    frameCount: reader.read(),
    samplingRate: reader.read(),
    measurementStatus: reader.readString(),
    algorithmVersion: reader.readString(),
  );
  @override
  void write(BinaryWriter writer, VitalRecordModel value) {
    writer.writeString(value.id);
    writer.writeInt(value.timestamp.millisecondsSinceEpoch);
    writer.writeDouble(value.heartRateBpm);
    writer.writeDouble(value.spo2Percent);
    writer.writeDouble(value.systolicBp);
    writer.writeDouble(value.diastolicBp);
    writer.writeDouble(value.signalQualityIndex);
    writer.write(value.frameCount);
    writer.write(value.samplingRate);
    writer.writeString(value.measurementStatus);
    writer.writeString(value.algorithmVersion);
  }
}
