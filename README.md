# Automerge Repo Sync Server

A very simple automerge-repo synchronization server. It pairs with the
websocket client protocol found in
`@automerge/automerge-repo-network-websocket`.

The server is an unsecured [Express](https://expressjs.com/) app. It is partly
for demonstration purposes but it's also a reasonable way to run a public sync
server.

## Running the sync server

`npx @automerge/automerge-repo-sync-server`

Or you can run it locally:

```
pnpm i
pnpm start
```

The server is configured with environment variables. There are two options:

- `PORT` - the port to listen for websocket connections on
- `DATA_DIR` - the directory to store saved documents in

## Running in Docker

Run in docker using image hosted by GitHub container registry:

```bash
docker run -d --name syncserver -p 3030:3030 ghcr.io/automerge/automerge-repo-sync-server:main
```

cleanup after:

```bash
docker stop syncserver
docker rm syncserver
```

## Running with Nix

If you have [Nix](https://nixos.org/) installed with flakes enabled:

**As a NixOS service:**

```nix
{
  services.automerge-sync-server = {
    enable = true;
    port = 3030;
  };
}
```

## Development

### Nix

To support the Nix package, the `npm-deps-hash.nix` must be kept in sync with the `package-lock.json` file.

If Nix is installed, you can simple run `npm run nix:deps` to update it.

If Nix is not available, the Nix GitHub Action workflow will report the correct value to update the file with.

Additionally, the build instructions in `flake.nix` and `.github/workflows/nix.yml` must be kept in sync, though these will change less frequently.

## Contributors

Originally written by @pvh.
