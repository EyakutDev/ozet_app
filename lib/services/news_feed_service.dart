import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ozet_app/core/diagnostics/app_logger.dart';
import 'package:ozet_app/core/errors/app_failure.dart';

class NewsPage {
  const NewsPage({
    required this.documents,
    required this.cursor,
    required this.hasMore,
    required this.isFromCache,
  });

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> documents;
  final DocumentSnapshot<Map<String, dynamic>>? cursor;
  final bool hasMore;
  final bool isFromCache;
}

class NewsFeedService {
  NewsFeedService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<NewsPage> loadPage({
    DocumentSnapshot<Map<String, dynamic>>? after,
    int pageSize = 12,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection('news')
        .orderBy('createdAt', descending: true)
        .limit(pageSize);

    if (after != null) {
      query = query.startAfterDocument(after);
    }

    late QuerySnapshot<Map<String, dynamic>> snapshot;
    Object? serverError;
    StackTrace? serverStackTrace;

    for (var attempt = 1; attempt <= 2; attempt++) {
      try {
        snapshot = await query.get().timeout(const Duration(seconds: 10));
        serverError = null;
        break;
      } catch (error, stackTrace) {
        serverError = error;
        serverStackTrace = stackTrace;
        final failure = AppFailure.from(error);
        final shouldRetry = attempt == 1 && failure.isTransient;
        if (!shouldRetry) break;

        AppLogger.event(
          'operation_retry',
          level: AppLogLevel.warning,
          context: {
            'operation': 'news.load_page',
            'attempt': attempt + 1,
            'code': failure.code,
          },
        );
        await Future<void>.delayed(const Duration(milliseconds: 350));
      }
    }

    if (serverError != null) {
      final serverFailure = AppFailure.from(serverError);
      try {
        snapshot = await query.get(const GetOptions(source: Source.cache));
      } catch (cacheError) {
        final cacheFailure = AppFailure.from(cacheError);
        AppLogger.event(
          'news_cache_failed',
          level: AppLogLevel.warning,
          context: {
            'serverCode': serverFailure.code,
            'cacheCode': cacheFailure.code,
          },
        );
        Error.throwWithStackTrace(serverError, serverStackTrace!);
      }

      AppLogger.event(
        'news_cache_fallback',
        level: AppLogLevel.warning,
        context: {
          'code': serverFailure.code,
          'documents': snapshot.docs.length,
        },
      );
    }

    return NewsPage(
      documents: snapshot.docs,
      cursor: snapshot.docs.isEmpty ? after : snapshot.docs.last,
      hasMore: snapshot.docs.length == pageSize,
      isFromCache: snapshot.metadata.isFromCache,
    );
  }
}
