#!/bin/bash

now=$(date)

working_dir=${XDG_CONFIG_HOME:-HOME/.config}/awesome/widget/stock

log() {
    echo $now"  $1" >> $working_dir/fetch-quotes.log
}

if [[ -z "$1" ]]; then
    log "ERROR: Missing symbol. Usage: fetch-quotes.sh SYMBOL"
    exit 1;
fi

cache=$working_dir/cache/$1.cache

# Mon 9:30 AM -> 1093000
# Fri 4:00 PM -> 5160000
day_time=$(date +"%w%H%M%S")
time=$(date +"%H%M%S")

if [[
    -f "$cache" # Cache exists
    && (
        "$day_time" > "5160000" # Past Friday 4PM
        || (
            "$time" > "160000" || "$time" < "093000" # Between 4PM and 9:30AM
        )
    )
    ]]; then
    log "INFO: Retrieving from cache"
    response=$(cat $cache)
else
    request=$(sed "s/%SYMBOL%/$1/g" $working_dir/request.json)
    response=$(curl -sX POST https://app-money.tmx.com/graphql --header 'Content-Type: application/json' -d "$request")
    echo $response > $cache 
fi

echo $response
