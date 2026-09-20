import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/auth_session.dart';
import '../controllers/parent_fee_voucher_controller.dart';
import '../models/parent_fee_vouchers.dart';
import '../services/parent_fee_voucher_service.dart';
import '../widgets/parent_load_more.dart';

class ParentFeeVouchersView extends StatefulWidget {
  const ParentFeeVouchersView({
    super.key,
    required this.session,
    this.service,
  });

  final AuthSession session;
  final ParentFeeVoucherService? service;

  @override
  State<ParentFeeVouchersView> createState() => _ParentFeeVouchersViewState();
}

class _ParentFeeVouchersViewState extends State<ParentFeeVouchersView> {
  late final ParentFeeVoucherController _controller = ParentFeeVoucherController(
    session: widget.session,
    service: widget.service,
  );

  @override
  void initState() {
    super.initState();
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.feeVouchers),
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.loading && _controller.data == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.navy),
            );
          }

          if (_controller.errorMessage != null && _controller.data == null) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 48, 20, 32),
              children: [
                Text(
                  _controller.errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _controller.load,
                  child: const Text(AppStrings.retry),
                ),
              ],
            );
          }

          final data = _controller.data ?? const ParentFeeVoucherData();
          final child = widget.session.selectedStudent;
          final studentName = (data.studentName ?? child?.title)?.trim();
          final subtitle = data.headerSubtitle.isNotEmpty
              ? data.headerSubtitle
              : [
                  if ((child?.classLabel ?? '').isNotEmpty) child!.classLabel,
                  if ((child?.branchName ?? '').trim().isNotEmpty) child!.branchName!.trim(),
                ].join(' · ');

          return RefreshIndicator(
            color: AppColors.navy,
            onRefresh: () => _controller.load(refresh: true),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _StudentHeader(
                  name: (studentName == null || studentName.isEmpty)
                      ? AppStrings.feeVouchers
                      : studentName,
                  subtitle: subtitle,
                ),
                const SizedBox(height: 12),
                _TabGrid(
                  tab: _controller.tab,
                  counts: data.counts,
                  onSelected: _controller.selectTab,
                ),
                const SizedBox(height: 12),
                _Panel(
                  tab: _controller.tab,
                  data: data,
                  hasMore: _controller.hasMore,
                  loadingMore: _controller.loadingMore,
                  onLoadMore: _controller.loadMore,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StudentHeader extends StatelessWidget {
  const _StudentHeader({
    required this.name,
    required this.subtitle,
  });

  final String name;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TabGrid extends StatelessWidget {
  const _TabGrid({
    required this.tab,
    required this.counts,
    required this.onSelected,
  });

  final ParentFeeVoucherTab tab;
  final ParentFeeVoucherCounts counts;
  final ValueChanged<ParentFeeVoucherTab> onSelected;

  @override
  Widget build(BuildContext context) {
    const items = [
      (ParentFeeVoucherTab.unpaid, AppStrings.feeVouchersUnpaid),
      (ParentFeeVoucherTab.partial, AppStrings.feeVouchersPartial),
      (ParentFeeVoucherTab.invoices, AppStrings.feeVouchersInvoices),
      (ParentFeeVoucherTab.ledger, AppStrings.feeVouchersLedger),
    ];

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _tab(items[0])),
            const SizedBox(width: 8),
            Expanded(child: _tab(items[1])),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _tab(items[2])),
            const SizedBox(width: 8),
            Expanded(child: _tab(items[3])),
          ],
        ),
      ],
    );
  }

  Widget _tab((ParentFeeVoucherTab, String) item) {
    return _FeeTab(
      label: item.$2,
      count: counts.of(item.$1),
      selected: tab == item.$1,
      onTap: () => onSelected(item.$1),
    );
  }
}

class _FeeTab extends StatelessWidget {
  const _FeeTab({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: selected
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF3B7EF6), Color(0xFF6C47F5)],
                  )
                : null,
            color: selected ? null : Colors.white,
            border: Border.all(
              color: selected ? Colors.transparent : const Color(0xFFD7DDE8),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? Colors.white : const Color(0xFF334155),
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                      height: 1.25,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.22)
                        : const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: selected ? Colors.white : const Color(0xFF3730A3),
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.tab,
    required this.data,
    required this.hasMore,
    required this.loadingMore,
    required this.onLoadMore,
  });

  final ParentFeeVoucherTab tab;
  final ParentFeeVoucherData data;
  final bool hasMore;
  final bool loadingMore;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    final (title, subtitle) = switch (tab) {
      ParentFeeVoucherTab.unpaid => (
          AppStrings.unpaidFeeVouchersTitle,
          AppStrings.unpaidFeeVouchersHint,
        ),
      ParentFeeVoucherTab.partial => (
          AppStrings.partialFeeVouchersTitle,
          AppStrings.partialFeeVouchersHint,
        ),
      ParentFeeVoucherTab.invoices => (
          AppStrings.paidInvoicesTitle,
          AppStrings.paidInvoicesHint,
        ),
      ParentFeeVoucherTab.ledger => (
          AppStrings.studentLedgerTitle,
          AppStrings.studentLedgerHint,
        ),
    };

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                if (tab == ParentFeeVoucherTab.ledger) ...[
                  const SizedBox(height: 10),
                  _LedgerTotals(ledger: data.ledger),
                ],
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEF2F7)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                _PanelBody(tab: tab, data: data),
                if (hasMore || loadingMore) ...[
                  const SizedBox(height: 12),
                  ParentLoadMore(loading: loadingMore, onPressed: onLoadMore),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelBody extends StatelessWidget {
  const _PanelBody({
    required this.tab,
    required this.data,
  });

  final ParentFeeVoucherTab tab;
  final ParentFeeVoucherData data;

  @override
  Widget build(BuildContext context) {
    switch (tab) {
      case ParentFeeVoucherTab.unpaid:
        if (data.unpaid.isEmpty) {
          return const _EmptyText(AppStrings.noUnpaidFeeVouchers);
        }
        return _VoucherList(vouchers: data.unpaid);
      case ParentFeeVoucherTab.partial:
        if (data.partial.isEmpty) {
          return const _EmptyText(AppStrings.noPartialFeeVouchers);
        }
        return _VoucherList(vouchers: data.partial, showPartial: true);
      case ParentFeeVoucherTab.invoices:
        if (data.invoices.isEmpty) {
          return const _EmptyText(AppStrings.noPaidInvoices);
        }
        return Column(
          children: [
            for (var i = 0; i < data.invoices.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              _InvoiceCard(invoice: data.invoices[i]),
            ],
          ],
        );
      case ParentFeeVoucherTab.ledger:
        if (!data.hasEnrollment) {
          return const _EmptyText(AppStrings.noFeeEnrollment);
        }
        if (data.ledger.entries.isEmpty) {
          return const _EmptyText(AppStrings.noLedgerEntries);
        }
        return Column(
          children: [
            for (var i = 0; i < data.ledger.entries.length; i++) ...[
              if (i > 0) const Divider(height: 18, color: Color(0xFFEEF2F7)),
              _LedgerRow(entry: data.ledger.entries[i]),
            ],
          ],
        );
    }
  }
}

class _VoucherList extends StatelessWidget {
  const _VoucherList({
    required this.vouchers,
    this.showPartial = false,
  });

  final List<ParentFeeVoucher> vouchers;
  final bool showPartial;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < vouchers.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _VoucherCard(voucher: vouchers[i], showPartial: showPartial),
        ],
      ],
    );
  }
}

class _VoucherCard extends StatelessWidget {
  const _VoucherCard({
    required this.voucher,
    required this.showPartial,
  });

  final ParentFeeVoucher voucher;
  final bool showPartial;

  @override
  Widget build(BuildContext context) {
    final sessionName = voucher.sessionName?.trim() ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEF2F7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  voucher.displayVoucherNo,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              _StatusPill(
                status: voucher.paymentStatus,
                label: voucher.displayStatus,
              ),
            ],
          ),
          if (sessionName.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              sessionName,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 10),
          _MetaRow(label: AppStrings.feeMonth, value: voucher.displayMonth),
          const SizedBox(height: 6),
          _MetaRow(label: AppStrings.dueDate, value: voucher.displayDueDate),
          const SizedBox(height: 6),
          _MetaRow(
            label: AppStrings.netPayable,
            value: formatFeeAmount(voucher.netPayable),
            emphasize: true,
          ),
          if (showPartial) ...[
            const SizedBox(height: 6),
            _MetaRow(label: AppStrings.paidAmount, value: formatFeeAmount(voucher.paidAmount)),
            const SizedBox(height: 6),
            _MetaRow(
              label: AppStrings.balanceAmount,
              value: formatFeeAmount(voucher.balanceAmount),
              emphasize: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard({required this.invoice});

  final ParentFeeInvoice invoice;

  @override
  Widget build(BuildContext context) {
    final sessionName = invoice.sessionName?.trim() ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEF2F7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            invoice.displayInvoiceNo,
            style: const TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          if (sessionName.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              sessionName,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 10),
          _MetaRow(label: AppStrings.paymentDate, value: invoice.displayPaymentDate),
          const SizedBox(height: 6),
          _MetaRow(label: AppStrings.feeMonths, value: invoice.displayMonths),
          const SizedBox(height: 6),
          _MetaRow(
            label: AppStrings.invoiceAmount,
            value: formatFeeAmount(invoice.amount),
            emphasize: true,
          ),
          const SizedBox(height: 6),
          _MetaRow(label: AppStrings.paymentMethod, value: invoice.displayMethod),
        ],
      ),
    );
  }
}

class _LedgerTotals extends StatelessWidget {
  const _LedgerTotals({required this.ledger});

  final ParentFeeLedger ledger;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: [
        _TotalChip(label: AppStrings.ledgerDebit, value: formatFeeAmount(ledger.totalDebit)),
        _TotalChip(label: AppStrings.ledgerCredit, value: formatFeeAmount(ledger.totalCredit)),
        _TotalChip(label: AppStrings.ledgerBalance, value: formatFeeAmount(ledger.netBalance)),
      ],
    );
  }
}

class _TotalChip extends StatelessWidget {
  const _TotalChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label ',
          style: const TextStyle(
            color: AppColors.muted,
            fontWeight: FontWeight.w600,
            fontSize: 12.5,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.w800,
            fontSize: 12.5,
          ),
        ),
      ],
    );
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({required this.entry});

  final ParentFeeLedgerEntry entry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                entry.displayDate,
                style: const TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            Text(
              entry.displayRef,
              style: const TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          entry.displayDescription,
          style: const TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
          ),
        ),
        if (entry.isAdvanceApplication) ...[
          const SizedBox(height: 2),
          const Text(
            AppStrings.advanceApplied,
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _MetaRow(label: AppStrings.ledgerDebit, value: entry.displayDebit)),
            Expanded(child: _MetaRow(label: AppStrings.ledgerCredit, value: entry.displayCredit)),
            Expanded(
              child: _MetaRow(
                label: AppStrings.ledgerBalance,
                value: formatFeeAmount(entry.balance),
                emphasize: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.muted,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: AppColors.text,
              fontWeight: emphasize ? FontWeight.w800 : FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.status,
    required this.label,
  });

  final String? status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (status) {
      'partial' => (const Color(0xFFFEF3C7), const Color(0xFF92400E)),
      'paid' => (const Color(0xFFDCFCE7), const Color(0xFF166534)),
      _ => (const Color(0xFFFEE2E2), const Color(0xFF991B1B)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _EmptyText extends StatelessWidget {
  const _EmptyText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF94A3B8),
          fontWeight: FontWeight.w600,
          fontSize: 13.5,
        ),
      ),
    );
  }
}
