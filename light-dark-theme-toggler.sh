#!/bin/sh
#
# Toggle between dark and light themes
#
# This script will apply themes to all applications specified in the config.
# The default config will most likely not work for you.
#
# Warning: If improperly used this script might corrupt configuration files
#
# License: GPL-3.0
# Author: tepf@tutanota.com
# Repository: github.com/tepf/light-dark-theme-toggler
#
# SYNOPSIS:
#    light-dark-theme-toggler.sh [option]
#    option:
#        --toggle    Switch to dark/light theme if light/dark is applied
#        --time      Apply dark theme in the night, else light theme




#------------------------------------------------------------------------------#
#  User Configuration                                                          #
#------------------------------------------------------------------------------#

##
## Define the hour (0-23) when dark/light themes should be applied
##

# When the script should apply dark themes e.g. 19 (=7pm)
NIGHT_START=19
# When it should use the light theme instead e.g. 6 (=6am)
NIGHT_END=6


##
## Define the themes
##

# Supported:
#     * GTK-Theme (found in /usr/share/themes) only for XFCE4
#     * Icon-Theme (found in /usr/share/icons) only for XFCE4
#     * XFCE4-Terminal
#     * Rofi
#     * Intellij Community Edition 2016
#
# Notes for configuration (that might not be obvious):
#     * The prefilled settings likely won't work for you. Especially
#       the path based ones. You have to declare themes/config files that 
#       are installed on your system
#     * The $HOME variable points to your home directory e.g. "/home/user"
#     * Spaces before and after "=" are not allowed
#     * Some apps require theme names other file paths
#     * File paths, theme names and apps will be checked for existence
#       before application

declare -A DARK_THEMES=(
	[gtk]="Xfce-dusk"                                             # name
	[icon]="Numix-Circle"                                         # name
	[xfce4-terminal]=$HOME/.config/xfce4/terminal/terminalrc.dark # path
	[rofi]=$HOME/.Xresources.dark                                 # path
	[intellij-global]="Darcula"                                   # name
	[intellij-color]="DonnieDarko"                                # name
)

declare -A LIGHT_THEMES=(
	[gtk]="Numix"                                                  # name
	[icon]="Numix-Circle"                                          # name
	[xfce4-terminal]=$HOME/.config/xfce4/terminal/terminalrc.light # path
	[rofi]=$HOME/.Xresources.light                                 # path
	[intellij-global]="Intellij"                                   # name
	[intellij-color]="LonnieLighto"                                # name
)


#------------------------------------------------------------------------------#
#  User Configuration END                                                      #
#------------------------------------------------------------------------------#












#------------------------------------------------------------------------------#
#  Theme Implementations                                                       #
#------------------------------------------------------------------------------#

# How to add new application?
#
# All implementations should have an applying and validating method.
# The apply method applies a theme given the theme name or theme file
# The valid method validates a theme name or theme file
# For collective referencing they should then be added to the associative arrays
# VALDIATORS and APPLIERS


#
# XFCE4-Terminal
#

# TODO: xfce4-terminal needs sometimes a restart before theme is applied
apply_xfce4_terminal_theme() {
	if [ -x `which xfce4-terminal` ]
	then
		ln -f $1 $HOME/.config/xfce4/terminal/terminalrc
	else
		echo "Changing xfce4-terminal theme failed: xfce4-terminal not installed"
	fi
}

valid_xfce4_terminal_theme_config() {
	[ -f $1 ]
}


#
# GTK-Theme
#

apply_gtk_theme() {
	if [ -x `which xfconf-query` ]
	then
		xfconf-query -c "xsettings" -p "/Net/ThemeName" -s $1
	else
		echo "Changing GTK theme failed: Desktop environment not supported"
	fi
}

valid_gtk_theme_config() {
	[ -d /usr/share/themes/$1 ]
}


#
# Icons
#

apply_icon_theme() {
	if [ -x `which xfconf-query` ]
	then
		xfconf-query -c "xsettings" -p "/Net/IconThemeName" -s $1
	else
		echo "Changing icon theme failed: Desktop environment not supported"
	fi
}


valid_icon_theme_config() {
	[ -d /usr/share/icons/$1 ]
}

#
# Rofi
#

apply_rofi_theme() {
	if [ -x `which rofi` ]
	then
		ln -f $1 $HOME/.Xresources
		xrdb $HOME/.Xresources
	else
		echo "Changing rofi theme failed: rofi not installed"
	fi
}

valid_rofi_theme_config() {
	[ -f $1 ]
}

#
# Intellij
#

editXML() {
	sed --in-place "s/$1 $2=\"[^\"]*\"/$1 $2=\"$3\"/" $4
}

INTELLIJ_HOME=$HOME/.IdeaIC2016.1

# FIXME: Very brittle...
#  * Breaks if no custom theme is applied. If the standard color themes
#    are in place then the "global_color_scheme" tag won't be present
#  * Where is $INTELLIJ_HOME??? Path is hardcoded now and will break after
#    update
apply_intellij_global_theme() {
	lower=`echo "what am i doing here??" | awk "{ print tolower(\"$1\") }"`
	editXML "laf" "class-name" "com.intellij.ide.ui.laf.$lower.${1}Laf" $INTELLIJ_HOME/config/options/laf.xml
}

apply_intellij_color_theme() {
	editXML "global_color_scheme" "name" "$1" $INTELLIJ_HOME/config/options/colors.scheme.xml
}

valid_intellij_global_theme_config() {
	case $1 in
		Darcula | Intellij )
			return 0
	esac
	return 1
}

valid_intellij_color_theme_config() {
	[ -f $INTELLIJ_HOME/config/colors/$1.icls ]
}



#
# Sum all implementations
#

declare -A APPLIERS=(
	[xfce4-terminal]=apply_xfce4_terminal_theme
	[gtk]=apply_gtk_theme
	[icon]=apply_icon_theme
	[rofi]=apply_rofi_theme
	[intellij-global]=apply_intellij_global_theme
	[intellij-color]=apply_intellij_color_theme
)

declare -A VALIDATORS=(
	[xfce4-terminal]=valid_xfce4_terminal_theme_config
	[gtk]=valid_gtk_theme_config
	[icon]=valid_icon_theme_config
	[rofi]=valid_rofi_theme_config
	[intellij-global]=valid_intellij_global_theme_config
	[intellij-color]=valid_intellij_color_theme_config
)

# Validates DARK_THEMES and LIGHT_THEMES
validate_config() {

	# Check DARK_THEMES
	for app in ${!DARK_THEMES[*]}
	do
		# Has DARK_THEME counter part?
		if [ "${LIGHT_THEMES[$app]}" == "" ]
		then
			echo "CONFIG ERROR: \"$app\" has a dark theme, but no light one"
			return 1
		# Has valid config?
		elif ! ${VALIDATORS[$app]} ${DARK_THEMES[$app]} 2>/dev/null
		then
			echo "CONFIG ERROR: \"$app\" dark theme config is invalid or not supported"
			return 1
		fi
	done

	# Check LIGHT_THEMES
	for app in ${!LIGHT_THEMES[*]}
	do
		# Has DARK_THEME counter part?
		if [ "${DARK_THEMES[$app]}" == ""  ]
		then
			echo "CONFIG ERROR: \"$app\" has a light theme, but no dark one"
			return 1
		# Has valid config?
		elif ! ${VALIDATORS[$app]} ${LIGHT_THEMES[$app]} 2>/dev/null
		then
			echo "CONFIG ERROR: \"$app\" light theme config is invalid or not supported"
			return 1
		fi
	done

	return 0
}


#------------------------------------------------------------------------------#
#  Theme Implementations END                                                   #
#------------------------------------------------------------------------------#



#------------------------------------------------------------------------------#
#  Main                                                                        #
#------------------------------------------------------------------------------#


theme_to_apply=""
# FIXME: Better way to test which theme applied now
current_theme=`xfconf-query -c "xsettings" -p "/Net/ThemeName"`

if [ "$1" == "--toggle" ]
then

	if [ "$current_theme" == "${DARK_THEMES[gtk]}" ]
	then
		theme_to_apply="light"
	else
		theme_to_apply="dark"
	fi

elif [ "$1" == "--time" ]
then

	hour=`date +%H`

	if (( hour >= NIGHT_START || hour < NIGHT_END ))
	then
		theme_to_apply="dark"
	else
		theme_to_apply="light"
	fi

else

	echo "Usage: ./light-dark-theme-toggler.sh [option]"
	echo "option:"
	echo "    --toggle Toggle between day and night themes"
	echo "    --time   Change theme based on time"
	exit 0

fi

if validate_config
then
	if [ $theme_to_apply == "dark" ]
	then
		for app in ${!DARK_THEMES[*]}
		do
			${APPLIERS[$app]} ${DARK_THEMES[$app]}
		done
	else
		for app in ${!LIGHT_THEMES[*]}
		do
			${APPLIERS[$app]} ${LIGHT_THEMES[$app]}
		done
	 fi

	# Notify user about theme changes
	notify-send "Welcome to the $theme_to_apply side" --icon=theme-config

fi


#------------------------------------------------------------------------------#
#  Main END                                                                    #
#------------------------------------------------------------------------------#
