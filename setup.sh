#!/bin/bash
export LC_ALL=en_US.UTF-8

DOTS_HOME="$HOME/.dots"
CONFIG_HOME=$HOME/.dots/firefox-user.js
FIREFOX_HOME=$HOME/.mozilla/firefox/profiles
ZEN_HOME=$HOME/.zen
TMP="$CONFIG_HOME/temp"

mkdir -p "$FIREFOX_HOME" "$DOTS_HOME" "$TMP" "$ZEN_HOME"

capitalize() {
  local word="$1"
  echo "$(tr '[:lower:]' '[:upper:]' <<<"${word:0:1}")${word:1}"
}

clone_config() {
  if [ ! -d "$CONFIG_HOME" ]; then
    echo "Cloning firefox-user.js"
    git clone https://github.com/razak17/firefox-user.js "$CONFIG_HOME"
  else
    echo "Remove '$CONFIG_HOME' and run again"
  fi
}

install_essentials() {
  update="$1"

  cd "$CONFIG_HOME" || exit

  # For update, remove old temporary files first
  if [[ "$update" == "update" ]]; then
    rm -rf "${TMP}"
  fi

  mkdir -p "$TMP"

  local files=("user.js" "updater.sh" "prefsCleaner.sh")
  local base_urls=(
    "https://raw.githubusercontent.com/arkenfox/user.js/master/user.js"
    "https://raw.githubusercontent.com/arkenfox/user.js/master/updater.sh"
    "https://raw.githubusercontent.com/arkenfox/user.js/master/prefsCleaner.sh"
  )
  for i in "${!files[@]}"; do
    if [ ! -e "$TMP/${files[$i]}" ]; then
      if curl -s -L "${base_urls[$i]}" -o "$TMP/${files[$i]}"; then
        echo "${files[$i]} downloaded"
      fi
    fi
  done

  # Verify all files exist
  for file in "${files[@]}"; do
    if [ ! -e "$TMP/$file" ]; then
      echo "Error downloading script: $file"
      exit 1
    fi
  done
}

# Clear old config directories inside a profile directory
clear_old_configs() {
  local base_dir="$1"
  local profile="$2"
  local path="$base_dir/$profile"
  if [ -d "$path" ]; then
    pushd "$path" >/dev/null || exit
    rm -rf chrome-* user.js-overrides-*
    popd >/dev/null || exit
  else
    echo "Profile '$profile' not found."
  fi
}

# Backup the profile history (places.sqlite file) into a timestamped file.
backup_profile_history() {
  local flav="$1"
  local profile="$2"
  local base_dir
  if [ "$flav" == "zen" ]; then
    base_dir="$ZEN_HOME"
  else
    base_dir="$FIREFOX_HOME"
  fi

  local backup_dir="$DOTS_HOME/${flav}_backups"
  mkdir -p "$backup_dir/$profile"
  if [ -f "$base_dir/$profile/places.sqlite" ]; then
    local time_stamp
    time_stamp=$(date +%F_%H%M%S_%N)
    cp "$base_dir/$profile/places.sqlite" "$backup_dir/$profile/places-$time_stamp.sqlite"
  fi
}

# Backup (or remove) an old chrome folder if exists
backup_chrome_css() {
  local base_dir="$1"
  local profile="$2"
  local profile_path="$base_dir/$profile"
  if [ -d "$profile_path/chrome" ]; then
    mv "$profile_path/chrome" "$profile_path/chrome-$(date +%F_%H%M%S_%N)"
  fi
}

chrome_css_setup() {
  local base_dir="$1"
  local profile="$2"
  local config="$3"
  local ff_ultima="$4"
  backup_chrome_css "$base_dir" "$profile"
  mkdir -p "$base_dir/$profile/chrome"
  pushd "$CONFIG_HOME" >/dev/null || exit
  if [ -n "$ff_ultima" ]; then
    cp -R ./FF-ULTIMA/theme ./FF-ULTIMA/userChrome.css ./FF-ULTIMA/userContent.css "$FIREFOX_HOME/$profile/chrome"
    popd >/dev/null || exit
    return
  fi
  if [ "$config" == "rec" ]; then
    cp -R ./chrome/ui ./chrome/content ./chrome/*-rec/* "$base_dir/$profile/chrome"
  else
    cp -R ./chrome/ui ./chrome/content ./chrome/*-coding/* "$base_dir/$profile/chrome"
  fi
  popd >/dev/null || exit
}

ff_ultima_overrides_setup() {
  pushd "$CONFIG_HOME" || exit
  cp ./FF-ULTIMA/user.js ./temp/_ffu_base.js
  echo -e "\n" >>./temp/_ffu_base.js
  cat ./user.js-overrides/_ffu.js >>./temp/_ffu_base.js
  cp ./temp/_ffu_base.js ./user.js-overrides/_ffu_base.js
  cp -R ./user.js-overrides/_base.js ./user.js-overrides/_ffu_base.js ./user.js-overrides/*-"$config"/* "$FIREFOX_HOME/$profile/user.js-overrides"
}

user_js_overrides_setup() {
  local flavor="$1"   # "firefox" or "zen"
  local base_dir="$2" # target directory (FIREFOX_HOME or ZEN_HOME)
  local profile="$3"
  local config="$4"
  local ff_ultima="$5"
  local overrides_target="$base_dir/$profile/user.js-overrides"

  # Backup old overrides if exists & re-create target folder
  [ -d "$overrides_target" ] && mv "$overrides_target" "${overrides_target}-$(date +%F_%H%M%S_%N)"
  mkdir -p "$overrides_target"

  pushd "$CONFIG_HOME" || exit

  # Remove temporary file if found
  [ -e "./user.js-overrides/_ffu_base.js" ] && rm ./user.js-overrides/_ffu_base.js

  # For FF Ultima, merge the base override files
  if [ -n "$ff_ultima" ]; then
    ff_ultima_overrides_setup
  else
    cp -R ./user.js-overrides/_base.js ./user.js-overrides/*-"$config"/* "$base_dir/$profile/user.js-overrides"
  fi

  # For "zen" flavor add our own zen override if exists.
  if [ "$flavor" == "zen" ] && [ -e "./user.js-overrides/_zen.js" ]; then
    cp -R ./user.js-overrides/_zen.js "$base_dir/$profile/user.js-overrides"
  fi

  # Copy the essential files into the profile directory
  pushd "$TMP" || exit
  cp -R user.js updater.sh prefsCleaner.sh "$base_dir/$profile"
  popd >/dev/null || exit

  # Run updater
  pushd "$base_dir/$profile" >/dev/null || exit
  sh ./updater.sh -d -s -o user.js-overrides
  popd >/dev/null || exit

  # Clean up temporary file if present
  [ -e "$CONFIG_HOME/user.js-overrides/_ffu_base.js" ] && rm "$CONFIG_HOME/user.js-overrides/_ffu_base.js"
  echo "Profile '$profile' configuration complete!"
  popd >/dev/null || exit
}

# Determine the target base directory using flavor
get_base_dir() {
  local flavor="$1"
  if [ "$flavor" == "zen" ]; then
    echo "$ZEN_HOME"
  else
    echo "$FIREFOX_HOME"
  fi
}

config_profile() {
  configs=("coding" "dev" "main" "rec" "rgt")

  local flavor="$1" # "firefox" or "zen"
  local profile="$2"
  local config="$3"
  local ff_ultima="$4"
  local target_dir
  target_dir=$(get_base_dir "$flavor")

  # Check if profile directory exists
  if [ ! -d "$target_dir/$profile" ]; then
    echo "Profile '$profile' does not exist."
    return
  fi

  # Try using the profile name as config
  if [ -z "$config" ]; then
    for conf in "${configs[@]}"; do
      if [ "$profile" == "$conf" ]; then
        config="$conf"
        break
      fi
    done
  fi

  # If config is not provided, ask for default
  local configs=("coding" "dev" "main" "rec" "rgt")
  local valid_conf=""
  for conf in "${configs[@]}"; do
    if [ "$profile" == "$conf" ]; then
      valid_conf="$conf"
      break
    fi
  done
  if [ -z "$config" ]; then
    printf "Config not specified... Use default config (coding)? [y/n] "
    read -r answer
    if [ "$answer" == "y" ]; then
      config="coding"
      echo "Using default config: coding"
    else
      echo "Exiting..."
      exit 1
    fi
  else
    echo "Using config: $config"
  fi

  # Quick check: if the user passed a matching config as profile name, use that.
  [ -n "$valid_conf" ] && config="$valid_conf"

  backup_profile_history "$flavor" "$profile"

  # Firefox has an extra chrome CSS step
  if [ "$flavor" == "firefox" ]; then
    chrome_css_setup "$target_dir" "$profile" "$config" "$ff_ultima"
  fi

  user_js_overrides_setup "$flavor" "$target_dir" "$profile" "$config" "$ff_ultima"
}

# Generic functions for profile management (create, delete, clear, list)
create_profile() {
  local flavor="$1" # "firefox" or "zen"
  local profile="$2"
  local target_dir
  target_dir=$(get_base_dir "$flavor")
  # Note: the command to create a profile differs between firefox and zen.
  if [ "$flavor" == "zen" ]; then
    zen -CreateProfile "${profile^} $target_dir/${profile,,}"
  else
    firefox -CreateProfile "${profile^} $target_dir/${profile,,}"
  fi
  echo "Profile created: $profile"
}

delete_profile() {
  local flavor="$1"
  local profile="$2"
  local target_dir
  target_dir=$(get_base_dir "$flavor")
  sudo rm -rf "$target_dir/$profile"
  echo "Profile deleted: $profile"
}

clear_profile_configs() {
  local flavor="$1"
  local profile="$2"
  local target_dir
  target_dir=$(get_base_dir "$flavor")
  clear_old_configs "$target_dir" "$profile"
}

get_profiles() {
  local base_dir="$1"
  local extra="$2"
  pushd "$base_dir" >/dev/null || exit
  local options
  options=$(find . -maxdepth 1 -type d -exec basename {} \; | grep -v -E '^(\.|\.\.|firefox-)$')
  local choice
  choice=$(echo "$options" | sort | dmenu -l 10 -p 'Choose :')
  if [ -z "$choice" ]; then
    exit 1
  fi

  # Verify profile exists
  local exists=false
  for elem in $options; do
    if [ "$elem" = "$choice" ]; then
      exists=true
      break
    fi
  done

  if ! $exists; then
    notify-send -u critical -t 2000 "Profiles" "That profile does not exist"
    exit 1
  fi
  notify-send -t 2000 "Profiles" "Opening ${choice^} profile..."
  if [ "$base_dir" == "$FIREFOX_HOME" ]; then
    firefox -P "$(capitalize "$choice")"
  else
    if [ "$extra" == "twilight" ]; then
      zen-tw -P "$(capitalize "$choice")"
    else
      zen -P "$(capitalize "$choice")"
    fi
  fi
  popd >/dev/null || exit
}

# Print help message
print_help() {
  echo "Usage: fuj [options]"
  echo "Options:"
  echo "  -install              : Install 'fuj' command"
  echo "  -clone                : Clone firefox-user.js repository"
  echo "  -upd                  : Update user.js (re-download scripts)"
  echo ""
  echo "  # Firefox commands"
  echo "  -new <profile>        : Create a new Firefox profile"
  echo "  -del <profile>        : Delete a Firefox profile"
  echo "  -profiles             : List all Firefox profiles"
  echo "  -p <profile> <cfg> [ff_ultima]: Configure a Firefox profile"
  echo "  -clear <profile>      : Clear old configs in a Firefox profile"
  echo "  -backup <profile>     : Backup Firefox profile history"
  echo "  -all                  : Configure all Firefox profiles"
  echo "  -coding, -dev, etc.   : Quick config for designated profiles"
  echo ""
  echo "  # Zen commands"
  echo "  -zen-new <profile>    : Create a new Zen profile"
  echo "  -zen-del <profile>    : Delete a Zen profile"
  echo "  -zen-p <profile> <cfg> [ff_ultima]: Configure a Zen profile"
  echo "  -zen-profiles [extra] : List all Zen profiles"
  echo "  -zen-clear <profile>  : Clear old configs in a Zen profile"
  echo "  -zen-all              : Configure all Zen profiles"
  exit 0
}

while [ "$#" -gt 0 ]; do
  curr=$1
  shift

  case "$curr" in
  --help | -h) print_help ;;
  -clone) clone_config ;;
  -install)
    mkdir -p "$HOME/.local/bin"
    if [ -e "$HOME/.local/bin/fuj" ]; then
      echo "fuj already exists in $HOME/.local/bin"
      exit 1
    fi
    ln -s "$CONFIG_HOME/setup.sh" "$HOME/.local/bin/fuj"
    echo "Installed 'fuj' command"
    ;;
  -upd) install_essentials update ;;
  #########################
  # Firefox commands
  -new)
    profile=$1
    shift
    create_profile "firefox" "$profile"
    ;;
  -del)
    profile=$1
    shift
    delete_profile "firefox" "$profile"
    ;;
  -profiles)
    get_profiles "$FIREFOX_HOME"
    ;;
  -p)
    profile=$1
    config="$2"
    ff_ultima="$3"
    [ -z "$profile" ] && {
      echo "missing profile "
      exit 1
    }
    [ -z "$config" ] && {
      echo "missing config"
      exit 1
    }
    shift 2
    [ -n "$ff_ultima" ] && shift
    config_firefox "$profile" "$config" "$ff_ultima"
    ;;
  -coding | -def | -dev | -main | -rec | -rgt | -social)
    # For these quick commands, use profile name from the flag or a default.
    flag="${curr#-}"
    # For social we want to override config to "dev"
    if [ "$flag" == "social" ]; then
      config="dev"
    elif [ "$flag" == "def" ]; then
      flag="default"
      config="coding"
    else
      config="$flag"
    fi
    # We assume the profile name is also the config name, but can be overridden later.
    config_profile "firefox" "$flag" "$config"
    ;;
  -clear)
    profile=$1
    shift
    clear_profile_configs "firefox" "$profile"
    ;;
  -backup)
    profile=$1
    shift
    backup_profile_history "firefox" "$profile"
    ;;
  -all)
    # Configure a list of profiles.
    for prof in coding default dev main rec rgt social; do
      if [ "$prof" == "social" ]; then
        config_profile "firefox" "$prof" "dev"
      elif [ "$prof" == "defalt" ]; then
        config_profile "firefox" "$prof" "coding"
      else
        config_profile "firefox" "$prof" "$prof"
      fi
    done
    echo "All Firefox profiles completed!"
    ;;
  -clear-all)
    # Clear old configs for a list of profiles.
    for prof in coding default dev main rec rgt social; do
      clear_old_configs "$FIREFOX_HOME" "$prof"
    done
    echo "All Firefox profiles cleared!"
    ;;
  -zen-new)
    profile=$1
    shift
    create_profile "zen" "$profile"
    ;;
  -zen-del)
    profile="$1"
    shift
    delete_profile "zen" "$profile"
    ;;
  -zen-p)
    profile="$1"
    config="$2"
    ff_ultima="$3"
    [ -z "$profile" ] && {
      echo "missing profile"
      exit 1
    }
    [ -z "$config" ] && {
      echo "missing config"
      exit 1
    }
    shift 2
    [ -n "$ff_ultima" ] && shift
    config_profile "zen" "$profile" "$config" "$ff_ultima"
    ;;
  -zen-profiles)
    get_profiles "$ZEN_HOME" "$1"
    ;;
  -zen-clear)
    profile="$1"
    shift
    clear_profile_configs "zen" "$profile"
    ;;
  -zen-clear-all)
    # Clear old configs for a list of profiles.
    for prof in code coding default dev debug jellyfin main rec rgt; do
      clear_old_configs "$ZEN_HOME" "$prof"
    done
    echo "All Zen profiles cleared!"
    ;;
  -zen-all)
    config_profile "zen" "code" "coding" &&
      config_profile "zen" "default" "coding" &&
      config_profile "zen" "debug" "coding" &&
      config_profile "zen" "dev" &&
      config_profile "zen" "jellyfin" "rec" &&
      config_profile "zen" "main" &&
      config_profile "zen" "rec" &&
      config_profile "zen" "rgt" &&
      config_profile "zen" "social" "dev" &&
      echo "All profiles completed!"
    ;;
  *) echo "Unavailable command... $curr" ;;
  esac
done
