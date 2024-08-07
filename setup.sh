#!/bin/bash
export LC_ALL=en_US.UTF-8
FIREFOX_HOME=$HOME/.mozilla/firefox/profiles
TMP="./temp"

mkdir -p "$FIREFOX_HOME"
mkdir -p "$HOME/.dots"
mkdir -p "$TMP"

install_essentials() {
  update="$1"

  cd "$HOME/.dots/firefox-user.js" || exit

  if [[ -n "$update" && "$update" == "update" ]] ; then
    # cleaner
    rm -rf "${TMP}"
  fi

  mkdir -p "$TMP"

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
	install_essentials

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
      backup_profile_history "$profile"
			setup "$profile" "$config"
			return
		fi
	done

	echo "Invalid config: $config"
}

capitalize() {
	word="$1"
	echo "$(tr '[:lower:]' '[:upper:]' <<<"${word:0:1}")${word:1}"
}

get_profiles() {
	cd "$FIREFOX_HOME" || exit
	options=$(dir | xargs -n 1 -P 1 echo "$0" | awk '{print $2}')
	choice="$(echo "$options" | dmenu -l 10 -p 'Choose :')"
	# echo "$choice"

	if [ -z "$choice" ]; then
		# notify-send -u critical -t 2000 "Firefox Profiles" "nothing selected!"
		exit 1
	fi

	# Use a for loop to iterate over the space-separated elements
	profile_exists=false
	for element in $options; do
		if [ "$element" = "$choice" ]; then
			# echo "Found $element"
			profile_exists=true
			break
		fi
	done

	if [ "$profile_exists" = false ]; then
		notify-send -u critical -t 2000 "Firefox Profiles" "That profile does not exist"
		exit 1
	fi

	notify-send -t 2000 "Firefox profiles" "Opening $choice profile..."
	profile=$(capitalize "$choice")
	firefox -P "${profile}"
}

clear_old_configs() {
	profile="$1"

	cd "$FIREFOX_HOME" || exit

  if [ -d "$FIREFOX_HOME/$profile" ] ; then
    cd "$FIREFOX_HOME/$profile" || exit

    if ls -d chrome-* 1> /dev/null 2>&1; then
      rm -r chrome-*
    fi
    if ls -d user.js-overrides-* 1> /dev/null 2>&1; then
      rm -r user.js-overrides-*
    fi
  else
		echo "Profile dir not found. Exiting..."
  fi
}

backup_profile_history() {
  profile="$1"

  mkdir -p "$HOME/.dots/firefox_backups"
  if [ -f "$FIREFOX_HOME/$profile/places.sqlite" ]; then
    mkdir -p "$HOME/.dots/firefox_backups/$profile"
	  time=$(date +%F_%H%M%S_%N)
    cp "$FIREFOX_HOME/$profile/places.sqlite" "$HOME/.dots/firefox_backups/$profile/places-$time.sqlite"
  fi
}

while [ "$#" -gt 0 ]; do
	curr=$1
	shift

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
	-profiles)
		get_profiles
		;;
	-p)
		profile=$1
		if [ -z "$profile" ]; then
			echo "missing profile"
			exit 1
		fi
		config="$2"
		if [ -n "$config" ]; then
			shift
    else
			echo "missing profile"
			exit 1
		fi
		config_profile "$profile" "$config"
		;;
	-profiles)
		get_profiles
		;;
	-coding) config_profile "coding" ;;
	-def) config_profile "default" ;;
	-dev) config_profile "dev" ;;
	-main) config_profile "main" ;;
	-rec) config_profile "rec" ;;
	-rgt) config_profile "rgt" ;;
	-social) config_profile "social" "dev" ;;
	-upd) install_essentials update ;;
	-clear)
		profile=$1
		if [ -z "$profile" ]; then
			echo "missing profile"
			exit 1
		fi

		shift
    clear_old_configs "$profile"
    ;;
	-backup)
		profile=$1
		if [ -z "$profile" ]; then
			echo "missing profile"
			exit 1
		fi

		shift
    backup_profile_history "$profile"
    ;;
	-clear-all)
    clear_old_configs "coding"
    clear_old_configs "default"
    clear_old_configs "dev"
    clear_old_configs "main"
    clear_old_configs "rec"
    clear_old_configs "rgt"
    clear_old_configs "social"
    ;;
  -all)
		config_profile "coding" &&
			config_profile "default" &&
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
