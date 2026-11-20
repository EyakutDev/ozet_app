const fs = require('node:fs');
const path = require('node:path');
const { after, before, beforeEach, test } = require('node:test');
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');
const {
  doc,
  getDoc,
  setDoc,
  Timestamp,
  updateDoc,
} = require('firebase/firestore');

const projectId = 'ozet-d09a3';
let testEnvironment;

before(async () => {
  testEnvironment = await initializeTestEnvironment({
    projectId,
    firestore: {
      rules: fs.readFileSync(
        path.join(__dirname, '..', 'firestore.rules'),
        'utf8',
      ),
    },
  });
});

beforeEach(async () => {
  await testEnvironment.clearFirestore();
});

after(async () => {
  await testEnvironment.cleanup();
});

function authenticatedDb(uid, email = `${uid}@example.test`) {
  return testEnvironment.authenticatedContext(uid, { email }).firestore();
}

function anonymousDb() {
  return testEnvironment.unauthenticatedContext().firestore();
}

async function seedDocument(pathSegments, data) {
  await testEnvironment.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), ...pathSegments), data);
  });
}

test('published news is public but client writes are denied', async () => {
  await seedDocument(['news', 'published'], { title: 'Test news' });

  await assertSucceeds(getDoc(doc(anonymousDb(), 'news', 'published')));
  await assertFails(
    setDoc(doc(anonymousDb(), 'news', 'client-write'), { title: 'Blocked' }),
  );
});

test('users can write only their own validated profile fields', async () => {
  const alice = authenticatedDb('alice');
  const bob = authenticatedDb('bob');

  await assertSucceeds(
    setDoc(doc(alice, 'users', 'alice'), {
      statusIcon: 'calm',
      statusText: 'Bugun sakinim.',
      statusExpiresAt: Timestamp.now(),
      partnerShares: [],
    }),
  );
  await assertFails(
    setDoc(doc(alice, 'users', 'bob'), { statusText: 'Not mine' }),
  );
  await assertFails(getDoc(doc(bob, 'users', 'alice')));
  await assertFails(
    updateDoc(doc(alice, 'users', 'alice'), { pairedWith: 'bob' }),
  );
  await assertFails(
    updateDoc(doc(alice, 'users', 'alice'), { statusText: 'x'.repeat(121) }),
  );
  await assertFails(
    updateDoc(doc(alice, 'users', 'alice'), {
      partnerShares: [{}, {}, {}, {}],
    }),
  );
});

test('a paired user can read the partner profile but cannot write it', async () => {
  await seedDocument(['users', 'alice'], {
    pairedWith: 'bob',
    statusText: 'Sakinim',
  });
  const bob = authenticatedDb('bob');

  await assertSucceeds(getDoc(doc(bob, 'users', 'alice')));
  await assertFails(
    updateDoc(doc(bob, 'users', 'alice'), { statusText: 'Changed by bob' }),
  );
});

test('private user data is isolated from every other user', async () => {
  const alice = authenticatedDb('alice');
  const bob = authenticatedDb('bob');

  await assertSucceeds(
    setDoc(doc(alice, 'user_private', 'alice'), {
      fcmToken: 'token',
      tokenUpdatedAt: Timestamp.now(),
      notificationPreferences: {
        morningDigest: true,
        eveningCheckIn: true,
        partnerUpdates: true,
      },
      updatedAt: Timestamp.now(),
    }),
  );
  await assertFails(getDoc(doc(bob, 'user_private', 'alice')));
  await assertFails(
    setDoc(doc(alice, 'user_private', 'alice'), { unexpectedSecret: true }),
  );
});

test('pair codes cannot be read or written directly by clients', async () => {
  await seedDocument(['pair_codes', 'ABC123'], { uid: 'alice' });
  const alice = authenticatedDb('alice');

  await assertFails(getDoc(doc(alice, 'pair_codes', 'ABC123')));
  await assertFails(
    setDoc(doc(alice, 'pair_codes', 'NEW123'), { uid: 'alice' }),
  );
});

test('admin activity is append-only and restricted to admins', async () => {
  await seedDocument(['admins', 'admin@example.test'], { active: true });
  const admin = authenticatedDb('admin-uid', 'admin@example.test');
  const regular = authenticatedDb('regular');
  const activityRef = doc(admin, 'admin_activity', 'delete-event');

  await assertSucceeds(
    setDoc(activityRef, {
      type: 'news_deleted',
      scope: 'draft',
      count: 3,
      actorUid: 'admin-uid',
      createdAt: Timestamp.now(),
    }),
  );
  await assertSucceeds(getDoc(activityRef));
  await assertFails(
    setDoc(doc(regular, 'admin_activity', 'blocked-event'), {
      type: 'news_deleted',
      scope: 'live',
      count: 1,
      actorUid: 'regular',
      createdAt: Timestamp.now(),
    }),
  );
  await assertFails(updateDoc(activityRef, { count: 4 }));
  await assertFails(
    setDoc(doc(admin, 'admin_activity', 'spoofed-event'), {
      type: 'news_deleted',
      scope: 'live',
      count: 1,
      actorUid: 'another-user',
      createdAt: Timestamp.now(),
    }),
  );
});

test('admin collections require an email listed in admins', async () => {
  await seedDocument(['admins', 'admin@example.test'], { active: true });
  const admin = authenticatedDb('admin-uid', 'admin@example.test');
  const regular = authenticatedDb('regular');

  await assertSucceeds(
    setDoc(doc(admin, 'draft_news', 'draft'), { title: 'Allowed' }),
  );
  await assertFails(
    setDoc(doc(regular, 'draft_news', 'draft-2'), { title: 'Blocked' }),
  );
});
