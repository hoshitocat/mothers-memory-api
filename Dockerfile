FROM ruby:2.4.2

ENV LANG C.UTF-8
ENV APP_HOME /usr/src/app

RUN mkdir -p $APP_HOME
RUN gem update --system
RUN gem install bundler && gem update bundler
RUN apt-get update -y && apt-get upgrade -y
RUN apt-get install -y libmecab-dev mecab mecab-ipadic-utf8

WORKDIR $APP_HOME

COPY Gemfile \
     Gemfile.lock \
     $APP_HOME/
