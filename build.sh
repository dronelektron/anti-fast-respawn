#!/bin/bash

PLUGIN_CORE_NAME="anti-fast-respawn"
PLUGIN_PUNISH_NAME="anti-fast-respawn-punishment"

cd scripting
echo ================ Core ================
spcomp $PLUGIN_CORE_NAME.sp -i include -o ../plugins/$PLUGIN_CORE_NAME.smx
echo ================ Punish ================
spcomp $PLUGIN_PUNISH_NAME.sp -o ../plugins/$PLUGIN_PUNISH_NAME.smx
