import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class PullToRefresh extends StatefulWidget {
  const PullToRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
    this.color = AppColors.navy,
    this.displacement = 40,
    this.edgeOffset = 0,
    this.notificationPredicate = defaultScrollNotificationPredicate,
  });

  final Future<void> Function() onRefresh;
  final Widget child;
  final Color color;
  final double displacement;
  final double edgeOffset;
  final ScrollNotificationPredicate notificationPredicate;

  @override
  State<PullToRefresh> createState() => _PullToRefreshState();
}

class _PullToRefreshState extends State<PullToRefresh> {
  var _refreshing = false;

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    try {
      await widget.onRefresh();
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        RefreshIndicator(
          color: widget.color,
          displacement: widget.displacement,
          edgeOffset: widget.edgeOffset,
          notificationPredicate: widget.notificationPredicate,
          onRefresh: _refresh,
          child: widget.child,
        ),
        if (_refreshing) const _RefreshLoadingOverlay(),
      ],
    );
  }
}

class _RefreshLoadingOverlay extends StatelessWidget {
  const _RefreshLoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return const Positioned.fill(
      child: AbsorbPointer(
        child: ColoredBox(
          color: Color(0x1A0F1D4A),
          child: Center(
            child: Material(
              color: Colors.white,
              elevation: 8,
              borderRadius: BorderRadius.all(Radius.circular(16)),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    key: Key('pull-refresh-loading'),
                    color: AppColors.navy,
                    strokeWidth: 3,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
