FROM debian:bookworm-slim

ARG RUNNER_VERSION=latest
ARG DEBIAN_FRONTEND=noninteractive

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        gnupg \
        jq \
        lsb-release \
        sudo \
        tar \
        unzip \
        wget \
        xz-utils \
        zip; \
    install -d -m 0755 /etc/apt/keyrings; \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
        | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg; \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" \
        > /etc/apt/sources.list.d/nodesource.list; \
    curl -fsSL https://packages.sury.org/php/apt.gpg \
        | gpg --dearmor -o /etc/apt/keyrings/sury-php.gpg; \
    echo "deb [signed-by=/etc/apt/keyrings/sury-php.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" \
        > /etc/apt/sources.list.d/sury-php.list; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        git \
        nodejs \
        php8.1 \
        php8.1-bcmath \
        php8.1-cli \
        php8.1-common \
        php8.1-curl \
        php8.1-gd \
        php8.1-intl \
        php8.1-mbstring \
        php8.1-mysql \
        php8.1-opcache \
        php8.1-soap \
        php8.1-sqlite3 \
        php8.1-xml \
        php8.1-zip; \
    curl -fsSL https://getcomposer.org/installer -o /tmp/composer-setup.php; \
    php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer; \
    rm -f /tmp/composer-setup.php; \
    corepack enable || true; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    useradd --create-home --shell /bin/bash runner; \
    usermod -aG sudo runner; \
    echo "runner ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/runner; \
    chmod 0440 /etc/sudoers.d/runner; \
    install -d -o runner -g runner /home/runner/actions-runner /home/runner/_work

WORKDIR /home/runner/actions-runner

RUN set -eux; \
    arch="$(dpkg --print-architecture)"; \
    case "$arch" in \
        amd64) runner_arch="x64" ;; \
        arm64) runner_arch="arm64" ;; \
        *) echo "Unsupported architecture: $arch" >&2; exit 1 ;; \
    esac; \
    if [[ "$RUNNER_VERSION" == "latest" ]]; then \
        resolved_version="$(curl -fsSL https://api.github.com/repos/actions/runner/releases/latest | jq -r '.tag_name | sub("^v"; "")')"; \
    else \
        resolved_version="$RUNNER_VERSION"; \
    fi; \
    curl -fsSL \
        "https://github.com/actions/runner/releases/download/v${resolved_version}/actions-runner-linux-${runner_arch}-${resolved_version}.tar.gz" \
        -o /tmp/actions-runner.tar.gz; \
    tar -xzf /tmp/actions-runner.tar.gz; \
    rm -f /tmp/actions-runner.tar.gz; \
    ./bin/installdependencies.sh; \
    chown -R runner:runner /home/runner/actions-runner /home/runner/_work

COPY --chown=runner:runner scripts/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod 0755 /usr/local/bin/entrypoint.sh

USER runner

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
