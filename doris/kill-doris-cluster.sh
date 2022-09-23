#!/bin/bash

# set -e

echo -e "\n\n\n\n
#############################
kill doris fe
kill -9 \$(pgrep -f 'doris.PaloFe')
#############################
"
# kill -9 "$(ps -ef | grep -v 'grep' | grep 'doris.PaloFe' | awk '{print $2}')"
kill -9 "$(pgrep -f 'doris.PaloFe')"

echo -e "\n\n\n\n
#############################
kill doris be
kill -9 \$(pgrep -f 'doris_be')
#############################
"
# kill -9 "$(ps -ef | grep -v 'grep' | grep 'doris_be' | awk '{print $2}')"
kill -9 "$(pgrep -f 'doris_be')"


if ps -ef | grep -v 'grep' | grep 'doris.PaloFe'; then exit 1;fi
if ps -ef | grep -v 'grep' | grep 'doris_be'; then exit 1;fi
