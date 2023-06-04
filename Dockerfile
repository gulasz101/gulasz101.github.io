FROM ruby:3.0-alpine

ENV BUNDLE_HOME=/usr/local/bundle
ENV BUNDLE_APP_CONFIG=/usr/local/bundle
ENV BUNDLE_DISABLE_PLATFORM_WARNINGS=true
ENV BUNDLE_BIN=/usr/local/bundle/bin
ENV GEM_BIN=/usr/gem/bin
ENV GEM_HOME=/usr/gem
ENV RUBYOPT=-W0

ENV JEKYLL_VAR_DIR=/var/jekyll
# ENV JEKYLL_DOCKER_TAG=<%= @meta.tag %>
# ENV JEKYLL_VERSION=<%= @meta.release?? @meta.release : @meta.tag %>
# ENV JEKYLL_DOCKER_COMMIT=<%= `git rev-parse --verify HEAD`.strip %>
# ENV JEKYLL_DOCKER_NAME=<%= @meta.name %>
ENV JEKYLL_DATA_DIR=/srv/jekyll
ENV JEKYLL_BIN=/usr/jekyll/bin
ENV JEKYLL_ENV=development

RUN apk update
RUN apk add --no-cache build-base gcc cmake git

RUN echo "gem: --no-ri --no-rdoc" > ~/.gemrc
RUN unset GEM_HOME && unset GEM_BIN && \
  yes | gem update --system

#
# Gems
# Main
#

RUN unset GEM_HOME && unset GEM_BIN && yes | gem install --force bundler
RUN gem install jekyll -v "3.9.3" 
RUN gem install \
    html-proofer \
    jekyll-reload \
    jekyll-mentions \
    jekyll-coffeescript \
    jekyll-sass-converter \
    jekyll-commonmark \
    jekyll-paginate \
    jekyll-compose \
    jekyll-assets \
    RedCloth \
    kramdown \
    jemoji \
    jekyll-redirect-from \
    jekyll-sitemap \
    jekyll-feed \
    minima \
    jekyll-github-metadata \
    github-pages \
    kramdown-parser-gfm

RUN bundle init 
RUN bundle add jekyll --version "3.9.3" \
  && bundle add webrick \
  && bundle add minima \
  && bundle add kramdown-parser-gfm \
  && bundle update

EXPOSE 4000
EXPOSE 35729

WORKDIR /srv/jekyll
VOLUME /srv/jekyll

CMD ["jekyll", "--help"]
