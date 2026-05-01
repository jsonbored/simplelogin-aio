# Releases

`simplelogin-aio` uses upstream-version-plus-AIO-revision releases such as `v4.79.0-aio.1`.

## Version format

- first wrapper release for upstream `v4.79.0`: `v4.79.0-aio.1`
- second wrapper-only release on the same upstream: `v4.79.0-aio.2`
- first wrapper release after upgrading upstream: `v4.80.0-aio.1`

## Published image tags

Every central `aio-fleet` publish for `main` publishes:

- `latest`
- the exact pinned upstream version
- `sha-<commit>`

Release commits also publish the immutable packaging line tag, for example `v4.79.0-aio-v1`. Ordinary `main` pushes do not overwrite that release tag.

## Release flow

1. From `aio-fleet`, run `python -m aio_fleet release status --repo simplelogin-aio` to inspect the next release.
2. Run `python -m aio_fleet release prepare --repo simplelogin-aio` on a release branch, then open a `chore(release): <version>` PR.
3. Review and merge that PR into `main`.
4. Run the central `aio-fleet` control check for the release target commit with publish enabled, and require `aio-fleet / required` to pass.
5. Run `python -m aio_fleet release publish --repo simplelogin-aio` from `aio-fleet` to create the GitHub Release.
