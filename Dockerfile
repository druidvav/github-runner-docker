FROM debian:trixie-slim

ARG RUNNER_VERSION=latest
ARG PHP_VERSION=8.1
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
        openssh-client \
        rsync \
        "php${PHP_VERSION}-bcmath" \
        "php${PHP_VERSION}-cli" \
        "php${PHP_VERSION}-common" \
        "php${PHP_VERSION}-curl" \
        "php${PHP_VERSION}-gd" \
        "php${PHP_VERSION}-imagick" \
        "php${PHP_VERSION}-intl" \
        "php${PHP_VERSION}-mbstring" \
        "php${PHP_VERSION}-memcached" \
        "php${PHP_VERSION}-mysql" \
        "php${PHP_VERSION}-opcache" \
        "php${PHP_VERSION}-soap" \
        "php${PHP_VERSION}-sqlite3" \
        "php${PHP_VERSION}-xml" \
        "php${PHP_VERSION}-zip"; \
    phpenmod -v "${PHP_VERSION}" imagick memcached; \
    php -r '$required = ["json", "curl", "ftp", "soap", "openssl", "fileinfo", "imagick", "mbstring", "dom", "zip", "simplexml", "memcached", "libxml"]; foreach ($required as $extension) { if (!extension_loaded($extension)) { fwrite(STDERR, "Missing PHP extension: {$extension}\n"); exit(1); } }'; \
    curl -fsSL https://getcomposer.org/installer -o /tmp/composer-setup.php; \
    composer_version_args=(); \
    if [[ "${PHP_VERSION}" == "7.4" ]]; then \
        composer_version_args=(--version=2.2); \
    fi; \
    php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer "${composer_version_args[@]}"; \
    rm -f /tmp/composer-setup.php; \
    composer --version; \
    corepack enable; \
    npm install -g grunt-cli; \
    corepack --version; \
    grunt --version; \
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

ENV HOME=/home/runner

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
