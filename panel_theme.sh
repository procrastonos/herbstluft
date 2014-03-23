
#!/bin/bash

# function wrapping the herbstclient command
hc() { "${herbstclient_command[@]:-herbstclient}" "$@" ;}

#==============================================================================
# colours
#==============================================================================
# default colors
panel_bg=$(hc get frame_bg_normal_color)
panel_fg="#cccccc"

#-tags-------------------------------------------------------------------------
# tag status '.' (empty)
unused_bg=$panel_bg
unused_fg=$panel_fg

# tag status ':' (non-empty)
used_bg=$panel_bg
used_fg=$panel_fg

# tag status '+' (not focused)
inactive_bg="#0000aa"
inactive_fg="#000055"

# tag status '#' (focused)
active_bg="#aaaaaa"
active_fg="#555555"

# tag status '-' (not focused and on other monitor)
inactive_m_bg="#0f00aa"
inactive_m_fg="#0f0055"

# tag status '%' (focused but on other monitor)
active_m_bg="#a0aaaa"
active_m_fg="#505555"

# tag status '!' (urgent)
urgent_bg="#ff0000"
urgent_fg="#000000"

#-other------------------------------------------------------------------------
# color of separator
sep_color=$panel_fg

# window title
title_bg=$panel_bg
title_fg=$panel_fg

# icon color
icon_color="#78a4ff"
battery_critical_fg_color="#220000"
battery_critical_bg_color="#660000"

# date color
clock_bg=$panel_bg
clock_fg=$icon_color
date_bg=$panel_bg
date_fg=$panel_fg

# gdbar colors
bar_bg_color=$panel_bg
bar_fg_color=$icon_color

# cpu
cpu_color=$panel_fg
cpu_icon_color=$icon_color
# now playing
playing_color="#33aa44"

#==============================================================================
# icons 
#==============================================================================
icon_width=14

now_playing_icon="$HOME/.icons/note.xbm"
battery_full_icon="$HOME/.icons/bat_full_01.xbm"
battery_charging_icon="$HOME/.icons/bat_full_01.xbm"
battery_discharging_icon="$HOME/.icons/bat_low_01.xbm"
battery_missing_icon="$HOME/.icons/ac_01.xbm"
wireless_icon="$HOME/.icons/wifi_01.xbm"
volume_icon="$HOME/.icons/spkr_01.xbm"
clock_icon="$HOME/.icons/clock.xbm"
cpu_icon="$HOME/.icons/cpu.xbm"

#==============================================================================
# style 
#==============================================================================

sep="^fg($sep_color)|"
clock_style="^bg($clock_bg)^fg($clock_fg)"
date_style="^bg($date_bg)^fg($date_fg)"

#-gdbar------------------------------------------------------------------------
bar_style="-w 33 -h 10 -s o -ss 0 -sw 3 -nonl"

# cpu
cpu_style="^bg()^fg($cpu_color)"
# now playing
playing_style="^bg()^fg($playing_color)"

#==============================================================================
# settings 
#==============================================================================

#-battery----------------------------------------------------------------------
battery_critical_percentage=10

#-font-------------------------------------------------------------------------
font="-*-fixed-medium-*-*-*-12-*-*-*-*-*-*-*"
#font="xft:sourcecodepro:pixelsize=12"

#-format-----------------------------------------------------------------------
clock_format="%H:%M:%S"
date_format="%d.%m"
now_playing_format="%artist% - %title%"
