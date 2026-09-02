import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../features/vitals_history/domain/entities/vital_record.dart';

class ExportHelper {
  static Future<void> exportToCsv(List<VitalRecord> records) async {
    List<List<dynamic>> rows = [];
    rows.add([
      "Timestamp",
      "Heart Rate (bpm)",
      "SpO2 (%)",
      "Systolic BP",
      "Diastolic BP",
      "Signal Quality",
      "Status",
    ]);

    for (var r in records) {
      rows.add([
        r.timestamp.toIso8601String(),
        r.heartRateBpm,
        r.spo2Percent,
        r.systolicBp,
        r.diastolicBp,
        r.signalQualityIndex,
        r.measurementStatus,
      ]);
    }

    String csv = const ListToCsvConverter().convert(rows);
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/senvo_health_history.csv');
    await file.writeAsString(csv);
    await Share.shareXFiles([XFile(file.path)], text: 'My Senvo Health History');
  }
}
