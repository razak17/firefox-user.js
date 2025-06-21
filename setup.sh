#!/bin/bash
export LC_ALL=en_US.UTF-8

DOTS_HOME="$HOME/.dots"
CONFIG_HOME="$HOME/.dots/firefox-user.js"
FIREFOX_HOME="$HOME/.mozilla/firefox/profiles"
FLOORP_HOME="$HOME/.floorp/profiles"
ZEN_HOME="$HOME/.zen"
TMP="$CONFIG_HOME/temp"
BETTER_FOX="$CONFIG_HOME/better"
CONFIGS=("coding" "dev" "main" "rec" "rgt" "fastfox")

mkdir -p "$FIREFOX_HOME" "$DOTS_HOME" "$TMP" "$ZEN_HOME" "$FLOORP_HOME"

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
    [ -e "$TMP" ] && rm -rf "${TMP}"
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

install_betterfox_essentials() {
  update="$1"

  cd "$CONFIG_HOME" || exit

  # For update, remove old temporary files first
  if [[ "$update" == "update" ]]; then
    [ -e "$BETTER_FOX" ] && rm -rf "${BETTER_FOX}"
  fi

  mkdir -p "$BETTER_FOX"

  local files=(
    "fastfox.js"
    "securefox.js"
    "peskyfox.js"
    "smoothfox.js"
    "user.js"
  )
  local base_urls=(
    "https://raw.githubusercontent.com/yokoffing/Betterfox/refs/heads/main/Fastfox.js"
    "https://raw.githubusercontent.com/yokoffing/Betterfox/refs/heads/main/Securefox.js"
    "https://raw.githubusercontent.com/yokoffing/Betterfox/refs/heads/main/Peskyfox.js"
    "https://raw.githubusercontent.com/yokoffing/Betterfox/refs/heads/main/Smoothfox.js"
    "https://raw.githubusercontent.com/yokoffing/Betterfox/refs/heads/main/user.js"
  )
  for i in "${!files[@]}"; do
    if [ ! -e "$BETTER_FOX/${files[$i]}" ]; then
      if curl -s -L "${base_urls[$i]}" -o "$BETTER_FOX/${files[$i]}"; then
        echo "${files[$i]} downloaded"
      fi
    fi
  done

  # Verify all files exist
  for file in "${files[@]}"; do
    if [ ! -e "$BETTER_FOX/$file" ]; then
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
  elif [ "$flav" == "floorp" ]; then
    base_dir="$FLOORP_HOME"
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
  local flavor="$1"
  local profile="$2"

  # Determine the base directory based on the flavor.
  local base_dir
  base_dir=$(get_base_dir "$flavor")
  local profile_chrome_dir="$base_dir/$profile/chrome"

  # Check if the chrome directory exists.
  if [ ! -d "$profile_chrome_dir" ]; then
    echo "No chrome folder found for $profile"
    return
  fi

  local backup_timestamp
  backup_timestamp=$(date +%F_%H%M%S_%N)

  if [ "$flavor" == "firefox" ]; then
    # Backup the entire chrome directory by renaming it.
    local backup_chrome_dir="$base_dir/$profile/chrome-$backup_timestamp"

    if mv "$profile_chrome_dir" "$backup_chrome_dir"; then
      printf "Successfully backed up '%s' to '%s'\n" "$profile_chrome_dir" "$backup_chrome_dir"
    else
      printf "Error: Failed to backup '%s' to '%s'\n" "$profile_chrome_dir" "$backup_chrome_dir"
      return 1
    fi
  elif [ "$flavor" == "zen" ]; then
    # Backup userChrome.css if it exists.
    local user_chrome_css="$profile_chrome_dir/userChrome.css"
    if [ -e "$user_chrome_css" ]; then
      local backup_dir="$base_dir/$profile/chrome-$backup_timestamp"
      mkdir -p "$backup_dir"
      if mv "$user_chrome_css" "$backup_dir"; then
        printf "Successfully backed up '%s' to '%s'\n" "$user_chrome_css" "$backup_dir"
      else
        printf "Error: Failed to backup '%s' to '%s'\n" "$user_chrome_css" "$backup_dir"
        return 1
      fi
    fi
  else
    printf "No chrome setup for flavor '%s'\n" "$flavor"
  fi
}

chrome_css_setup() {
  local flavor="$1"
  local profile="$2"
  local config="$3"
  local base_dir
  base_dir=$(get_base_dir "$flavor")
  local profile_chrome_dir="$base_dir/$profile/chrome"

  backup_chrome_css "$flavor" "$profile"

  if [ "$flavor" == "firefox" ]; then
    mkdir -p "$base_dir/$profile/chrome"
    pushd "$CONFIG_HOME" >/dev/null || exit
    if [ "$config" == "rec" ]; then
      cp -R ./chrome/ui ./chrome/content ./chrome/*-rec/* "$profile_chrome_dir"
    else
      cp -R ./chrome/ui ./chrome/content ./chrome/*-coding/* "$profile_chrome_dir"
    fi
    popd >/dev/null || exit
  fi
  if [ "$flavor" == "zen" ]; then
    mkdir -p "$base_dir/$profile/chrome"
    local config_chrome_zen_css="$CONFIG_HOME/chrome/zen/userChrome.css"
    if [ -e "$config_chrome_zen_css" ]; then
      cp -f "$config_chrome_zen_css" "$profile_chrome_dir"
    fi
  fi
}

user_js_overrides_setup() {
  local flavor="$1" # "firefox", "zen", or "floorp"
  local profile="$2"
  local config="$3"
  local base_dir
  base_dir=$(get_base_dir "$flavor")
  local overrides_target="$base_dir/$profile/user.js-overrides"
  local overrides_dir="$CONFIG_HOME/user.js-overrides"

  # Backup old overrides if exists & re-create target folder
  [ -d "$overrides_target" ] && mv "$overrides_target" "${overrides_target}-$(date +%F_%H%M%S_%N)"
  mkdir -p "$overrides_target"

  if [ "$config" == "fastfox" ]; then
    cp -R "$overrides_dir"/*-"$config".js "$overrides_target"
    cp -R "$BETTER_FOX"/smoothfox.js "$overrides_target"
  else
    cp -R "$overrides_dir"/0-base.js "$overrides_dir"/*-"$config".js "$overrides_target"
  fi

  # For "zen" flavor add our own zen override if exists.
  if [ "$flavor" == "zen" ] && [ -e "$overrides_dir/_zen.js" ]; then
    cp -R "$overrides_dir"/_zen.js "$overrides_target"
  fi

  # For "floorp" flavor add our own floorp override if exists.
  if [ "$flavor" == "floorp" ] && [ -e "$overrides_dir/_floorp.js" ]; then
    cp -R "$overrides_dir"/_floorp.js "$overrides_target"
  fi

  # check if temp files exist
  if [ ! -e "$TMP/user.js" ] || [ ! -e "$TMP/prefsCleaner.sh" ] || [ ! -e "$TMP/updater.sh" ]; then
    install_essentials
  fi
  if [ "$config" == "fastfox" ] && [ ! -e "$BETTER_FOX"/"$config".js ]; then
    install_betterfox_essentials
  fi

  # Copy the essential files into the profile directory
  if [ "$config" == "fastfox" ]; then
    cp -R "$BETTER_FOX"/"$config".js "$base_dir/$profile"/user.js
  else
    cp -R "$TMP"/user.js "$base_dir/$profile"
  fi

  pushd "$TMP" >/dev/null || exit
  cp -R "$CONFIG_HOME"/updater.sh prefsCleaner.sh "$base_dir/$profile"
  # cp -R updater.sh prefsCleaner.sh "$base_dir/$profile"
  cp -R prefsCleaner.sh "$base_dir/$profile"

  # Run updater
  pushd "$base_dir/$profile" >/dev/null || exit
  # sh ./updater.sh -d -s -o user.js-overrides
  sh ./updater.sh -o user.js-overrides
  popd >/dev/null || exit

  echo "Profile '$profile' configuration complete!"
}

# Determine the target base directory using flavor
get_base_dir() {
  local flavor="$1"
  if [ "$flavor" == "zen" ]; then
    echo "$ZEN_HOME"
  elif [ "$flavor" == "floorp" ]; then
    echo "$FLOORP_HOME"
  else
    echo "$FIREFOX_HOME"
  fi
}

config_profile() {
  local flavor="$1" # "firefox", "zen", or "floorp"
  local profile="$2"
  local config="$3"
  local target_dir
  target_dir=$(get_base_dir "$flavor")

  # Check if profile directory exists
  if [ ! -d "$target_dir/$profile" ]; then
    echo "Profile '$profile' does not exist in $target_dir."
    return
  fi

  # If config is not provided, ask for default
  local valid_conf=""
  for conf in "${CONFIGS[@]}"; do
    if [ "$config" == "$conf" ]; then
      valid_conf="$conf"
      break
    fi
  done
  if [ -z "$config" ]; then
    printf "Config not specified... Use default config (coding)? [y/n] "
    read -r answer
    if [ "$answer" == "y" ]; then
      config="coding"
    else
      echo "Exiting..."
      exit 1
    fi
  fi

  # Quick check: if the user passed a matching config as profile name, use that.
  if [ -z "$valid_conf" ]; then
    echo "Invalid config '$config'. Available configs are: ${CONFIGS[*]}"
    echo "Exiting..."
    exit 1
  fi

  echo "Using config: $config"

  backup_profile_history "$flavor" "$profile"
  chrome_css_setup "$flavor" "$profile" "$config"
  user_js_overrides_setup "$flavor" "$profile" "$config"
}

# Generic functions for profile management (create, delete, clear, list)
create_profile() {
  local flavor="$1" # "firefox", "zen", or "floorp"
  local profile="$2"
  local target_dir
  target_dir=$(get_base_dir "$flavor")
  # Command to create a profile differs based on flavor.
  if [ "$flavor" == "zen" ]; then
    zen -CreateProfile "${profile^} $target_dir/${profile,,}"
  elif [ "$flavor" == "floorp" ]; then
    floorp -CreateProfile "${profile^} $target_dir/${profile,,}"
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
  rm -rf "$target_dir/$profile:?"
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
  # options=$(find . -maxdepth 1 -type d -exec basename {} \; | grep -v -E '^(\.|\.\.|firefox-|zen-|floorp-)$')
  options=$(find . -maxdepth 1 -type d -exec basename {} \; | grep -v '^.$' | grep -v '^..$' | grep -v '^firefox-' | grep -v '^Profile Groups')
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
  notify-send -t 2000 "Profiles" "Opening $(capitalize "$choice") profile..."

  if [ "$base_dir" == "$FIREFOX_HOME" ]; then
    firefox -P "$(capitalize "$choice")"
  elif [ "$base_dir" == "$FLOORP_HOME" ]; then
    floorp -P "$(capitalize "$choice")"
  else
    # For zen, check for extra command
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
  echo "  -p <profile> <cfg>    : Configure a Firefox profile"
  echo "  -clear <profile>      : Clear old configs in a Firefox profile"
  echo "  -clear-all            : Clear old configs in all Firefox profiles"
  echo "  -backup <profile>     : Backup Firefox profile history"
  echo "  -all                  : Configure all Firefox profiles"
  echo "  -coding, -dev, etc.   : Quick config for designated profiles"
  echo ""
  echo "  # Zen commands"
  echo "  -zen-new <profile>    : Create a new Zen profile"
  echo "  -zen-del <profile>    : Delete a Zen profile"
  echo "  -zen-p <profile> <cfg>: Configure a Zen profile"
  echo "  -zen-profiles [extra] : List all Zen profiles"
  echo "  -zen-clear <profile>  : Clear old configs in a Zen profile"
  echo "  -zen-clear-all        : Clear old configs in all Zen profiles"
  echo "  -zen-all              : Configure all Zen profiles"
  echo ""
  echo "  # Floorp commands"
  echo "  -floorp-new <profile>        : Create a new Floorp profile"
  echo "  -floorp-del <profile>        : Delete a Floorp profile"
  echo "  -floorp-p <profile> <cfg>    : Configure a Floorp profile"
  echo "  -floorp-profiles             : List all Floorp profiles"
  echo "  -floorp-clear <profile>      : Clear old configs in a Floorp profile"
  echo "  -floorp-clear-all            : Clear old configs in all Floorp profiles"
  echo "  -floorp-all                  : Configure all Floorp profiles"
  exit 0
}

while [ "$#" -gt 0 ]; do
  curr=$1
  shift

  case "$curr" in
  --help | -h) print_help ;;
  -clone) clone_config ;;
  -reinstall)
    mkdir -p "$HOME/.local/bin"
    [ -e "$HOME/.local/bin/fuj" ] && rm -f "$HOME/.local/bin/fuj"
    ln -s "$CONFIG_HOME/setup.sh" "$HOME/.local/bin/fuj"
    echo "Installed 'fuj' command"
    ;;
  -install)
    mkdir -p "$HOME/.local/bin"
    if [ -e "$HOME/.local/bin/fuj" ]; then
      echo "fuj already exists in $HOME/.local/bin"
      exit 1
    fi
    ln -s "$CONFIG_HOME/setup.sh" "$HOME/.local/bin/fuj"
    echo "Installed 'fuj' command"
    ;;
  -upd)
    install_essentials update
    install_betterfox_essentials update
    ;;
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
    [ -z "$profile" ] && {
      echo "missing profile"
      exit 1
    }
    [ -z "$config" ] && {
      echo "missing config"
      exit 1
    }
    shift 2
    config_profile "firefox" "$profile" "$config"
    ;;
  -coding | -def | -dev | -main | -rec | -rgt | -social)
    flag="${curr#-}"
    if [ "$flag" == "social" ]; then
      config="dev"
    elif [ "$flag" == "def" ]; then
      flag="default"
      config="coding"
    else
      config="$flag"
    fi
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
    for prof in coding default dev main rec rgt social; do
      clear_old_configs "$FIREFOX_HOME" "$prof"
    done
    echo "All Firefox profiles cleared!"
    ;;
  #########################
  # Zen commands
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
    [ -z "$profile" ] && {
      echo "missing profile"
      exit 1
    }
    [ -z "$config" ] && {
      echo "missing config"
      exit 1
    }
    shift 2
    config_profile "zen" "$profile" "$config"
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
    for prof in coding default dev debug jellyfin main rec rgt; do
      clear_old_configs "$ZEN_HOME" "$prof"
    done
    echo "All Zen profiles cleared!"
    ;;
  -zen-all)
    config_profile "zen" "default" "coding" &&
      config_profile "zen" "debug" "coding" &&
      config_profile "zen" "dev" &&
      config_profile "zen" "jellyfin" "rec" &&
      config_profile "zen" "main" &&
      config_profile "zen" "rec" &&
      config_profile "zen" "rgt" &&
      config_profile "zen" "social" "dev" &&
      echo "All Zen profiles completed!"
    ;;
  #########################
  # Floorp commands (added support for floorp)
  -floorp-new)
    profile=$1
    shift
    create_profile "floorp" "$profile"
    ;;
  -floorp-del)
    profile=$1
    shift
    delete_profile "floorp" "$profile"
    ;;
  -floorp-p)
    profile=$1
    config="$2"
    [ -z "$profile" ] && {
      echo "missing profile"
      exit 1
    }
    [ -z "$config" ] && {
      echo "missing config"
      exit 1
    }
    shift 2
    config_profile "floorp" "$profile" "$config"
    ;;
  -floorp-profiles)
    get_profiles "$FLOORP_HOME"
    ;;
  -floorp-clear)
    profile="$1"
    shift
    clear_profile_configs "floorp" "$profile"
    ;;
  -floorp-clear-all)
    for prof in coding default dev main rec rgt social; do
      clear_old_configs "$FLOORP_HOME" "$prof"
    done
    echo "All Floorp profiles cleared!"
    ;;
  -floorp-all)
    for prof in coding default; do
      if [ "$prof" == "default" ]; then
        config_profile "floorp" "$prof" "coding"
      else
        config_profile "floorp" "$prof" "$prof"
      fi
    done
    echo "All Floorp profiles completed!"
    ;;
  *) echo "Unavailable command... $curr" ;;
  esac
done
