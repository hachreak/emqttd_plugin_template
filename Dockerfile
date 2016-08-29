from hachreak/erlang

# ADD http://emqtt.io/downloads/debian /tmp/emqttd.zip

USER root

RUN mkdir -p /src && \
    chown erlang:erlang /src && \
    apt-get update && \
    apt-get install -y libssl1.0.0 unzip build-essential && \
    apt-get remove -y erlang-mode

USER erlang

WORKDIR /src

RUN git clone https://github.com/erlang/rebar3.git && \
    cd rebar3 && \
    ./bootstrap && \
    ./rebar3 local install

RUN git clone -b rebar3_app_loading_compatibility --single-branch https://github.com/hachreak/emqttd.git

WORKDIR /src/emqttd

RUN make all && \
    make plugins && \
    make rel

COPY ./etc/emqttd.config.development /src/emqttd/rel/emqttd/etc/emqttd.config

COPY ./scripts/start.sh /src
COPY ./scripts/recover.sh /src
