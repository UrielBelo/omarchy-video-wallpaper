# omarchy-video-wallpaper

Animated (video) wallpapers for [Omarchy](https://omarchy.org/), picked from
the same grid picker Omarchy already uses for static backgrounds — mix
regular images and looping mp4s side by side, switch between them with one
keybinding, and drop new videos into a watched folder without touching a
config file.

Mostly a handful of shell scripts plus a keybinding, built on top of
[`mpvpaper`](https://github.com/GhostNaN/mpvpaper) and Hyprland — not on the
Omarchy shell's plugin runtime. See [How it works](#how-it-works) if you're
curious why. A thin Quattro bar-widget is included too, for a clickable bar
icon that opens the same picker; it's optional and doesn't replace the
scripts below (see [Optional: bar icon](#optional-bar-icon-quattro-plugin)).

## Credit

Built while testing wallpapers from
[mylivewallpapers.com](https://mylivewallpapers.com/) — a good source of
free, loopable 4K video wallpapers. Nothing here is affiliated with that
site; it's just where the test videos in my own setup came from. Any mp4
works, from anywhere.

## Features

- **One picker for everything** — static backgrounds and video wallpapers
  show up together in `omarchy-menu-images`, the same thumbnail grid
  Omarchy's own background switcher uses.
- **Theme-independent** — the video you pick stays active across theme
  switches. Nothing here hooks into theme-set; switching themes never turns
  your video off or back on.
- **Drop-in videos** — put an `.mp4`/`.webm`/`.mkv` in
  `~/.config/omarchy/videos/` and a thumbnail appears in the picker within a
  couple of seconds, generated automatically with `ffmpeg`.
- **Survives reloads** — a background watcher re-asserts the video on top
  after theme switches, `hyprctl reload`, and monitor changes, which would
  otherwise silently bury it behind Omarchy's background layer (see below).
- **Light on resources** — tuned `mpv` options turn off the demuxer's
  network-oriented cache and cap decoder threads, since a short local file
  on loop doesn't need either. One mpv process serves every monitor.

## Requirements

- Omarchy on Hyprland (Wayland).
- [`mpvpaper`](https://aur.archlinux.org/packages/mpvpaper) — AUR:
  `yay -S mpvpaper`.
- `inotify-tools`, `socat`, `ffmpeg` — official repos:
  `sudo pacman -S inotify-tools socat ffmpeg`.

## Install

```bash
git clone https://github.com/UrielBelo/omarchy-video-wallpaper.git
cd omarchy-video-wallpaper
./install.sh
```

Then, by hand (the installer doesn't touch your Hyprland config for you):

1. Add the three `o.launch_on_start(...)` lines from
   [`examples/autostart.lua.snippet`](examples/autostart.lua.snippet) to
   `~/.config/hypr/autostart.lua`.
2. Add a keybinding from
   [`examples/bindings.lua.snippet`](examples/bindings.lua.snippet) to
   `~/.config/hypr/bindings.lua` — any free key combo works, it's just a
   normal `o.bind(...)` call.
3. `hyprctl reload`, log out and back in (autostart only runs at Hyprland
   start), then drop a video into `~/.config/omarchy/videos/` and press your
   bound key.

## Usage

Press your bound key (`SUPER + SHIFT + W` in the examples) to open the
picker. It shows your current theme's static backgrounds next to every video
in `~/.config/omarchy/videos/`. Pick an image to go back to a normal static
background (this also stops the video); pick a video thumbnail to start it
looping across every connected monitor.

Add more videos any time by copying them into
`~/.config/omarchy/videos/` — no restart needed.

## Optional: bar icon (Quattro plugin)

`manifest.json` + `BarWidget.qml` at the repo root make this installable as
an Omarchy shell plugin too — adds a 🎬 icon to the bar that opens the same
picker on click (`omarchy plugin add <this-repo-url>`, then
`omarchy plugin enable io.github.urielbelo.video-wallpaper`; rename the ID in
`manifest.json` first if you fork this).

This is a convenience trigger only — it does **not** replace the setup
above. The bar icon just runs the bundled `omarchy-wallpaper-picker`; the
daemons that start your video at login, pick up new files, and keep it on
top across reloads still come from `install.sh` + the autostart lines. An
earlier version tried to own all of that from inside a Quattro `service`
plugin kind, but third-party services didn't get activated reliably in
testing (the `bar-widget` kind works fine — it's specifically `service` that
didn't). If you figure out what's missing there, a PR is very welcome.

## How it works

Omarchy's shell renders the static background as a layer-shell surface on
each output. There's no supported way for a third-party process to render
*into* that same surface, so this plays video with
[`mpvpaper`](https://github.com/GhostNaN/mpvpaper), which opens its own
independent layer-shell surface on the background layer, right alongside
Omarchy's. Whichever of the two last mapped its surface on a given output
ends up stacked on top there.

That's fine while nothing changes — but Omarchy's shell tears down and
recreates its background layer on every output as part of reacting to a
theme switch, `hyprctl reload`, or a monitor being added or removed. If that
recreation happens *after* mpvpaper last mapped its layer, the shell ends up
on top and silently hides the video, even though mpvpaper is still running
and decoding frames underneath. There's no compositor event for "the shell
is done re-laying-out," so `omarchy-video-wallpaper-reload-watch` just
listens for Hyprland's `configreloaded` event and tells
`omarchy-video-wallpaper reassert` to recheck the stacking order (via
`hyprctl layers`) and restart mpvpaper until it's confirmed on top across a
few consecutive checks, rather than guessing a fixed delay.

The currently active video is tracked the same way Omarchy tracks the
active static background: a symlink, at
`~/.local/state/omarchy/current/video-wallpaper`. Nothing here is theme-aware
— the symlink is the only state.

### Scripts

| Script | Role |
|---|---|
| `omarchy-video-wallpaper` | Core: `set <video>`, `stop`, `start`, `reassert`, `current`. Everything else calls into this. |
| `omarchy-video-wallpaper-thumbs` | Generates/prunes one JPG thumbnail per video via `ffmpeg`. |
| `omarchy-video-wallpaper-watch` | Watches the videos folder with `inotifywait` and reruns the thumbnailer on change. |
| `omarchy-video-wallpaper-reload-watch` | Watches Hyprland's IPC socket and calls `reassert` after every config reload. |
| `omarchy-wallpaper-picker` | The picker itself: merges static backgrounds and video thumbnails in one `omarchy-menu-images` call, and applies whichever you pick. |

## Known limitation

The reassert loop is a mitigation for a real stacking race, not a guarantee
— on an unusually slow reload it could in theory still lose. In practice,
across repeated testing (multiple theme switches back to back, with a
third/headless monitor being added and removed), it has reliably landed the
video on top within a few seconds every time.

## License

MIT — see [LICENSE](LICENSE).
