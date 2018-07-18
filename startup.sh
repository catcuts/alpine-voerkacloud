#!/bin/bash

echo -e "startup.sh: voerkacloud 运行配置(VC_CONFIG_FILE): $VC_CONFIG_FILE"
ls -l $VC_CONFIG_FILE
export VOERKA_SETTINGS="$VC_CONFIG_FILE"
python $VC_SRC/voerka/manage.py run &> $VC_SRC/log
