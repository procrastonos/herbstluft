#!/bin/bash

# function wrapping the herbstclient command
hc() { "${herbstclient_command[@]:-herbstclient}" "$@" ;}

#==============================================================================
# theme 
#==============================================================================

# load theme file
source $HOME/.config/herbstluftwm/panel_theme.sh

#==============================================================================
# variables 
#==============================================================================

#-geometry---------------------------------------------------------------------

# get monitor dimensions
monitor=${1:-0}
geometry=( $(hc monitor_rect $monitor) )

# set panel dimensions
x=${geometry[0]}
y=${geometry[1]}
w=${geometry[2]}
h=$((${geometry[3]}/65))

#-settings---------------------------------------------------------------------

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
    if [ "$battery_status" == "Full" ]; then
        echo $(icon $icon_color $battery_full_icon)
    elif [ "$battery_status" == "Charging" ]; then
        echo $(icon $icon_color $battery_charging_icon)
    elif [ "$battery_status" == "Discharging" ]; then
        echo $(icon $icon_color $battery_discharging_icon)
    else
        echo $(icon $icon_color $battery_missing_icon)
    fi
}

battery_percentage() {
    percentage=$(acpi -b | egrep -o "[0-9]+%" | tr -d '%')
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
    battery_status=$(acpi -b | egrep -o "(Full|Charging|Discharging|Unknown)")
    echo $(battery_icon)
}

volume() {
    volume=$(amixer get Master | egrep -o "[0-9]+%" | tr -d "%")
        echo -n "^ca(1, amixer -q set Master 5%-)"
        echo -n "^ca(3, amixer -q set Master 5%+)"
        echo -n "^ca(2, amixer -q set Master toggle)"
        if [ -z "$(amixer get Master | grep "\[on\]")" ]; then
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
    # conky
    conky -c $HOME/.conky/statusbar | while read -r conky_reply; do
        echo -e "conky $conky_reply";
    done > >(uniq_linebuffered) &
    childpid=$!

    # herbstluftwm event
    hc --idle

    kill $childpid

} | tee /dev/stderr | {

    # get tags from herbstluft 
    tags=( $(hc tag_status $monitor) )
    date=""
    conky=""
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

#==============================================================================
# draw right part of bar
#==============================================================================
        
#-parse-conky-stats------------------------------------------------------------
        # parse conky stats 
        IFS='|' read -ra conky_stats <<< "$conky"
        for i in "${conky_stats[@]}"; do
            read -ra stat <<< "$i"
            case "${stat[0]}" in
                UPTIME)
                    uptime="${stat[@]:1}"
                    ;;
                CPU)
                    cpu="${stat[@]:1}"
                    ;;
                TIME)
                    time="${stat[@]:1}"
                    ;;
                DATE)
                    date="${stat[@]:1}"
                    ;;
            esac
        done

        right="$sep "
        text="|"
        width=0

#-draw-volume------------------------------------------------------------------
        right="$right $(icon $volume_icon_color $volume_icon)"
        right="$right $(volume)"
        right="$right $sep"
        text="$text   |"
        width=$(($width+$icon_width*2))

#-draw-cpu---------------------------------------------------------------------
        if [ ${#cpu} == 2 ]; then
            # pad cpu string
            cpu=" $cpu"
        fi
        right="$right $(icon $cpu_icon_color $cpu_icon)"
        right="$right $cpu_style$cpu"
        right="$right $sep"
        text="$text  $cpu |"
        width=$(($width+$icon_width))

#-draw-mpd---------------------------------------------------------------------
        playing=$(now_playing)
        if [ ! -z "$playing" ]; then
            right="$right $(icon $icon_color $now_playing_icon)"
            right="$right $playing_style$playing" 
            right="$right $sep"
            text="$text  $playing |"
            width=$(($width+icon_width))
        fi

#-draw-battery-----------------------------------------------------------------
        right="$right $(battery)"
        right="$right $(battery_percentage)"
        right="$right $sep"
        text="$text   |"
        width=$(($width+icon_width*3))

#-draw-clock-------------------------------------------------------------------
        right="$right $(icon $icon_color $clock_icon)"
        right="$right $date_style$date"
        right="$right $clock_style$time"
        right="$right $sep"
        text="$text  $time $date |"
        width=$(($width+$icon_width))
       
#-finish-output----------------------------------------------------------------
        text="$text| "
        width=$(($width+$(textwidth "$font" "$text"))) 

        echo -n "^pa($(($w - $width)))$right"
        echo

#==============================================================================
# handle events
#==============================================================================
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
            conky*)
                conky="${cmd[@]:1}"
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
# use this for debug messages
} | $dzen
