class DashboardSummary {
  final int consultationsToday;
  final int pendingApprovals;
  final int activeAlerts;
  final int adherenceRate;

  DashboardSummary({
    required this.consultationsToday,
    required this.pendingApprovals,
    required this.activeAlerts,
    required this.adherenceRate,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      consultationsToday: json['consultationsToday'] ?? 0,
      pendingApprovals: json['pendingApprovals'] ?? 0,
      activeAlerts: json['activeAlerts'] ?? 0,
      adherenceRate: json['adherenceRate'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'consultationsToday': consultationsToday,
      'pendingApprovals': pendingApprovals,
      'activeAlerts': activeAlerts,
      'adherenceRate': adherenceRate,
    };
  }
}
