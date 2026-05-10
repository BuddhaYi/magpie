# magpie 🐦

> Unified CLI for X/Twitter (via [bird](https://github.com/steipete/bird)) and 132 other sites (via [opencli](https://github.com/jackwener/opencli)). Magpies hoard shiny things — so does this one.

```bash
tx search "Claude Code"        # → bird (fast GraphQL)
tx like https://x.com/.../...  # → opencli (browser automation)
tx arxiv search "vision"       # → opencli arxiv adapter
tx archive                     # incremental sync of X bookmarks → SQLite
```

One short binary that **routes 183 commands** across two backends, with **zero per-command code** to maintain.

---

## Why

| Pain | Solution |
|---|---|
| `bird` covers X but only X. `opencli` covers 132 sites but its Twitter has different verb names. | One unified `tx` with consistent verbs |
| Hand-coding wrappers for every command means upgrades break things. | All commands auto-discovered from `bird --help` and `opencli list` |
| Safari's ITP kills cookies after 7-30 days. Cron jobs can't read encrypted browser cookies. | One-time extraction → `~/.tx/cookies.env` lasts months on Edge Beta |
| Cookie expiration is silent — you find out weeks later your archive is broken. | `tx auth` shows fresh / aging / stale / expired status with renewal hints |

---

## Install

### Prerequisites

```bash
# 1. Node tools
npm install -g @steipete/bird @jackwener/opencli

# 2. Python 3.10+ (stdlib only, no pip deps)
python3 --version
```

### Install magpie

```bash
git clone https://github.com/BuddhaYi/magpie.git
cd magpie
./install.sh                 # symlinks tx → /usr/local/bin (or ~/.local/bin)
tx --help
```

### One-time browser setup

```bash
# Log in to x.com in Microsoft Edge Beta (preferred — no Safari ITP)
tx cookies-save              # extracts auth_token + ct0 → ~/.tx/cookies.env
tx auth                      # verify everything is green
```

---

## Usage

### Routing model

```
tx <command> [args...]
       │
       ├─ Layer 1: internal      auth / archive / cookies-save / doctor / help
       ├─ Layer 2: explicit      tx bird <args> | tx <site> <args>
       ├─ Layer 3: --via flag    tx --via opencli search "x"
       └─ Layer 4: auto-route    bird-only → bird
                                  opencli-only → opencli twitter
                                  collision → bird (faster)
```

### Common commands

| Command | Routes to | Purpose |
|---|---|---|
| `tx home` | bird | For You timeline |
| `tx search "x"` | bird | search tweets |
| `tx user-tweets karpathy` | bird | someone's recent tweets |
| `tx thread <url>` | bird | full conversation tree |
| `tx like <url>` | opencli | like a tweet |
| `tx download karpathy` | opencli | download all media |
| `tx arxiv search "transformer"` | opencli arxiv | search arxiv |
| `tx hackernews top` | opencli hackernews | HN front page |
| `tx archive` | internal | sync bookmarks to SQLite |
| `tx auth` | internal | health check |

Run `tx help` for the full categorized list (50+ X commands + 136 site adapters).

### Force a backend

```bash
tx bird search "x"           # always bird
tx --via opencli search "x"  # force opencli twitter
tx twitter post "hi"         # force opencli twitter (twitter is a site adapter)
```

---

## Cookies management

X cookies expire (server-side session invalidation). magpie extracts them once and caches for non-interactive use (cron / launchd).

### Browser preference (most → least persistent)

| Browser | macOS persistence | Why |
|---|---|---|
| **Edge Beta** ⭐ | months (~13 mo on auth_token) | No ITP, no aggressive cleanup |
| Edge stable | months | Same architecture as Edge Beta |
| Chrome | months | Same as Edge |
| Firefox | months | No ITP |
| Safari | **7-30 days** | Apple ITP auto-deletes inactive cookies |

### Renewal flow

```bash
tx cookies-save --check-age   # is renewal needed?

# When stale:
#  1. open browser → x.com → ensure logged in
#  2. tx cookies-save           # extracts current cookies
#  3. tx auth                   # verify
```

---

## Automation

### macOS launchd (recommended)

```bash
cp examples/launchd.plist.template ~/Library/LaunchAgents/com.YOURNAME.tx-archive.plist
# edit the plist: replace YOURNAME and adjust the Hour
launchctl load ~/Library/LaunchAgents/com.YOURNAME.tx-archive.plist
```

Run daily at 9 AM. launchd survives sleep/wake (cron does not).

### Manual

```bash
# Once a day:
tx archive

# Or alias to your morning routine:
echo "alias morning='tx archive && tail -3 ~/.tx/archive.log'" >> ~/.zshrc
```

---

## Where data lives

| Path | Purpose | Sensitive? |
|---|---|---|
| `~/.tx/cache.json` | command discovery cache (TTL 7d) | no |
| `~/.tx/cookies.env` | extracted X auth_token + ct0 | **YES** (mode 0600) |
| `~/.tx/bookmarks.db` | SQLite archive of X bookmarks | personal |
| `~/.tx/archive.log` | launchd output | personal |

Nothing leaves your machine. magpie does not phone home.

---

## Architecture

magpie is **~600 LOC of Python** + **0 dependencies** beyond stdlib.

Routing is fully introspection-based:

1. On first run (or `tx --refresh`), parse:
   - `bird --help` → set of bird commands
   - `opencli twitter --help` → opencli twitter commands (with `[read]/[write]` tags)
   - `opencli list` → 136 site/app adapters
2. Cache to `~/.tx/cache.json` (TTL 7d)
3. At command time: lookup → `os.execvp` (zero overhead post-routing)

Key insight: `opencli`'s help output is structured. magpie reads that structure rather than maintaining handwritten routing tables, so **upgrades to bird/opencli automatically pick up new commands**.

### Cookie extraction details

bird natively supports Safari/Chrome/Firefox cookie extraction but not Edge. magpie bypasses this by calling [`@steipete/sweet-cookie`](https://www.npmjs.com/package/@steipete/sweet-cookie) directly (bird's underlying library), which has Edge support — just not exposed through bird's CLI.

---

## License

MIT — see [LICENSE](./LICENSE).

## Credits

Built on top of:
- [bird](https://github.com/steipete/bird) by Peter Steinberger — fast X CLI
- [opencli](https://github.com/jackwener/opencli) by jackwener — universal site CLI
- [sweet-cookie](https://www.npmjs.com/package/@steipete/sweet-cookie) — cookie extraction

Inspired by [ve-twini](https://clianything.cc/) (which only exposes 5 commands) — magpie generalizes the bridge to all 183.
