# Deskie

Your Claude Code, with a face.

Deskie puts a little 3D character at a desk in the corner of your Mac:
- It types while Claude Code works.
- It stands up and waves at you when Claude needs an answer.
- It dances when a task is done.
- It naps when nothing's running.

It works in any terminal and stays on top of every app, so you notice Claude waiting on you even while you're scrolling Twitter.

<!-- demo gif goes here -->

## Install

In Terminal:

```
curl -fsSL https://raw.githubusercontent.com/Aditya-A-G/deskie/main/install.sh | sh
```

Or ask Claude: *"install Deskie with `curl -fsSL https://raw.githubusercontent.com/Aditya-A-G/deskie/main/install.sh | sh`"*.

It downloads the app from this repo's releases (checksum-verified) into `~/Applications`, starts it, and adds the Claude Code plugin. Tom shows up in the top-right corner within seconds. Every Claude chat you already have open shows up on the desk straight away, and new ones join by themselves. No sudo; [read the script](install.sh) first if you like.

Or, without the script, inside Claude Code:

```
/plugin marketplace add Aditya-A-G/deskie
/plugin install deskie@deskie
```

Then run `/reload-plugins` (or start a new Claude session). The first time, the plugin downloads the app in the background, and Tom shows up in the top-right corner in about a minute.

Needs macOS 13 Ventura or later (Apple Silicon and Intel). macOS only for now.

## What it does

| Claude is… | The character… |
| --- | --- |
| working | types at the laptop |
| waiting for your answer or a permission | stands up and waves both arms, with a "!" |
| done | does a little seated dance |
| idle | leans back and naps |

- **Several chats at once:** the small pill on the character's desk shows a dot per chat, in the order you opened their terminal tabs. A dot keeps its place while its chat runs; only its colour changes. (With one chat, the dot shows only while it needs you.)
- **One click:** hover the dots to see every chat by name, in the same order. Click a chat (or its dot) to jump straight to its terminal tab. A waiting chat also shows what Claude asked; click its clock (◷) for **Later**, which stops the wave without opening anything. ⌥-click the character to mark every waiting chat as seen.
- **The first exact-tab jump:** the first time you click a chat in iTerm or Terminal, macOS asks once whether Deskie may control that terminal (Automation). Allow it to land on the exact tab, and Deskie then also keeps the dots in your tabs' real order, even after you drag or close tabs. Say no and Deskie just brings the terminal app forward; it never asks again (you can change it in System Settings → Privacy & Security → Automation).
- **When a jump can't land:** the row says why for a few seconds ("Couldn't find that tab", "Allow Deskie in Settings → Automation" or "Couldn't open it"), and the chat keeps waving until you get to it.
- **Hard to miss:** while a chat waits on you, Deskie waves again with a soft chime every minute (up to 10 times) until you answer, open that chat or click Later.
- **Out of your way:** hover over the character and it fades. Hold ⌥ and drag to move it anywhere. ⌃⌥B hides or shows it (you can change this in Settings).
- **Settings:** from the menu bar icon, or open Deskie again from Spotlight.
- **Always there:** Deskie starts with Claude Code. If it crashes, it comes back with your next message (checked at most every 3 minutes). If you quit it, it stays closed until you start a new Claude session. Turn off **Start with Claude Code** in Settings to keep it closed.

## Privacy

- Nothing is ever sent to us: no account, no tracking, no analytics.
- The plugin in this repo is a few small shell scripts. They send Claude Code's hook events to the Deskie app on `127.0.0.1`, and that's all they do. Read them in [`plugin/bin`](plugin/bin).
- **Updates:** Deskie checks GitHub for a new release 15 seconds after it starts and then once a day (one request to `api.github.com` for this repo's latest release, no data about you), and downloads it from GitHub when there is one. The installer (or the plugin, on first install) downloads the app from this repo's GitHub releases. Nothing else goes over the network from Deskie itself.
- To show every open chat, Deskie reads (never changes) Claude Code's own list of running chats in `~/.claude/sessions` and the end of each chat's transcript, on your Mac.
- One thing does leave your Mac, only through **your own** Claude account: to tell "Claude asked you something" apart from "Claude is done", Deskie sends Claude's last message to Claude Haiku with your own `claude` CLI, with no tools and nothing else loaded. You can turn this off in Settings ("Ask Haiku if Claude asked a question").

## Uninstall

Use **Uninstall Deskie…** in the menu bar icon. Or do it by hand:

```
/plugin uninstall deskie@deskie
/plugin marketplace remove deskie
```

Then delete `~/Applications/Deskie.app` and `~/.desk-buddy`.

## Credits

- Tom: "Tom cat(2.0)from Tom & Jerry" (https://sketchfab.com/3d-models/tom-cat20from-tom-jerry-b98882f3cc154fe297868d16c17306cf) by 兔八哥永远的神！ (https://sketchfab.com/Bugsbunnyisgodforever), licensed under CC-BY-4.0. The colours were tinted and the model was re-rigged for Deskie. Tom and Jerry is owned by Warner Bros. Deskie is a free fan project and isn't affiliated with or endorsed by them.
- Mannequin: the Mixamo X Bot, from the three.js examples.
- Rendered with three.js (MIT).
- Deskie isn't affiliated with Anthropic.

## License

The plugin in this repo is MIT licensed. The Deskie app is free to use.
