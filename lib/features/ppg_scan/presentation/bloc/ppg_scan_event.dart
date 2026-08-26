sealed class PpgScanEvent {
  const PpgScanEvent();
}

class BeginScan extends PpgScanEvent {
  const BeginScan();
}

class ResetScan extends PpgScanEvent {
  const ResetScan();
}
