#!/usr/bin/env bash
# ame.sh
#set -x

WIDTH=`xwininfo -id $WINDOWID | grep Width: | sed -e "s/\s*Width:\s*\(.*\)/\1/"`

function ame_init() {
    deps=(curl convert)
    for d in "${deps[@]}"; do
        if ! type $d > /dev/null 2>&1; then
            echo "$d not found"
            exit 1
        fi
    done
    if [ ! -d ~/.ame ]; then
        mkdir -p ~/.ame
    fi
    if [ ! -f ~/.ame/map000.jpg ]; then
        curl -s -o ~/.ame/map000.jpg https://tokyo-ame.jwa.or.jp/map/map000.jpg
    fi
    if [ ! -f ~/.ame/msk000.png ]; then
        curl -s -o ~/.ame/msk000.png https://tokyo-ame.jwa.or.jp/map/msk000.png
    fi
}

function ame_print() {
    SIZE="${WIDTH}x"
    TIME=$1
    LABEL=${TIME:8:2}:${TIME:10}
    URI=https://tokyo-ame.jwa.or.jp/mesh/000/${TIME}.gif
    curl -s -o ~/.ame/tmp.gif "$URI"
    convert ~/.ame/map000.jpg \
            ~/.ame/tmp.gif \
	        -compose over \
            -composite \
            ~/.ame/msk000.png \
            -composite \
            -undercolor white -stroke gray -pointsize 26 -gravity south -annotate 0 " ${LABEL} " \
            -resize ${SIZE} \
            sixel:-
}

function ame_last() {
    LAST=`curl -s https://tokyo-ame.jwa.or.jp/scripts/mesh_index.js \
           |sed -e 's/[^0-9,]//g' |tr -s ',' '\n' |head -1`
    ame_print "${LAST}"
}

function ame_play() {
    INDEX=`curl -s https://tokyo-ame.jwa.or.jp/scripts/mesh_index.js \
         |sed -e 's/[^0-9,]//g' |tr -s ',' '\n' |tac`
    declare -a TIMES=()
    for t in $INDEX; do
        TIMES+=( ${t} )
        ame_print $t
        sleep 0.5
    done
    i=$((${#TIMES[@]}-1))
    while IFS= read -r -n1 -s c; do
        if [[ $c == $'\x1b' ]]; then
            read -r -n2 -s rest
            c+="$rest"
        fi
        case $c in
            l | j | $'\x1b\x5b\x43' | $'\x1b\x5b\x42')
                let i++
                if [ $i -ge ${#TIMES[@]} ]; then
                    i=$((${#TIMES[@]}-1))
                fi
                ame_print ${TIMES[$i]}
                echo "time: ${TIMES[$i]}"
                ;;
            h | k | $'\x1b\x5b\x44' | $'\x1b\x5b\x41')
                let i--
                if [ $i -lt 0 ]; then
                    i=0
                fi
                ame_print ${TIMES[$i]}
                echo "time: ${TIMES[$i]}"
                ;;
        esac
    done
}

function usage() {
    echo "Usage: $0 [--play]" 1>&2
    exit 1
}

while getopts :h:play opt
do
    case $opt in
        h)
            usage
            ;;
        p)
            ame_init
            ame_play
            exit
            ;;
    esac
done

ame_init
ame_last
