import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ozet_app/core/errors/app_error_handler.dart';
import 'package:ozet_app/core/errors/app_failure.dart';
import 'package:ozet_app/services/news_feed_service.dart';

typedef NewsVisibilityPredicate =
    bool Function(QueryDocumentSnapshot<Map<String, dynamic>> document);
typedef NewsDocumentBuilder =
    Widget Function(
      BuildContext context,
      QueryDocumentSnapshot<Map<String, dynamic>> document,
    );

class PaginatedNewsFeed extends StatefulWidget {
  const PaginatedNewsFeed({
    super.key,
    required this.service,
    required this.isVisible,
    required this.itemBuilder,
    required this.mutedColor,
    required this.dividerColor,
    required this.scrollController,
    this.pageSize = 12,
    this.prefetchExtent = 650,
  });

  final NewsFeedService service;
  final NewsVisibilityPredicate isVisible;
  final NewsDocumentBuilder itemBuilder;
  final Color mutedColor;
  final Color dividerColor;
  final ScrollController scrollController;
  final int pageSize;
  final double prefetchExtent;

  @override
  State<PaginatedNewsFeed> createState() => _PaginatedNewsFeedState();
}

class _PaginatedNewsFeedState extends State<PaginatedNewsFeed>
    with WidgetsBindingObserver {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> _documents = [];
  DocumentSnapshot<Map<String, dynamic>>? _cursor;
  AppFailure? _error;
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.scrollController.addListener(_handleScroll);
    unawaited(_loadPage(reset: true));
  }

  @override
  void didUpdateWidget(covariant PaginatedNewsFeed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController.removeListener(_handleScroll);
      widget.scrollController.addListener(_handleScroll);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_loadPage(reset: true, silent: true));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.scrollController.removeListener(_handleScroll);
    super.dispose();
  }

  void _handleScroll() {
    if (!mounted ||
        _isInitialLoading ||
        _isLoadingMore ||
        !_hasMore ||
        _error != null ||
        !widget.scrollController.hasClients) {
      return;
    }

    if (widget.scrollController.position.extentAfter <= widget.prefetchExtent) {
      unawaited(_loadPage());
    }
  }

  Future<void> _loadPage({bool reset = false, bool silent = false}) async {
    if (_isLoadingMore || (_isInitialLoading && !reset)) return;
    if (!reset && !_hasMore) return;

    final currentVisibleCount = _documents.where(widget.isVisible).length;
    final targetVisibleCount = reset
        ? widget.pageSize
        : currentVisibleCount + widget.pageSize;
    final loadedDocuments = reset
        ? <QueryDocumentSnapshot<Map<String, dynamic>>>[]
        : List<QueryDocumentSnapshot<Map<String, dynamic>>>.of(_documents);
    var nextCursor = reset ? null : _cursor;
    var hasMore = reset ? true : _hasMore;

    setState(() {
      _error = null;
      if (reset) {
        _isInitialLoading = !silent && _documents.isEmpty;
      } else {
        _isLoadingMore = true;
      }
    });

    try {
      // Taslaklar ayni koleksiyonda oldugu icin, ekranda yeterli sayida
      // yayinlanmis haber olana kadar cursor sayfalarini otomatik atlariz.
      while (hasMore &&
          loadedDocuments.where(widget.isVisible).length < targetVisibleCount) {
        final page = await widget.service.loadPage(
          after: nextCursor,
          pageSize: widget.pageSize,
        );
        final knownIds = loadedDocuments.map((item) => item.id).toSet();
        loadedDocuments.addAll(
          page.documents.where((item) => knownIds.add(item.id)),
        );
        nextCursor = page.cursor;
        hasMore = page.hasMore;
      }
      if (!mounted) return;

      setState(() {
        if (reset && silent && _documents.isNotEmpty) {
          final refreshedIds = loadedDocuments.map((item) => item.id).toSet();
          loadedDocuments.addAll(
            _documents.where((item) => refreshedIds.add(item.id)),
          );
          nextCursor = _cursor;
          hasMore = _hasMore;
        }
        _documents
          ..clear()
          ..addAll(loadedDocuments);
        _cursor = nextCursor;
        _hasMore = hasMore;
      });
    } catch (error, stackTrace) {
      final failure = await AppErrorHandler.capture(
        error,
        stackTrace,
        operation: reset ? 'news.initial_load' : 'news.load_more',
        fallbackMessage: 'Haberler yüklenemedi.',
        context: {'reset': reset, 'loadedDocuments': loadedDocuments.length},
      );
      if (!mounted) return;
      setState(() => _error = failure);
    } finally {
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
          _isLoadingMore = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => _handleScroll());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    final visibleDocuments = _documents.where(widget.isVisible).toList();
    if (visibleDocuments.isEmpty && _error != null) {
      return _buildRecoveryState(_error!);
    }

    if (visibleDocuments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Column(
          children: [
            Text(
              'Yayında haber yok.',
              textAlign: TextAlign.center,
              style: GoogleFonts.kadwa(fontSize: 14, color: widget.mutedColor),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        ListView.separated(
          padding: const EdgeInsets.only(top: 8),
          itemCount: visibleDocuments.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          separatorBuilder: (context, index) =>
              Divider(height: 1, thickness: 1, color: widget.dividerColor),
          itemBuilder: (context, index) =>
              widget.itemBuilder(context, visibleDocuments[index]),
        ),
        if (_error != null)
          _buildRecoveryState(_error!)
        else if (_isLoadingMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 1.8),
            ),
          ),
      ],
    );
  }

  Widget _buildRecoveryState(AppFailure failure) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_outlined, size: 18, color: widget.mutedColor),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              failure.userMessage,
              style: GoogleFonts.inter(
                color: widget.mutedColor,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (failure.canRetry) ...[
            const SizedBox(width: 6),
            TextButton(
              onPressed: () => _loadPage(reset: _documents.isEmpty),
              child: const Text('Tekrar dene'),
            ),
          ],
        ],
      ),
    );
  }
}
