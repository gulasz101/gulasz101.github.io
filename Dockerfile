FROM ruby:3-alpine

ENV JEKYLL_VAR_DIR=/var/jekyll
# ENV JEKYLL_DOCKER_TAG=<%= @meta.tag %>
# ENV JEKYLL_VERSION=<%= @meta.release?? @meta.release : @meta.tag %>
# ENV JEKYLL_DOCKER_COMMIT=<%= `git rev-parse --verify HEAD`.strip %>
# ENV JEKYLL_DOCKER_NAME=<%= @meta.name %>
ENV JEKYLL_DATA_DIR=/srv/jekyll
ENV JEKYLL_BIN=/usr/jekyll/bin
ENV JEKYLL_ENV=development

RUN apk update
RUN apk add git build-base openssl-dev

EXPOSE 4000
EXPOSE 35729

WORKDIR /srv/jekyll

RUN git clone https://github.com/gulasz101/gulasz101.github.io.git /srv/jekyll
RUN bundle update
RUN bundle install

CMD ["jekyll", "serve", "--livereload", "--host", "0.0.0.0"]

VOLUME /srv/jekyll
