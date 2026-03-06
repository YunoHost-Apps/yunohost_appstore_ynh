#!/usr/bin/env bash

install_dir=__INSTALL_DIR__

pushd "$install_dir" > /dev/null


git_pull() {
    msg="$1"
    git_was_updated=0
    commit="$(git rev-parse HEAD)"

    if ! git pull &>/dev/null; then
        sendxmpppy "$msg"
        exit 1
    fi

    if [[ "$(git rev-parse HEAD)" == "$commit" ]]; then
        git_was_updated=1
    fi
}

update_venv() {
    if [ ! -d "venv" ]; then
        python3 -m venv venv
    fi
    venv/bin/pip install --upgrade pip > /dev/null
    if [ -f requirements.txt ]; then
        venv/bin/pip install -r requirements.txt > /dev/null
    else
        venv/bin/pip install -e . > /dev/null
    fi
}

reload_store() {
    PIDFile=/run/gunicorn/__APP__-pid
    if [ -f "$PIDFile" ]; then
        kill -s HUP "$(cat "$PIDFile")"
    fi
}

update_git_and_venv() {
    pushd "apps_tools" > /dev/null
    {
        git_pull "[appstore/apps-tools] Couldn't pull, maybe local changes are present?"
        update_venv
    }
    popd > /dev/null

    pushd "__DATA_DIR__/appstore_data/apps" > /dev/null
    {
        git_pull "[appstore/apps] Couldn't pull, maybe local changes are present?"
    }
    popd > /dev/null

    pushd appstore >/dev/null
    {
        git_pull "[appstore] Couldn't pull, maybe local changes are present?"
        update_venv
        ./tools/fetch_assets

        if [[ "${git_was_updated}" == 1 ]]; then
            if ! reload_store; then
                sendxmpppy "[appstore] Couldn't reload appstore, is it down?"
            fi
        fi
    }
    popd > /dev/null
}


main() {
    date
    update_git_and_venv

    apps_tools/venv/bin/python3 apps_tools/app_caches.py \
        -l "__DATA_DIR__/appstore_data/apps" \
        -c "__DATA_DIR__/appstore_data/apps_cache" \
        -d -j20

    apps_tools/venv/bin/python3 apps_tools/list_builder.py \
        -l "__DATA_DIR__/appstore_data/apps" \
        -c "__DATA_DIR__/appstore_data/apps_cache" \
        "__INSTALL_DIR__/catalog/default"

    pushd "appstore"
        # curl https://__DOMAIN__/default/v3/apps.json -so .cache/apps.json
        cp "__INSTALL_DIR__/catalog/default/v3/apps.json" "__DATA_DIR__/appstore_data/apps.json"

        venv/bin/fetch_main_dashboard 2>&1 | grep -v 'Following Github server redirection'
        venv/bin/fetch_level_history
    popd
}

main
