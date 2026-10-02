class TeacherSalaryLine {
  const TeacherSalaryLine({
    required this.category,
    this.headName,
    required this.amount,
  });

  final String category;
  final String? headName;
  final double amount;

  factory TeacherSalaryLine.fromJson(Map<String, dynamic> json) {
    return TeacherSalaryLine(
      category: '${json['category'] ?? ''}',
      headName: json['head_name'] as String?,
      amount: _asDouble(json['amount']) ?? 0,
    );
  }
}

class TeacherSalaryItem {
  const TeacherSalaryItem({
    required this.id,
    this.periodLabel,
    this.periodMonth,
    this.periodYear,
    this.status,
    this.statusLabel,
    this.totalEarnings = 0,
    this.totalDeductions = 0,
    this.netPay = 0,
    this.paidAt,
    this.paidAtLabel,
    this.workingDays,
    this.presentDays,
    this.unpaidLeaveDays,
    this.lines = const [],
  });

  final int id;
  final String? periodLabel;
  final int? periodMonth;
  final int? periodYear;
  final String? status;
  final String? statusLabel;
  final double totalEarnings;
  final double totalDeductions;
  final double netPay;
  final String? paidAt;
  final String? paidAtLabel;
  final int? workingDays;
  final int? presentDays;
  final int? unpaidLeaveDays;
  final List<TeacherSalaryLine> lines;

  factory TeacherSalaryItem.fromJson(Map<String, dynamic> json) {
    final rawLines = json['lines'];
    return TeacherSalaryItem(
      id: _asInt(json['id']) ?? 0,
      periodLabel: json['period_label'] as String?,
      periodMonth: _asInt(json['period_month']),
      periodYear: _asInt(json['period_year']),
      status: json['status'] as String?,
      statusLabel: json['status_label'] as String?,
      totalEarnings: _asDouble(json['total_earnings']) ?? 0,
      totalDeductions: _asDouble(json['total_deductions']) ?? 0,
      netPay: _asDouble(json['net_pay']) ?? 0,
      paidAt: json['paid_at'] as String?,
      paidAtLabel: json['paid_at_label'] as String?,
      workingDays: _asInt(json['working_days']),
      presentDays: _asInt(json['present_days']),
      unpaidLeaveDays: _asInt(json['unpaid_leave_days']),
      lines: rawLines is List
          ? [
              for (final row in rawLines)
                if (row is Map)
                  TeacherSalaryLine.fromJson(Map<String, dynamic>.from(row)),
            ]
          : const [],
    );
  }
}

class TeacherSalarySummary {
  const TeacherSalarySummary({
    this.teacherId,
    this.fullName,
    this.monthlySalary,
    this.branchId,
    this.branchName,
  });

  final int? teacherId;
  final String? fullName;
  final double? monthlySalary;
  final int? branchId;
  final String? branchName;

  factory TeacherSalarySummary.fromJson(Map<String, dynamic> json) {
    final teacher = json['teacher'];
    final branch = json['branch'];
    final teacherMap = teacher is Map ? Map<String, dynamic>.from(teacher) : const <String, dynamic>{};
    final branchMap = branch is Map ? Map<String, dynamic>.from(branch) : const <String, dynamic>{};

    return TeacherSalarySummary(
      teacherId: _asInt(teacherMap['teacher_id']),
      fullName: teacherMap['full_name'] as String?,
      monthlySalary: _asDouble(teacherMap['monthly_salary']),
      branchId: _asInt(branchMap['branch_id']),
      branchName: branchMap['branch_name'] as String?,
    );
  }
}

class TeacherSalaryPageMeta {
  const TeacherSalaryPageMeta({
    this.currentPage = 1,
    this.lastPage = 1,
    this.perPage = 25,
    this.total = 0,
  });

  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  bool get hasMore => currentPage < lastPage;

  factory TeacherSalaryPageMeta.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const TeacherSalaryPageMeta();
    return TeacherSalaryPageMeta(
      currentPage: _asInt(json['current_page']) ?? 1,
      lastPage: _asInt(json['last_page']) ?? 1,
      perPage: _asInt(json['per_page']) ?? 25,
      total: _asInt(json['total']) ?? 0,
    );
  }
}

class TeacherSalaryData {
  const TeacherSalaryData({
    required this.summary,
    this.items = const [],
    this.meta = const TeacherSalaryPageMeta(),
  });

  final TeacherSalarySummary summary;
  final List<TeacherSalaryItem> items;
  final TeacherSalaryPageMeta meta;

  factory TeacherSalaryData.fromJson(
    Map<String, dynamic> json, {
    Map<String, dynamic>? metaJson,
  }) {
    final rawItems = json['items'];
    return TeacherSalaryData(
      summary: TeacherSalarySummary.fromJson(json),
      items: rawItems is List
          ? [
              for (final row in rawItems)
                if (row is Map)
                  TeacherSalaryItem.fromJson(Map<String, dynamic>.from(row)),
            ]
          : const [],
      meta: TeacherSalaryPageMeta.fromJson(metaJson),
    );
  }
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return null;
}

double? _asDouble(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}
