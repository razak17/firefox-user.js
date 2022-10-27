#!/bin/bash
export LC_ALL=en_US.UTF-8
FIREFOX_HOME=$HOME/.mozilla/firefox/profiles
TMP="./temp"

# cleaner
rm -rf "${TMP}"

mkdir -p "$FIREFOX_HOME"
mkdir -p "$HOME/.dots"
mkdir -p "$TMP"

install_essentials() {
	if curl -s -L "https://raw.githubusercontent.com/arkenfox/user.js/master/user.js" -o "${TMP}/user.js"; then
		echo "User.js file downloaded"
	fi

	if curl -s -L "https://raw.githubusercontent.com/arkenfox/user.js/master/updater.sh" -o "${TMP}/updater.sh"; then
		echo "Update script downloaded"
	fi

	if curl -s -L "https://raw.githubusercontent.com/arkenfox/user.js/master/prefsCleaner.sh" -o "${TMP}/prefsCleaner.sh"; then
		echo "prefsCleaner script downloaded"
	fi

	if [ ! -e "$TMP/updater.sh" ] || [ ! -e "$TMP/prefsCleaner.sh" ]; then
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
	git checkout "$profile"
	cp -R ./chrome ./user.js-overrides "$FIREFOX_HOME/$profile"

	pushd "$TMP" || exit
	cp -R user.js updater.sh prefsCleaner.sh "$FIREFOX_HOME/$profile"

	pushd "$FIREFOX_HOME/$profile" || exit
	sh ./updater.sh -d -s -o user.js-overrides
	echo "Profile '$profile' Completed!"
}

while [ "$#" -gt 0 ]; do
	curr=$1
	shift

	case "$curr" in
	-install) clone_config ;;
	-main) install_essentials && config_branch "main" ;;
	-dev) install_essentials && config_branch "dev" ;;
	-coding) install_essentials && config_branch "coding" ;;
	-rec) install_essentials && config_branch "rec" ;;
	-all)
		install_essentials &&
		config_branch "main"
		config_branch "dev"
		config_branch "coding"
		config_branch "rec"
		;;
	*) echo "Unavailable command... $curr" ;;
	esac
done
