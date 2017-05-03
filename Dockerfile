FROM ruby:2.3.0

# update apt-get
RUN apt-get update -qq

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

ENV APP_HOME /cut-notifications
RUN mkdir $APP_HOME
WORKDIR $APP_HOME

ADD Gemfile $APP_HOME
ADD Gemfile.lock $APP_HOME
RUN gem install bundler
RUN bundle install

ADD . $APP_HOME

CMD ["bundle", "exec", "foreman", "start"]
