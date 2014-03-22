#!/bin/bash

# function wrapping the herbstclient command
hc() { "${herbstclient_command[@]:-herbstclient}" "$@" ;}

#==============================================================================
# theme 
#==============================================================================

# load theme file
source $HOME/src/herbstluft/panel_theme.sh

#==============================================================================
# variables 
#==============================================================================

#-geometry---------------------------------------------------------------------

# get monitor dimensions
monitor=${1:-0}
geometry=( $(hc monitor_rect) )

# set panel dimensions
x=${geometry[0]}
y=${geometry[1]}
w=${geometry[2]}
h=$((${geometry[3]}/65))

#-settings---------------------------------------------------------------------

bar_style="-w 33 -h 10 -s o -ss 1 -sw 4 -nonl"
wireless_client="wicd-client"
dzen="dzen2 -x $x -y $y -w $w -h $h -fn $font -ta l -bg $panel_bg -fg $panel_fg"

#==============================================================================
# functions 
#==============================================================================

icon() {
    echo "^bg()^fg($1)^i($2)"
}

bar() {
    echo $1 | gdbar $bar_style -fg $bar_fg_color -bg $bar_bg_color
}

now_playing() {
    mpc -h c8h10n4o2@localhost -f "$now_playing_format" current
}

battery_icon() {
    if [ "$battery_status" == "charging" ]; then
        icon "$battery_charging_icon"
    elif [ "$battery_status" == "discharging" ]; then
        icon "$battery_discharging_icon"
    else
        icon "$battery_missing_icon"
    fi
}

battery_percentage() {
    percentage=$(acpi -b | cut -d "," -f 2 | tr -d " %")
    # this doesn't work, percentage is always shown
    if [ -z "$percentage" ]; then 
        echo "ac"
    elif [ $percentage -le $battery_critical_percentage ] && 
         [ $battery_status == "discharging" ]; then
        echo 100 | gdbar $bar_style -fg $battery_critical_fg_color\
                                    -bg $battery_critical_bg_color
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
    echo "^ca(3, $wireless_client)$quality_bar^ca()"
}

volume() {
    volume=$(amixer get master | egrep -o "[0-9]+%" | tr -d "%")
        echo -n "^ca(1, amixer -q set master 5%-)^ca(3, amixer -q set master 5%+)^ca(2, amixer -q set master toggle)"
        if [ -z "$(amixer get master | grep "\[on\]")" ]; then
                echo -n "$(echo $volume |\
                         gdbar $bar_style -bg $bar_bg_color -fg $bar_bg_color)"
        else
                echo -n "$(bar $volume)"
        fi
        echo "^ca()^ca()^ca()"
}

function uniq_linebuffered() {
   awk '$0 != l { print ; l=$0 ; fflush(); }' "$@"
}

#==============================================================================
# execution  
#==============================================================================

# leave room for the panel
hc pad $monitor $h

#-event-generating-------------------------------------------------------------
{
    # clock
    while true ; do
        date +"date %S"
        sleep 1 || break
    done > >(uniq_linebuffered) &
    childpid=$!

    # herbstluftwm event
    hc --idle

    kill $childpid

} | tee /dev/stderr | {

    # get tags from herbstluft 
    tags=( $(hc tag_status $monitor) )
    date=""
    windowtitle=""

#-draw-tags--------------------------------------------------------------------
    while true ; do
        for i in "${tags[@]}" ; do
            case ${i:0:1} in
                '.')            # tag is empty
                    echo -n "^bg($unused_bg)^fg($unused_fg)"
                    ;;
                ':')            # tag is not empty
                    echo -n "^bg($used_bg)^fg($used_fg)"
                    ;;
                '#')            # currently focused on active monitor
                    echo -n "^bg($active_bg)^fg($active_fg)"
                    ;;
                '+')            # not focused but on active monitor
                    echo -n "^bg($inactive_bg)^fg($inactive_fg)"
                    ;;
                # '-', '%' are still missing
                '!')            # urgent tag
                    echo -n "^bg($urgent_bg)^fg($urgent_fg)"
                    ;;
                *)
                    echo -n "^bg()^fg()"
                    ;;
            esac

            # clickable tags 
            echo -n "^ca(1,\"herbstclient\" "
            echo -n "focus_monitor \"$monitor\" && "
            echo -n "\"${herbstclient_command[@]:-herbstclient}\" "
            echo -n "use \"${i:1}\") ${i:1} ^ca()"
        done

        echo -n "$sep"
        
        # draw window title
        echo -n "^bg($title_bg)^fg($title_fg) ${windowtitle//^/^^}"

#-draw-right-part-of-bar-------------------------------------------------------
        
        right="$sep"

        # draw clock
        right="$right $(icon $icon_color $clock_icon)"
        right="$right $clock_style$time"
        right="$right $date_style$date"
       
        # draw final seperator
        right="$right $sep"
        width=$(textwidth "$font" "|  $time $date |")
        echo -n "^pa($(($w - $width - $icon_width)))$right"

        # Finish output
        echo

#-handle-events----------------------------------------------------------------
        # wait for next event
        read line || break
        cmd=( $line )
        # find out event origin
        echo "Command: ${cmd[0]}" >&2
        case "${cmd[0]}" in
            tag*)
                # reset tags
                tags=( $(hc tag_status $monitor) )
                ;;
            date)
                # reset date
                time=$(date +"$clock_format")
                date=$(date +"$date_format")
                ;;
            quit_panel)
                exit
                ;;
            reload)
                exit
               ;;
            focus_changed|window_title_changed)
                windowtitle="${cmd[@]:2}"
                ;;
        esac
    done
# pipe result to dzen
#} 2> /dev/null | $dzen 
} | $dzen
