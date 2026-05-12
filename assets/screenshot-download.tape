# Static screenshot of `tx download` showing max-quality variant selection
Output assets/screenshot-download.png

Set Shell zsh
Set FontSize 16
Set FontFamily "JetBrains Mono"
Set Width 1300
Set Height 500
Set Theme "Catppuccin Mocha"

Hide
Type "rm -rf /tmp/magpie-shot && mkdir -p /tmp/magpie-shot && cd /tmp/magpie-shot"
Enter
Sleep 200ms
Type "clear && tx download --tweet-url https://x.com/i/status/2053430277020770561 --output ."
Enter
Sleep 18000ms
Show
Sleep 100ms
