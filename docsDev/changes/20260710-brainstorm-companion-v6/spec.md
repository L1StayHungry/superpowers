---
change_id: 20260710-brainstorm-companion-v6
created_at: 2026-07-10T05:21:03Z
updated_at: 2026-07-10T05:47:35Z
owner: lihuajun
---

# Brainstorming Visual Companion v6 Spec

## Change History

- 2026-07-10: Initial approved v6 visual-companion sync design.
- 2026-07-10: Review hardening moved default runtime state to a stable temp scope, adopted the `.t-superpowers` cache namespace, removed shell-based browser overrides, and required reload after every reconnect plus explicit traversal rejection.

## Context

The fork's brainstorming companion is still based on upstream v5.1.0. Upstream v6.1.1 adds authentication, path confinement, safer process lifecycle handling, reconnect behavior, and browser-launch hardening. This change selectively adopts those improvements while keeping the internal `t-superpowers` namespace, narrow complex-work trigger boundary, `docsDev/` artifacts, and local-only branding.

## Goals

- Require a per-session key for all HTTP endpoints and WebSocket upgrades, with a secure cookie/bootstrap flow for browser navigation.
- Confine served files to the companion content directory and reject traversal, dotfiles, and symlink escapes.
- Bound WebSocket frames and harden malformed-frame handling.
- Preserve a browser session across server restarts through a stable temp-scoped port/key cache, reconnect backoff, paused-state UI, and a four-hour idle timeout.
- Make start/stop behavior safe across POSIX, Windows shells, WSL, stale PID reuse, and server restarts.
- Keep `T-Superpowers Brainstorming` as local text-only branding with the repository version, falling back to the Codex manifest when the root package is unavailable.
- Offer the visual companion only when the first genuinely visual question appears, open it automatically after acceptance, and do not ask again after refusal.

## Non-Goals

- No Prime Radiant logo, `primeradiant.com` request, remote image, analytics, telemetry pixel, or external branding link.
- No widening of the local complex-work trigger boundary.
- No new artifact path outside `docsDev/changes/<change-id>/`.
- No default runtime state at repository-root `.superpowers/` or `.t-superpowers/`; temporary sessions use `$TMPDIR/t-superpowers-brainstorm/<stable-project-id>`, while user-requested persistent artifacts stay under the change's `docsDev/.../transcripts/` directory.
- No version bump, publish, push, archive, upstream PR, or vendor customization.

## Requirements

### Requirement: Session Authentication

The companion must generate or reuse a strong per-session token, include it only in the initial launch URL, store it in an HttpOnly `SameSite=Strict` cookie, and reject missing or invalid credentials on every HTTP route and WebSocket upgrade.

#### Scenario: Unauthenticated access

- Given the companion is running with a session key
- When an HTTP or WebSocket client supplies no key or the wrong key
- Then the request is rejected
- And no screen, file, event channel, or state data is exposed

### Requirement: Confined Local Content

The companion must serve only regular non-dotfiles located beneath its content directory after real-path resolution.

#### Scenario: Unsafe file request

- Given a client is authenticated
- When it requests traversal, encoded traversal, a dotfile, a directory, or a symlink escaping the content root
- Then the request is rejected without disclosing file contents

### Requirement: Stable Authenticated Browser Session

The browser helper must reconnect with bounded exponential backoff, display connected/reconnecting/disconnected states, show a paused tombstone after the grace period, and reload after recovery. Server restarts must reuse the persisted port and token when safe.

#### Scenario: Server restarts while a tab stays open

- Given an authenticated companion tab is open
- When its server stops and restarts for the same project
- Then the tab reports reconnection state
- And the restarted server reuses the session port and token
- And the tab reconnects and reloads without requiring a new keyed URL

### Requirement: Safe Lifecycle and Protocol Bounds

The companion must reject oversized WebSocket payloads, stop after four hours of inactivity, avoid owner-PID shutdown on Windows shells, launch browsers without a command interpreter, and signal only a process whose brainstorm instance ID matches persisted state.

#### Scenario: Stale server PID

- Given the persisted PID now belongs to an unrelated process
- When `stop-server.sh` runs
- Then the unrelated process remains alive
- And the command reports stale PID state instead of signalling it

### Requirement: Local T-Superpowers Branding

Framed and waiting screens must display local text branding `T-Superpowers Brainstorming` with a dynamically resolved local version. The generated HTML and scripts must not contain Prime Radiant URLs, remote logos, tracking parameters, or telemetry requests.

#### Scenario: Packaged Codex-only installation

- Given the scripts are installed without a root `package.json`
- And `.codex-plugin/plugin.json` contains the package version
- When the companion renders a page
- Then the page displays that fallback version next to `T-Superpowers Brainstorming`
- And no remote branding request is present

### Requirement: Just-in-Time Visual Offer

The brainstorming skill must ask about the visual companion only when the first question whose answer materially depends on seeing layouts, diagrams, visual comparisons, or spatial relationships is reached.

#### Scenario: User accepts or refuses

- Given earlier brainstorming questions were conceptual or textual
- When the first genuinely visual question appears
- Then the agent asks a separate companion opt-in question
- And acceptance starts the server with `--open`
- And refusal continues in text without asking again in the same brainstorming session

## Validation

- Adapt upstream v6.1.1 brainstorm-server tests for the local `t-brainstorming` path and text-only branding.
- Run the full brainstorm suite, shell syntax checks, stage-one namespace regression, installer suite, build, pack dry-run, and `git diff --check`.
- Preserve the existing team tests while adding authentication, confinement, reconnect, lifecycle, start/stop, version fallback, and branding-network regression coverage.

## Risks

- Fixed-port integration tests can collide with another local process; tests must fail clearly rather than silently fall back when a fixed port is required.
- Cookie and sessionStorage bootstrapping can leak the key through referrers or history unless the keyed response is no-store/no-referrer and immediately replaces the URL.
- PID verification differs across operating systems; the stop script must fail closed when ownership cannot be proven.
- Tests simulate Windows shell branches on non-Windows hosts, but a real Windows environment remains the strongest lifecycle coverage.

## Archive Patch

### brainstorming

Target: docsDev/specs/brainstorming/spec.md
Action: create

#### ADDED Requirements

##### Requirement: Visual Brainstorming Companions Are Local, Authenticated, and Optional

The brainstorming workflow must offer its local visual companion only at the first genuinely visual decision, require explicit opt-in, protect every HTTP and WebSocket surface with a per-session key, confine served content to the session directory, and avoid all remote branding or telemetry requests.

###### Scenario: First visual decision

- Given a complex brainstorming session begins with conceptual questions
- When the first layout, diagram, visual comparison, or spatial decision appears
- Then the agent asks once whether to use the visual companion
- And acceptance opens an authenticated local session
- And refusal keeps the remaining session text-only without repeating the offer

##### Requirement: Visual Companion Sessions Recover Safely

The visual companion must preserve safe project-scoped sessions across server restarts, reconnect browser tabs with bounded backoff, enforce protocol size limits, and stop only processes whose persisted instance identity matches.

###### Scenario: Restart and safe stop

- Given a companion tab and its project session metadata already exist
- When the server restarts and is later explicitly stopped
- Then the session reuses its port and key so the tab reconnects
- And the stop command signals only the matching brainstorm server process
