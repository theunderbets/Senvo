import 'dart:convert';
import 'package:hive/hive.dart';
import '../../../../core/risk/risk_enums.dart';
import '../../domain/entities/health_risk_record.dart';
import '../../domain/entities/risk_result.dart';

class HealthRiskRecordModel extends HiveObject {
  HealthRiskRecordModel({
    required this.id,
    required this.riskResultJson,
    this.userId,
    required this.createdAt,
  });
  final String id;
  final String riskResultJson;
  final String? userId;
  final DateTime createdAt;

  HealthRiskRecord toEntity() {
    final map = jsonDecode(riskResultJson) as Map<String, dynamic>;
    
    final domainResults = <String, DomainRiskResult>{};
    final domainMap = map['domainResults'] as Map<String, dynamic>;
    for (final entry in domainMap.entries) {
      final v = entry.value as Map<String, dynamic>;
      domainResults[entry.key] = DomainRiskResult(
        domain: v['domain'] as String,
        score: (v['score'] as num).toDouble(),
        level: RiskLevel.values.firstWhere((e) => e.name == v['level']),
        confidence: (v['confidence'] as num).toDouble(),
        primaryContributors: List<String>.from(v['primaryContributors']),
        insights: List<String>.from(v['insights']),
      );
    }

    final riskResult = OverallRiskResult(
      overallScore: (map['overallScore'] as num).toDouble(),
      overallLevel: RiskLevel.values.firstWhere((e) => e.name == map['overallLevel']),
      overallConfidence: (map['overallConfidence'] as num).toDouble(),
      domainResults: domainResults,
      criticalAlerts: List<String>.from(map['criticalAlerts']),
      calculatedAt: DateTime.fromMillisecondsSinceEpoch(map['calculatedAt'] as int),
    );

    return HealthRiskRecord(
      id: id,
      riskResult: riskResult,
      userId: userId,
      createdAt: createdAt,
    );
  }

  factory HealthRiskRecordModel.fromEntity(HealthRiskRecord record) {
    final riskResult = record.riskResult;
    final map = {
      'overallScore': riskResult.overallScore,
      'overallLevel': riskResult.overallLevel.name,
      'overallConfidence': riskResult.overallConfidence,
      'domainResults': riskResult.domainResults.map((k, v) => MapEntry(k, {
        'domain': v.domain,
        'score': v.score,
        'level': v.level.name,
        'confidence': v.confidence,
        'primaryContributors': v.primaryContributors,
        'insights': v.insights,
      })),
      'criticalAlerts': riskResult.criticalAlerts,
      'calculatedAt': riskResult.calculatedAt.millisecondsSinceEpoch,
    };

    return HealthRiskRecordModel(
      id: record.id,
      riskResultJson: jsonEncode(map),
      userId: record.userId,
      createdAt: record.createdAt,
    );
  }
}

class HealthRiskRecordAdapter extends TypeAdapter<HealthRiskRecordModel> {
  @override
  final int typeId = 1;

  @override
  HealthRiskRecordModel read(BinaryReader reader) {
    return HealthRiskRecordModel(
      id: reader.readString(),
      riskResultJson: reader.readString(),
      userId: reader.readString(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
    );
  }

  @override
  void write(BinaryWriter writer, HealthRiskRecordModel obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.riskResultJson);
    writer.writeString(obj.userId ?? '');
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
  }
}
