# =============================================
# Builder stage
FROM ruby:3.4.8-alpine AS builder

ENV APP_ROOT=/usr/src/app
WORKDIR $APP_ROOT

# Install build dependencies
RUN apk add --no-cache \
    build-base \
    git \
    nodejs \
    postgresql-dev \
    tzdata \
    curl-dev \
    yaml-dev \
    libffi-dev \
    zlib-dev

# Copy Gemfiles
COPY Gemfile Gemfile.lock $APP_ROOT/

# Install Ruby dependencies
RUN gem update --system \
 && gem install bundler foreman \
 && bundle config --global frozen 1 \
 && bundle config set without 'test' \
 && bundle install --jobs 2

# Copy application code
COPY . $APP_ROOT

# Precompile bootsnap cache
RUN bundle exec bootsnap precompile --gemfile app/ lib/

# Precompile assets for production
RUN RAILS_ENV=production bundle exec rake assets:precompile

# =============================================
# Final stage
FROM ruby:3.4.8-alpine

ENV APP_ROOT=/usr/src/app
ENV DATABASE_PORT=5432
WORKDIR $APP_ROOT

# Install runtime dependencies only
RUN apk add --no-cache \
    bash \
    nodejs \
    postgresql-libs \
    tzdata \
    curl \
    yaml \
    jemalloc \
    netcat-openbsd

ENV LD_PRELOAD=/usr/lib/libjemalloc.so.2
ENV RUBY_YJIT_ENABLE=1

# Copy gems from builder
COPY --from=builder /usr/local/bundle /usr/local/bundle

# Copy application code
COPY . $APP_ROOT

# Copy precompiled assets and bootsnap cache from builder
COPY --from=builder $APP_ROOT/public/assets $APP_ROOT/public/assets
COPY --from=builder $APP_ROOT/tmp/cache $APP_ROOT/tmp/cache

# Startup
CMD ["bin/docker-start"]
