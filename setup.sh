#!/bin/bash
export LC_ALL=en_US.UTF-8
FIREFOX_HOME=$HOME/.mozilla/firefox/profiless
TMP="./temp"

# cleaner
rm -rf "${TMP}"

mkdir -p "$FIREFOX_HOME"
mkdir -p "$HOME/.dots"
mkdir -p "$TMP"

if [ ! -d "$HOME/.dots/user.js" ]; then
	git clone https://github.com/arkenfox/user.js "$HOME/.dots"
fi

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

config_branch() {
	profile="$1"
	mkdir -p "$FIREFOX_HOME/$profile"

	pushd "$HOME/.dots/firefox-user.js" || exit
	git checkout "$profile"
	cp -R ./chrome ./user-overrides.js "$FIREFOX_HOME/$profile"

	pushd "$TMP" || exit
	cp -R user.js updater.sh prefsCleaner.sh "$FIREFOX_HOME/$profile"

	pushd "$FIREFOX_HOME/$profile" || exit
  sh ./updater.sh -d -s -o user-overrides.js
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
