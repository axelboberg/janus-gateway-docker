FROM ubuntu:20.04

WORKDIR /opt
ARG DEBIAN_FRONTEND=noninteractive

# Install basic dependencies
RUN apt-get update \
    && apt-get install -y git

# Download janus-gateway
RUN git clone git://github.com/axelboberg/janus-gateway.git

# Download and install Janus' dependencies
RUN apt-get install -y libmicrohttpd-dev libjansson-dev \
	  libssl-dev libsrtp2-dev libsofia-sip-ua-dev libglib2.0-dev \
	  libopus-dev libogg-dev libcurl4-openssl-dev libconfig-dev \
	  pkg-config gengetopt libtool automake libnice-dev build-essential

# Download and install libwebsockets
# from the v4.0-stable -branch
# for the latest stable version
RUN apt-get install -y cmake \
    && git clone https://libwebsockets.org/repo/libwebsockets \
    && cd libwebsockets \
    && git checkout v4.0-stable \
    && mkdir build \
    && cd build \
    && cmake \
      -DLWS_MAX_SMP=1 \
      -DCMAKE_INSTALL_PREFIX:PATH=/usr \
      -DCMAKE_C_FLAGS="-fpic" .. \
    && make \
    && make install \
    && cd ../../ \
    && rm -r libwebsockets

# Install janus-gateway
RUN cd janus-gateway \
    && sh autogen.sh \
    && ./configure \
      --disable-data-channels \
      --disable-rabbitmq \
      --disable-docs \
      --prefix=/opt/janus \
      --disable-all-plugins \
      --enable-plugin-duktape \
      --enable-plugin-videoroom \
      LDFLAGS="-L/usr/local/lib -Wl,-rpath=/usr/local/lib" \
      CFLAGS="-I/usr/local/include" \
    && make \
    && make install \
    && make configs \
    && cd ../ \
    && rm -r janus-gateway

# 8088 - HTTP interface
# 8188 - Websocket interface
EXPOSE 8088 8188

# Start Janus
CMD '/opt/janus/bin/janus'