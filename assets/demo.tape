# magpie demo.tape — produces assets/demo.gif via `VHS_PORT=9876 vhs demo.tape`

Output assets/demo.gif

Set Shell zsh
Set FontSize 16
Set FontFamily "JetBrains Mono"
Set Width 1280
Set Height 700
Set Theme "Catppuccin Mocha"
Set TypingSpeed 40ms

# ── 1. 3-backend health check (2s) ──
Type "tx auth"
Enter
Sleep 2500ms
Hide
Type "clear"
Enter
Show

# ── 2. real X read via twitter-cli TLS impersonation (4s) ──
Type "tx search 'Claude Code' --max 2"
Enter
Sleep 3500ms
Hide
Type "clear"
Enter
Show

# ── 3. the killer feature: max-quality media download (8s) ──
Type "tx download --tweet-url https://x.com/i/status/2053430277020770561"
Enter
Sleep 6500ms
Type "ls -lh twitter-downloads/"
Enter
Sleep 2000ms
