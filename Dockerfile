FROM ruby:2.7
EXPOSE 4000
RUN gem install bundler -v 2.4.22
RUN gem install jekyll -v 3.9.5