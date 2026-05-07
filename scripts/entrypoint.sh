#!/usr/bin/env bash
set -euo pipefail

cd /home/runner/actions-runner

usage() {
    cat <<'USAGE'
Usage:
  docker compose run --rm github-runner --configure-only
  docker compose run --rm github-runner --url https://github.com/owner/repo --token TOKEN --configure-only

Options:
  --url URL              GitHub repository or organization URL.
  --token TOKEN          GitHub runner registration token.
  --name NAME            Runner name. Defaults to container hostname.
  --labels LABELS        Comma-separated labels. Defaults to self-hosted,linux,node22,php${PHP_VERSION}.
  --group GROUP          Runner group. Defaults to Default.
  --work DIR             Work directory. Defaults to RUNNER_WORKDIR or /home/runner/_work.
  --replace              Replace an existing runner with the same name. Default.
  --no-replace           Do not replace an existing runner with the same name.
  --ephemeral            Register an ephemeral one-job runner.
  --remove-on-exit       Deregister the runner when the container exits. Requires token.
  --configure-only       Register the runner and exit without starting it.
  --help                 Show this help.

After the first successful registration, start normally:
  docker compose up -d
USAGE
}

github_url=""
runner_token=""
runner_name="$(hostname)"
runner_labels="self-hosted,linux,node22,php${PHP_VERSION:-8.1}"
runner_group="Default"
runner_workdir="${RUNNER_WORKDIR:-/home/runner/_work}"
runner_replace="true"
runner_ephemeral="false"
remove_on_exit="false"
configure_only="false"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --url)
            github_url="${2:-}"
            shift 2
            ;;
        --token)
            runner_token="${2:-}"
            shift 2
            ;;
        --name)
            runner_name="${2:-}"
            shift 2
            ;;
        --labels)
            runner_labels="${2:-}"
            shift 2
            ;;
        --group)
            runner_group="${2:-}"
            shift 2
            ;;
        --work)
            runner_workdir="${2:-}"
            shift 2
            ;;
        --replace)
            runner_replace="true"
            shift
            ;;
        --no-replace)
            runner_replace="false"
            shift
            ;;
        --ephemeral)
            runner_ephemeral="true"
            shift
            ;;
        --remove-on-exit)
            remove_on_exit="true"
            shift
            ;;
        --configure-only)
            configure_only="true"
            shift
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        --)
            shift
            break
            ;;
        -*)
            echo "Unknown option: $1" >&2
            usage >&2
            exit 2
            ;;
        *)
            exec "$@"
            ;;
    esac
done

mkdir -p "${runner_workdir}"

cleanup() {
    if [[ "${remove_on_exit}" == "true" && -f .runner && -n "${runner_token}" ]]; then
        ./config.sh remove --unattended --token "${runner_token}" || true
    fi
}

stop_runner() {
    if [[ -n "${runner_pid:-}" ]]; then
        kill "${runner_pid}" 2>/dev/null || true
        wait "${runner_pid}" 2>/dev/null || true
    fi
}

prompt_if_needed() {
    if [[ -z "${github_url}" ]]; then
        if [[ -t 0 ]]; then
            read -r -p "GitHub URL: " github_url
        else
            echo "GitHub URL is required on first start." >&2
            echo "Run interactively: docker compose run --rm github-runner --configure-only" >&2
            echo "Or pass arguments: docker compose run --rm github-runner --url URL --token TOKEN --configure-only" >&2
            exit 1
        fi
    fi

    if [[ -z "${runner_token}" ]]; then
        if [[ -t 0 ]]; then
            read -r -s -p "Runner registration token: " runner_token
            echo
        else
            echo "Runner registration token is required on first start." >&2
            echo "Run interactively: docker compose run --rm github-runner --configure-only" >&2
            echo "Or pass arguments: docker compose run --rm github-runner --url URL --token TOKEN --configure-only" >&2
            exit 1
        fi
    fi
}

trap cleanup EXIT
trap 'stop_runner; exit 130' INT
trap 'stop_runner; exit 143' TERM

if [[ ! -f .runner ]]; then
    prompt_if_needed

    config_args=(
        --unattended
        --url "${github_url}"
        --token "${runner_token}"
        --name "${runner_name}"
        --work "${runner_workdir}"
        --labels "${runner_labels}"
        --runnergroup "${runner_group}"
    )

    if [[ "${runner_replace}" == "true" ]]; then
        config_args+=(--replace)
    fi

    if [[ "${runner_ephemeral}" == "true" ]]; then
        config_args+=(--ephemeral)
    fi

    ./config.sh "${config_args[@]}"
else
    echo "Existing GitHub Actions runner configuration found. Skipping registration."
fi

if [[ "${configure_only}" == "true" ]]; then
    exit 0
fi

./run.sh &
runner_pid="$!"
wait "${runner_pid}"
