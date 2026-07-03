import 'package:flutter/material.dart';

typedef PageLoader<T> = Future<({List<T> items, int lastPage})> Function(
  int page,
);

/// Scrollable list with pull-to-refresh and infinite scroll at the bottom.
class LoadMoreListView<T> extends StatefulWidget {
  const LoadMoreListView({
    super.key,
    required this.loader,
    required this.itemBuilder,
    this.padding,
    this.separatorBuilder,
    this.empty,
    this.onRefreshExtra,
  });

  final PageLoader<T> loader;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final EdgeInsetsGeometry? padding;
  final Widget Function(BuildContext context, int index)? separatorBuilder;
  final Widget? empty;
  final Future<void> Function()? onRefreshExtra;

  @override
  State<LoadMoreListView<T>> createState() => _LoadMoreListViewState<T>();
}

class _LoadMoreListViewState<T> extends State<LoadMoreListView<T>> {
  final _scrollController = ScrollController();
  final _items = <T>[];
  var _page = 1;
  var _lastPage = 1;
  var _loading = true;
  var _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitial();
  }

  @override
  void didUpdateWidget(LoadMoreListView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loader != widget.loader) {
      _resetAndLoad();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _resetAndLoad() async {
    setState(() {
      _items.clear();
      _page = 1;
      _lastPage = 1;
      _loading = true;
      _error = null;
    });
    await _loadPage(1, replace: true);
  }

  Future<void> _loadInitial() => _loadPage(1, replace: true);

  void _onScroll() {
    if (_loadingMore || _loading || _page >= _lastPage) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 240) {
      _loadPage(_page + 1);
    }
  }

  Future<void> _loadPage(int page, {bool replace = false}) async {
    if (!replace && page > 1) {
      setState(() => _loadingMore = true);
    } else if (replace) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final result = await widget.loader(page);
      if (!mounted) return;
      setState(() {
        if (replace) {
          _items
            ..clear()
            ..addAll(result.items);
        } else {
          _items.addAll(result.items);
        }
        _page = page;
        _lastPage = result.lastPage < 1 ? 1 : result.lastPage;
        _loading = false;
        _loadingMore = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _refresh() async {
    await widget.onRefreshExtra?.call();
    await _resetAndLoad();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _loadInitial,
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return widget.empty ?? const Center(child: Text('Tidak ada data'));
    }

    final itemCount = _items.length + (_loadingMore ? 1 : 0);

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        controller: _scrollController,
        padding: widget.padding ?? const EdgeInsets.symmetric(vertical: 8),
        itemCount: itemCount,
        separatorBuilder: widget.separatorBuilder ??
            (_, __) => const SizedBox.shrink(),
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          return widget.itemBuilder(context, _items[index], index);
        },
      ),
    );
  }
}