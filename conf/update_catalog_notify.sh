#!/usr/bin/env bash

ID=__UPTIME_KUMA_ID__

if [[ "$SERVICE_RESULT" == "success" ]]; then
    status=up
    msg=
else
    status=down
    msg="$SERVICE_RESULT ($EXIT_CODE $EXIT_STATUS)"
fi

curl --get --data-urlencode "status=$status" --data-urlencode "msg=$msg" "https://status.yunohost.org/api/push/$ID"

if [ "$EXIT_STATUS" != "0" ]; then
    mail -s "Error updating __APP__ !" root <<EOF
Here is the end of the log:

$(tail -n 30 /var/log/appstore/update_catalog.log)

EOF
fi
