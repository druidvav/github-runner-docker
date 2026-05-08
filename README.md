# GitHub Self-Hosted Runner

Dockerized GitHub Actions self-hosted runner with Node.js 22 from NodeSource, configurable PHP from Sury packages, OpenSSH client tools, and rsync.
Node.js ships with Corepack enabled in this image, so Yarn versions can be pinned by each project through `packageManager` or `yarnPath`. The image also includes global `grunt-cli`.

## First Start

Create local compose config from the distributed template:

```bash
cp docker-compose.yml.dist docker-compose.yml
```

Edit `docker-compose.yml` if needed:

```yaml
network_mode: host
args:
  PHP_VERSION: "8.1"
volumes:
  - runner-config:/home/runner/actions-runner
  - runner-work:/home/runner/_work
```

Build the image:

```bash
docker compose build
```

`network_mode: host` avoids Docker creating a separate network namespace. This is useful on restricted hosts where container startup fails while Docker tries to set `net.ipv4.ip_unprivileged_port_start`.

The base image is fixed to `debian:trixie-slim` because current Sury PHP packages can depend on Debian 13 libraries such as `libicu76` and `libssl3t64`.
Composer is pinned to the 2.2 LTS line automatically when `PHP_VERSION` is `7.4`.

Create a registration token in GitHub:

```text
Settings -> Actions -> Runners -> New self-hosted runner
```

Register the runner interactively and exit:

```bash
docker compose run --rm github-runner --configure-only
```

The container will ask for:

```text
GitHub URL: https://github.com/owner/repo
Runner registration token: ...
```

You can also pass the first-start settings as command arguments:

```bash
docker compose run --rm github-runner \
  --url https://github.com/owner/repo \
  --token YOUR_REGISTRATION_TOKEN \
  --name my-server-runner \
  --labels self-hosted,linux,node22,php8.1 \
  --configure-only
```

For an organization runner, use the organization URL:

```text
https://github.com/owner
```

After the first successful registration, runner configuration is kept in the `runner-config` Docker volume, and workflow files are kept in the `runner-work` Docker volume.

## Normal Start

Start the already configured runner:

```bash
docker compose up -d
```

The compose file uses `stop_signal: SIGINT` and `stop_grace_period: 5m` so `docker compose down` gives the GitHub runner time to close its active session cleanly.

View logs:

```bash
docker compose logs -f github-runner
```

Restart:

```bash
docker compose restart github-runner
```

Remove container but keep runner configuration:

```bash
docker compose down
```

Remove runner data and force a fresh registration next time:

```bash
docker compose down -v
```

## Runner Options

The entrypoint accepts these options during first registration:

```text
--url URL
--token TOKEN
--name NAME
--labels LABELS
--group GROUP
--work DIR
--replace
--no-replace
--ephemeral
--remove-on-exit
--configure-only
```

Defaults:

```text
labels: self-hosted,linux,node22
group: Default
workdir: /home/runner/_work
replace: true
```

This image does not mount the host Docker socket and does not install Docker CLI inside the runner.
