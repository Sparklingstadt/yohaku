# Vercel（framework: container）用のイメージ。
ARG RUBY_VERSION=3.4.1
FROM ruby:${RUBY_VERSION}-slim AS base
WORKDIR /rails
ENV RAILS_ENV=production BUNDLE_DEPLOYMENT=1 BUNDLE_PATH=/usr/local/bundle BUNDLE_WITHOUT=development:test
RUN apt-get update -qq && apt-get install --no-install-recommends -y libyaml-0-2 && rm -rf /var/lib/apt/lists/*

FROM base AS build
RUN apt-get update -qq && apt-get install --no-install-recommends -y build-essential git libyaml-dev pkg-config && rm -rf /var/lib/apt/lists/*
COPY Gemfile Gemfile.lock ./
RUN bundle install && rm -rf /usr/local/bundle/ruby/*/cache
COPY . .
RUN bundle exec bootsnap precompile app/ lib/ || true

FROM base
RUN groupadd --system --gid 1000 rails && useradd rails --uid 1000 --gid 1000 --create-home
COPY --chown=rails:rails --from=build /usr/local/bundle /usr/local/bundle
COPY --chown=rails:rails --from=build /rails /rails
USER 1000:1000
ENV PORT=3000 RAILS_LOG_TO_STDOUT=1
EXPOSE 3000
CMD ["/rails/bin/vercel-start"]
