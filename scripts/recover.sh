#!/bin/sh

MNESIA=/src/emqttd/rel/emqttd/data/mnesia

if [ -d "$MNESIA" ] && [ -n "`echo $MNESIA | grep emqttd`" ]; then
  rm ${MNESIA}/* -Rf
fi
