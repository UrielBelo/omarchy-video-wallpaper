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

### 1. Dependencies

```bash
yay -S mpvpaper                                 # AUR
sudo pacman -S inotify-tools socat ffmpeg       # official repos
```

### 2. Get the scripts

```bash
git clone https://github.com/UrielBelo/omarchy-video-wallpaper.git
cd omarchy-video-wallpaper
./install.sh
```

This copies the five `bin/omarchy-*` scripts to `~/.local/bin/` and creates
`~/.config/omarchy/videos/`. Verify:

```bash
command -v omarchy-video-wallpaper && echo ok
```

### 3. Wire it into Hyprland

The installer doesn't touch your Hyprland config — add these yourself:

1. **Autostart** — append the three `o.launch_on_start(...)` lines from
   [`examples/autostart.lua.snippet`](examples/autostart.lua.snippet) to
   `~/.config/hypr/autostart.lua`. These start the service, the folder
   watcher, and the reload watcher at login.
2. **Keybinding** — append a binding from
   [`examples/bindings.lua.snippet`](examples/bindings.lua.snippet) to
   `~/.config/hypr/bindings.lua`. Any free key combo works; the snippet uses
   `SUPER + SHIFT + W` and shows how to free it up first if you want that
   exact one (it's bound to Omawrite by default on a stock install).
3. Reload Hyprland so the new bindings take effect:
   ```bash
   hyprctl reload
   ```
   Autostart only runs when Hyprland itself starts, so the three
   `launch_on_start` entries need a full logout/login (or a reboot) to take
   effect the first time.

### 4. First run

1. Drop a video into the watched folder:
   ```bash
   cp /path/to/some-video.mp4 ~/.config/omarchy/videos/
   ```
2. Press your bound key. The picker should open showing your current theme's
   static backgrounds plus a thumbnail for the video you just copied
   (thumbnail generation takes a couple of seconds on the first drop).
3. Click the video thumbnail. It should start looping across every connected
   monitor within a second or two.

If the thumbnail never appears, check that the watcher is actually running:
`pgrep -af omarchy-video-wallpaper-watch` (empty output means step 3 above
didn't take effect yet — re-check autostart.lua and that you've logged out
and back in since editing it).

### Uninstall

```bash
omarchy-video-wallpaper stop
rm ~/.local/bin/omarchy-video-wallpaper ~/.local/bin/omarchy-video-wallpaper-* ~/.local/bin/omarchy-wallpaper-picker
```

Then remove the lines you added to `autostart.lua` and `bindings.lua`, and
delete `~/.config/omarchy/videos/` and
`~/.cache/omarchy/video-wallpaper-thumbs/` if you don't want to keep the
videos/thumbnails around.

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
didn't).

**The click doesn't currently work** — see [Known issues](#known-issues)
below. Use the keybinding in the meantime.

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

## Troubleshooting

- **Video doesn't start**: check `omarchy-video-wallpaper current` (prints
  the active video path, or nothing). If it prints a path but nothing is
  playing, run `omarchy-video-wallpaper start` by hand and read its output;
  `pgrep -x mpvpaper` should show one process afterward.
- **Video is hidden behind the static background** after a theme switch or
  reload: confirm `omarchy-video-wallpaper-reload-watch` is running
  (`pgrep -af omarchy-video-wallpaper-reload-watch`). If it's not, re-check
  the autostart.lua lines and log out/in once.
- **New video doesn't show up in the picker**: confirm
  `omarchy-video-wallpaper-watch` is running the same way; its only job is
  regenerating thumbnails when the folder changes. You can also force a
  refresh by hand: `omarchy-video-wallpaper-thumbs`.
- **`mpvpaper: command not found`**: it's AUR-only, not in the official
  repos — `yay -S mpvpaper`.

## Known issues

- **Reassert is a mitigation, not a guarantee.** The stacking race described
  above (video vs. Omarchy's background layer) is resolved by re-checking and
  retrying for a few seconds after every reload, not by an actual fix to the
  underlying race. On an unusually slow reload it could in theory still lose.
  In practice, across repeated testing (multiple theme switches back to back,
  with a third/headless monitor being added and removed), it has reliably
  landed the video on top within a few seconds every time.
- **The bar-widget's click doesn't fire.** The Quattro plugin (see above)
  loads with no errors and the icon renders in the bar, but clicking it does
  not currently trigger `WidgetButton`'s `onPressed` in testing — the
  manifest, path resolution, and `bar.run()` call all check out against the
  official reference, so this looks like a Quattro-side quirk specific to
  third-party `bar-widget` click handling rather than a bug in this plugin.
  Until it's resolved, use the keybinding (step 3 above) instead of the bar
  icon. A PR is very welcome if you track it down.

## License

MIT — see [LICENSE](LICENSE).
