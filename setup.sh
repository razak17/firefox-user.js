#!/bin/bash
export LC_ALL=en_US.UTF-8
FIREFOX_HOME=$HOME/.mozilla/firefox/profiless

mkdir -p "$FIREFOX_HOME"
mkdir -p "$HOME/.dots"

if [ ! -d "$HOME/.dots/user.js" ]; then
	git clone https://github.com/arkenfox/user.js "$HOME/.dots"
fi

# Personal Firefox settings. Based by arkenfox/user.js
# by Denis G. (https://github.com/denis-g/firefox-settings)

# config
# TMP="./temp"
# source ./config.ini
#
# FIREFOX_PROFILE=$1
#
# if [ -z "$FIREFOX_PROFILE" ]; then
# 	echo "Error: Variable FIREFOX_PROFILE is empty or wrong"
# 	echo "Please check FIREFOX_PROFILE variable on config.ini file"
# 	exit 22
# fi
#
# if [ ! -d "$FIREFOX_PROFILE" ]; then
# 	echo "Error: Firefox profile directory does not exists"
# 	echo "Please check FIREFOX_PROFILE variable on config.ini file"
# 	exit 2
# fi
#
# # cleaner
# rm -rf "${TMP}"
# rm -rf "${FIREFOX_PROFILE}/chrome/"
#
# # download actual arkenfox/user.js main files
# mkdir "${TMP}"
#
# if curl -s -L "https://raw.githubusercontent.com/arkenfox/user.js/master/updater.sh" -o "${TMP}/updater.sh"; then
# 	# generate user.js
# 	cp -R ./user.js-overrides/ "${TMP}/user.js-overrides/"
# 	sh "${TMP}/updater.sh" -d -s -o "user.js-overrides"
#
# 	# copy prefs
# 	cp "${TMP}/user.js" "${FIREFOX_PROFILE}"
#
# 	# copy styles
# 	cp -R ./chrome/ "${FIREFOX_PROFILE}/chrome/"
#
# 	# cleaner
# 	rm -rf "${TMP}"
#
# 	echo "Completed!"
# 	exit 0
# else
# 	echo "Error! Could not download arkenfox/user.js"
# 	exit 2
# fi

config_branch() {
	profile="$1"
  mkdir -p "$FIREFOX_HOME/$profile"
  git checkout "$profile"
  cp -R ./user-overrides.js "$FIREFOX_HOME/$profile"
  cp -R ./chrome "$FIREFOX_HOME/$profile"

	pushd "$HOME/.dots/user.js" || exit
	cp -R user.js updater.sh prefsCleaner.sh "$FIREFOX_HOME/$profile"
  echo "Profile '$profile' Completed!"
}

while [ "$#" -gt 0 ]; do
	curr=$1
	shift

	case "$curr" in
	-main) config_branch "main" ;;
	-dev) config_branch "dev" ;;
	-coding) config_branch "coding" ;;
	-rec) config_branch "rec" ;;
  -all)
    config_branch "main"
    config_branch "dev"
    config_branch "coding"
    config_branch "rec"
    ;;
	*) echo "Unavailable command... $curr" ;;
	esac
done
