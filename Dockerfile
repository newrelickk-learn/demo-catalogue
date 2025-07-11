FROM ruby:3.0.2

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - &&\
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list &&\
    apt-get -y update && apt-get install -y yarn nodejs
# throw errors if Gemfile has been modified since Gemfile.lock
RUN useradd -u 1000 -m -s /bin/bash appuser
USER 1000
RUN gem uninstall bundler
RUN gem install bundler --version '2.2.22'
RUN bundle config --global frozen 1

RUN mkdir /home/appuser/webapp

WORKDIR /home/appuser/webapp

COPY ./app ./app
COPY ./bin ./bin
COPY ./vendor ./vendor
COPY ./config ./config
COPY ./db ./db
COPY ./lib ./lib
COPY ./public ./public
COPY ./storage ./storage
COPY ./config.ru ./
COPY ./babel.config.js ./
COPY ./.browserslistrc ./
COPY ./.ruby-version ./
COPY ./Rakefile ./
COPY ./package.json ./
COPY ./yarn.lock ./

COPY Gemfile Gemfile.lock ./
RUN mkdir -p tmp/pids

USER root
RUN gem update --system
RUN chmod 644 config/master.key
RUN chown -R appuser:appuser /home/appuser/webapp
USER 1000
RUN bundle install
RUN bundle exec rails assets:precompile RAILS_ENV=production
ARG COMMIT_SHA="sha"
ARG RELEASE_TAG="dev"
ENV NEW_RELIC_METADATA_COMMIT=$COMMIT_SHA
ENV NEW_RELIC_METADATA_HOGE=fuga
ENV NEW_RELIC_METADATA_RELEASE_TAG=$RELEASE_TAG
ENV NEW_RELIC_CODE_LEVEL_METRICS_ENABLED=true
ENV NEW_RELIC_RULES_IGNORE_URL_REGEXES="health"

CMD ["rails", "server", "--environment", "production"]
