# Icon Viewer

A native Crystal GUI for browsing [Radix](https://github.com/kojix2/icon-radix), [Fluent](https://github.com/kojix2/icon-fluent), [Octicons](https://github.com/kojix2/icon-octicons), [Eva](https://github.com/kojix2/icon-eva), and [Ionicons](https://github.com/kojix2/icon-ionic), built with [UIng](https://github.com/kojix2/uing).

Choose a collection and size/style variant, search by name, then preview an icon and copy its Crystal constant. Results are paged in groups of 256. Icon PNGs are decoded when displayed.

## Run

Install Crystal and the platform prerequisites for UIng, then:

```sh
shards install
shards build
./bin/icon-viewer
```

The UIng shard downloads a libui-ng binary during installation.

## Adding a collection

Add its shard to `shard.yml` and register it in `src/icon_catalog.cr`. `scripts/png_catalog.cr` reads each shard's `src/data/*.tsv` at compile time; the collection and variant selectors update automatically.

## License

Application code: MIT. Icon shards retain their own licenses.
