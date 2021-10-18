#!/bin/bash

spcomp scripting/afr.sp -i scripting/include -o plugins/afr.smx
spcomp scripting/afr-attack-blocker.sp -i scripting/include -o plugins/afr-attack-blocker.smx
spcomp scripting/afr-commands.sp -i scripting/include -o plugins/afr-commands.smx
spcomp scripting/afr-map-warnings.sp -i scripting/include -o plugins/afr-map-warnings.smx
spcomp scripting/afr-menu.sp -i scripting/include -o plugins/afr-menu.smx
spcomp scripting/afr-punishment.sp -i scripting/include -o plugins/afr-punishment.smx
