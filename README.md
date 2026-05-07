# GitHub Self-Hosted Runner

Dockerized GitHub Actions self-hosted runner with Node.js 22 from NodeSource, configurable PHP from Sury packages, OpenSSH client tools, and rsync.

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
environment:
  PHP_VERSION: "8.1"
  RUNNER_WORKDIR: /home/runner/_work
volumes:
  - ./data/actions-runner:/home/runner/actions-runner
  - ./data/work:/home/runner/_work
```

Create local data directories:

```bash
mkdir -p data/actions-runner data/work
```

Build the image:

```bash
docker compose build
```

`network_mode: host` avoids Docker creating a separate network namespace. This is useful on restricted hosts where container startup fails while Docker tries to set `net.ipv4.ip_unprivileged_port_start`.

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

After the first successful registration, runner configuration is kept in `./data/actions-runner`, and workflow files are kept in `./data/work`.

## Normal Start

Start the already configured runner:

```bash
docker compose up -d
```

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
rm -rf data/actions-runner data/work
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
labels: self-hosted,linux,node22,php8.1 when PHP_VERSION=8.1
group: Default
workdir: RUNNER_WORKDIR or /home/runner/_work
replace: true
```

This image does not mount the host Docker socket and does not install Docker CLI inside the runner.
