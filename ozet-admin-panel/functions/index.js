const crypto = require('node:crypto');
const admin = require('firebase-admin');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { defineSecret } = require('firebase-functions/params');

admin.initializeApp();

const db = admin.firestore();
const REGION = 'europe-west1';
const MAX_ITEMS_PER_SOURCE = 10;
const GEMINI_MODEL = 'gemini-3.5-flash';
const GEMINI_API_KEY = defineSecret('GEMINI_API_KEY');
const FEED_CONTENT_TYPES = [
  'application/rss+xml',
  'application/atom+xml',
  'application/xml',
  'text/xml',
];

exports.importRssNow = onCall({ region: REGION, timeoutSeconds: 180, invoker: 'public' }, async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Admin oturumu gerekli.');
  }
  await assertAdmin(request.auth);

  return importActiveRssSources();
});

exports.importRssScheduled = onSchedule(
  { region: REGION, schedule: 'every 5 hours', timeoutSeconds: 300 },
  async () => importActiveRssSources(),
);

exports.summarizeNewsWithAi = onCall(
  { region: REGION, timeoutSeconds: 180, invoker: 'public', secrets: [GEMINI_API_KEY] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Admin oturumu gerekli.');
    }
    await assertAdmin(request.auth);

    const newsId = cleanText(request.data && request.data.newsId);
    if (!newsId) {
      throw new HttpsError('invalid-argument', 'Haber id bilgisi eksik.');
    }

    const newsRef = db.collection('news').doc(newsId);
    const newsDoc = await newsRef.get();
    if (!newsDoc.exists) {
      throw new HttpsError('not-found', 'Haber bulunamadi.');
    }

    const news = newsDoc.data();
    const sourceText = await buildAiSourceText(news);
    if (sourceText.length < 80) {
      throw new HttpsError('failed-precondition', 'AI ozeti icin yeterli kaynak metin bulunamadi.');
    }

    const summary = await summarizeWithGemini(news, sourceText);
    await newsRef.set(
      {
        title: summary.title,
        summary: summary.summary,
        detail: summary.detail,
        tags: summary.tags,
        aiGenerated: true,
        aiModel: GEMINI_MODEL,
        aiSummarizedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    return summary;
  },
);
async function assertAdmin(auth) {
  const email = cleanText(auth && auth.token && auth.token.email);
  if (!email) {
    throw new HttpsError('permission-denied', 'Admin e-postasi bulunamadi.');
  }

  let adminDoc = await db.collection('admins').doc(email).get();
  if (!adminDoc.exists && email !== email.toLowerCase()) {
    adminDoc = await db.collection('admins').doc(email.toLowerCase()).get();
  }
  if (!adminDoc.exists) {
    throw new HttpsError('permission-denied', 'Bu islem icin admin yetkisi gerekli.');
  }
}

async function buildAiSourceText(news) {
  const chunks = [
    cleanText(news.originalTitle),
    cleanText(news.title),
    cleanText(news.summary),
    cleanText(news.detail),
    cleanText(news.originalText),
  ];

  const sourceUrl = cleanText(news.sourceUrl);
  if (sourceUrl) {
    const page = await fetchText(sourceUrl).catch(() => null);
    if (page && !isFeedContentType(page.contentType)) {
      chunks.push(cleanHtmlArticleText(page.text));
    }
  }

  return summarize(chunks.filter(Boolean).join('\n\n'), 6000);
}

function cleanHtmlArticleText(html) {
  return stripMarkup(html)
    .replace(/\s+/g, ' ')
    .trim();
}

// AI ozetleme sadece backend'de calisir; API anahtari admin panel JS'ine yazilmaz.
async function summarizeWithGemini(news, sourceText) {
  const apiKey = cleanApiKey(GEMINI_API_KEY.value());
  if (!apiKey) {
    throw new HttpsError('failed-precondition', 'GEMINI_API_KEY secret tanimli degil.');
  }

  const prompt = [
    'Sen Ozet App icin Turkce haber editorusun.',
    'Kaynak metinde olmayan bilgi ekleme. Sade, dogrudan ve tarafsiz yaz.',
    'Reklam, kaynak dipnotu, RSS parametresi ve tekrar eden cumleleri temizle.',
    '',
    `Kaynak: ${cleanText(news.source, 'RSS')}`,
    `Kategori: ${cleanText(news.category, 'Gundem')}`,
    'Istenen JSON alani:',
    '- title: En fazla 90 karakterlik Turkce baslik.',
    '- summary: 1-2 cumle, en fazla 280 karakter.',
    '- detail: 2-4 kisa paragraf, en fazla 900 karakter.',
    '- tags: En fazla 5 kisa etiket.',
    '',
    'Kaynak metin:',
    sourceText,
  ].join('\n');

  const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent`, {
    method: 'POST',
    headers: {
      'x-goog-api-key': apiKey,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      contents: [
        {
          role: 'user',
          parts: [{ text: prompt }],
        },
      ],
      generationConfig: {
        temperature: 0.2,
        responseMimeType: 'application/json',
        responseSchema: newsSummarySchema(),
      },
    }),
  });

  const responseBody = await response.text();
  const payload = parseJson(responseBody);
  if (!response.ok) {
    const message = payload.error && payload.error.message
      ? payload.error.message
      : responseBody || `Gemini HTTP ${response.status}`;
    throw new HttpsError('internal', `AI ozeti alinamadi: ${message}`);
  }

  const text = extractGeminiResponseText(payload);
  const parsed = parseAiJson(text);
  return normalizeAiSummary(parsed);
}

function cleanApiKey(value) {
  return cleanText(value).replace(/^['"]+|['"]+$/g, '');
}

function parseJson(value) {
  try {
    return JSON.parse(value);
  } catch (_) {
    return {};
  }
}

function parseAiJson(text) {
  const cleaned = cleanText(text)
    .replace(/^```json\s*/i, '')
    .replace(/^```\s*/i, '')
    .replace(/\s*```$/i, '')
    .trim();
  try {
    return JSON.parse(cleaned);
  } catch (_) {
    throw new HttpsError('internal', `AI yaniti JSON formatinda degil: ${summarize(cleaned, 180)}`);
  }
}

function newsSummarySchema() {
  return {
    type: 'OBJECT',
    required: ['title', 'summary', 'detail', 'tags'],
    properties: {
      title: { type: 'STRING' },
      summary: { type: 'STRING' },
      detail: { type: 'STRING' },
      tags: {
        type: 'ARRAY',
        items: { type: 'STRING' },
      },
    },
  };
}

function normalizeAiSummary(parsed) {
  return {
    title: summarize(parsed.title, 90),
    summary: summarize(parsed.summary, 280),
    detail: summarize(parsed.detail, 900),
    tags: Array.isArray(parsed.tags) ? parsed.tags.map((tag) => summarize(tag, 32)).filter(Boolean).slice(0, 5) : [],
  };
}

function extractGeminiResponseText(payload) {
  if (typeof payload.output_text === 'string') return payload.output_text;

  const chunks = [];
  for (const candidate of payload.candidates || []) {
    const parts = candidate.content && Array.isArray(candidate.content.parts) ? candidate.content.parts : [];
    for (const part of parts) {
      if (typeof part.text === 'string') chunks.push(part.text);
    }
  }

  if (chunks.length === 0) {
    const candidate = Array.isArray(payload.candidates) ? payload.candidates[0] : null;
    const reason = candidate && candidate.finishReason ? candidate.finishReason : '';
    const promptReason = payload.promptFeedback && payload.promptFeedback.blockReason
      ? payload.promptFeedback.blockReason
      : '';
    const detail = reason || promptReason || summarize(JSON.stringify(payload), 220);
    throw new HttpsError('internal', `AI yaniti metin dondurmedi: ${detail}`);
  }
  return chunks.join('\n').trim();
}
async function importActiveRssSources() {
  const sourcesSnapshot = await db
    .collection('rss_sources')
    .where('active', '==', true)
    .get();

  let imported = 0;
  let skipped = 0;
  let failed = 0;
  const errors = [];

  for (const sourceDoc of sourcesSnapshot.docs) {
    const result = await importSource(sourceDoc).catch(async (error) => {
      const message = error.message || String(error);
      failed += 1;
      errors.push({
        sourceId: sourceDoc.id,
        source: cleanText(sourceDoc.data().name, 'RSS'),
        message,
      });
      await sourceDoc.ref.set(
        {
          lastError: message,
          lastFetchedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
      return null;
    });

    if (!result) continue;
    imported += result.imported;
    skipped += result.skipped;
  }

  return {
    sources: sourcesSnapshot.size,
    imported,
    skipped,
    failed,
    errors,
  };
}

async function importSource(sourceDoc) {
  const source = sourceDoc.data();
  const url = cleanText(source.url);
  if (!url) throw new Error('RSS URL bos.');

  const feed = await loadFeed(url);
  const items = parseFeed(feed.text).slice(0, MAX_ITEMS_PER_SOURCE);

  if (items.length === 0) {
    throw new Error('Bu kaynak RSS/Atom haberi dondurmedi. Normal sayfa linki yerine gercek RSS linki gir.');
  }

  let imported = 0;
  let skipped = 0;
  const batch = db.batch();

  for (const item of items) {
    const sourceUrl = cleanText(item.link);
    const title = cleanText(item.title);
    if (!sourceUrl || !title) {
      skipped += 1;
      continue;
    }

    const itemId = stableId(`${sourceDoc.id}|${sourceUrl}|${item.guid || title}`);
    const newsRef = db.collection('news').doc(`rss_${itemId}`);
    const existing = await newsRef.get();
    if (existing.exists) {
      skipped += 1;
      continue;
    }

    const summary = summarize(item.description || item.content || title, 320);
    const detail = summarize(item.content || item.description || title, 1200);

    batch.set(newsRef, {
      title,
      summary,
      detail,
      source: cleanText(source.name, 'RSS'),
      sourceUrl,
      rssSource: sourceDoc.id,
      category: cleanText(source.defaultCategory, 'Gundem'),
      tags: [],
      published: false,
      status: 'draft',
      aiGenerated: false,
      originalTitle: title,
      originalText: item.description || item.content || '',
      rssItemId: item.guid || sourceUrl,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      importedAt: admin.firestore.FieldValue.serverTimestamp(),
      publishedAt: null,
    });
    imported += 1;
  }

  batch.set(
    sourceDoc.ref,
    {
      lastFetchedAt: admin.firestore.FieldValue.serverTimestamp(),
      lastError: '',
      resolvedFeedUrl: feed.url,
    },
    { merge: true },
  );

  await batch.commit();
  return { imported, skipped };
}

async function fetchText(url) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 15000);

  try {
    const response = await fetch(url, {
      signal: controller.signal,
      headers: {
        'User-Agent': 'OzetAppRSSImporter/1.0',
        Accept: 'application/rss+xml, application/atom+xml, application/xml, text/xml, */*',
      },
    });

    if (!response.ok) {
      throw new Error(`RSS alinamadi: HTTP ${response.status}`);
    }

    return {
      text: await response.text(),
      url: response.url || url,
      contentType: response.headers.get('content-type') || '',
    };
  } finally {
    clearTimeout(timeout);
  }
}

async function loadFeed(url) {
  const firstResponse = await fetchText(url);
  let items = parseFeed(firstResponse.text);
  if (items.length > 0 || isFeedContentType(firstResponse.contentType)) {
    return firstResponse;
  }

  // Admin normal haber/kategori sayfasi eklerse HTML icindeki RSS/Atom
  // alternate linklerini bulup ilk calisan feed'i deneriz.
  const candidates = discoverFeedUrls(firstResponse.text, firstResponse.url);
  for (const candidate of candidates) {
    const candidateResponse = await fetchText(candidate).catch(() => null);
    if (!candidateResponse) continue;

    items = parseFeed(candidateResponse.text);
    if (items.length > 0) return candidateResponse;
  }

  throw new Error('Kaynak RSS/Atom degil ve sayfa icinde feed linki bulunamadi.');
}

function isFeedContentType(contentType) {
  const normalized = contentType.toLowerCase();
  return FEED_CONTENT_TYPES.some((type) => normalized.includes(type));
}

function discoverFeedUrls(html, baseUrl) {
  const candidates = new Set();
  const linkTags = html.match(/<link\b[^>]*>/gi) || [];

  for (const tag of linkTags) {
    const rel = attr(tag, 'rel').toLowerCase();
    const type = attr(tag, 'type').toLowerCase();
    const href = attr(tag, 'href');
    const looksLikeFeed =
      rel.includes('alternate') &&
      (type.includes('rss') || type.includes('atom') || type.includes('xml'));

    if (href && looksLikeFeed) {
      candidates.add(resolveUrl(href, baseUrl));
    }
  }

  const anchorPattern = /<a\b[^>]*href=["']([^"']+)["'][^>]*>/gi;
  for (const match of html.matchAll(anchorPattern)) {
    const href = match[1];
    if (/(\brss\b|\batom\b|\/feed\b|\.xml\b)/i.test(href)) {
      candidates.add(resolveUrl(href, baseUrl));
    }
  }

  return [...candidates].filter(Boolean);
}

function attr(tag, name) {
  const pattern = new RegExp(`${name}=["']([^"']+)["']`, 'i');
  const match = tag.match(pattern);
  return match ? decodeXml(match[1]).trim() : '';
}

function resolveUrl(value, baseUrl) {
  try {
    return new URL(value, baseUrl).toString();
  } catch (_) {
    return '';
  }
}

function parseFeed(xml) {
  const rssItems = blocks(xml, 'item').map(parseRssItem);
  if (rssItems.length > 0) return rssItems;
  return blocks(xml, 'entry').map(parseAtomEntry);
}

function parseRssItem(xml) {
  return {
    title: textTag(xml, 'title'),
    link: textTag(xml, 'link'),
    guid: textTag(xml, 'guid'),
    description: textTag(xml, 'description'),
    content: textTag(xml, 'content:encoded') || textTag(xml, 'encoded'),
    publishedAt: textTag(xml, 'pubDate'),
  };
}

function parseAtomEntry(xml) {
  return {
    title: textTag(xml, 'title'),
    link: atomLink(xml),
    guid: textTag(xml, 'id'),
    description: textTag(xml, 'summary'),
    content: textTag(xml, 'content'),
    publishedAt: textTag(xml, 'published') || textTag(xml, 'updated'),
  };
}

function blocks(xml, tag) {
  const pattern = new RegExp(`<${escapeRegExp(tag)}\\b[^>]*>([\\s\\S]*?)<\\/${escapeRegExp(tag)}>`, 'gi');
  return [...xml.matchAll(pattern)].map((match) => match[1]);
}

function textTag(xml, tag) {
  const pattern = new RegExp(`<${escapeRegExp(tag)}\\b[^>]*>([\\s\\S]*?)<\\/${escapeRegExp(tag)}>`, 'i');
  const match = xml.match(pattern);
  return match ? decodeXml(stripMarkup(stripCdata(match[1]))).trim() : '';
}

function atomLink(xml) {
  const hrefMatch = xml.match(/<link\b[^>]*href=["']([^"']+)["'][^>]*>/i);
  return hrefMatch ? decodeXml(hrefMatch[1]).trim() : textTag(xml, 'link');
}

function stripCdata(value) {
  return value.replace(/<!\[CDATA\[([\s\S]*?)\]\]>/g, '$1');
}

function stripMarkup(value) {
  return value
    .replace(/<script\b[\s\S]*?<\/script>/gi, ' ')
    .replace(/<style\b[\s\S]*?<\/style>/gi, ' ')
    .replace(/<[^>]+>/g, ' ')
    .replace(/\s+/g, ' ');
}

function decodeXml(value) {
  return value
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&#(\d+);/g, (_, code) => String.fromCharCode(Number(code)));
}

function summarize(value, maxLength) {
  const text = cleanText(stripMarkup(stripCdata(value)));
  if (text.length <= maxLength) return text;
  return `${text.slice(0, maxLength - 3).trim()}...`;
}

function cleanText(value, fallback = '') {
  const text = typeof value === 'string' ? value.trim() : '';
  return text || fallback;
}

function stableId(value) {
  return crypto.createHash('sha256').update(value).digest('hex').slice(0, 32);
}

function escapeRegExp(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}