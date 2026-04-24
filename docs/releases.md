# Releases

`simplelogin-aio` uses upstream-version-plus-AIO-revision releases such as `v4.79.0-aio.1`.

## Version format

- first wrapper release for upstream `v4.79.0`: `v4.79.0-aio.1`
- second wrapper-only release on the same upstream: `v4.79.0-aio.2`
- first wrapper release after upgrading upstream: `v4.80.0-aio.1`

## Published image tags

Every `main` build publishes:

- `latest`
- the exact pinned upstream version
- `sha-<commit>`

Release commits also publish the immutable packaging line tag, for example `v4.79.0-aio-v1`. Ordinary `main` pushes do not overwrite that release tag.

## Release flow

1. Trigger **Prepare Release / SimpleLogin-AIO** from `main`.
2. The workflow computes the next `upstream-aio.N` version and opens a release PR.
3. Review and merge that PR into `main`.
4. Trigger **Publish Release / SimpleLogin-AIO** from `main`.
5. The workflow reads the merged `CHANGELOG.md` entry, verifies CI passed on the release target commit, creates the Git tag, and publishes the GitHub Release.
