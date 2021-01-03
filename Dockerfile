FROM andrius/alpine-ruby
WORKDIR /app-dir/
COPY Gemfile .
COPY Gemfile.lock .
RUN bundle update --bundler &&\
    rm Gemfile Gemfile.lock

RUN apk add -f \
      ruby-json \
      vim
