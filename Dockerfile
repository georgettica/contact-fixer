FROM ruby:slim-buster
WORKDIR /app-dir/
COPY Gemfile .
COPY Gemfile.lock .
RUN bundle update --bundler &&\
    rm Gemfile Gemfile.lock

RUN apt update && \
    apt install -y \
      ruby-json \
      vim && \
    rm -rf /var/lib/apt/lists/*
