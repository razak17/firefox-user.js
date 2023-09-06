#!/bin/bash
export LC_ALL=en_US.UTF-8
FIREFOX_HOME=$HOME/.mozilla/firefox/profiles
TMP="./temp"

# cleaner
# rm -rf "${TMP}"

mkdir -p "$FIREFOX_HOME"
mkdir -p "$HOME/.dots"
mkdir -p "$TMP"

install_essentials() {
	if [ ! -e "$TMP/user.js" ]; then
		if curl -s -L "https://raw.githubusercontent.com/arkenfox/user.js/master/user.js" -o "${TMP}/user.js"; then
			echo "User.js file downloaded"
		fi
	fi

	if [ ! -e "$TMP/updater.sh" ]; then
		if curl -s -L "https://raw.githubusercontent.com/arkenfox/user.js/master/updater.sh" -o "${TMP}/updater.sh"; then
			echo "Update script downloaded"
		fi
	fi

	if [ ! -e "$TMP/prefsCleaner.sh" ]; then
		if curl -s -L "https://raw.githubusercontent.com/arkenfox/user.js/master/prefsCleaner.sh" -o "${TMP}/prefsCleaner.sh"; then
			echo "prefsCleaner script downloaded"
		fi
	fi

	if [ ! -e "$TMP/updater.sh" ] || [ ! -e "$TMP/prefsCleaner.sh" ] || [ ! -e "$TMP/user.js" ]; then
		echo "Error downloading scripts"
		exit 1
	fi
}

clone_config() {
	if [ ! -d "$HOME/.dots/firefox-user.js" ]; then
		echo "Cloning firefox-user.js"
		git clone https://github.com/razak17/firefox-user.js "$HOME"/.dots/firefox-user.js
	else
		echo "Remove '$HOME/.dots/firefox-user.js' and run again"
	fi
}

config_branch() {
	profile="$1"
	mkdir -p "$FIREFOX_HOME/$profile"

	pushd "$HOME/.dots/firefox-user.js" || exit
	if [ -d "$FIREFOX_HOME/$profile/chrome" ]; then
		mv "$FIREFOX_HOME/$profile/chrome" "$FIREFOX_HOME/$profile/chrome-$(date +%F_%H%M%S_%N)"
	fi
	mkdir -p "$FIREFOX_HOME/$profile/chrome"
	if [ "$profile" == "rec" ]; then
		cp -R ./chrome/ui ./chrome/content ./chrome/*-"$profile"/* "$FIREFOX_HOME/$profile/chrome"
	else
		cp -R ./chrome/ui ./chrome/content ./chrome/*-coding/* "$FIREFOX_HOME/$profile/chrome"
	fi

	if [ -d "$FIREFOX_HOME/$profile/user.js-overrides" ]; then
		mv "$FIREFOX_HOME/$profile/user.js-overrides" "$FIREFOX_HOME/$profile/user.js-overrides-$(date +%F_%H%M%S_%N)"
	fi
	mkdir -p "$FIREFOX_HOME/$profile/user.js-overrides"
	if [ "$profile" == "coding" ] || [ "$profile" == "rec" ] || [ "$profile" == "dev" ] || [ "$profile" == "main" ]; then
		cp -R ./user.js-overrides/_base.js ./user.js-overrides/*-"$profile"/* "$FIREFOX_HOME/$profile/user.js-overrides"
	else
		cp -R ./user.js-overrides/_base.js ./user.js-overrides/*-coding/* "$FIREFOX_HOME/$profile/user.js-overrides"
	fi

	pushd "$TMP" || exit
	cp -R user.js updater.sh prefsCleaner.sh "$FIREFOX_HOME/$profile"

	pushd "$FIREFOX_HOME/$profile" || exit
	sh ./updater.sh -d -s -o user.js-overrides
	echo "Profile '$profile' Completed!"
}

while [ "$#" -gt 0 ]; do
	curr=$1
	shift

	install_essentials
	case "$curr" in
	-install) clone_config ;;
	-main) config_branch "main" ;;
	-dev) config_branch "dev" ;;
	-coding) config_branch "coding" ;;
	-rec) config_branch "rec" ;;
	-fin) config_branch "finance" ;;
	-all)
		config_branch "main" &&
			config_branch "dev" &&
			config_branch "coding" &&
			config_branch "rec"
		;;
	*) echo "Unavailable command... $curr" ;;
	esac
done
