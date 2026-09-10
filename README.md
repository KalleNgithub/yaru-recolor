# yaru-recolor

Rebuild Ubuntu's Yaru cursor theme with custom colors. Single bash script
plus a bundled snapshot of the Yaru cursor PNGs (see `NOTICE`). No build
step, no source compilation. Works on Ubuntu 20.04+ and Debian 11+ (with
GNOME — see below for other desktops).

## Install

```bash
git clone https://github.com/KalleNgithub/yaru-recolor.git
cd yaru-recolor
./install.sh
```

That's it. The script installs dependencies (`imagemagick`, `x11-apps`),
copies the script to `~/.local/bin/` and the cursor sources to
`~/.local/share/yaru-recolor/`. Do not run with `sudo` — it asks for
your password only for the `apt install` step.

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

Undoes everything this tool has done, in one command: restores the cursor
theme to whatever was active before the most recent apply (falls back to
`Yaru` if there's no saved value), and — if `--snap` was ever used — also
fully undoes that (restores the original `gtk-common-themes` mount and host
`Yaru` cursors). You never need to remember a separate command for the snap
side; `--reset` figures out what needs undoing on its own. Doesn't delete
the recolored theme directory — re-applying is fast.

## Snap apps (Firefox, Thunderbird, Discord, ...)

```bash
yaru-recolor fill='#FF1493' border='#2CFF05' --snap
```

`--snap` is easy to miss, so you don't actually have to remember the flag:
if you omit it on a system with snapd + `gtk-common-themes` installed,
you'll be asked interactively whether to also patch snap apps. Say yes once
and it becomes **sticky** — every future recolor (even without `--snap`)
re-applies the snap patch automatically. Skipped entirely on non-interactive
runs or systems without snapd.

Strict-confinement snaps don't read `~/.icons` or `/usr/share/icons` for
cursor themes — they get them through the `gtk-common-themes` snap's content
interface, whose `icon-themes` slot exports a **fixed list of theme names
hardcoded in its `meta/snap.yaml`**. `YaruRecolored` isn't on that list (and
adding a new name to it isn't possible without rebuilding/reinstalling the
snap in a way that breaks trust for strict-confinement consumers), but
`Yaru` is.

So `--snap` takes a different approach: it overwrites the *cursor files*
inside the already-allow-listed `Yaru` theme — both the copy bundled in the
`gtk-common-themes` snap and your system's `/usr/share/icons/Yaru` — with
your recolor, then switches the active cursor theme to plain `Yaru` (not
`YaruRecolored`), since that's the one name that works everywhere. Concretely
it:

1. Copies the installed `gtk-common-themes` snap's content into a work dir
   and overwrites `share/icons/Yaru/cursors` with your recolored cursors.
2. Rebuilds that into a squashfs image (`~/.local/share/yaru-recolor/snap-patch/`).
3. Backs up (once) and overwrites `/usr/share/icons/Yaru/cursors` on the host
   the same way, so non-snap apps stay in sync under the same theme name.
4. Holds `gtk-common-themes` auto-refresh (`snap refresh --hold=forever`) so
   a store update doesn't silently overwrite the patch.
5. Points gtk-common-themes' own systemd mount unit at the patched squashfs
   via a drop-in (`/etc/systemd/system/snap-gtk\x2dcommon\x2dthemes-<rev>.mount.d/`),
   instead of raw-mounting over it. This matters: that mount is itself a
   systemd `.mount` unit that other snaps' background services pull in as a
   dependency (`snapd.mounts.target`). A bare `mount` bypasses systemd's own
   bookkeeping for the unit, so the next time anything re-triggers that
   target — which happens routinely within the first minute after boot, as
   other snap services start — systemd can silently restart the unit back
   to its own original definition, undoing a raw mount within seconds. A
   drop-in makes the patched squashfs the unit's actual, authoritative
   `What=`, so systemd enforces it instead of fighting it. This is also what
   makes the patch **survive reboots automatically**, with no separate boot
   service needed.
6. Discards the mount namespace of every snap connected to
   `gtk-common-themes:icon-themes`, and force-quits any that are still
   running (after asking for confirmation), so their *next* launch picks up
   the patched content. Just closing windows and reopening isn't enough:
   snapd reuses a persistent per-snap mount namespace across launches, and
   some snaps (e.g. Discord with its tray icon) keep running in the
   background after the window is closed. The only reliable fix is a real
   quit + relaunch *after* the patch is in place.

**Caveats:**
- Needs `sudo` for several steps (mounting, `/usr/share/icons` writes, the
  namespace discard). Always asks before force-quitting connected apps.
- Plain `yaru-recolor --reset` fully undoes it too: removes the mount-unit
  drop-in (restoring the original `gtk-common-themes` mount), restores the
  backed-up host `Yaru/cursors`, and un-holds refreshes — no separate
  command needed.
- Only `Yaru`'s cursors get patched (not `Yaru-dark` etc. — those variants
  have no `cursors` subdir of their own; they inherit Yaru's).
- The primary GNOME Shell desktop pointer (as opposed to individual app
  windows) may not refresh from the gsettings bounce the way snap apps do —
  it's a long-running process like Discord, so it can keep showing the old
  cursor until you log out/in or restart the shell, even though the
  underlying files are already correctly patched.

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
- `~/.local/share/yaru-recolor/snap-patch/` — only created by `--snap`:
  cached patched squashfs + state file, used by `--snap-reapply` and cleaned
  up by `--reset`
- `/usr/share/icons/Yaru/cursors.orig-backup` — only created by `--snap`:
  one-time backup of the stock cursors, restored by `--reset`
- `/etc/systemd/system/snap-gtk\x2dcommon\x2dthemes-<rev>.mount.d/99-yaru-recolor.conf`
  — only created by `--snap`: the drop-in pointing gtk-common-themes' mount
  unit at the patched squashfs, removed by `--reset`

Nothing outside `~/.icons/` and `~/.local/` is touched
(**unless you use `--snap`**, which also writes to `/usr/share/icons/Yaru`
and patches the installed `gtk-common-themes` snap — see above). To
uninstall completely (undoes `--snap` too, then deletes the theme, cached
data, and the script itself):

```bash
yaru-recolor --uninstall
```

