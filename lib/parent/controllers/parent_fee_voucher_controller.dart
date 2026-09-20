import 'package:flutter/foundation.dart';

import '../../core/network/api_exception.dart';
import '../../models/auth_session.dart';
import '../models/parent_fee_vouchers.dart';
import '../services/parent_fee_voucher_service.dart';

class ParentFeeVoucherController extends ChangeNotifier {
  ParentFeeVoucherController({
    required this.session,
    ParentFeeVoucherService? service,
  }) : _service = service ?? ParentFeeVoucherService();

  static const int pageSize = 25;

  final AuthSession session;
  final ParentFeeVoucherService _service;

  ParentFeeVoucherTab tab = ParentFeeVoucherTab.unpaid;
  bool loading = true;
  bool loadingMore = false;
  String? errorMessage;
  ParentFeeVoucherData? data;

  final Set<ParentFeeVoucherTab> _loadedTabs = {};
  final Map<ParentFeeVoucherTab, int> _pages = {};
  final Map<ParentFeeVoucherTab, ParentFeePageMeta> _metas = {};

  bool get hasMore => _metas[tab]?.hasMore ?? false;

  ParentFeeVoucherQuery queryFor(ParentFeeVoucherTab tab, {required int page}) {
    return ParentFeeVoucherQuery(
      tab: tab.apiValue,
      page: page,
      perPage: pageSize,
    );
  }

  Future<void> load({bool refresh = false, ParentFeeVoucherTab? tab}) async {
    final target = tab ?? this.tab;
    if (refresh) {
      _loadedTabs.clear();
      _pages.clear();
      _metas.clear();
    }

    if (!refresh) {
      loading = true;
      errorMessage = null;
      notifyListeners();
    }

    try {
      final result = await _service.fetch(
        session,
        query: queryFor(target, page: 1),
      );
      data = (data ?? result).mergeTab(result, tab: target);
      _pages[target] = result.meta.currentPage;
      _metas[target] = result.meta;
      _loadedTabs.add(target);
      errorMessage = null;
    } on ApiException catch (error) {
      if (data == null) {
        errorMessage = error.message;
      }
    } catch (_) {
      if (data == null) {
        errorMessage = 'Unable to load fee vouchers. Please try again.';
      }
    } finally {
      loading = false;
      loadingMore = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (loading || loadingMore || !hasMore) return;

    loadingMore = true;
    notifyListeners();

    try {
      final nextPage = (_pages[tab] ?? 1) + 1;
      final result = await _service.fetch(
        session,
        query: queryFor(tab, page: nextPage),
      );
      data = (data ?? result).mergeTab(result, tab: tab, append: true);
      _pages[tab] = result.meta.currentPage;
      _metas[tab] = result.meta;
    } catch (_) {
      // Keep the loaded page if more records fail.
    } finally {
      loadingMore = false;
      notifyListeners();
    }
  }

  Future<void> selectTab(ParentFeeVoucherTab value) async {
    if (tab == value) return;
    tab = value;
    notifyListeners();
    if (!_loadedTabs.contains(value)) {
      await load(tab: value);
    }
  }
}
