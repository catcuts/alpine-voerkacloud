#!/usr/bin/bash

export VOERKA_SETTINGS="$VC_SRC/voerka/data/settings/for_test_run_on_192.168.110.12.yaml"
python $VC_SRC/voerka/manage.py db init &> $VC_SRC/db_init_log