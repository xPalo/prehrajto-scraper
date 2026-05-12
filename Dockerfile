FROM ruby:3.3.6

WORKDIR /prehrajto-scraper

RUN apt-get update -qq && apt-get install -y \
  postgresql-client \
  python3 python3-pip \
  nodejs npm \
  redis-tools \
  ffmpeg \
  libvidstab-dev \
  && rm -rf /var/lib/apt/lists/*

RUN npm install -g yarn

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY package.json ./
RUN yarn install

COPY . .

RUN pip3 install ryanair-py --break-system-packages
RUN bundle exec rake assets:precompile
RUN chmod +x bin/docker-entrypoint

EXPOSE 8080
CMD ["bin/docker-entrypoint"]