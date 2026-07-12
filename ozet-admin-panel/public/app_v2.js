// Firebase Config
const firebaseConfig = {
    apiKey: "AIzaSyBmEbkdQVV75t6Y2Isdf7oF8al9uVUAeHw",
    authDomain: "ozet-d09a3.firebaseapp.com",
    projectId: "ozet-d09a3",
    storageBucket: "ozet-d09a3.firebasestorage.app",
    messagingSenderId: "736183634189",
    appId: "1:736183634189:web:99aebfe2b7200942fe0844"
};

firebase.initializeApp(firebaseConfig);
const auth = firebase.auth();
const db = firebase.firestore();
const functions = firebase.app().functions('europe-west1');
const newsCollection = db.collection('news');
const legacyDraftNewsCollection = db.collection('draft_news');
const rssSourcesCollection = db.collection('rss_sources');
const financeDocRef = db.collection('live_data').doc('finance');

window.addEventListener('load', () => {
    const loginContainer = document.getElementById('login-container');
    const adminContainer = document.getElementById('admin-container');

    const emailInput = document.getElementById('email');
    const passwordInput = document.getElementById('password');
    const loginBtn = document.getElementById('login-btn');
    const logoutBtn = document.getElementById('logout-btn');
    const loginError = document.getElementById('login-error');

    const dolarPriceInput = document.getElementById('dolar-price');
    const altinPriceInput = document.getElementById('altin-price');
    const updateFinanceBtn = document.getElementById('update-finance-btn');

    const titleInput = document.getElementById('news-title');
    const summaryInput = document.getElementById('news-summary');
    const detailInput = document.getElementById('news-detail');
    const sourceInput = document.getElementById('news-source');
    const sourceUrlInput = document.getElementById('news-source-url');
    const categoryInput = document.getElementById('news-category');
    const addDraftBtn = document.getElementById('add-draft-btn');
    const publishSuccess = document.getElementById('publish-success');
    const draftListContainer = document.getElementById('draft-list-container');
    const draftCount = document.getElementById('draft-count');
    const publishAllBtn = document.getElementById('publish-all-btn');
    const draftBulkToolbar = document.getElementById('draft-bulk-toolbar');
    const selectedDraftCount = document.getElementById('selected-draft-count');
    const selectVisibleDraftsBtn = document.getElementById('select-visible-drafts-btn');
    const clearDraftSelectionBtn = document.getElementById('clear-draft-selection-btn');
    const publishSelectedDraftsBtn = document.getElementById('publish-selected-drafts-btn');
    const deleteSelectedDraftsBtn = document.getElementById('delete-selected-drafts-btn');

    const rssNameInput = document.getElementById('rss-name');
    const rssUrlInput = document.getElementById('rss-url');
    const rssCategoryInput = document.getElementById('rss-category');
    const addRssSourceBtn = document.getElementById('add-rss-source-btn');
    const fetchRssNowBtn = document.getElementById('fetch-rss-now-btn');
    const rssSuccess = document.getElementById('rss-success');
    const rssSourceListContainer = document.getElementById('rss-source-list-container');

    const liveListContainer = document.getElementById('live-list-container');
    const liveCount = document.getElementById('live-count');
    const liveBulkToolbar = document.getElementById('live-bulk-toolbar');
    const selectedLiveCount = document.getElementById('selected-live-count');
    const selectVisibleLiveBtn = document.getElementById('select-visible-live-btn');
    const clearLiveSelectionBtn = document.getElementById('clear-live-selection-btn');
    const unpublishSelectedLiveBtn = document.getElementById('unpublish-selected-live-btn');
    const deleteSelectedLiveBtn = document.getElementById('delete-selected-live-btn');
    const liveSuccess = document.getElementById('live-success');

    const statLiveCount = document.getElementById('stat-live-count');
    const statDraftCount = document.getElementById('stat-draft-count');
    const statAiCount = document.getElementById('stat-ai-count');
    const statRssActive = document.getElementById('stat-rss-active');
    const statTodayPublished = document.getElementById('stat-today-published');
    const statRssError = document.getElementById('stat-rss-error');
    const refreshAdminBtn = document.getElementById('refresh-admin-btn');
    const lastRefreshLabel = document.getElementById('last-refresh-label');

    const notifTitleInput = document.getElementById('notif-title');
    const notifBodyInput = document.getElementById('notif-body');
    const sendNotifBtn = document.getElementById('send-notif-btn');
    const notifSuccess = document.getElementById('notif-success');
    const selectedDrafts = new Map();
    const selectedLiveNews = new Map();
    let visibleDrafts = [];
    let visibleLiveNews = [];

    document.querySelectorAll('.nav-link').forEach((link) => {
        link.addEventListener('click', () => {
            document.querySelectorAll('.nav-link').forEach((item) => item.classList.remove('active'));
            link.classList.add('active');
        });
    });

    if (loginBtn) {
        loginBtn.addEventListener('click', () => {
            auth.signInWithEmailAndPassword(emailInput.value, passwordInput.value)
                .catch((error) => {
                    if (loginError) loginError.textContent = 'Hata: ' + error.message;
                });
        });
    }

    if (logoutBtn) {
        logoutBtn.addEventListener('click', () => auth.signOut());
    }

    auth.onAuthStateChanged((user) => {
        if (user) {
            if (loginContainer) loginContainer.style.display = 'none';
            if (adminContainer) adminContainer.style.display = 'block';
            refreshAdminData();
        } else {
            if (loginContainer) loginContainer.style.display = 'block';
            if (adminContainer) adminContainer.style.display = 'none';
        }
    });

    async function refreshAdminData() {
        if (refreshAdminBtn) {
            refreshAdminBtn.disabled = true;
            refreshAdminBtn.textContent = 'Yenileniyor';
        }

        await Promise.allSettled([
            loadCurrentFinanceData(),
            loadDraftNews(),
            loadLiveNews(),
            loadRssSources()
        ]);

        if (lastRefreshLabel) {
            lastRefreshLabel.textContent = 'Son yenileme ' + new Date().toLocaleTimeString('tr-TR', {
                hour: '2-digit',
                minute: '2-digit'
            });
        }
        if (refreshAdminBtn) {
            refreshAdminBtn.disabled = false;
            refreshAdminBtn.textContent = 'Yenile';
        }
    }

    if (refreshAdminBtn) {
        refreshAdminBtn.addEventListener('click', refreshAdminData);
    }

    function cleanText(value, fallback = '') {
        const text = typeof value === 'string' ? value.trim() : '';
        return text || fallback;
    }

    function showTemporaryMessage(element, message) {
        if (!element) return;
        element.textContent = message;
        setTimeout(() => { element.textContent = ''; }, 3000);
    }
    function draftSelectionKey(docId, legacy) {
        return `${legacy ? 'legacy' : 'news'}:${docId}`;
    }

    function setDraftSelection(docId, data, legacy, checked) {
        const key = draftSelectionKey(docId, legacy);
        if (checked) {
            selectedDrafts.set(key, { docId, data, legacy });
        } else {
            selectedDrafts.delete(key);
        }
        updateDraftBulkToolbar();
    }

    function syncSelectedDraftsWithVisible(drafts) {
        visibleDrafts = drafts;
        const visibleKeys = new Set();
        drafts.forEach(({ doc, data, legacy }) => {
            const key = draftSelectionKey(doc.id, legacy);
            visibleKeys.add(key);
            if (selectedDrafts.has(key)) selectedDrafts.set(key, { docId: doc.id, data, legacy });
        });
        for (const key of selectedDrafts.keys()) {
            if (!visibleKeys.has(key)) selectedDrafts.delete(key);
        }
        updateDraftBulkToolbar();
    }

    function updateDraftBulkToolbar() {
        const count = selectedDrafts.size;
        if (selectedDraftCount) selectedDraftCount.textContent = `${count} secili`;
        if (draftBulkToolbar) draftBulkToolbar.classList.toggle('has-selection', count > 0);
        if (publishSelectedDraftsBtn) publishSelectedDraftsBtn.disabled = count === 0;
        if (deleteSelectedDraftsBtn) deleteSelectedDraftsBtn.disabled = count === 0;
        if (clearDraftSelectionBtn) clearDraftSelectionBtn.disabled = count === 0;
    }

    function selectedDraftList() {
        return Array.from(selectedDrafts.values());
    }

    function setLiveSelection(docId, data, checked) {
        if (checked) {
            selectedLiveNews.set(docId, { docId, data });
        } else {
            selectedLiveNews.delete(docId);
        }
        updateLiveBulkToolbar();
    }

    function syncSelectedLiveNews(liveDocs) {
        visibleLiveNews = liveDocs;
        const visibleIds = new Set(liveDocs.map(({ doc }) => doc.id));

        for (const docId of selectedLiveNews.keys()) {
            if (!visibleIds.has(docId)) selectedLiveNews.delete(docId);
        }

        liveDocs.forEach(({ doc, data }) => {
            if (selectedLiveNews.has(doc.id)) selectedLiveNews.set(doc.id, { docId: doc.id, data });
        });
        updateLiveBulkToolbar();
    }

    function updateLiveBulkToolbar() {
        const count = selectedLiveNews.size;
        if (selectedLiveCount) selectedLiveCount.textContent = count + ' secili';
        if (liveBulkToolbar) liveBulkToolbar.classList.toggle('has-selection', count > 0);
        if (clearLiveSelectionBtn) clearLiveSelectionBtn.disabled = count === 0;
        if (unpublishSelectedLiveBtn) unpublishSelectedLiveBtn.disabled = count === 0;
        if (deleteSelectedLiveBtn) deleteSelectedLiveBtn.disabled = count === 0;
    }

    function isDraftNews(data) {
        const status = cleanText(data.status).toLowerCase();
        return data.published === false || status === 'draft' || status === 'reviewed';
    }

    function isLiveNews(data) {
        const status = cleanText(data.status).toLowerCase();
        return data.published === true || status === 'published' || (!status && data.published !== false);
    }

    function newsSortValue(data) {
        const date = data.publishedAt || data.createdAt;
        return date && typeof date.toMillis === 'function' ? date.toMillis() : 0;
    }

    function isRssNews(data) {
        return Boolean(cleanText(data.rssSource) || cleanText(data.rssItemId));
    }

    function escapeHtml(value) {
        return cleanText(value)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#39;');
    }

    function safeUrl(value) {
        const url = cleanText(value);
        return /^https?:\/\//i.test(url) ? url : '';
    }

    function previewText(value, maxLength = 140) {
        const text = cleanText(value).replace(/\s+/g, ' ');
        if (text.length <= maxLength) return text;
        return text.slice(0, maxLength - 3).trim() + '...';
    }

    async function loadCurrentFinanceData() {
        if (!dolarPriceInput) return;
        try {
            const doc = await financeDocRef.get();
            if (doc.exists) {
                const data = doc.data();
                dolarPriceInput.value = data.dolar || '';
                altinPriceInput.value = data.altin || '';
            }
        } catch (e) {
            console.error(e);
        }
    }

    if (updateFinanceBtn) {
        updateFinanceBtn.addEventListener('click', async () => {
            const dolar = dolarPriceInput.value;
            const altin = altinPriceInput.value;
            if (!dolar || !altin) {
                alert('Dolar ve Altın zorunlu!');
                return;
            }

            try {
                await financeDocRef.set({
                    dolar: parseFloat(dolar),
                    altin: parseFloat(altin),
                    lastUpdated: firebase.firestore.FieldValue.serverTimestamp()
                });
                alert('Finans güncellendi!');
            } catch (e) {
                alert('Hata: ' + e.message);
            }
        });
    }

    if (sendNotifBtn) {
        sendNotifBtn.addEventListener('click', async () => {
            const title = cleanText(notifTitleInput.value);
            const body = cleanText(notifBodyInput.value);

            if (!title || !body) {
                alert('Başlık ve mesaj boş olamaz!');
                return;
            }
            if (!confirm('Tüm kullanıcılara bildirim gidecek. Emin misin?')) return;

            const serverKey = "AIzaSyBcA32H_ytMwdX1qCfxN5eIBw7v86KKkiY";

            try {
                const response = await fetch('https://fcm.googleapis.com/fcm/send', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json', 'Authorization': 'key=' + serverKey },
                    body: JSON.stringify({
                        to: '/topics/all',
                        notification: { title, body, sound: 'default' }
                    })
                });

                if (!response.ok) {
                    const errorData = await response.json();
                    alert('Hata: ' + JSON.stringify(errorData));
                    return;
                }

                showTemporaryMessage(notifSuccess, 'Bildirim gönderildi!');
            } catch (e) {
                alert('Gönderim hatası: ' + e.message);
            }
        });
    }

    if (addDraftBtn) {
        addDraftBtn.addEventListener('click', async () => {
            const title = cleanText(titleInput.value);
            const summary = cleanText(summaryInput.value);
            const detail = cleanText(detailInput ? detailInput.value : '', summary);
            const source = cleanText(sourceInput ? sourceInput.value : '', 'Özet App');
            const sourceUrl = cleanText(sourceUrlInput ? sourceUrlInput.value : '');
            const category = cleanText(categoryInput ? categoryInput.value : '', 'Gündem');

            if (!title || !summary) {
                alert('Başlık ve özet zorunlu!');
                return;
            }

            try {
                await newsCollection.add({
                    title,
                    summary,
                    detail,
                    source,
                    sourceUrl,
                    category,
                    tags: [],
                    published: false,
                    status: 'draft',
                    aiGenerated: false,
                    manual: true,
                    originalTitle: title,
                    originalText: detail,
                    createdAt: firebase.firestore.FieldValue.serverTimestamp()
                });

                showTemporaryMessage(publishSuccess, 'Taslak eklendi!');
                titleInput.value = '';
                summaryInput.value = '';
                if (detailInput) detailInput.value = '';
                if (sourceInput) sourceInput.value = '';
                if (sourceUrlInput) sourceUrlInput.value = '';
                if (categoryInput) categoryInput.value = '';
                loadDraftNews();
            } catch (e) {
                alert('Hata: ' + e.message);
            }
        });
    }

    async function loadDraftNews() {
        if (!draftListContainer) return;
        draftListContainer.innerHTML = 'Yükleniyor...';

        const [newsSnapshot, legacySnapshot] = await Promise.all([
            newsCollection.orderBy('createdAt', 'desc').get(),
            legacyDraftNewsCollection.orderBy('createdAt', 'desc').get().catch(() => ({ docs: [] }))
        ]);

        const draftDocs = newsSnapshot.docs
            .filter((doc) => isDraftNews(doc.data()))
            .map((doc) => ({ doc, data: doc.data(), legacy: false }));

        const legacyDraftDocs = legacySnapshot.docs
            .map((doc) => ({ doc, data: doc.data(), legacy: true }));

        const allDrafts = [...draftDocs, ...legacyDraftDocs]
            .sort((a, b) => newsSortValue(b.data) - newsSortValue(a.data));

        draftListContainer.innerHTML = '';
        if (draftCount) draftCount.textContent = allDrafts.length;
        if (statDraftCount) statDraftCount.textContent = allDrafts.length;
        if (statAiCount) {
            statAiCount.textContent = newsSnapshot.docs.filter((doc) => doc.data().aiGenerated === true).length;
        }
        syncSelectedDraftsWithVisible(allDrafts);

        if (allDrafts.length === 0) {
            draftListContainer.innerHTML = '<p class="empty-state">Onay bekleyen haber yok.</p>';
            return;
        }

        allDrafts.forEach(({ doc, data, legacy }) => {
            draftListContainer.appendChild(createNewsItem({
                docId: doc.id,
                data,
                legacy,
                mode: 'draft'
            }));
        });
    }

    function createNewsItem({ docId, data, legacy, mode }) {
        const item = document.createElement('div');
        const rssNews = isRssNews(data);
        item.className = `draft-item news-admin-item ${rssNews ? 'rss-news-item' : 'manual-news-item'}`;

        if (mode === 'draft' || mode === 'live') {
            const selectWrap = document.createElement('label');
            selectWrap.className = 'item-select-wrap';
            selectWrap.title = 'Toplu islem icin sec';

            const selectInput = document.createElement('input');
            selectInput.type = 'checkbox';

            if (mode === 'draft') {
                selectInput.checked = selectedDrafts.has(draftSelectionKey(docId, legacy));
                selectInput.addEventListener('change', () => {
                    setDraftSelection(docId, data, legacy, selectInput.checked);
                });
            } else {
                selectInput.checked = selectedLiveNews.has(docId);
                selectInput.addEventListener('change', () => {
                    setLiveSelection(docId, data, selectInput.checked);
                });
            }

            selectWrap.appendChild(selectInput);
            item.appendChild(selectWrap);
        }

        const content = document.createElement('div');
        content.className = 'item-content';
        const statusLabel = legacy ? 'Eski taslak' : cleanText(data.status, mode === 'live' ? 'published' : 'draft');
        const originLabel = legacy ? 'Eski' : rssNews ? 'RSS' : 'Manuel';
        const originClass = legacy ? 'origin-legacy' : rssNews ? 'origin-rss' : 'origin-manual';
        const sourceUrl = safeUrl(data.sourceUrl);
        const title = cleanText(data.title, 'Basliksiz');
        const summary = cleanText(data.summary || data.detail || data.originalText);
        const detail = cleanText(data.detail || data.summary || data.originalText);
        const summaryPreview = previewText(summary);
        const hasReadableText = Boolean(summary || detail);

        content.innerHTML = `
            <span class="item-topline">
                <span class="origin-badge ${originClass}">${originLabel}</span>
                ${data.aiGenerated ? '<span class="origin-badge origin-ai">AI</span>' : ''}
                <span class="item-status">${escapeHtml(statusLabel)}</span>
            </span>
            <strong>${escapeHtml(title)}</strong>
            <span class="item-meta">${escapeHtml(data.category || 'Genel')} &middot; ${escapeHtml(data.source || 'Ozet App')}</span>
            ${summaryPreview ? `<span class="item-summary">${escapeHtml(summaryPreview)}</span>` : ''}
            <span class="item-inline-actions">
                ${hasReadableText ? '<button class="item-text-action" type="button">Ozeti Gor</button>' : ''}
                ${sourceUrl ? `<a class="item-link" href="${escapeHtml(sourceUrl)}" target="_blank" rel="noopener noreferrer">Kaynagi ac</a>` : ''}
            </span>
            ${hasReadableText ? `
                <div class="item-detail-panel" hidden>
                    ${summary ? `<span class="detail-label">Kisa ozet</span><p>${escapeHtml(summary)}</p>` : ''}
                    ${detail && detail !== summary ? `<span class="detail-label">Detay</span><p>${escapeHtml(detail)}</p>` : ''}
                </div>
            ` : ''}
        `;

        const detailToggle = content.querySelector('.item-text-action');
        const detailPanel = content.querySelector('.item-detail-panel');
        if (detailToggle && detailPanel) {
            detailToggle.addEventListener('click', () => {
                const nextHidden = !detailPanel.hidden;
                detailPanel.hidden = nextHidden;
                detailToggle.textContent = nextHidden ? 'Ozeti Gor' : 'Gizle';
            });
        }

        const actions = document.createElement('div');
        actions.className = 'item-actions';

        if (mode === 'draft' && !legacy) {
            const aiBtn = document.createElement('button');
            aiBtn.className = 'small-action ai-action';
            aiBtn.textContent = data.aiGenerated ? 'AI Yenile' : 'AI Ozetle';
            aiBtn.addEventListener('click', () => summarizeDraftWithAi(docId, aiBtn));
            actions.appendChild(aiBtn);
        }
        if (mode === 'draft') {
            const publishBtn = document.createElement('button');
            publishBtn.className = 'small-action publish-action';
            publishBtn.textContent = 'Yayinla';
            publishBtn.addEventListener('click', () => publishDraft(docId, data, legacy));
            actions.appendChild(publishBtn);
        }

        const removeBtn = document.createElement('button');
        removeBtn.className = 'small-action delete-btn';
        removeBtn.textContent = mode === 'live' ? 'Kaldir' : 'Sil';
        removeBtn.addEventListener('click', () => {
            if (mode === 'live') {
                unpublishNews(docId);
            } else {
                deleteDraft(docId, legacy);
            }
        });
        actions.appendChild(removeBtn);

        item.appendChild(content);
        item.appendChild(actions);
        return item;
    }

    async function summarizeDraftWithAi(docId, button) {
        if (!confirm('Bu taslak AI ile ozetlensin mi? Mevcut baslik, ozet ve detay guncellenecek.')) return;

        const oldText = button.textContent;
        button.disabled = true;
        button.textContent = 'AI...';

        try {
            const summarizeNewsWithAi = functions.httpsCallable('summarizeNewsWithAi');
            await summarizeNewsWithAi({ newsId: docId });
            showTemporaryMessage(publishSuccess, 'AI ozeti hazirlandi.');
            loadDraftNews();
        } catch (e) {
            alert('AI ozetleme basarisiz: ' + e.message);
        } finally {
            button.disabled = false;
            button.textContent = oldText;
        }
    }

    async function publishDraft(docId, data, legacy = false) {
        if (!confirm('Bu haber canlıya alınsın mı?')) return;

        const publishedData = {
            ...data,
            published: true,
            status: 'published',
            publishedAt: firebase.firestore.FieldValue.serverTimestamp()
        };

        if (legacy) {
            await newsCollection.add(publishedData);
            await legacyDraftNewsCollection.doc(docId).delete();
        } else {
            await newsCollection.doc(docId).set(publishedData, { merge: true });
        }

        loadDraftNews();
        loadLiveNews();
    }

    async function deleteDraft(docId, legacy = false) {
        if (!confirm('Taslak silinsin mi?')) return;
        if (legacy) {
            await legacyDraftNewsCollection.doc(docId).delete();
        } else {
            await newsCollection.doc(docId).delete();
        }
        loadDraftNews();
    }
    async function publishSelectedDrafts() {
        const selected = selectedDraftList();
        if (selected.length === 0) return;
        if (!confirm(`${selected.length} taslak canliya alinsin mi?`)) return;

        const batch = db.batch();
        selected.forEach(({ docId, data, legacy }) => {
            const publishedData = {
                ...data,
                published: true,
                status: 'published',
                publishedAt: firebase.firestore.FieldValue.serverTimestamp()
            };

            if (legacy) {
                batch.set(newsCollection.doc(), publishedData);
                batch.delete(legacyDraftNewsCollection.doc(docId));
            } else {
                batch.set(newsCollection.doc(docId), publishedData, { merge: true });
            }
        });

        await batch.commit();
        selectedDrafts.clear();
        showTemporaryMessage(publishSuccess, `${selected.length} taslak yayinlandi.`);
        loadDraftNews();
        loadLiveNews();
    }

    async function deleteSelectedDrafts() {
        const selected = selectedDraftList();
        if (selected.length === 0) return;
        if (!confirm(`${selected.length} taslak kalici olarak silinsin mi?`)) return;

        const batch = db.batch();
        selected.forEach(({ docId, legacy }) => {
            const ref = legacy ? legacyDraftNewsCollection.doc(docId) : newsCollection.doc(docId);
            batch.delete(ref);
        });

        await batch.commit();
        selectedDrafts.clear();
        showTemporaryMessage(publishSuccess, `${selected.length} taslak silindi.`);
        loadDraftNews();
    }

    if (selectVisibleDraftsBtn) {
        selectVisibleDraftsBtn.addEventListener('click', () => {
            visibleDrafts.forEach(({ doc, data, legacy }) => {
                selectedDrafts.set(draftSelectionKey(doc.id, legacy), { docId: doc.id, data, legacy });
            });
            loadDraftNews();
        });
    }

    if (clearDraftSelectionBtn) {
        clearDraftSelectionBtn.addEventListener('click', () => {
            selectedDrafts.clear();
            loadDraftNews();
        });
    }

    if (publishSelectedDraftsBtn) {
        publishSelectedDraftsBtn.addEventListener('click', publishSelectedDrafts);
    }

    if (deleteSelectedDraftsBtn) {
        deleteSelectedDraftsBtn.addEventListener('click', deleteSelectedDrafts);
    }

    if (publishAllBtn) {
        publishAllBtn.addEventListener('click', async () => {
            if (!confirm('Tüm taslaklar canlıya alınacak. Emin misin?')) return;

            const [newsSnapshot, legacySnapshot] = await Promise.all([
                newsCollection.get(),
                legacyDraftNewsCollection.get().catch(() => ({ docs: [] }))
            ]);

            const draftDocs = newsSnapshot.docs.filter((doc) => isDraftNews(doc.data()));
            if (draftDocs.length === 0 && legacySnapshot.docs.length === 0) {
                alert('Taslak yok!');
                return;
            }

            const batch = db.batch();
            draftDocs.forEach((doc) => {
                batch.set(doc.ref, {
                    published: true,
                    status: 'published',
                    publishedAt: firebase.firestore.FieldValue.serverTimestamp()
                }, { merge: true });
            });
            legacySnapshot.docs.forEach((doc) => {
                const newLiveRef = newsCollection.doc();
                batch.set(newLiveRef, {
                    ...doc.data(),
                    published: true,
                    status: 'published',
                    publishedAt: firebase.firestore.FieldValue.serverTimestamp()
                });
                batch.delete(doc.ref);
            });

            await batch.commit();
            alert('Yayınlandı!');
            loadDraftNews();
            loadLiveNews();
        });
    }

    async function unpublishNews(docId) {
        if (!confirm('Haber yayından kaldırılsın mı?')) return;
        await newsCollection.doc(docId).set({
            published: false,
            status: 'rejected',
            unpublishedAt: firebase.firestore.FieldValue.serverTimestamp()
        }, { merge: true });
        loadLiveNews();
        loadDraftNews();
    }

    async function unpublishSelectedLiveNews() {
        const selected = Array.from(selectedLiveNews.values());
        if (selected.length === 0) return;
        if (!confirm(selected.length + ' canli haber yayindan kaldirilsin mi? Haberler taslak listesine gececek.')) return;

        try {
            const batch = db.batch();
            selected.forEach(({ docId }) => {
                batch.set(newsCollection.doc(docId), {
                    published: false,
                    status: 'rejected',
                    unpublishedAt: firebase.firestore.FieldValue.serverTimestamp()
                }, { merge: true });
            });

            await batch.commit();
            selectedLiveNews.clear();
            showTemporaryMessage(liveSuccess, selected.length + ' haber yayindan kaldirildi.');
            await Promise.all([loadLiveNews(), loadDraftNews()]);
        } catch (e) {
            alert('Haberler yayindan kaldirilamadi: ' + e.message);
        }
    }

    async function deleteSelectedLiveNews() {
        const selected = Array.from(selectedLiveNews.values());
        if (selected.length === 0) return;
        if (!confirm(selected.length + ' canli haber KALICI olarak silinecek. Bu islem geri alinamaz. Devam edilsin mi?')) return;

        try {
            const batch = db.batch();
            selected.forEach(({ docId }) => batch.delete(newsCollection.doc(docId)));
            await batch.commit();

            selectedLiveNews.clear();
            showTemporaryMessage(liveSuccess, selected.length + ' canli haber kalici olarak silindi.');
            await loadLiveNews();
        } catch (e) {
            alert('Canli haberler silinemedi: ' + e.message);
        }
    }

    if (selectVisibleLiveBtn) {
        selectVisibleLiveBtn.addEventListener('click', () => {
            visibleLiveNews.forEach(({ doc, data }) => {
                selectedLiveNews.set(doc.id, { docId: doc.id, data });
            });
            loadLiveNews();
        });
    }

    if (clearLiveSelectionBtn) {
        clearLiveSelectionBtn.addEventListener('click', () => {
            selectedLiveNews.clear();
            loadLiveNews();
        });
    }

    if (unpublishSelectedLiveBtn) {
        unpublishSelectedLiveBtn.addEventListener('click', unpublishSelectedLiveNews);
    }

    if (deleteSelectedLiveBtn) {
        deleteSelectedLiveBtn.addEventListener('click', deleteSelectedLiveNews);
    }

    async function loadLiveNews() {
        if (!liveListContainer) return;
        liveListContainer.innerHTML = 'Yükleniyor...';
        const snapshot = await newsCollection.orderBy('createdAt', 'desc').get();
        const liveDocs = snapshot.docs
            .filter((doc) => isLiveNews(doc.data()))
            .map((doc) => ({ doc, data: doc.data() }))
            .sort((a, b) => newsSortValue(b.data) - newsSortValue(a.data));

        liveListContainer.innerHTML = '';
        if (liveCount) liveCount.textContent = liveDocs.length;
        if (statLiveCount) statLiveCount.textContent = liveDocs.length;
        if (statTodayPublished) {
            const now = new Date();
            const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime();
            statTodayPublished.textContent = liveDocs.filter(({ data }) => {
                const date = data.publishedAt;
                return date && typeof date.toMillis === 'function' && date.toMillis() >= startOfToday;
            }).length;
        }
        syncSelectedLiveNews(liveDocs);

        if (liveDocs.length === 0) {
            liveListContainer.innerHTML = '<p class="empty-state">Canlı haber yok.</p>';
            return;
        }

        liveDocs.forEach(({ doc, data }) => {
            liveListContainer.appendChild(createNewsItem({
                docId: doc.id,
                data,
                legacy: false,
                mode: 'live'
            }));
        });
    }

    if (addRssSourceBtn) {
        addRssSourceBtn.addEventListener('click', async () => {
            const name = cleanText(rssNameInput.value);
            const url = cleanText(rssUrlInput.value);
            const defaultCategory = cleanText(rssCategoryInput.value, 'Gündem');

            if (!name || !url) {
                alert('Kaynak adı ve RSS URL zorunlu!');
                return;
            }

            try {
                await rssSourcesCollection.add({
                    name,
                    url,
                    defaultCategory,
                    active: true,
                    createdAt: firebase.firestore.FieldValue.serverTimestamp(),
                    lastFetchedAt: null,
                    lastError: ''
                });
                showTemporaryMessage(rssSuccess, 'RSS kaynağı eklendi!');
                rssNameInput.value = '';
                rssUrlInput.value = '';
                rssCategoryInput.value = '';
                loadRssSources();
            } catch (e) {
                alert('RSS kaynağı eklenemedi: ' + e.message);
            }
        });
    }


    if (fetchRssNowBtn) {
        fetchRssNowBtn.addEventListener('click', async () => {
            if (!confirm('Aktif RSS kaynakları şimdi çekilsin mi?')) return;

            fetchRssNowBtn.disabled = true;
            fetchRssNowBtn.textContent = 'RSS çekiliyor...';

            try {
                const importRssNow = functions.httpsCallable('importRssNow');
                const result = await importRssNow({});
                const data = result.data || {};
                const errors = Array.isArray(data.errors) ? data.errors : [];
                let message = `RSS tamamlandı. Kaynak: ${data.sources || 0}, yeni: ${data.imported || 0}, atlanan: ${data.skipped || 0}, hata: ${data.failed || 0}`;

                if ((data.imported || 0) === 0 && (data.skipped || 0) === 0 && (data.failed || 0) === 0) {
                    message = 'RSS çalıştı ama haber bulunamadı. Kaynak gerçek RSS/Atom linki olmayabilir.';
                }

                if ((data.failed || 0) > 0 && errors.length > 0) {
                    message += ` | İlk hata: ${errors[0].source}: ${errors[0].message}`;
                }

                showTemporaryMessage(rssSuccess, message);
                loadDraftNews();
                loadRssSources();
            } catch (e) {
                alert('RSS çekilemedi: ' + e.message);
            } finally {
                fetchRssNowBtn.disabled = false;
                fetchRssNowBtn.textContent = 'Şimdi RSS Çek';
            }
        });
    }
    async function loadRssSources() {
        if (!rssSourceListContainer) return;
        rssSourceListContainer.innerHTML = 'Yükleniyor...';
        const snapshot = await rssSourcesCollection.orderBy('createdAt', 'desc').get();
        rssSourceListContainer.innerHTML = '';

        if (statRssActive) {
            statRssActive.textContent = snapshot.docs.filter((doc) => doc.data().active !== false).length;
        }
        if (statRssError) {
            statRssError.textContent = snapshot.docs.filter((doc) => Boolean(cleanText(doc.data().lastError))).length;
        }

        if (snapshot.empty) {
            rssSourceListContainer.innerHTML = '<p class="empty-state">RSS kaynağı yok.</p>';
            return;
        }

        snapshot.docs.forEach((doc) => {
            const data = doc.data();
            const item = document.createElement('div');
            item.className = 'draft-item news-admin-item';

            const content = document.createElement('p');
            content.innerHTML = `
                <strong>${cleanText(data.name, 'Kaynak')}</strong>
                <span class="item-meta">${cleanText(data.defaultCategory, 'Genel')} &middot; ${data.active === false ? 'Pasif' : 'Aktif'}</span>
                <span class="item-url">${cleanText(data.url)}</span>
                ${cleanText(data.lastError) ? `<span class="item-error">${cleanText(data.lastError)}</span>` : ''}
            `;

            const actions = document.createElement('div');
            actions.className = 'item-actions';

            const toggleBtn = document.createElement('button');
            toggleBtn.className = 'small-action secondary-action';
            toggleBtn.textContent = data.active === false ? 'Aktif Yap' : 'Pasifleştir';
            toggleBtn.addEventListener('click', async () => {
                await rssSourcesCollection.doc(doc.id).set({ active: data.active === false }, { merge: true });
                loadRssSources();
            });

            const deleteBtn = document.createElement('button');
            deleteBtn.className = 'small-action delete-btn';
            deleteBtn.textContent = 'Sil';
            deleteBtn.addEventListener('click', async () => {
                if (!confirm('RSS kaynağı silinsin mi?')) return;
                await rssSourcesCollection.doc(doc.id).delete();
                loadRssSources();
            });

            actions.appendChild(toggleBtn);
            actions.appendChild(deleteBtn);
            item.appendChild(content);
            item.appendChild(actions);
            rssSourceListContainer.appendChild(item);
        });
    }
});