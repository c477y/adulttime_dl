FROM ruby:3.1.3-slim-bullseye

ENV DOCKER_ENV=1

RUN apt-get update -y && \
    apt-get install -y \
    git \
    python3 \
    python3-pip \
    build-essential

RUN pip3 install --upgrade youtube_dl

WORKDIR /app

COPY xxx_download.gemspec Gemfile Gemfile.lock ./
COPY lib/xxx_download/version.rb ./lib/xxx_download/

RUN bundle install

COPY . .

#RUN gem build xxx_rename.gemspec
#RUN gem install xxx_rename-0.3.0.gem

CMD ["bash"]
