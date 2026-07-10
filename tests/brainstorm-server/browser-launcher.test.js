const assert = require('assert');
const {
  browserLauncherForPlatform,
  browserLauncherFromCommandJson
} = require('../../skills/t-brainstorming/scripts/server.cjs');

let passed = 0;
let failed = 0;

async function test(name, fn) {
  try {
    await fn();
    console.log(`  PASS: ${name}`);
    passed++;
  } catch (e) {
    console.log(`  FAIL: ${name}`);
    console.log(`    ${e.message}`);
    failed++;
  }
}

(async () => {
  console.log('\n--- Browser Launcher ---');

  await test('Windows launcher does not route URLs through cmd.exe', () => {
    const url = 'http://localhost:54122/?key=abc&x=SAFE&echo=INJECTED';
    const launcher = browserLauncherForPlatform(url, {
      platform: 'win32',
      osRelease: '10.0.26200',
      env: {}
    });

    assert.deepStrictEqual(launcher, {
      bin: 'rundll32.exe',
      args: ['url.dll,FileProtocolHandler', url]
    });
    assert(!launcher.args.includes('/c'), 'Windows launcher must not pass /c to a command interpreter');
  });

  await test('WSL launcher does not route URLs through cmd.exe', () => {
    const url = 'http://localhost:54122/?key=abc&x=SAFE&echo=INJECTED';
    const launcher = browserLauncherForPlatform(url, {
      platform: 'linux',
      osRelease: '5.15.167.4-microsoft-standard-WSL2',
      env: {}
    });

    assert.deepStrictEqual(launcher, {
      bin: 'rundll32.exe',
      args: ['url.dll,FileProtocolHandler', url]
    });
  });

  await test('Linux launcher stays headless without a display', () => {
    assert.strictEqual(
      browserLauncherForPlatform('http://localhost:1/', {
        platform: 'linux',
        osRelease: '6.0.0',
        env: {}
      }),
      null
    );
  });

  await test('operator override keeps a hostile URL as one argv element without a shell', () => {
    const url = 'http://localhost:54122/?key=abc&x=$(touch /tmp/never-run)';
    const launcher = browserLauncherFromCommandJson(
      JSON.stringify(['/usr/bin/node', '/tmp/capture-open.cjs', '/tmp/marker']),
      url
    );
    assert.deepStrictEqual(launcher, {
      bin: '/usr/bin/node',
      args: ['/tmp/capture-open.cjs', '/tmp/marker', url]
    });
  });

  await test('operator override rejects non-array and empty commands', () => {
    assert.throws(() => browserLauncherFromCommandJson('"node --version"', 'http://localhost/'), /JSON array/i);
    assert.throws(() => browserLauncherFromCommandJson('[]', 'http://localhost/'), /non-empty/i);
  });

  console.log(`\n--- Results: ${passed} passed, ${failed} failed ---`);
  if (failed > 0) process.exit(1);
})();
