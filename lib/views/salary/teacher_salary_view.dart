import 'package:flutter/material.dart';

import '../../controllers/teacher_salary_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/auth_session.dart';
import '../../models/teacher_salary.dart';
import '../../services/teacher_salary_service.dart';
import '../widgets/pull_to_refresh.dart';

String _money(double amount) {
  final parts = amount.abs().toStringAsFixed(2).split('.');
  final whole = parts[0].replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]},',
  );
  return '$whole.${parts[1]}';
}

class TeacherSalaryView extends StatefulWidget {
  const TeacherSalaryView({
    super.key,
    required this.session,
    this.service,
  });

  final AuthSession session;
  final TeacherSalaryService? service;

  @override
  State<TeacherSalaryView> createState() => _TeacherSalaryViewState();
}

class _TeacherSalaryViewState extends State<TeacherSalaryView> {
  late final TeacherSalaryController _controller = TeacherSalaryController(
    session: widget.session,
    service: widget.service,
  );
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _controller.load();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 240) {
      _controller.loadMore();
    }
  }

  Future<void> _openSlip(TeacherSalaryItem item) async {
    final slip = await _controller.openSlip(item.id);
    if (!mounted || slip == null) {
      if (!mounted) return;
      final message = _controller.errorMessage;
      if (message != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => _SalarySlipSheet(slip: slip),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text(AppStrings.salarySlips)),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.loading && _controller.data == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.navy),
            );
          }

          if (_controller.errorMessage != null && _controller.data == null) {
            return PullToRefresh(
              color: AppColors.navy,
              onRefresh: () => _controller.load(refresh: true),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
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
                    onPressed: () => _controller.load(refresh: true),
                    child: const Text(AppStrings.retry),
                  ),
                ],
              ),
            );
          }

          final data = _controller.data;
          final items = data?.items ?? const <TeacherSalaryItem>[];
          final salary = data?.summary.monthlySalary;

          return PullToRefresh(
            color: AppColors.navy,
            onRefresh: () => _controller.load(refresh: true),
            child: ListView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                if (salary != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.payments_outlined, color: AppColors.navy),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                AppStrings.monthlySalary,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.muted,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'PKR ${_money(salary)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.navy,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                if (items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 48),
                    child: Text(
                      AppStrings.noSalarySlips,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  ...items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: _controller.loadingSlip
                              ? null
                              : () => _openSlip(item),
                          child: Ink(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.periodLabel?.trim().isNotEmpty == true
                                              ? item.periodLabel!
                                              : 'Salary slip',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.navy,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.statusLabel ?? item.status ?? '—',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.muted,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if ((item.paidAtLabel ?? '').trim().isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            'Paid on ${item.paidAtLabel}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.muted,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'PKR ${_money(item.netPay)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.navy,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      const Icon(
                                        Icons.chevron_right_rounded,
                                        color: AppColors.muted,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_controller.loadingMore)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.navy),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SalarySlipSheet extends StatelessWidget {
  const _SalarySlipSheet({
    required this.slip,
  });

  final TeacherSalaryItem slip;

  @override
  Widget build(BuildContext context) {
    final earnings = slip.lines.where((line) => line.category == 'earning');
    final deductions = slip.lines.where((line) => line.category == 'deduction');

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                slip.periodLabel ?? AppStrings.salarySlips,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                slip.statusLabel ?? slip.status ?? '—',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              _InfoRow(
                label: 'Net pay',
                value: 'PKR ${_money(slip.netPay)}',
                emphasize: true,
              ),
              _InfoRow(
                label: 'Earnings',
                value: 'PKR ${_money(slip.totalEarnings)}',
              ),
              _InfoRow(
                label: 'Deductions',
                value: 'PKR ${_money(slip.totalDeductions)}',
              ),
              if (slip.workingDays != null)
                _InfoRow(
                  label: 'Attendance',
                  value:
                      '${slip.presentDays ?? 0} present / ${slip.unpaidLeaveDays ?? 0} unpaid of ${slip.workingDays} days',
                ),
              if ((slip.paidAtLabel ?? '').trim().isNotEmpty)
                _InfoRow(label: 'Paid on', value: slip.paidAtLabel!),
              const SizedBox(height: 14),
              const Text(
                'Earnings',
                style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy),
              ),
              const SizedBox(height: 8),
              ...earnings.map(
                (line) => _InfoRow(
                  label: line.headName?.trim().isNotEmpty == true
                      ? line.headName!
                      : 'Earning',
                  value: _money(line.amount),
                ),
              ),
              if (earnings.isEmpty) const _InfoRow(label: '—', value: '0.00'),
              const SizedBox(height: 14),
              const Text(
                'Deductions',
                style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy),
              ),
              const SizedBox(height: 8),
              ...deductions.map(
                (line) => _InfoRow(
                  label: line.headName?.trim().isNotEmpty == true
                      ? line.headName!
                      : 'Deduction',
                  value: '-${_money(line.amount)}',
                ),
              ),
              if (deductions.isEmpty) const _InfoRow(label: '—', value: '0.00'),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.muted,
                fontWeight: emphasize ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: AppColors.navy,
              fontWeight: emphasize ? FontWeight.w800 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
