/**
 * Local branding regression tests for the T-Superpowers visual companion.
 *
 * The internal fork intentionally does not adopt upstream Prime Radiant images
 * or telemetry. Both source and rendered pages must stay local-only, while the
 * displayed version works in the repository and in a Codex-manifest-only
 * packaged layout.
 */

const { spawn } = require('child_process');
const http = require('http');
const fs = require('fs');
const path = require('path');
const assert = require('assert');

const REPO_ROOT = path.join(__dirname, '../..');
const SCRIPTS = path.join(REPO_ROOT, 'skills/t-brainstorming/scripts');
const SERVER_PATH = path.join(SCRIPTS, 'server.cjs');
const PACKAGE_VERSION = JSON.parse(
  fs.readFileSync(path.join(REPO_ROOT, 'package.json'), 'utf-8')
).version;
const TOKEN = 'testtoken-branding-0123456789abcdef';

function testPort(offset) {
  const base = Number(
    process.env.BRAINSTORM_BRANDING_TEST_PORT || (49152 + Math.floor(Math.random() * 12000))
  );
  return base + offset;
}

function cleanup(dir) {
  fs.rmSync(dir, { recursive: true, force: true });
}

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

function startServer({ port, dir, serverPath = SERVER_PATH }) {
  cleanup(dir);
  return spawn('node', [serverPath], {
    env: {
      ...process.env,
      BRAINSTORM_PORT: String(port),
      BRAINSTORM_DIR: dir,
      BRAINSTORM_TOKEN: TOKEN
    }
  });
}

function waitForServer(server) {
  let stdout = '';
  let stderr = '';
  return new Promise((resolve, reject) => {
    const timeout = setTimeout(
      () => reject(new Error(`Server did not start. stderr: ${stderr}`)),
      5000
    );
    server.stdout.on('data', data => {
      stdout += data.toString();
      if (stdout.includes('server-started')) {
        clearTimeout(timeout);
        resolve();
      }
    });
    server.stderr.on('data', data => { stderr += data.toString(); });
    server.on('error', reject);
  });
}

function fetchHtml(port) {
  const headers = { Cookie: `brainstorm-key-${port}=${TOKEN}` };
  return new Promise((resolve, reject) => {
    http.get(`http://localhost:${port}/`, { headers }, res => {
      let body = '';
      res.on('data', chunk => { body += chunk; });
      res.on('end', () => resolve({ status: res.statusCode, body }));
    }).on('error', reject);
  });
}

function writeFragment(dir) {
  const contentDir = path.join(dir, 'content');
  fs.mkdirSync(contentDir, { recursive: true });
  fs.writeFileSync(path.join(contentDir, 'screen.html'), '<h2>Pick a layout</h2>');
}

function createCodexOnlyFixture(version) {
  const root = fs.mkdtempSync(path.join('/tmp', 't-superpowers-codex-only-'));
  const scriptDir = path.join(root, 'skills/t-brainstorming/scripts');
  fs.cpSync(SCRIPTS, scriptDir, { recursive: true });
  fs.mkdirSync(path.join(root, '.codex-plugin'), { recursive: true });
  fs.writeFileSync(
    path.join(root, '.codex-plugin/plugin.json'),
    JSON.stringify({ name: 't-superpowers', version }, null, 2)
  );
  return { root, serverPath: path.join(scriptDir, 'server.cjs') };
}

async function withServer(options, fn) {
  const server = startServer(options);
  try {
    await waitForServer(server);
    await fn();
  } finally {
    if (server.exitCode === null && server.signalCode === null) {
      server.kill();
      await new Promise(resolve => server.once('exit', resolve));
    }
    cleanup(options.dir);
  }
}

function assertLocalBrand(html, version) {
  assert(
    html.includes(`T-Superpowers Brainstorming v${version}`),
    `page should contain local text brand and version ${version}`
  );
  assert(!/primeradiant\.com/i.test(html), 'must not load Prime Radiant assets');
  assert(!/brand-logo/i.test(html), 'must not render an external brand logo');
  assert(!/(?:event|surface|launch_id|lid)=/i.test(html), 'must not emit telemetry parameters');
}

let passed = 0;
let failed = 0;

async function test(name, fn) {
  try {
    await fn();
    console.log(`  PASS: ${name}`);
    passed++;
  } catch (error) {
    console.log(`  FAIL: ${name}`);
    console.log(`    ${error.message}`);
    failed++;
  }
}

async function main() {
  console.log('\n--- T-Superpowers Local Branding ---');

  await test('source contains no Prime Radiant URL or remote branding request', () => {
    const source = fs.readdirSync(SCRIPTS)
      .filter(name => /\.(?:cjs|js|html|sh)$/.test(name))
      .map(name => fs.readFileSync(path.join(SCRIPTS, name), 'utf-8'))
      .join('\n');
    assert(!/primeradiant\.com/i.test(source), 'source must not mention primeradiant.com');
    assert(!/superpowers-visual-brainstorming-logo/i.test(source), 'source must not name a remote logo');
  });

  await test('framed screen uses repository version with local text-only brand', async () => {
    const port = testPort(0);
    const dir = '/tmp/t-brainstorm-branding-repo';
    await withServer({ port, dir }, async () => {
      writeFragment(dir);
      await sleep(300);
      const response = await fetchHtml(port);
      assert.strictEqual(response.status, 200);
      assertLocalBrand(response.body, PACKAGE_VERSION);
    });
  });

  await test('waiting screen uses repository version with local text-only brand', async () => {
    const port = testPort(1);
    const dir = '/tmp/t-brainstorm-branding-waiting';
    await withServer({ port, dir }, async () => {
      const response = await fetchHtml(port);
      assert.strictEqual(response.status, 200);
      assertLocalBrand(response.body, PACKAGE_VERSION);
    });
  });

  await test('Codex-only packaged layout falls back to manifest version', async () => {
    const fixture = createCodexOnlyFixture('9.8.7');
    const port = testPort(2);
    const dir = '/tmp/t-brainstorm-branding-codex';
    try {
      await withServer({ port, dir, serverPath: fixture.serverPath }, async () => {
        writeFragment(dir);
        await sleep(300);
        const response = await fetchHtml(port);
        assert.strictEqual(response.status, 200);
        assertLocalBrand(response.body, '9.8.7');
      });
    } finally {
      cleanup(fixture.root);
    }
  });

  console.log(`\n--- Results: ${passed} passed, ${failed} failed ---`);
  if (failed > 0) process.exit(1);
}

main().catch(error => {
  console.error(error);
  process.exit(1);
});
