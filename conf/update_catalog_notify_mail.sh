#!/usr/bin/env bash

if [ "$EXIT_STATUS" != "0" ]; then
    mail -s "Error updating __APP__ !" root <<EOF
Here is the end of the log:

$(tail -n 30 /var/log/appstore/update_catalog.log)

EOF
fi
