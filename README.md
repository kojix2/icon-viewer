# Icon Viewer

A native Crystal GUI for browsing [Radix](https://github.com/kojix2/icon-radix), [Fluent](https://github.com/kojix2/icon-fluent), [Octicons](https://github.com/kojix2/icon-octicons), [Eva](https://github.com/kojix2/icon-eva), and [Ionicons](https://github.com/kojix2/icon-ionic), built with [UIng](https://github.com/kojix2/uing).

Choose a collection and size/style variant, search by name, then preview an icon and copy its Crystal constant. Results are paged in groups of 256. Icon PNGs are decoded when displayed.

## Screenshots

Screenshots are refreshed when a release is built.

| Linux | Windows | macOS |
| --- | --- | --- |
| ![Icon Viewer on Linux](https://raw.githubusercontent.com/kojix2/icon-viewer/screenshots/icon-viewer-ubuntu.png) | ![Icon Viewer on Windows](https://raw.githubusercontent.com/kojix2/icon-viewer/screenshots/icon-viewer-windows.png) | ![Icon Viewer on macOS](https://raw.githubusercontent.com/kojix2/icon-viewer/screenshots/icon-viewer-macos.png) |

## Download

Download the archive for your platform from [Releases](https://github.com/kojix2/icon-viewer/releases):

- **Linux x64:** Extract `icon-viewer-linux-x64.tar.gz` and run `icon-viewer`. GTK 3 must be installed.
- **Windows x64:** Extract `icon-viewer-windows-x64.zip` and run `icon-viewer.exe`.
- **macOS Apple Silicon:** Extract `icon-viewer-macos-arm64.zip` and open `IconViewer.app`. The app is not notarized. If macOS blocks it, use **System Settings → Privacy & Security → Open Anyway** after the first launch attempt.

## Run

Install Crystal and the platform prerequisites for UIng, then:

```sh
shards install
shards build
./bin/icon-viewer
```

The UIng shard downloads a libui-ng binary during installation.

## Adding a collection

Add its shard to `shard.yml` and call its compile-time catalog macro in `src/icon_catalog.cr`. The collection and variant selectors update automatically.

## License

Application code: MIT. Icon shards retain their own licenses.
