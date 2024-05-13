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

setup() {
	profile="$1"
	config="$2"

	mkdir -p "$FIREFOX_HOME/$profile"

	pushd "$HOME/.dots/firefox-user.js" || exit
	if [ -d "$FIREFOX_HOME/$profile/chrome" ]; then
		mv "$FIREFOX_HOME/$profile/chrome" "$FIREFOX_HOME/$profile/chrome-$(date +%F_%H%M%S_%N)"
	fi

	mkdir -p "$FIREFOX_HOME/$profile/chrome"
	if [ "$config" == "rec" ]; then
		cp -R ./chrome/ui ./chrome/content ./chrome/*-rec/* "$FIREFOX_HOME/$profile/chrome"
	else
		cp -R ./chrome/ui ./chrome/content ./chrome/*-coding/* "$FIREFOX_HOME/$profile/chrome"
	fi

	if [ -d "$FIREFOX_HOME/$profile/user.js-overrides" ]; then
		mv "$FIREFOX_HOME/$profile/user.js-overrides" "$FIREFOX_HOME/$profile/user.js-overrides-$(date +%F_%H%M%S_%N)"
	fi

	mkdir -p "$FIREFOX_HOME/$profile/user.js-overrides"
	cp -R ./user.js-overrides/_base.js ./user.js-overrides/*-"$config"/* "$FIREFOX_HOME/$profile/user.js-overrides"

	pushd "$TMP" || exit
	cp -R user.js updater.sh prefsCleaner.sh "$FIREFOX_HOME/$profile"

	pushd "$FIREFOX_HOME/$profile" || exit
	sh ./updater.sh -d -s -o user.js-overrides
	echo "Profile '$profile' Completed!"
}

config_profile() {
	configs=("coding" "dev" "main" "rec" "rgt")

	profile="$1"

	if [ -z "$profile" ]; then
		echo "Profile not found... Exiting..."
		exit 1
	fi

	config="$2"

	for i in "${configs[@]}"; do
		if [ "$profile" == "$i" ]; then
			config="$i"
			break
		fi
	done

	if [ -z "$config" ]; then
		echo "Config not specified... Do you want to use default config (coding)? [y/n]"
		read -r ans
		if [ "$ans" == "y" ]; then
			config="coding"
			echo "Using default config: $config"
		else
			echo "Exiting..."
			exit 1
		fi
	fi

	for i in "${configs[@]}"; do
		if [ "$config" == "$i" ]; then
			echo "Using config: $config"
			setup "$profile" "$config"
			return
		fi
	done

	echo "Invalid config: $config"
}

while [ "$#" -gt 0 ]; do
	curr=$1
	shift

	install_essentials
	case "$curr" in
	-clone) clone_config ;;
	-install)
		mkdir -p "$HOME/.local/bin"
		if [ -e "$HOME/.local/bin/fuj" ]; then
			echo "fuj already exists in $HOME/.local/bin"
			exit 1
		fi
		ln -s "$HOME/.dots/firefox-user.js/setup.sh" "$HOME/.local/bin/fuj"
		echo "Installed 'fuj' command"
		;;
	-new)
		profile=$1
		if [ -z "$profile" ]; then
			echo "missing profile"
			exit 1
		fi
		config="$2"
		if [ -n "$config" ]; then
			shift
		fi
		firefox -CreateProfile "${profile^} /home/razak/.mozilla/firefox/profiles/${profile,,}"
		config_profile "${profile,,}" "${config,,}"
		;;
	-coding) config_profile "coding" ;;
	-dev) config_profile "dev" ;;
	-main) config_profile "main" ;;
	-rec) config_profile "rec" ;;
	-rgt) config_profile "rgt" ;;
	-social) config_profile "social" "dev" ;;
	-all)
		config_profile "coding" &&
			config_profile "dev" &&
			config_profile "main" &&
			config_profile "rec" &&
			config_profile "rgt" &&
			config_profile "social" "dev" &&
			echo "All profiles completed!"
		;;
	*) echo "Unavailable command... $curr" ;;
	esac
done
