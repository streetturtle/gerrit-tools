#!/usr/bin/env bash

GERRIT_HOST=$1
PATH_TO_ICON=$2

url_encode () {
    echo $(sed -e 's/ /%20/g' \
   -e 's/!/%21/g' \
   -e 's/"/%22/g' \
   -e 's/#/%23/g' \
   -e 's/\&/%26/g' \
   -e 's/'\''/%28/g' \
   -e 's/(/%28/g' \
   -e 's/)/%29/g' \
   -e 's/:/%3A/g' \
   -e 's/\//%2F/g'<<<$1)
}

get_open_reviews() {
    encoded=$(url_encode "status:open AND NOT is:wip AND is:reviewer")
    curl -s -X GET -n ${GERRIT_HOST}/a/changes/\?q\=${encoded} | tail -n +2
}

get_user_name_by_id() {
    curl -s -X GET -n ${GERRIT_HOST}/accounts/$1/name | tail -n +2
}

if [[ -z $DBUS_SESSION_BUS_ADDRESS ]]; then
    pgrep "$XDG_SESSION_DESKTOP" -u "$USER" | while read -r line; do
        exp=$(cat /proc/$line/environ | grep -z "^DBUS_SESSION_BUS_ADDRESS=")
        echo export "$exp" > ~/.exports.sh
        break
    done
    if [[ -f ~/.exports.sh ]]; then
        source ~/.exports.sh
    fi
fi


if [[ ! -e /tmp/gerrit-notif ]]; then
    echo '0' > /tmp/gerrit-notif
fi

current_open_reviews=$(get_open_reviews)
current_open_reviews_num=$(echo ${current_open_reviews} | jq '. | length')
prev_open_reviews_num=$(cat /tmp/gerrit-notif)

echo ${current_open_reviews_num} > /tmp/gerrit-notif

if (($current_open_reviews_num > $prev_open_reviews_num)); then
    n=$(echo ${current_open_reviews} | jq -r '.[0] | ("Project: " + .project +  "\nSubject: " + .subject)')
    acc_id=$(echo ${current_open_reviews} | jq '.[0] | (.owner._account_id)')
    owner="\nOwner: $(get_user_name_by_id ${acc_id})"

    /usr/bin/notify-send "New Review" "${n} ${owner}" -i ${PATH_TO_ICON}
fi
