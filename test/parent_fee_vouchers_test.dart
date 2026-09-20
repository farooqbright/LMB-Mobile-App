import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lmssystem/core/constants/app_strings.dart';
import 'package:lmssystem/core/network/api_exception.dart';
import 'package:lmssystem/models/auth_session.dart';
import 'package:lmssystem/parent/controllers/parent_fee_voucher_controller.dart';
import 'package:lmssystem/parent/models/parent_fee_vouchers.dart';
import 'package:lmssystem/parent/screens/parent_fee_vouchers_view.dart';
import 'package:lmssystem/parent/services/parent_fee_voucher_service.dart';

AuthSession _parentSession() {
  return AuthSession.fromJson({
    'token': 'parent.token',
    'token_type': 'Bearer',
    'type': 'parent',
    'school': {'id': '1', 'name': 'SLS', 'domain': 'sls.localhost'},
    'user': {
      'id': 9,
      'name': 'Ali',
      'last_name': 'Parent',
      'username': '34101-0111110-6',
      'roles': ['Parent'],
    },
    'profile': {
      'type': 'parent',
      'guardian_id': 4,
      'full_name': 'Ali Parent',
      'children': [
        {
          'student_id': 11,
          'full_name': 'Ahmed Ali',
          'roll_number': '05',
          'class_name': 'Class 5',
          'section_name': 'A',
          'branch_name': 'Main Campus',
        },
      ],
    },
    'selected_student_id': 11,
  });
}

class _FakeFeeService extends ParentFeeVoucherService {
  _FakeFeeService(this.data, {this.error});

  final ParentFeeVoucherData data;
  final Object? error;
  var fetches = 0;
  ParentFeeVoucherQuery? lastQuery;

  @override
  Future<ParentFeeVoucherData> fetch(
    AuthSession session, {
    ParentFeeVoucherQuery query = const ParentFeeVoucherQuery(),
  }) async {
    fetches += 1;
    lastQuery = query;
    if (error != null) throw error!;
    return data;
  }
}

class _PagingFeeService extends ParentFeeVoucherService {
  var fetches = 0;

  @override
  Future<ParentFeeVoucherData> fetch(
    AuthSession session, {
    ParentFeeVoucherQuery query = const ParentFeeVoucherQuery(),
  }) async {
    fetches += 1;
    final voucherNo = query.page == 1 ? 'FV-1001' : 'FV-1002';
    return ParentFeeVoucherData.fromJson({
      'student': {
        'student_id': 11,
        'full_name': 'Ahmed Ali',
        'class_name': 'Class 5',
        'section_name': 'A',
        'branch_name': 'Main Campus',
        'session_name': '2026-27',
      },
      'has_enrollment': true,
      'counts': {'unpaid': 2, 'partial': 0, 'invoices': 0, 'ledger': 0},
      'unpaid': [
        {
          'id': query.page,
          'voucher_no': voucherNo,
          'month': 'September',
          'payment_status': 'unpaid',
          'status_label': 'Unpaid',
          'net_payable': 1000,
        },
      ],
      'partial': [],
      'invoices': [],
      'ledger': {'total_debit': 0, 'total_credit': 0, 'net_balance': 0, 'entries': []},
    }, metaJson: {
      'current_page': query.page,
      'last_page': 2,
      'per_page': 25,
      'total': 2,
    });
  }
}

ParentFeeVoucherData _sampleData() {
  return ParentFeeVoucherData.fromJson({
    'student': {
      'student_id': 11,
      'full_name': 'Ahmed Ali',
      'roll_number': '05',
      'class_name': 'Class 5',
      'section_name': 'A',
      'branch_name': 'Main Campus',
      'session_name': '2026-27',
    },
    'has_enrollment': true,
    'counts': {
      'unpaid': 1,
      'partial': 1,
      'invoices': 1,
      'ledger': 2,
    },
    'unpaid': [
      {
        'id': 21,
        'voucher_no': 'FV-1001',
        'session_name': '2026-27',
        'month': 'September',
        'due_date': '2026-09-10',
        'due_date_label': '10 Sep 2026',
        'net_payable': 12500,
        'paid_amount': 0,
        'balance_amount': 12500,
        'payment_status': 'unpaid',
        'status_label': 'Unpaid',
      },
    ],
    'partial': [
      {
        'id': 22,
        'voucher_no': 'FV-0988',
        'session_name': '2026-27',
        'month': 'August',
        'due_date': '2026-08-10',
        'due_date_label': '10 Aug 2026',
        'net_payable': 12500,
        'paid_amount': 5000,
        'balance_amount': 7500,
        'payment_status': 'partial',
        'status_label': 'Partial',
      },
    ],
    'invoices': [
      {
        'id': 9,
        'invoice_no': 'INV-0044',
        'session_name': '2026-27',
        'payment_date': '2026-08-12',
        'payment_date_label': '12 Aug 2026',
        'months_label': 'August-(partially)',
        'amount': 5000,
        'payment_method': 'cash',
        'payment_method_label': 'Cash',
      },
    ],
    'ledger': {
      'total_debit': 25000,
      'total_credit': 5000,
      'net_balance': 20000,
      'entries': [
        {
          'id': 1,
          'entry_date': '2026-08-01',
          'entry_date_label': '01 Aug 2026',
          'description': 'September fee voucher',
          'is_advance_application': false,
          'ref': 'FV-1001',
          'debit': 12500,
          'credit': null,
          'balance': 12500,
        },
        {
          'id': 2,
          'entry_date': '2026-08-12',
          'entry_date_label': '12 Aug 2026',
          'description': 'Fee collection',
          'is_advance_application': false,
          'ref': 'INV-0044',
          'debit': null,
          'credit': 5000,
          'balance': 7500,
        },
      ],
    },
  });
}

void main() {
  test('parses unpaid, partial, invoice and ledger fee data', () {
    final data = _sampleData();

    expect(data.studentName, 'Ahmed Ali');
    expect(data.headerSubtitle, 'Main Campus · 2026-27 · Class 5 — A · Roll 05');
    expect(data.counts.unpaid, 1);
    expect(data.unpaid.first.displayVoucherNo, 'FV-1001');
    expect(data.unpaid.first.displayStatus, 'Unpaid');
    expect(formatFeeAmount(data.unpaid.first.netPayable), '12,500.00');
    expect(data.partial.first.displayStatus, 'Partial');
    expect(data.invoices.first.displayMonths, 'August-(partially)');
    expect(data.invoices.first.displayMethod, 'Cash');
    expect(data.ledger.entries, hasLength(2));
    expect(data.ledger.entries.first.displayDebit, '12,500.00');
    expect(data.ledger.entries.last.displayCredit, '5,000.00');
  });

  test('defaults to the unpaid tab and loads other tabs on demand', () async {
    final fake = _FakeFeeService(_sampleData());
    final controller = ParentFeeVoucherController(
      session: _parentSession(),
      service: fake,
    );

    expect(controller.tab, ParentFeeVoucherTab.unpaid);

    await controller.load();
    await controller.selectTab(ParentFeeVoucherTab.ledger);

    expect(fake.fetches, 2);
    expect(fake.lastQuery?.tab, 'ledger');
    expect(controller.tab, ParentFeeVoucherTab.ledger);
    expect(controller.data?.ledger.entries, hasLength(2));
  });

  test('loads more unpaid vouchers when another page exists', () async {
    final fake = _PagingFeeService();
    final controller = ParentFeeVoucherController(
      session: _parentSession(),
      service: fake,
    );

    await controller.load();
    expect(controller.data?.unpaid.map((row) => row.voucherNo), ['FV-1001']);
    expect(controller.hasMore, isTrue);

    await controller.loadMore();
    expect(fake.fetches, 2);
    expect(controller.data?.unpaid.map((row) => row.voucherNo), ['FV-1001', 'FV-1002']);
    expect(controller.hasMore, isFalse);
  });

  testWidgets('shows unpaid vouchers then switches to invoices and ledger', (tester) async {
    final fake = _FakeFeeService(_sampleData());

    await tester.pumpWidget(
      MaterialApp(
        home: ParentFeeVouchersView(
          session: _parentSession(),
          service: fake,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.feeVouchers), findsOneWidget);
    expect(find.text('Ahmed Ali'), findsOneWidget);
    expect(find.text('Main Campus · 2026-27 · Class 5 — A · Roll 05'), findsOneWidget);
    expect(find.text(AppStrings.feeVouchersUnpaid), findsOneWidget);
    expect(find.text(AppStrings.unpaidFeeVouchersTitle), findsOneWidget);
    expect(find.text('FV-1001'), findsOneWidget);
    expect(find.text('September'), findsOneWidget);
    expect(find.text('10 Sep 2026'), findsOneWidget);
    expect(find.text('12,500.00'), findsWidgets);
    expect(find.text('Unpaid'), findsOneWidget);

    await tester.tap(find.text(AppStrings.feeVouchersInvoices));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.paidInvoicesTitle), findsOneWidget);
    expect(find.text('INV-0044'), findsOneWidget);
    expect(find.text('August-(partially)'), findsOneWidget);
    expect(find.text('Cash'), findsOneWidget);
    expect(fake.fetches, 2);

    await tester.tap(find.text(AppStrings.feeVouchersLedger));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.studentLedgerTitle), findsOneWidget);
    expect(find.text('September fee voucher'), findsOneWidget);
    expect(find.text('Fee collection'), findsOneWidget);
    expect(find.text('20,000.00'), findsOneWidget);
    expect(fake.fetches, 3);
  });

  testWidgets('shows empty unpaid message', (tester) async {
    final fake = _FakeFeeService(
      ParentFeeVoucherData.fromJson({
        'student': {
          'student_id': 11,
          'full_name': 'Ahmed Ali',
          'class_name': 'Class 5',
          'section_name': 'A',
          'branch_name': 'Main Campus',
          'session_name': '2026-27',
        },
        'has_enrollment': true,
        'counts': {'unpaid': 0, 'partial': 0, 'invoices': 0, 'ledger': 0},
        'unpaid': [],
        'partial': [],
        'invoices': [],
        'ledger': {
          'total_debit': 0,
          'total_credit': 0,
          'net_balance': 0,
          'entries': [],
        },
      }),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ParentFeeVouchersView(
          session: _parentSession(),
          service: fake,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.noUnpaidFeeVouchers), findsOneWidget);
  });

  testWidgets('shows error with retry', (tester) async {
    final fake = _FakeFeeService(
      const ParentFeeVoucherData(),
      error: const ApiException('Unable to load fee vouchers.'),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ParentFeeVouchersView(
          session: _parentSession(),
          service: fake,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Unable to load fee vouchers.'), findsOneWidget);
    expect(find.text(AppStrings.retry), findsOneWidget);
  });
}
