class ParentFeeVoucherData {
  const ParentFeeVoucherData({
    this.studentName,
    this.className,
    this.sectionName,
    this.branchName,
    this.sessionName,
    this.rollNumber,
    this.hasEnrollment = true,
    this.counts = const ParentFeeVoucherCounts(),
    this.unpaid = const [],
    this.partial = const [],
    this.invoices = const [],
    this.ledger = const ParentFeeLedger(),
    this.meta = const ParentFeePageMeta(),
  });

  final String? studentName;
  final String? className;
  final String? sectionName;
  final String? branchName;
  final String? sessionName;
  final String? rollNumber;
  final bool hasEnrollment;
  final ParentFeeVoucherCounts counts;
  final List<ParentFeeVoucher> unpaid;
  final List<ParentFeeVoucher> partial;
  final List<ParentFeeInvoice> invoices;
  final ParentFeeLedger ledger;
  final ParentFeePageMeta meta;

  String get classLabel {
    final klass = className?.trim();
    final section = sectionName?.trim();
    if (klass != null && klass.isNotEmpty && section != null && section.isNotEmpty) {
      return '$klass — $section';
    }
    if (klass != null && klass.isNotEmpty) return klass;
    if (section != null && section.isNotEmpty) return section;
    return '';
  }

  String get headerSubtitle {
    return [
      if ((branchName ?? '').trim().isNotEmpty) branchName!.trim(),
      if ((sessionName ?? '').trim().isNotEmpty) sessionName!.trim(),
      if (classLabel.isNotEmpty) classLabel,
      if ((rollNumber ?? '').trim().isNotEmpty) 'Roll ${rollNumber!.trim()}',
    ].join(' · ');
  }

  bool get hasMore => meta.hasMore;

  ParentFeeVoucherData mergeTab(
    ParentFeeVoucherData next, {
    required ParentFeeVoucherTab tab,
    bool append = false,
  }) {
    return ParentFeeVoucherData(
      studentName: next.studentName ?? studentName,
      className: next.className ?? className,
      sectionName: next.sectionName ?? sectionName,
      branchName: next.branchName ?? branchName,
      sessionName: next.sessionName ?? sessionName,
      rollNumber: next.rollNumber ?? rollNumber,
      hasEnrollment: next.hasEnrollment,
      counts: next.counts,
      unpaid: tab == ParentFeeVoucherTab.unpaid
          ? (append ? _mergeById(unpaid, next.unpaid, (row) => row.id) : next.unpaid)
          : unpaid,
      partial: tab == ParentFeeVoucherTab.partial
          ? (append ? _mergeById(partial, next.partial, (row) => row.id) : next.partial)
          : partial,
      invoices: tab == ParentFeeVoucherTab.invoices
          ? (append ? _mergeById(invoices, next.invoices, (row) => row.id) : next.invoices)
          : invoices,
      ledger: tab == ParentFeeVoucherTab.ledger
          ? ParentFeeLedger(
              totalDebit: next.ledger.totalDebit,
              totalCredit: next.ledger.totalCredit,
              netBalance: next.ledger.netBalance,
              entries: append
                  ? _mergeById(ledger.entries, next.ledger.entries, (row) => row.id)
                  : next.ledger.entries,
            )
          : ledger,
      meta: next.meta,
    );
  }

  factory ParentFeeVoucherData.fromJson(
    Map<String, dynamic> json, {
    Map<String, dynamic>? metaJson,
  }) {
    final student = _asMap(json['student']) ?? const <String, dynamic>{};
    final counts = _asMap(json['counts']) ?? const <String, dynamic>{};
    final ledger = _asMap(json['ledger']) ?? const <String, dynamic>{};

    return ParentFeeVoucherData(
      studentName: _asString(student['full_name']) ?? _asString(json['student_name']),
      className: _asString(student['class_name']),
      sectionName: _asString(student['section_name']),
      branchName: _asString(student['branch_name']),
      sessionName: _asString(student['session_name']),
      rollNumber: _asString(student['roll_number']),
      hasEnrollment: json['has_enrollment'] != false,
      counts: ParentFeeVoucherCounts.fromJson(counts),
      unpaid: _asObjectList(json['unpaid'], ParentFeeVoucher.fromJson),
      partial: _asObjectList(json['partial'], ParentFeeVoucher.fromJson),
      invoices: _asObjectList(json['invoices'], ParentFeeInvoice.fromJson),
      ledger: ParentFeeLedger.fromJson(ledger),
      meta: ParentFeePageMeta.fromJson(metaJson ?? _asMap(json['meta']) ?? const {}),
    );
  }
}

class ParentFeeVoucherCounts {
  const ParentFeeVoucherCounts({
    this.unpaid = 0,
    this.partial = 0,
    this.invoices = 0,
    this.ledger = 0,
  });

  final int unpaid;
  final int partial;
  final int invoices;
  final int ledger;

  int of(ParentFeeVoucherTab tab) {
    switch (tab) {
      case ParentFeeVoucherTab.unpaid:
        return unpaid;
      case ParentFeeVoucherTab.partial:
        return partial;
      case ParentFeeVoucherTab.invoices:
        return invoices;
      case ParentFeeVoucherTab.ledger:
        return ledger;
    }
  }

  factory ParentFeeVoucherCounts.fromJson(Map<String, dynamic> json) {
    return ParentFeeVoucherCounts(
      unpaid: _asInt(json['unpaid']) ?? 0,
      partial: _asInt(json['partial']) ?? 0,
      invoices: _asInt(json['invoices']) ?? 0,
      ledger: _asInt(json['ledger']) ?? 0,
    );
  }
}

enum ParentFeeVoucherTab {
  unpaid,
  partial,
  invoices,
  ledger;

  String get apiValue {
    switch (this) {
      case ParentFeeVoucherTab.unpaid:
        return 'unpaid';
      case ParentFeeVoucherTab.partial:
        return 'partial';
      case ParentFeeVoucherTab.invoices:
        return 'invoices';
      case ParentFeeVoucherTab.ledger:
        return 'ledger';
    }
  }
}

class ParentFeePageMeta {
  const ParentFeePageMeta({
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

  factory ParentFeePageMeta.fromJson(Map<String, dynamic> json) {
    return ParentFeePageMeta(
      currentPage: _asInt(json['current_page']) ?? 1,
      lastPage: _asInt(json['last_page']) ?? 1,
      perPage: _asInt(json['per_page']) ?? 25,
      total: _asInt(json['total']) ?? 0,
    );
  }
}

class ParentFeeVoucher {
  const ParentFeeVoucher({
    this.id,
    this.voucherNo,
    this.sessionName,
    this.month,
    this.dueDate,
    this.dueDateLabel,
    this.netPayable = 0,
    this.paidAmount = 0,
    this.balanceAmount = 0,
    this.paymentStatus,
    this.statusLabel,
  });

  final int? id;
  final String? voucherNo;
  final String? sessionName;
  final String? month;
  final String? dueDate;
  final String? dueDateLabel;
  final double netPayable;
  final double paidAmount;
  final double balanceAmount;
  final String? paymentStatus;
  final String? statusLabel;

  String get displayVoucherNo => _dash(voucherNo);

  String get displayMonth => _dash(month);

  String get displayDueDate => _dash(dueDateLabel ?? dueDate);

  String get displayStatus {
    final label = statusLabel?.trim();
    if (label != null && label.isNotEmpty) return label;
    switch (paymentStatus) {
      case 'partial':
        return 'Partial';
      case 'paid':
        return 'Paid';
      default:
        return 'Unpaid';
    }
  }

  factory ParentFeeVoucher.fromJson(Map<String, dynamic> json) {
    return ParentFeeVoucher(
      id: _asInt(json['id']),
      voucherNo: _asString(json['voucher_no']),
      sessionName: _asString(json['session_name']),
      month: _asString(json['month']),
      dueDate: _asString(json['due_date']),
      dueDateLabel: _asString(json['due_date_label']),
      netPayable: _asDouble(json['net_payable']) ?? 0,
      paidAmount: _asDouble(json['paid_amount']) ?? 0,
      balanceAmount: _asDouble(json['balance_amount']) ?? 0,
      paymentStatus: _asString(json['payment_status']),
      statusLabel: _asString(json['status_label']),
    );
  }
}

class ParentFeeInvoice {
  const ParentFeeInvoice({
    this.id,
    this.invoiceNo,
    this.sessionName,
    this.paymentDate,
    this.paymentDateLabel,
    this.monthsLabel,
    this.amount = 0,
    this.paymentMethod,
    this.paymentMethodLabel,
  });

  final int? id;
  final String? invoiceNo;
  final String? sessionName;
  final String? paymentDate;
  final String? paymentDateLabel;
  final String? monthsLabel;
  final double amount;
  final String? paymentMethod;
  final String? paymentMethodLabel;

  String get displayInvoiceNo => _dash(invoiceNo);

  String get displayPaymentDate => _dash(paymentDateLabel ?? paymentDate);

  String get displayMonths => _dash(monthsLabel);

  String get displayMethod => _dash(paymentMethodLabel ?? paymentMethod);

  factory ParentFeeInvoice.fromJson(Map<String, dynamic> json) {
    return ParentFeeInvoice(
      id: _asInt(json['id']),
      invoiceNo: _asString(json['invoice_no']),
      sessionName: _asString(json['session_name']),
      paymentDate: _asString(json['payment_date']),
      paymentDateLabel: _asString(json['payment_date_label']),
      monthsLabel: _asString(json['months_label']),
      amount: _asDouble(json['amount']) ?? 0,
      paymentMethod: _asString(json['payment_method']),
      paymentMethodLabel: _asString(json['payment_method_label']),
    );
  }
}

class ParentFeeLedger {
  const ParentFeeLedger({
    this.totalDebit = 0,
    this.totalCredit = 0,
    this.netBalance = 0,
    this.entries = const [],
  });

  final double totalDebit;
  final double totalCredit;
  final double netBalance;
  final List<ParentFeeLedgerEntry> entries;

  factory ParentFeeLedger.fromJson(Map<String, dynamic> json) {
    return ParentFeeLedger(
      totalDebit: _asDouble(json['total_debit']) ?? 0,
      totalCredit: _asDouble(json['total_credit']) ?? 0,
      netBalance: _asDouble(json['net_balance']) ?? 0,
      entries: _asObjectList(json['entries'], ParentFeeLedgerEntry.fromJson),
    );
  }
}

class ParentFeeLedgerEntry {
  const ParentFeeLedgerEntry({
    this.id,
    this.entryDate,
    this.entryDateLabel,
    this.description,
    this.isAdvanceApplication = false,
    this.ref,
    this.debit,
    this.credit,
    this.balance = 0,
  });

  final int? id;
  final String? entryDate;
  final String? entryDateLabel;
  final String? description;
  final bool isAdvanceApplication;
  final String? ref;
  final double? debit;
  final double? credit;
  final double balance;

  String get displayDate => _dash(entryDateLabel ?? entryDate);

  String get displayDescription => _dash(description);

  String get displayRef => _dash(ref);

  String get displayDebit => debit == null ? '—' : formatFeeAmount(debit);

  String get displayCredit => credit == null ? '—' : formatFeeAmount(credit);

  factory ParentFeeLedgerEntry.fromJson(Map<String, dynamic> json) {
    return ParentFeeLedgerEntry(
      id: _asInt(json['id']),
      entryDate: _asString(json['entry_date']),
      entryDateLabel: _asString(json['entry_date_label']),
      description: _asString(json['description']),
      isAdvanceApplication: json['is_advance_application'] == true,
      ref: _asString(json['ref']),
      debit: _asDouble(json['debit']),
      credit: _asDouble(json['credit']),
      balance: _asDouble(json['balance']) ?? 0,
    );
  }
}

String formatFeeAmount(num? value) {
  final amount = (value ?? 0).toDouble();
  final negative = amount < 0;
  final parts = amount.abs().toStringAsFixed(2).split('.');
  final whole = parts[0];
  final buffer = StringBuffer();
  for (var i = 0; i < whole.length; i++) {
    final remaining = whole.length - i;
    if (i > 0 && remaining % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(whole[i]);
  }
  return '${negative ? '-' : ''}${buffer.toString()}.${parts[1]}';
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

double? _asDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

String? _asString(dynamic value) {
  if (value == null) return null;
  if (value is String) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
  return value.toString();
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

List<T> _asObjectList<T>(
  dynamic value,
  T Function(Map<String, dynamic> json) map,
) {
  if (value is! List) return const [];
  return [
    for (final item in value)
      if (_asMap(item) != null) map(_asMap(item)!),
  ];
}

String _dash(String? value) {
  final text = value?.trim() ?? '';
  return text.isEmpty ? '—' : text;
}

List<T> _mergeById<T>(
  List<T> current,
  List<T> extra,
  int? Function(T row) idOf,
) {
  final seen = <int>{
    for (final row in current)
      if (idOf(row) != null) idOf(row)!,
  };

  return [
    ...current,
    for (final row in extra)
      if (idOf(row) == null || seen.add(idOf(row)!)) row,
  ];
}
