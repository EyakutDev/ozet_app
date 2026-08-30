import 'package:cloud_firestore/cloud_firestore.dart';

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

    QuerySnapshot<Map<String, dynamic>> snapshot;
    try {
      snapshot = await query.get();
    } catch (serverError) {
      try {
        snapshot = await query.get(const GetOptions(source: Source.cache));
      } catch (_) {
        Error.throwWithStackTrace(serverError, StackTrace.current);
      }
    }

    return NewsPage(
      documents: snapshot.docs,
      cursor: snapshot.docs.isEmpty ? after : snapshot.docs.last,
      hasMore: snapshot.docs.length == pageSize,
      isFromCache: snapshot.metadata.isFromCache,
    );
  }
}
