#!/usr/bin/env bash
set -Eeuo pipefail

if [[ -z "${UPTIME_KUMA_KEY}" ]]; then
    echo "Please define the environment variable UPTIME_KUMA_KEY!"
    exit 1
fi

if [[ "$SERVICE_RESULT" == "success" ]]; then
    status=up
    msg=
else
    status=down
    msg="$SERVICE_RESULT ($EXIT_CODE $EXIT_STATUS)"
fi

curl --get --data-urlencode "status=$status" --data-urlencode "msg=$msg" "https://status.yunohost.org/api/push/$UPTIME_KUMA_KEY"
