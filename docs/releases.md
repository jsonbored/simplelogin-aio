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
- an explicit packaging line tag like `v4.79.0-aio-v1`
- `sha-<commit>`

## Release flow

1. Trigger **Prepare Release / SimpleLogin-AIO** from `main`.
2. The workflow computes the next `upstream-aio.N` version and opens a release PR.
3. Review and merge that PR into `main`.
4. Let the normal `main` CI publish the image tags after the merge passes pytest and integration.
5. Trigger **Publish Release / SimpleLogin-AIO** from `main`.
6. The workflow reads the merged `CHANGELOG.md` entry, creates the Git tag, and publishes the GitHub Release.
