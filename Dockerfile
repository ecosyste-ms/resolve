# =============================================
# Stage 1: Build Go resolve binary
FROM golang:1.25-bookworm AS go-builder

RUN apt-get update && apt-get install -y --no-install-recommends git && rm -rf /var/lib/apt/lists/*
WORKDIR /build
RUN git clone --depth 1 https://github.com/ecosyste-ms/resolve-cli.git .
RUN go mod download
RUN CGO_ENABLED=0 go build -o /resolve-bin ./cmd/resolve

# =============================================
# Stage 2: Build Ruby app
FROM ruby:4.0.2-slim-bookworm AS ruby-builder

ENV APP_ROOT=/usr/src/app
WORKDIR $APP_ROOT

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    libpq-dev \
    libyaml-dev \
    libffi-dev \
    zlib1g-dev \
    libcurl4-openssl-dev \
    nodejs \
 && rm -rf /var/lib/apt/lists/*

COPY Gemfile Gemfile.lock $APP_ROOT/
RUN gem update --system \
 && gem install bundler foreman \
 && bundle config --global frozen 1 \
 && bundle config set without 'test' \
 && bundle install --jobs 4

COPY . $APP_ROOT
RUN bundle exec bootsnap precompile --gemfile app/ lib/
RUN RAILS_ENV=production bundle exec rake assets:precompile

# =============================================
# Stage 3: Runtime with all package managers
FROM debian:bookworm-slim

ENV APP_ROOT=/usr/src/app
ENV DATABASE_PORT=5432
ENV DEBIAN_FRONTEND=noninteractive
WORKDIR $APP_ROOT

# Base dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gnupg \
    git \
    bash \
    libpq5 \
    libyaml-0-2 \
    tzdata \
    netcat-openbsd \
    unzip \
    xz-utils \
 && rm -rf /var/lib/apt/lists/*

# Ruby (copy entire install from builder)
COPY --from=ruby-builder /usr/local/ /usr/local/
RUN ldconfig

# Node.js + npm + yarn + pnpm + bun
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
 && apt-get install -y --no-install-recommends nodejs \
 && npm install -g yarn pnpm \
 && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:${PATH}"

# Python + pip + poetry + uv
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-venv \
 && rm -rf /var/lib/apt/lists/*
RUN pip3 install --break-system-packages poetry
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:${PATH}"

# Rust + cargo
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Go
COPY --from=go-builder /usr/local/go /usr/local/go
ENV PATH="/usr/local/go/bin:${PATH}"

# Java + Maven + Gradle
RUN apt-get update && apt-get install -y --no-install-recommends \
    default-jdk-headless \
    maven \
    gradle \
 && rm -rf /var/lib/apt/lists/*

# .NET SDK (nuget)
RUN curl -fsSL https://dot.net/v1/dotnet-install.sh | bash -s -- --channel 8.0 --install-dir /usr/share/dotnet
ENV PATH="/usr/share/dotnet:${PATH}"
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1

# PHP + Composer
RUN apt-get update && apt-get install -y --no-install-recommends \
    php-cli \
    php-zip \
    php-mbstring \
    php-xml \
    php-curl \
 && rm -rf /var/lib/apt/lists/*
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Dart SDK (pub)
RUN DART_ARCH=$(dpkg --print-architecture | sed 's/amd64/x64/;s/arm64/arm64/') && \
    curl -fsSL "https://storage.googleapis.com/dart-archive/channels/stable/release/latest/sdk/dartsdk-linux-${DART_ARCH}-release.zip" -o /tmp/dart.zip \
 && unzip -q /tmp/dart.zip -d /opt \
 && rm /tmp/dart.zip
ENV PATH="/opt/dart-sdk/bin:${PATH}"

# Elixir + Mix
RUN apt-get update && apt-get install -y --no-install-recommends \
    erlang-base \
    erlang-dev \
    elixir \
 && rm -rf /var/lib/apt/lists/* \
 && mix local.hex --force \
 && mix local.rebar --force

# Swift
RUN SWIFT_ARCH=$(dpkg --print-architecture | sed 's/amd64/x86_64/;s/arm64/aarch64/') && \
    if [ "$SWIFT_ARCH" = "x86_64" ]; then \
      curl -fsSL https://download.swift.org/swift-6.0.3-release/ubuntu2204/swift-6.0.3-RELEASE/swift-6.0.3-RELEASE-ubuntu22.04.tar.gz \
        | tar xz --strip-components=1 -C /usr; \
    else \
      curl -fsSL https://download.swift.org/swift-6.0.3-release/ubuntu2204-aarch64/swift-6.0.3-RELEASE/swift-6.0.3-RELEASE-ubuntu22.04-aarch64.tar.gz \
        | tar xz --strip-components=1 -C /usr; \
    fi

# Helm
RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Deno
RUN curl -fsSL https://deno.land/install.sh | sh
ENV DENO_DIR="/root/.deno"
ENV PATH="/root/.deno/bin:${PATH}"

# Conda (miniconda)
RUN ARCH=$(uname -m) && \
    curl -fsSL https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-${ARCH}.sh -o /tmp/miniconda.sh \
 && bash /tmp/miniconda.sh -b -p /opt/conda \
 && rm /tmp/miniconda.sh
ENV PATH="/opt/conda/bin:${PATH}"

# Build tools needed by stack, native gem extensions, etc.
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libffi-dev \
    libgmp-dev \
    zlib1g-dev \
    netbase \
 && rm -rf /var/lib/apt/lists/*

# Haskell Stack
RUN curl -sSL https://get.haskellstack.org/ | sh

# Leiningen (Clojure)
RUN curl -fsSL https://raw.githubusercontent.com/technomancy/leiningen/stable/bin/lein -o /usr/local/bin/lein \
 && chmod +x /usr/local/bin/lein

# Conan (C/C++)
RUN pip3 install --break-system-packages conan

# Copy Go resolve binary
COPY --from=go-builder /resolve-bin /usr/local/bin/resolve

# Copy Ruby app
COPY . $APP_ROOT
COPY --from=ruby-builder /usr/local/bundle /usr/local/bundle
COPY --from=ruby-builder $APP_ROOT/public/assets $APP_ROOT/public/assets
COPY --from=ruby-builder $APP_ROOT/tmp/cache $APP_ROOT/tmp/cache

ENV RUBY_YJIT_ENABLE=1

CMD ["bin/docker-start"]
