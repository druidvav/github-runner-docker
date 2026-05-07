# GitHub Self-Hosted Runner

Dockerized GitHub Actions self-hosted runner with Node.js 22 from NodeSource and PHP 8.1 from Sury packages.

## First Start

Build the image:

```bash
docker compose build
```

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

After the first successful registration, runner configuration is kept in the `runner-config` Docker volume.

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
labels: self-hosted,linux,node22,php8.1
group: Default
workdir: /home/runner/_work
replace: true
```

This image does not mount the host Docker socket and does not install Docker CLI inside the runner.
