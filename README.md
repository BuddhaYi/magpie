# magpie 🐦

> Unified CLI for X/Twitter (via [bird](https://github.com/steipete/bird)) and 132 other sites (via [opencli](https://github.com/jackwener/opencli)). Magpies hoard shiny things — so does this one.

```bash
tx search "Claude Code"        # → bird (fast GraphQL)
tx follow karpathy             # → opencli (real browser, lower anti-bot fingerprint)
tx tweet "hello world"         # → opencli (alias for post — content writes go via browser)
tx arxiv search "vision"       # → opencli arxiv adapter
tx archive                     # incremental SQLite sync of X bookmarks
```

One short binary that **routes 180+ commands** across two backends — with risk-aware defaults so reads go via the fast API and social writes go via a real browser.

---

## Why

| Pain | Solution |
|---|---|
| `bird` covers X but only X. `opencli` covers 132 sites with different verb names. | One unified `tx` with consistent verbs |
| Hand-coding wrappers for every command means upgrades break things. | All commands auto-discovered from `bird --help` and `opencli list` |
| Reads should be fast (API), social writes should be stealthy (browser) — but pure "all writes via browser" wastes 10× time on harmless operations like bookmarking. | Routing splits **reads / self-writes → bird** and **social writes → opencli**, automatically |
| Safari's ITP kills cookies after 7-30 days. Cron jobs can't read encrypted browser cookies. | One-time extraction → `~/.tx/cookies.env` (Edge Beta cookies last ~13 months) |
| Cookie expiration is silent — you find out weeks later your archive is broken. | `tx auth` shows fresh / aging / stale / expired status with renewal hints |

---

## Install

### Prerequisites

```bash
# 1. Node-based upstream tools
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
# Log in to x.com in Microsoft Edge Beta (recommended — no Safari ITP cleanup)
tx cookies-save              # extracts auth_token + ct0 → ~/.tx/cookies.env (mode 0600)
tx auth                      # verify everything is green
```

For `opencli` write operations (like, retweet, follow, post, reply, ...), you also need the OpenCLI browser extension installed and connected — see [opencli docs](https://opencli.info/) for `opencli browser init` setup.

---

## Routing model

```
tx <command> [args...]
       │
       ├─ Layer 1: internal       auth / archive / cookies-save / doctor / help
       ├─ Layer 2: explicit       tx bird <args>   tx <site> <args>
       ├─ Layer 3: --via flag     tx --via opencli search "x"
       └─ Layer 4: auto-route
            ├─ tweet alias        → opencli twitter post  (content creation defaults to browser)
            ├─ social-write       → opencli  (follow / unfollow / reply)
            ├─ overlap (other)    → bird     (reads + self-writes like bookmark)
            ├─ bird-only          → bird
            └─ opencli-only       → opencli twitter
```

### Why "social-write → opencli" by default

| Tier | Op | What it triggers in X | Default backend |
|---|---|---|---|
| 0 | Reads of your own data (search/home/bookmarks/mentions) | Nothing X cares about | **bird** ✓ |
| 1 | Private toggles (bookmark/unbookmark) | No notifications, no public visibility | **bird** ✓ |
| 2 | Other-toggle (like/unlike) | Small notification footprint | **opencli** ✓ |
| 3 | Social signal (follow/unfollow/retweet) | Public-graph mutation, anti-bot scrutiny | **opencli** ✓ |
| 4 | Content creation (post/tweet/quote/reply) | Most scrutinized — anti-spam systems all watch this | **opencli** ✓ |

A 5-10 second browser-driven action is invisible compared to the seconds-to-minutes a human spends deciding to perform a tier 3-4 operation. Spending those seconds on a real browser fingerprint reduces detection risk to ~zero.

### Override at will

```bash
tx --via bird follow karpathy   # force GraphQL (faster, ~marginally higher detection footprint)
tx --via opencli search "x"     # force browser (slower, no detection benefit for reads)
tx bird tweet "raw"             # explicit bird passthrough (escape hatch)
tx twitter post "via browser"   # opencli site adapter passthrough
```

---

## Common commands

| Command | Routes to | Purpose |
|---|---|---|
| `tx home` | bird | For You timeline |
| `tx search "x"` | bird | search tweets |
| `tx user-tweets karpathy` | bird | someone's recent tweets |
| `tx thread <url>` | bird | full conversation tree |
| `tx bookmarks` | bird | your bookmarks |
| `tx like <url>` | opencli | like a tweet |
| `tx retweet <url>` | opencli | retweet |
| `tx follow karpathy` | **opencli** | follow user (was bird in v0.1) |
| `tx reply <url> "text"` | **opencli** | reply (was bird in v0.1) |
| `tx tweet "hi"` | **opencli** post | new tweet (alias, was bird in v0.1) |
| `tx download karpathy` | opencli | download all media |
| `tx arxiv search "transformer"` | opencli arxiv | search arxiv |
| `tx hackernews top` | opencli hackernews | HN front page |
| `tx archive` | internal | sync bookmarks to SQLite |
| `tx auth` | internal | health check (bird + opencli + cookie age) |

Run `tx help` for the full categorized list (50+ X commands + 136 site adapters).

---

## Cookie management

X cookies expire (server-side session invalidation). magpie extracts them **once** and caches for non-interactive use (cron / launchd).

### Browser preference (most → least persistent on macOS)

| Browser | Persistence | Why |
|---|---|---|
| **Edge Beta** ⭐ | months (~13 mo on auth_token) | No ITP, no aggressive cleanup |
| Edge stable | months | Same Chromium architecture |
| Chrome | months | Same as Edge |
| Firefox | months | No ITP |
| Safari | **7-30 days** | Apple ITP auto-deletes inactive cookies |

### Renewal flow

```bash
tx cookies-save --check-age   # is renewal needed?

# When stale:
#  1. open Edge Beta → x.com → ensure logged in
#  2. tx cookies-save           # extracts current cookies
#  3. tx auth                   # verify
```

### Override source

```bash
tx cookies-save --from chrome      # use Chrome instead of Edge
tx cookies-save --from safari      # use Safari (short-lived; not recommended)
tx cookies-save --from firefox
tx cookies-save --from edge-stable
```

---

## Automation

### macOS launchd (recommended)

```bash
cp examples/launchd.plist.template ~/Library/LaunchAgents/com.YOURNAME.tx-archive.plist
sed -i '' "s|YOURUSERNAME|$(whoami)|g" ~/Library/LaunchAgents/com.YOURNAME.tx-archive.plist
launchctl load ~/Library/LaunchAgents/com.YOURNAME.tx-archive.plist
```

Runs daily at 9 AM. launchd survives sleep/wake (cron does not on macOS).

Why a separate `cookies.env` file? launchd processes lack Full Disk Access — they can't read encrypted browser cookies. `tx cookies-save` extracts them once interactively (where Keychain prompts can be approved) so launchd can read the resulting plain `cookies.env`.

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

## Safety / risk profile

magpie's defaults are tuned for **personal single-user CLI use**. For a single human:

- **At default volumes (one human, manual + 1 archive/day)**: anti-bot risk is effectively zero
- **Reads via bird are indistinguishable from web client behavior**
- **Social writes via opencli use a real browser** — same fingerprint as you clicking manually

**What WILL trigger X risk controls (don't do these with magpie or anything else):**

- Mass follow / unfollow (>400/day) → rate limited, possible flag
- Mass like (>400/day) → rate limited
- Mass tweet (>50/day) → rate limited
- Sub-second consecutive actions → behavioral analysis flag
- Same cookies on multiple IP locations → security check / verification challenge

**For new accounts (<6 months old)**: be especially conservative. New accounts attract more anti-bot attention.

---

## Architecture

**~660 LOC of Python, zero dependencies beyond stdlib.**

Routing is fully introspection-based:

1. On first run (or `tx --refresh`), parse:
   - `bird --help` → set of bird commands
   - `opencli twitter --help` → opencli twitter commands (with `[read]/[write]` tags)
   - `opencli list` → 136 site/app adapters
2. Cache to `~/.tx/cache.json` (TTL 7d)
3. At command time: lookup → `os.execvp` (zero overhead post-routing)

Key insight: both upstream tools have structured help output. magpie reads that structure rather than maintaining handwritten routing tables — **upgrades to bird/opencli automatically pick up new commands**.

### Cookie extraction details

bird natively supports Safari/Chrome/Firefox cookie extraction but NOT Edge. magpie bypasses this by calling [`@steipete/sweet-cookie`](https://www.npmjs.com/package/@steipete/sweet-cookie) directly (bird's underlying library), which has Edge support — just not exposed through bird's CLI.

---

## Changelog

### v0.2 (current — risk-aware routing)
- **Routing change**: `follow` / `unfollow` / `reply` now default to **opencli** (was bird)
- **Alias added**: `tx tweet` → `opencli twitter post` (was bird `tweet`)
- Rationale: tier-3-4 X operations (social writes & content creation) have higher anti-bot scrutiny; using a real browser fingerprint reduces risk to ~zero with negligible UX cost (5-10s for a single deliberate action)
- Override: `tx --via bird <cmd>` or `tx bird <cmd>` if you need the API path

### v0.1
- Initial release: bird + opencli routing, sweet-cookie Edge support, launchd template, SQLite archive

---

## License

MIT — see [LICENSE](./LICENSE).

## Credits

Built on top of:
- [bird](https://github.com/steipete/bird) by Peter Steinberger — fast X CLI
- [opencli](https://github.com/jackwener/opencli) by jackwener — universal site CLI
- [sweet-cookie](https://www.npmjs.com/package/@steipete/sweet-cookie) — cookie extraction

Inspired by [ve-twini](https://clianything.cc/) (which only exposes 5 commands) — magpie generalizes the bridge to all 180+.
