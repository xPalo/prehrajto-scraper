FROM ruby:3.3.6

WORKDIR /prehrajto-scraper
RUN apt-get update -qq && apt-get install -y postgresql-client

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .
RUN bundle exec rake assets:precompile
RUN chmod +x bin/docker-entrypoint

EXPOSE 8080
CMD ["bin/rails", "server", "-b", "0.0.0.0", "-p", "8080"]
