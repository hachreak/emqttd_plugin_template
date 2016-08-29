#!/bin/sh

SCRIPT_DIR=`dirname $0`

# Configure rebar3 path
export PATH=$PATH:$HOME/.cache/rebar3/bin

# configure hostname
MYHOSTNAME=`hostname -f`
MYIP=`cat /etc/hosts | grep $MYHOSTNAME | awk '{print $1}'`
cd /src/emqttd/rel/emqttd
sed -i 's/-name emqttd@.*/-name emqttd@'"$MYIP"'/g' etc/vm.args

# clean broken libs and build the plugin again
cd /src/emqttd/rel/emqttd/plugins/emqttd_plugin_template
# don't worry if fail, the rebar.lock creation it's enough
rebar3 compile
for i in `find . -type l -! -exec test -e {} \; -print`; do
  rm $i
done
rebar3 as prod compile
rebar3 as prod release
cd -

# Emqttd stop and clean
./bin/emqttd stop
$SCRIPT_DIR/recover.sh
# Emqttd start
./bin/emqttd start
sleep 5

# plugin loading
./bin/emqttd_ctl plugins unload emqttd_plugin_template
./bin/emqttd_ctl plugins load emqttd_plugin_template
./bin/emqttd_ctl plugins list

# Emqttd configure master/slave
if [ -n "$MASTER" ]; then
  # try to ping master
  ping -c 1 -w 10 $MASTER
  if [ $? = 0 ]; then
    MASTERIP=`ping $MASTER -c 1 | grep ^PING | awk -F"(" '{print $2}' | awk -F")" '{print $1}'`
    echo "Connect `hostname -d` to the master.."
    ./bin/emqttd_ctl cluster join emqttd@${MASTERIP}
    echo "Cluster status:"
    ./bin/emqttd_ctl cluster status
  else
    echo "Node master unreachable.."
  fi
fi

tail -f --retry log/*
