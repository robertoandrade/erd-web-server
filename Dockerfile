FROM haskell:7.8
MAINTAINER Roberto Andrade <me@robertoandrade.com>

ENV APP_DIR /app/
ENV BUILD_DIR $APP_DIR/dist/build/erd-web-server
ENV APP_PORT 8000

# Installing Prerequisites 
RUN apt-get update && \
	apt-get install -y graphviz && \
	apt-get clean && \
	cabal update

# Building web app
WORKDIR $APP_DIR

COPY erd-web-server.cabal $APP_DIR
RUN cabal install --only-dependencies

COPY src $APP_DIR/src
RUN cabal install

# Copying web artifacts required at runtime only
COPY . $APP_DIR

# Starting
EXPOSE $APP_PORT

CMD "$BUILD_DIR/erd-web-server"