#!/usr/bin/bash

bash run.sh \
-c xxx_voerkacloud \
-i meeyi/voerkacloud:v1.2.python3.6.6.alpine3.7 \
-w $(pwd) \
-d `readlink -f $(pwd)/src` \
-p 8000 \
-m xxx_mysql