const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const { test } = require('node:test');
const assert = require('node:assert/strict');

const publicDir = path.join(__dirname, '..', 'public');
const html = fs.readFileSync(path.join(publicDir, 'index.html'), 'utf8');
const script = fs.readFileSync(path.join(publicDir, 'app_v2.js'), 'utf8');
const styles = fs.readFileSync(path.join(publicDir, 'style_v2.css'), 'utf8');

test('admin JavaScript parses without syntax errors', () => {
  assert.doesNotThrow(() => new vm.Script(script, { filename: 'app_v2.js' }));
});

test('every JavaScript element reference exists once in the HTML', () => {
  const htmlIds = [...html.matchAll(/\bid="([^"]+)"/g)].map((match) => match[1]);
  const duplicateIds = htmlIds.filter((id, index) => htmlIds.indexOf(id) !== index);
  assert.deepEqual(duplicateIds, []);

  const idSet = new Set(htmlIds);
  const referencedIds = [
    ...script.matchAll(/getElementById\('([^']+)'\)/g),
  ].map((match) => match[1]);
  const missingIds = [...new Set(referencedIds.filter((id) => !idSet.has(id)))];
  assert.deepEqual(missingIds, []);
});

test('bulk controls and mobile dock ship with matching cache versions', () => {
  assert.match(html, /id="summarize-selected-drafts-btn"/);
  assert.match(html, /id="categorize-selected-live-btn"/);
  assert.match(html, /id="mobile-bulk-dock"/);
  assert.match(html, /style_v2\.css\?v=20260902-1/);
  assert.match(html, /app_v2\.js\?v=20260902-1/);
  assert.match(styles, /@media \(max-width: 620px\)/);
  assert.match(styles, /\.mobile-bulk-dock\.is-visible/);
});
