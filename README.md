# yaru-recolor

Rebuild Ubuntu's Yaru cursor theme with custom colors. Single bash script
plus a bundled snapshot of the Yaru cursor PNGs (see `NOTICE`). No build
step, no source compilation. Works on Ubuntu 20.04+ and Debian 11+ (with
GNOME — see below for other desktops).

## Install

Run from the unpacked `yaru-recolor/` directory, one line at a time:

```bash
sudo apt install -y imagemagick x11-apps
install -m 0755 ./yaru-recolor ~/.local/bin/
mkdir -p ~/.local/share/yaru-recolor
cp -r ./yaru-sources ~/.local/share/yaru-recolor/
```

That's it. `imagemagick` gives `convert`, `x11-apps` gives
`xcursorgen`. The bundled `yaru-sources/` (extracted Yaru cursor PNGs +
.conf files) is copied to `~/.local/share/yaru-recolor/` where the
script finds them at runtime — no `xcur2png`, no source builds, no
`yaru-theme-icon` package required.

If `yaru-recolor` isn't on your PATH after install, add `~/.local/bin`:

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc && source ~/.bashrc
```

## First run

```bash
yaru-recolor fill='#FF1493' border='#2CFF05'
```

Rebuilds the cursors with hot-pink fill + neon-green border, writes the theme
to `~/.icons/YaruRecolored`, and switches GNOME to use it. The cursor changes
take effect immediately on Wayland too, but already-open apps may keep their
old cursor until you re-focus them.

## More flags

```bash
yaru-recolor --help     # all options
yaru-recolor --colors   # palette of suggested fill+border combos
```

Five color slots: `fill`, `border`, `highlight`, `shadow`. You can pass any
subset; the rest keep the original Yaru value or are auto-derived from
`fill` + `border`. All pixels (including anti-aliased edges) are smoothly
recolored via a gradient map — no fuzz gaps.

(`shading` is accepted as a deprecated alias for `shadow`.)

## Revert

```bash
yaru-recolor --reset
```

Restores the cursor theme to whatever was active before the most recent apply
(falls back to `Yaru` if there's no saved value). Doesn't delete the
recolored theme directory — re-applying is fast.

## Example: shiny gold

```bash
yaru-recolor fill='#FFD700' border='#7A5008' highlight='#FFF8DC'
```

## Debian notes

Same install steps as Ubuntu. One difference: on Debian 12 (bookworm)
`xcursorgen` is still its own package, so you can `sudo apt install
xcursorgen` instead of (or in addition to) `x11-apps`. Debian 13+ follows
the Ubuntu-24.04 layout and folds it into `x11-apps`. The bundled Yaru
sources mean Debian doesn't need `yaru-theme-icon` installed.

## Non-GNOME desktops (KDE, XFCE, Cinnamon, …)

The auto-apply step uses `gsettings`, which is GNOME-specific. On other
desktops:

```bash
yaru-recolor --no-apply fill='#FF1493' border='#2CFF05'
```

Then either pick `YaruRecolored` in your DE's mouse/cursor settings dialog, or
make it the system default by creating `~/.icons/default/index.theme` with:

```
[Icon Theme]
Inherits=YaruRecolored
```

## Files

- `~/.local/bin/yaru-recolor` — the script
- `~/.local/share/yaru-recolor/yaru-sources/` — bundled cursor source PNGs
- `~/.icons/YaruRecolored/` — generated theme
- `~/.icons/YaruRecolored/.previous-theme` — saved name for `--reset`

Nothing outside `~/.icons/` and `~/.local/` is touched. To uninstall
completely:

```bash
yaru-recolor --reset
rm -rf ~/.icons/YaruRecolored ~/.local/share/yaru-recolor
rm ~/.local/bin/yaru-recolor
```
