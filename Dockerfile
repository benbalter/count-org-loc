FROM ruby:alpine

WORKDIR /src

RUN apk update && apk add git cloc

RUN sh -c "git clone https://github.com/benbalter/count-org-loc ." && \
    gem install bundler && \
    bundle install

ENTRYPOINT ["./script/count"]
