FROM ruby:2.5-slim

COPY Gemfile Gemfile.lock /usr/src/app/
WORKDIR /usr/src/app

RUN apt-get update && apt-get -y install curl jq libgmp3-dev ruby-dev build-essential libsqlite3-dev && \
    bundle install && \
    apt-get autoremove -y --purge && \
    apt-get remove -y --auto-remove --purge ruby-dev libgmp3-dev build-essential libsqlite3-dev && \
    apt-get clean && \
    rm -rvf /root/* /root/.gem* /var/cache/*

COPY . /usr/src/app
RUN chmod +x /usr/src/app/startup.sh

# helpful when trying to update gems -> bundle update, remove the Gemfile.lock, start ruby
# RUN bundle update
# RUN rm -vf /usr/src/app/Gemfile.lock

HEALTHCHECK --interval=10s --timeout=3s \
  CMD curl -f -s http://localhost:3000/health/ || exit 1
EXPOSE 3000
ENTRYPOINT ["bash","/usr/src/app/startup.sh"]
