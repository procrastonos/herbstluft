#!/bin/bash

# functions by http://dotshare.it/~foozer/

# function wrapping the herbstclient command
hc() { "${herbstclient_command[@]:-herbstclient}" "$@" ;}

#-variables---------------------------------------------------------------------
# get current MONITOR size
MONITOR=${1:-0}
GEOMETRY=( $(herbstclient monitor_rect "$MONITOR") )

# dzen settings

# set panel dimensions
X=${GEOMETRY[0]}
Y=${GEOMETRY[1]}
WIDTH=${GEOMETRY[2]}
HEIGHT=$((${GEOMETRY[3]}/75))

# set colours
BG=$(hc get frame_border_normal_color)
SC=$(hc get window_border_active_color)
FG="#101010"

# set font
FONT="xft:SourceCodePro:pixelsize=12"
#FONT="xft:digitalix:pixelsize=12"

# leave room for the panel
hc pad $MONITOR $HEIGHT

ICON_COLOR="#78a4ff"
SEP="^fg(#2a2a2a) | ^fg()"

BAR_STYLE="-w 33 -h 10 -s o -ss 1 -sw 4 -nonl"
BAR_FG_COLOR=$FG_COLOR
BAR_BG_COLOR="#333333"

NOW_PLAYING_ICON="$HOME/.icons/dzen/note.xbm"
NOW_PLAYING_FORMAT="%a - %t"

BATTERY_CHARGING_ICON="$HOME/.icons/dzen/bat_full_01.xbm"
BATTERY_DISCHARGING_ICON="$HOME/.icons/dzen/bat_low_01.xbm"
BATTERY_MISSING_ICON="$HOME/.icons/dzen/ac_01.xbm"
BATTERY_CRITICAL_PERCENTAGE=10
BATTERY_CRITICAL_FG_COLOR="#220000"
BATTERY_CRITICAL_BG_COLOR="#660000"

WIRELESS_ICON="$HOME/.icons/dzen/wifi_01.xbm"
WIRELESS_CLIENT="wicd-client"

VOLUME_ICON="$HOME/.icons/dzen/spkr_01.xbm"

CLOCK_ICON="$HOME/.icons/dzen/clock.xbm"
CLOCK_FORMAT="%H:%M"


#-functions---------------------------------------------------------------------

icon() {
    echo "^fg($ICON_COLOR)^i($1)^fg()"
}

bar() {
    echo $1 | gdbar $BAR_STYLE -fg $BAR_FG_COLOR -bg $BAR_BG_COLOR
}

now_playing() {
    ncmpcpp --now-playing "$NOW_PLAYING_FORMAT"
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
    if [ -z "$percentage" ]; then
        echo "AC"
    elif [ $percentage -le $BATTERY_CRITICAL_PERCENTAGE ] && [ $battery_status == "Discharging" ]; then
        echo 100 | gdbar $BAR_STYLE -fg $BATTERY_CRITICAL_FG_COLOR -bg $BATTERY_CRITICAL_BG_COLOR
    else
        bar "$percentage"
    fi
}

battery() {
    battery_status=$(acpi -b | cut -d ' ' -f 3 | tr -d ',')
    echo $(battery_icon) $(battery_percentage)
}

wireless_quality() {
    quality_bar=$(bar "$(cat /proc/net/wireless | grep wlan0 | cut -d ' ' -f 6 | tr -d '.')")
    echo "^ca(3, $WIRELESS_CLIENT)$quality_bar^ca()"
}

volume() {
    volume=$(amixer get Master | egrep -o "[0-9]+%" | tr -d "%")
        echo -n "^ca(1, amixer -q set Master 5%-)^ca(3, amixer -q set Master 5%+)^ca(2, amixer -q set Master toggle)"
        if [ -z "$(amixer get Master | grep "\[on\]")" ]; then
                echo -n "$(echo $volume | gdbar $BAR_STYLE -bg $BAR_BG_COLOR -fg $BAR_BG_COLOR)"
        else
                echo -n "$(bar $volume)"
        fi
        echo "^ca()^ca()^ca()"
}

clock() {
    echo $(date +$CLOCK_FORMAT)
}

# -------------------------------------------- SCRIPT EXECUTION LOOP, PIPED INTO DZEN2

while :; do
        echo -n "$(icon $NOW_PLAYING_ICON) $(now_playing)$SEP"
        echo -n "$(battery)$SEP"
        echo -n "$(icon $WIRELESS_ICON) $(wireless_quality)$SEP"
        echo -n "$(icon $VOLUME_ICON) $(volume)$SEP"
        echo "$(icon $CLOCK_ICON) $(clock) "
        sleep 3

# start dzen bar
done | dzen2 -fg $FG -bg $BG -w $WIDTH -x $X -y $Y -fn "$FONT" -h $HEIGHT
