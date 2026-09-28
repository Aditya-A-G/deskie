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

Inside Claude Code:

```
/plugin marketplace add Aditya-A-G/deskie
/plugin install deskie@deskie
```

Or just tell Claude: *"install the deskie plugin from github.com/Aditya-A-G/deskie"*.

Start a new Claude session. The first time, Deskie sets itself up, and the character shows up in the top-right corner in about a minute.

macOS only for now (Apple Silicon and Intel).

## What it does

| Claude is… | The character… |
| --- | --- |
| working | types at the laptop |
| waiting for your answer or a permission | stands up and waves both arms, with a "!" |
| done | does a little seated dance |
| idle | leans back and naps |

- **Several chats at once:** each Claude session shows as a dot under the character. Hover the dots to see every chat by name, and click one to jump back to its terminal.
- **Out of your way:** hover over the character and it fades. Hold ⌥ and drag to move it anywhere. ⌃⌥B hides or shows it (you can change this in Settings).
- **Settings:** from the menu bar icon, or open Deskie again from Spotlight.

## Privacy

- Everything stays on your Mac: no account, no tracking.
- The plugin in this repo is a few small shell scripts. They send Claude Code's hook events to the Deskie app on `127.0.0.1`, and that's all they do. Read them in [`plugin/bin`](plugin/bin).
- To tell "Claude asked you something" apart from "Claude is done", Deskie asks Claude Haiku through **your own** `claude` login, with no tools and nothing else loaded. You can turn this off in the menu.

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
