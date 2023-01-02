FROM ruby:3.2.0-alpine
RUN mkdir /app
COPY Gemfile Gemfile.lock LICENSE Rakefile README.md shard_utils.rb spec /app/
ENTRYPOINT ["/app/shard_utils.rb"]
CMD "help"
