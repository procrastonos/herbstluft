
#!/bin/bash

# function wrapping the herbstclient command
hc() { "${herbstclient_command[@]:-herbstclient}" "$@" ;}

#==============================================================================
# general 
#==============================================================================

# default colors
panel_bg=$(hc get frame_bg_normal_color)
panel_fg="#dddddd"

# font
font="-*-fixed-medium-*-*-*-12-*-*-*-*-*-*-*"
#font="xft:sourcecodepro:pixelsize=12"

#-title------------------------------------------------------------------------
title_bg=$panel_bg
title_fg=$panel_fg

# padding
padding=" "

#-separator--------------------------------------------------------------------
sep=" "
sep_bg="$panel_bg"
sep_fg="$panel_fg"
sep_style="^bg($sep_bg)^fg($sep_fg)$sep"

#-icons------------------------------------------------------------------------
icon_path="$HOME/.icons"
icon_bg="#000000"
icon_fg="#78a4ff"
icon_padding=" "
icon_width=20

#-gdbar------------------------------------------------------------------------
bar_bg="#111111"
bar_fg="$icon_color"
bar_w="33"
bar_h="0.4" # * panel height
bar_style="-s 0 -ss 0 -sw 3 -nonl"

#==============================================================================
# tags 
#==============================================================================
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

#==============================================================================
# widgets 
#==============================================================================

#-battery----------------------------------------------------------------------
battery_critical_percentage=10
battery_icon_bg="#bb8833"
battery_icon_fg="$panel_bg"
battery_critical_fg_color="#220000"
battery_critical_bg_color="#660000"
battery_full_icon="bat_full_01"
battery_charging_icon="bat_full_01"
battery_discharging_icon="bat_low_01"
battery_missing_icon="ac_01"
battery_icon_style="$battery_icon_bg $battery_icon_fg"

#-clock-date-------------------------------------------------------------------
clock_format="%H:%M:%S"
date_format="%d.%m"
clock_bg=$panel_bg
clock_fg=$panel_fg
clock_icon_bg="#33bb33" 
clock_icon_fg="$panel_bg"
clock_icon="clock"
clock_style="^bg($clock_bg)^fg($clock_fg)"
clock_icon_style="$clock_icon_bg $clock_icon_fg"
date_bg=$panel_bg
date_fg=$panel_fg
date_style="^bg($date_bg)^fg($date_fg)"

#-cpu--------------------------------------------------------------------------
cpu_color=$panel_fg
cpu_icon_bg=$icon_fg
cpu_icon_fg=$icon_bg
cpu_icon="cpu"
cpu_style="^bg()^fg($cpu_color)"
cpu_icon_style="$cpu_icon_bg $cpu_icon_fg"

#-playing----------------------------------------------------------------------
playing_bg="$panel_bg"
playing_fg="$icon_fg"
playing_icon_bg="#ff0000"
playing_icon_fg="$panel_bg"
now_playing_icon="note"
playing_style="^bg()^fg($playing_color)"
playing_icon_style="$playing_icon_bg $playing_icon_fg"
now_playing_format="%artist% - %title%"

#-temp-------------------------------------------------------------------------
temp_bar_fg=$panel_fg
temp_bar_bg=$panel_bg
temp_icon_bg="#ffaa22"
temp_icon_fg=$panel_bg
temp_icon="temp"
temp_icon_style="$temp_icon_bg $temp_icon_fg"

#-volume-------------------------------------------------------------------------
volume_bar_fg="$icon_fg"
volume_bar_bg="$panel_bg"
volume_icon_bg="bbbb33"
volume_icon_fg="$panel_bg"
volume_icon="spkr_01"
volume_style="^bg()^fg($volume_color)"
volume_icon_style="$volume_icon_bg $volume_icon_fg"

#-wireless-------------------------------------------------------------------------
wireless_icon="wifi_01"
