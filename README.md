# Radix Icon Viewer

A small, native Crystal GUI for browsing the 332 Radix icons via
the bundled `icon` shard (from [icon-radix](https://github.com/kojix2/icon-radix)) and
[UIng](https://github.com/kojix2/uing).

## Features

- A searchable table containing icon thumbnails and names.
- A large preview and copyable `Icon::Radix::Name` constant field.
- A **native** UIng toolbar, with Radix images for every toolbar action:
  Previous, Next, Random, Clear, Compact, and Help.
- Icon catalog generated at compile time from `Icon::Radix.constants`;
  it stays in sync when new icons are added.

## Run

Install Crystal and the platform prerequisites for UIng, then:

```sh
shards install
crystal run src/radix_icon_viewer.cr
```

For a release build:

```sh
shards build --release
./bin/radix-icon-viewer
```

The UIng shard downloads an appropriate libui-ng binary at installation time.
The `icon` shard is included in `vendor/icon` so `require "icon/radix"` works
before the renamed shard is published. If you work offline, supply the UIng
binary and install the remaining dependencies in `lib/`.

## Implementation notes

The source icons are shared `CrImage` constants and are converted once to
owned `UIng::Image` objects. The Table and Toolbar borrow those images;
ImageView copies its selected image. On closing, the Toolbar and Table are
released before their shared images, and the Table is destroyed before its
model is freed.

## License

Example application code: MIT. Dependencies retain their own licenses.
