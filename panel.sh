#!/bin/bash

# function wrapping the herbstclient command
hc() { "${herbstclient_command[@]:-herbstclient}" "$@" ;}

#-variables--------------------------------------------------------------------

#==============================================================================
# geometry
#==============================================================================
# get monitor dimensions
MONITOR=${1:-0}
GEOMETRY=( $(hc monitor_rect "$MONITOR") )

# set panel dimensions
X=${GEOMETRY[0]}
Y=${GEOMETRY[1]}
W=${GEOMETRY[2]}
H=$((${GEOMETRY[3]}/65))

#==============================================================================
# colours
#==============================================================================
PANEL_BACKGROUND=$(hc get frame_border_normal_color)
TEXT_ACTIVE="#aaaaaa"
ACTIVE_BACKGROUND=$(hc get window_border_normal_color)
WINDOW_ACTIVE_COLOR=$(hc get window_border_active_color)
SEP_COLOR=$WINDOW_ACTIVE_COLOR
ICON_COLOR="#78a4ff"
BAR_FG_COLOR="#aaaaff"
BAR_BG_COLOR="#000000"
BATTERY_CRITICAL_FG_COLOR="#220000"
BATTERY_CRITICAL_BG_COLOR="#660000"

FG=$BAR_FG_COLOR
BG=$BAR_BG_COLOR

#==============================================================================
# icons 
#==============================================================================
NOW_PLAYING_ICON="$HOME/.icons/note.xbm"
NOW_PLAYING_FORMAT="%artist% - %title%"
BATTERY_CHARGING_ICON="$HOME/.icons/bat_full_01.xbm"
BATTERY_DISCHARGING_ICON="$HOME/.icons/bat_low_01.xbm"
BATTERY_MISSING_ICON="$HOME/.icons/ac_01.xbm"
WIRELESS_ICON="$HOME/.icons/wifi_01.xbm"
VOLUME_ICON="$HOME/.icons/spkr_01.xbm"
CLOCK_ICON="$HOME/.icons/clock.xbm"

#==============================================================================
# style 
#==============================================================================
# set font
CLOCK_FORMAT="%H:%M %d.%m"
SEP="^fg($SEP_COLOR) | ^fg()"
BAR_STYLE="-w 33 -h 10 -s o -ss 1 -sw 4 -nonl"

#==============================================================================
# other 
#==============================================================================
FONT="xft:SourceCodePro:pixelsize=12"
WIRELESS_CLIENT="wicd-client"
BATTERY_CRITICAL_PERCENTAGE=10

#-functions---------------------------------------------------------------------

icon() {
    echo "^fg($ICON_COLOR)^i($1)^fg()"
}

bar() {
    echo $1 | gdbar $BAR_STYLE -fg $BAR_FG_COLOR -bg $BAR_BG_COLOR
}

now_playing() {
    # ncmpcpp version
    # ncmpcpp --now-playing "$NOW_PLAYING_FORMAT"
    # mpc version
    mpc -h c8h10n4o2@localhost -f "$NOW_PLAYING_FORMAT" current
}

battery_icon() {
    if [ "$battery_status" == "Charging" ]; then
        icon "$BATTERY_CHARGING_ICON"
    elif [ "$battery_status" == "Discharging" ]; then
        icon "$BATTERY_DISCHARGING_ICON"
    else
        icon "$BATTERY_MISSING_ICON"
    fi
}

battery_percentage() {
    percentage=$(acpi -b | cut -d "," -f 2 | tr -d " %")
    # this doesn't work, percentage is always shown
    if [ -z "$percentage" ]; then 
        echo "AC"
    elif [ $percentage -le $BATTERY_CRITICAL_PERCENTAGE ] && 
         [ $battery_status == "Discharging" ]; then
        echo 100 | gdbar $BAR_STYLE -fg $BATTERY_CRITICAL_FG_COLOR\
                                    -bg $BATTERY_CRITICAL_BG_COLOR
    else
        bar "$percentage"
    fi
}

battery() {
    battery_status=$(acpi -b | egrep -o "[0-9]+%" | tr -d ',')
    echo $(battery_icon) $(battery_percentage)
}

wireless_quality() {
    quality_bar=$(bar "$(cat /proc/net/wireless | grep wlp3s0 | cut -d ' ' -f 5\
                 | tr -d '.')")
    echo "^ca(3, $WIRELESS_CLIENT)$quality_bar^ca()"
}

volume() {
    volume=$(amixer get Master | egrep -o "[0-9]+%" | tr -d "%")
        echo -n "^ca(1, amixer -q set Master 5%-)^ca(3, amixer -q set Master 5%+)^ca(2, amixer -q set Master toggle)"
        if [ -z "$(amixer get Master | grep "\[on\]")" ]; then
                echo -n "$(echo $volume |\
                         gdbar $BAR_STYLE -bg $BAR_BG_COLOR -fg $BAR_BG_COLOR)"
        else
                echo -n "$(bar $volume)"
        fi
        echo "^ca()^ca()^ca()"
}

clock() {
    echo $(date +"$CLOCK_FORMAT")
}

function uniq_linebuffered() {
   awk '$0 != l { print ; l=$0 ; fflush(); }' "$@"
}

# leave room for the panel
hc pad $MONITOR $HEIGHT

#==============================================================================
# execution  
#==============================================================================
{
    while true ; do
        date +$'date\t^fg(#efefef)%H:%M^fg(#909090), %Y-%m-^fg(#efefef)%d'
        sleep 1 || break
    done > >(uniq_linebuffered) &
    childpid=$!
    hc --idle
    kill $childpid
} 2> /dev/null | {
    IFS=$'\t' read -ra tags <<< "$(hc tag_status $MONITOR)"
    visible=true
    date=""
    windowtitle=""
    while true ; do

        ### Output ###
        # This part prints dzen data based on the _previous_ data handling run,
        # and then waits for the next event to happen.

        bordercolor="#26221C"
        separator="^bg()^fg($selbg)|"
        # draw tags
        for i in "${tags[@]}" ; do
            case ${i:0:1} in
                '#')
                    echo -n "^bg($selbg)^fg($selfg)"
                    ;;
                '+')
                    echo -n "^bg(#9CA668)^fg(#141414)"
                    ;;
                ':')
                    echo -n "^bg()^fg(#ffffff)"
                    ;;
                '!')
                    echo -n "^bg(#FF0675)^fg(#141414)"
                    ;;
                *)
                    echo -n "^bg()^fg(#ababab)"
                    ;;
            esac
            if [ ! -z "$dzen2_svn" ] ; then
                # clickable tags if using SVN dzen
                echo -n "^ca(1,\"${herbstclient_command[@]:-herbstclient}\" "
                echo -n "focus_monitor \"$MONITOR\" && "
                echo -n "\"${herbstclient_command[@]:-herbstclient}\" "
                echo -n "use \"${i:1}\") ${i:1} ^ca()"
            else
                # non-clickable tags if using older dzen
                echo -n " ${i:1} "
            fi
        done
        echo -n "$SEP"
        echo -n "^bg()^fg() ${windowtitle//^/^^}"
        # small adjustments
        right="$SEP^bg() $date $SEP"
        right_text_only=$(echo -n "$right" | sed 's.\^[^(]*([^)]*)..g')
        # get width of right aligned text.. and add some space..
        width=$($textwidth "$FONT" "$right_text_only    ")
        echo -n "^pa($(($W- $width)))$right"
        echo

        ### Data handling ###
        # This part handles the events generated in the event loop, and sets
        # internal variables based on them. The event and its arguments are
        # read into the array cmd, then action is taken depending on the event
        # name.
        # "Special" events (quit_panel/togglehidepanel/reload) are also handled
        # here.

        # wait for next event
        IFS=$'\t' read -ra cmd || break
        # find out event origin
        case "${cmd[0]}" in
            tag*)
                #echo "resetting tags" >&2
                IFS=$'\t' read -ra tags <<< "$(hc tag_status $MONITOR)"
                ;;
            date)
                #echo "resetting date" >&2
                date="${cmd[@]:1}"
                ;;
            quit_panel)
                exit
                ;;
            togglehidepanel)
                currentmonidx=$(hc list_monitors | sed -n '/\[FOCUS\]$/s/:.*//p')
                if [ "${cmd[1]}" -ne "$monitor" ] ; then
                    continue
                fi
                if [ "${cmd[1]}" = "current" ] && [ "$currentmonidx" -ne "$monitor" ] ; then
                    continue
                fi
                echo "^togglehide()"
                if $visible ; then
                    visible=false
                    hc pad $monitor 0
                else
                    visible=true
                    hc pad $monitor $H
                fi
                ;;
            reload)
                exit
                ;;
            focus_changed|window_title_changed)
                windowtitle="${cmd[@]:2}"
                ;;
            #player)
            #    ;;
        esac
    done

    ### dzen2 ###
    # After the data is gathered and processed, the output of the previous block
    # gets piped to dzen2.

} 2> /dev/null | dzen2 -w $W -x $X -y $Y -fn "$FONT" -h $H \
    -e 'button3=' -ta l -bg "$BG" -fg "$FG"
