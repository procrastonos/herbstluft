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
    echo "^bg(${1})^fg(${2}) ^i($icon_path/${3}.xbm) ^bg()^fg()"
}

bar() {
    bar_height=$(echo "$h*$bar_h" | bc)
    echo $3 | gdbar -w $bar_w -h $bar_height $bar_style -bg ${1} -fg ${2}
}

function uniq_linebuffered() {
   awk '$0 != l { print ; l=$0 ; fflush(); }' "$@"
}

#-widgets----------------------------------------------------------------------

battery_icon() {
    if [ "$battery_status" == "Full" ]; then
        echo $(icon $battery_icon_style $battery_full_icon)
    elif [ "$battery_status" == "Charging" ]; then
        echo $(icon $battery_icon_style $battery_charging_icon)
    elif [ "$battery_status" == "Discharging" ]; then
        echo $(icon $battery_icon_style $battery_discharging_icon)
    else
        echo $(icon $battery_icon_style $battery_missing_icon)
    fi
}

battery_percentage() {
    # TODO support more than one battery
    if [ -z "${1}" ]; then 
        echo "ac"
    elif [ ${1} -le $battery_critical_percentage ] && 
         [ $battery_status == "Discharging" ]; then
         $(bar $battery_critical_fg_color $battery_critical_bg_color ${1})
    else
        echo -n "$(bar $bar_bg $bar_fg ${1})"
    fi
}

battery() {
    # TODO support more than one battery
    battery_status=$(acpi -b | egrep -o "Battery 0.*" |\
        egrep -o "(Full|Charging|Discharging|Unknown)")
    echo $(battery_icon)
}

playing() {
    mpc -h passwd@localhost -f "$now_playing_format" current
}

temp() {
    echo -n "$(bar $temp_bar_bg $temp_bar_fg ${1})"
}

volume() {
    volume=$(amixer get Master | egrep -o "[0-9]+%" | tr -d "%")
        echo -n "^ca(1, amixer -q set Master 5%-)"
        echo -n "^ca(3, amixer -q set Master 5%+)"
        echo -n "^ca(2, amixer -q set Master toggle)"
        if [ -z "$(amixer get Master | grep "\[on\]")" ]; then
            echo -n "$(bar $bar_bg $bar_fg $volume)"
        else
            echo -n "$(bar $bar_bg $bar_fg $volume)"
        fi
        echo "^ca()^ca()^ca()"
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
                BAT)
                    bat="${stat[@]:1}"
                    ;;
                TEMPCPU)
                    temp="${stat[@]:1}"
                    ;;
            esac
        done

        right="$sep_style"
        text="$sep"
        width=0

#-draw-volume------------------------------------------------------------------
        right="$right$(icon $volume_icon_style $volume_icon)"
        right="$right$padding"
        right="$right$(volume)"
        right="$right$sep_style"
        text="$text$padding$sep"
        width=$(($width+$icon_width+$bar_w))

#-draw-cpu---------------------------------------------------------------------
        if [ ${#cpu} == 2 ]; then
            # pad cpu string
            cpu=" $cpu"
        fi
        right="$right$(icon $cpu_icon_style $cpu_icon)"
        right="$right$padding"
        right="$right$cpu_style$cpu"
        right="$right$sep_style"
        text="$text$padding$cpu$sep"
        width=$(($width+$icon_width))

#-draw-cpu-temp----------------------------------------------------------------
        right="$right$(icon $temp_icon_style $temp_icon)"
        right="$right$padding"
        right="$right$(temp $temp)"
        right="$right$sep_style"
        text="$text$padding$sep"
        width=$(($width+$icon_width+$bar_w))

#-draw-mpd---------------------------------------------------------------------
        playing=$(now_playing)
        if [ ! -z "$playing" ]; then
            right="$right$(icon $playing_icon_style $now_playing_icon)"
            right="$right$padding"
            right="$right$playing_style$playing" 
            right="$right$sep_syle"
            text="$text$padding$playing$sep"
            width=$(($width+$icon_width))
        fi

#-draw-battery-----------------------------------------------------------------
        right="$right$(battery $bat)"
        right="$right$padding"
        right="$right$(battery_percentage $bat)"
        right="$right$sep_style"
        text="$text$padding$sep"
        width=$(($width+$icon_width+$bar_w))

#-draw-clock-------------------------------------------------------------------
        right="$right$(icon $clock_icon_style $clock_icon)"
        right="$right$padding"
        right="$right$date_style$date"
        right="$right$padding"
        right="$right$clock_style$time"
        right="$right$sep_style"
        text="$text$padding$time$padding$date$sep"
        width=$(($width+$icon_width))
       
#-finish-output----------------------------------------------------------------
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
