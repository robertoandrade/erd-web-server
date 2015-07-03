FROM heroku/cedar:14
MAINTAINER Roberto Andrade <me@robertoandrade.com>

# Haskell install

ENV GHCVER 7.8.4
ENV CABALVER 1.22

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
  	software-properties-common \
  	graphviz \
  && add-apt-repository -y ppa:hvr/ghc \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
    cabal-install-$CABALVER \
    ghc-$GHCVER \
  && rm -rf /var/lib/apt/lists/*

ENV PATH /opt/ghc/$GHCVER/bin:/opt/cabal/$CABALVER/bin:$PATH

# Heroku settings

RUN useradd -d /app -m app
USER app
WORKDIR /app

ENV HOME /app
ENV PORT 3000

RUN mkdir -p /app/heroku
RUN mkdir -p /app/src
RUN mkdir -p /app/.profile.d

WORKDIR /app/src

# App build

RUN cabal update

ENV SRC $HOME/src
COPY erd-web-server.cabal $SRC/
RUN cabal install --only-dependencies

RUN mkdir $SRC/generated $SRC/log && \
	touch $SRC/log/access.log $SRC/log/error.log && \
	chown -R app:app generated log

ONBUILD COPY src $SRC/src
ONBUILD RUN cabal install
ONBUILD RUN rm -Rf /app/.cabal /app/.ghc

ONBUILD COPY assets $SRC/assets
ONBUILD COPY templates $SRC/templates
ONBUILD EXPOSE $PORT
