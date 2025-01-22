#!/bin/bash
export LC_ALL=en_US.UTF-8
CONFIG_HOME=$HOME/.dots/firefox-user.js
FIREFOX_HOME=$HOME/.mozilla/firefox/profiles
ZEN_HOME=$HOME/.zen
TMP="$CONFIG_HOME/temp"

mkdir -p "$FIREFOX_HOME"
mkdir -p "$HOME/.dots"
mkdir -p "$TMP"
mkdir -p "$ZEN_HOME"

capitalize() {
  word="$1"
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

  if [[ -n "$update" && "$update" == "update" ]]; then
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

clear_old_configs() {
  dir="$1"
  profile="$2"

  cd "$dir" || exit

  if [ -d "$dir/$profile" ]; then
    cd "$dir/$profile" || exit

    if ls -d chrome-* 1>/dev/null 2>&1; then
      rm -r chrome-*
    fi
    if ls -d user.js-overrides-* 1>/dev/null 2>&1; then
      rm -r user.js-overrides-*
    fi
  else
    echo "Profile dir not found. Exiting..."
  fi
}

backup_profile_history() {
  flav="$1"
  profile="$2"

  dir="$FIREFOX_HOME"

  if [ "$flav" == "zen" ]; then
    dir="$ZEN_HOME"
  fi

  backup_dir=""$HOME/.dots/${flav}_backups""
  mkdir -p "$backup_dir"
  if [ -f "$dir/$profile/places.sqlite" ]; then
    mkdir -p "$backup_dir/$profile"
    time=$(date +%F_%H%M%S_%N)
    cp "$dir/$profile/places.sqlite" "$backup_dir/$profile/places-$time.sqlite"
  fi
}

backup_chrome_css() {
  dir="$1"
  profile="$2"

  if [ -d "$dir/$profile/chrome" ]; then
    mv "$dir/$profile/chrome" "$dir/$profile/chrome-$(date +%F_%H%M%S_%N)"
  fi
}

chrome_css_setup() {
  dir="$1"
  profile="$2"
  config="$3"
  ff_ultima="$4"

  backup_chrome_css "$dir" "$profile"

  mkdir -p "$dir/$profile/chrome"

  pushd "$CONFIG_HOME" || exit

  if [ -n "$ff_ultima" ]; then
    cp -R ./FF-ULTIMA/theme ./FF-ULTIMA/userChrome.css ./FF-ULTIMA/userContent.css "$FIREFOX_HOME/$profile/chrome"
    return
  fi

  if [ "$config" == "rec" ]; then
    cp -R ./chrome/ui ./chrome/content ./chrome/*-rec/* "$dir/$profile/chrome"
  else
    cp -R ./chrome/ui ./chrome/content ./chrome/*-coding/* "$dir/$profile/chrome"
  fi
}

backup_user_js_overrides() {
  dir="$1"
  profile="$2"

  if [ -d "$dir/$profile/user.js-overrides" ]; then
    mv "$dir/$profile/user.js-overrides" "$dir/$profile/user.js-overrides-$(date +%F_%H%M%S_%N)"
  fi
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
  flav="$1"
  dir="$2"
  profile="$3"
  config="$4"
  ff_ultima="$5"

  backup_user_js_overrides "$dir" "$profile"

  mkdir -p "$dir/$profile/user.js-overrides"

  pushd "$CONFIG_HOME" || exit

  if [ -e "./user.js-overrides/_ffu_base.js" ]; then
    rm ./user.js-overrides/_ffu_base.js
  fi

  if [ -n "$ff_ultima" ]; then
    ff_ultima_overrides_setup
  else
    cp -R ./user.js-overrides/_base.js ./user.js-overrides/*-"$config"/* "$dir/$profile/user.js-overrides"
  fi

  if [ "$flav" == "zen" ]; then
    cp -R ./user.js-overrides/_zen.js "$dir/$profile/user.js-overrides"
  fi

  pushd "$TMP" || exit

  cp -R user.js updater.sh prefsCleaner.sh "$dir/$profile"

  pushd "$dir/$profile" || exit
  sh ./updater.sh -d -s -o user.js-overrides
  cd "$CONFIG_HOME" || exit
  if [ -e "./user.js-overrides/_ffu_base.js" ]; then
    rm ./user.js-overrides/_ffu_base.js
  fi
  echo "Profile '$profile' Completed!"
}

config_profile() {
  configs=("coding" "dev" "main" "rec" "rgt")

  flav="$1"
  profile="$2"

  if [ "$flav" == "firefox" ]; then
    cd "$FIREFOX_HOME" || exit
  elif [ "$flav" == "zen" ]; then
    cd "$ZEN_HOME" || exit
  else
    echo "Invalid flavor... Exiting..."
    exit 1
  fi

  options=$(find . -maxdepth 1 -type d -name '*' -exec basename {} \; | grep -v '^.$' | grep -v '^..$')

  profile_exists=false
  for element in $options; do
    if [ "$element" = "$profile" ]; then
      echo "Found $element"
      profile_exists=true
      break
    fi
  done

  if [ "$profile_exists" = false ]; then
    echo "Profile does not exist"
    exit 1
  fi

  if [ -z "$profile" ]; then
    echo "Profile not found... Exiting..."
    exit 1
  fi

  config="$3"
  ff_ultima="$4"

  for i in "${configs[@]}"; do
    if [ "$profile" == "$i" ]; then
      config="$i"
      break
    fi
  done

  if [ -z "$config" ]; then
    printf "Config not specified... Do you want to use default config (coding)? [y/n] "
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
      backup_profile_history "$flav" "$profile"
      if [ "$flav" == "zen" ]; then
        setup_zen "$profile" "$config" "$ff_ultima"
        return
      fi
      setup_firefox "$profile" "$config" "$ff_ultima"
      return
    fi
  done

  echo "Invalid config: $config"
}

get_profiles() {
  dir="$1"
  extra="$2"

  cd "$dir" || exit
  # options=$(find . -maxdepth 1 -type d -name '*' -exec basename {} \; | grep -v '^.$' | grep -v '^..$')
  options=$(find . -maxdepth 1 -type d -exec basename {} \; | grep -v '^.$' | grep -v '^..$' | grep -v '^firefox-')
  # options=$(dir | xargs -n 1 -P 1 echo "$0" | awk '{print $2}')
  choice="$(echo "$options" | sort | dmenu -l 10 -p 'Choose :')"

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
  if [ "$dir" == "$FIREFOX_HOME" ]; then
    firefox -P "$profile"
  else
    if [ "$extra" == "twilight" ]; then
      zen-tw -P "$profile"
    else
      zen -P "$profile"
    fi
  fi
}

# OG Firefox
setup_firefox() {
  install_essentials

  profile="$1"
  config="$2"
  ff_ultima="$3"

  dir="$FIREFOX_HOME"

  mkdir -p "$dir/$profile"

  chrome_css_setup "$dir" "$profile" "$config" "$ff_ultima"

  user_js_overrides_setup "firefox" "$dir" "$profile" "$config" "$ff_ultima"
}

config_firefox() {
  profile="$1"
  config="$2"
  ff_ultima="$3"

  config_profile "firefox" "$profile" "$config" "$ff_ultima"
}

get_firefox_profiles() {
  get_profiles "$FIREFOX_HOME"
}

create_firefox_profile() {
  profile="$1"
  firefox -CreateProfile "${profile^} $FIREFOX_HOME/${profile,,}"
  printf "Profile created: %s" "$profile"
}

delete_firefox_profile() {
  profile="$1"
  sudo rm -r "$FIREFOX_HOME/$profile"
  printf "Profile deleted: %s" "$profile"
}

clear_old_firefox_configs() {
  profile="$1"

  dir="$FIREFOX_HOME"

  clear_old_configs "$dir" "$profile"
}

# Zen
setup_zen() {
  install_essentials

  profile="$1"
  config="$2"
  ff_ultima="$3"

  dir="$ZEN_HOME"

  mkdir -p "$dir/$profile"

  user_js_overrides_setup "zen" "$dir" "$profile" "$config" "$ff_ultima"
}

config_zen() {
  profile="$1"
  config="$2"
  ff_ultima="$3"

  config_profile "zen" "$profile" "$config" "$ff_ultima"
}

get_zen_profiles() {
  get_profiles "$ZEN_HOME" "$1"
}

create_zen_profile() {
  profile="$1"
  zen -CreateProfile "${profile^} $ZEN_HOME/${profile,,}"
  printf "Profile created: %s" "$profile"
}

clear_old_zen_configs() {
  profile="$1"

  dir="$ZEN_HOME"

  clear_old_configs "$dir" "$profile"
}

while [ "$#" -gt 0 ]; do
  curr=$1
  shift

  case "$curr" in
  --help | -h)
    echo "Usage: fuj [options]"
    echo "Options:"
    echo "  -install: Install 'fuj' command"
    echo "  -new <profile> <config>: Create a new profile"
    echo "  -del <profile>: Delete a profile"
    echo "  -profiles: List all profiles"
    echo "  -p <profile> <config> <ff_ultima>: Configure a profile"
    echo "  -clear <profile>: Clear old configs"
    echo "  -backup <profile>: Backup profile history"
    echo "  -clear-all: Clear all old configs"
    echo "  -all: Configure all profiles"
    echo "  -coding: Configure coding profile"
    echo "  -def: Configure default profile"
    echo "  -dev: Configure dev profile"
    echo "  -main: Configure main profile"
    echo "  -rec: Configure rec profile"
    echo "  -rgt: Configure rgt profile"
    echo "  -social: Configure social profile"
    echo "  -upd: Update user.js"
    echo "  -clone: Clone firefox-user.js"
    exit 0
    ;;
  -zen-new)
    profile=$1
    if [ -z "$profile" ]; then
      echo "missing profile"
      exit 1
    fi
    shift
    create_zen_profile "$profile"
    ;;
  -zen-p)
    profile=$1
    if [ -z "$profile" ]; then
      echo "missing profile"
      exit 1
    fi
    config="$2"
    ff_ultima="$3"
    if [ -n "$config" ]; then
      shift
    else
      echo "missing config"
      exit 1
    fi
    if [ -n "$ff_ultima" ]; then
      shift
    fi
    shift
    config_zen "$profile" "$config" "$ff_ultima"
    ;;
  -zen-profiles)
    get_zen_profiles "$1"
    ;;
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
  -zen-clear)
    profile=$1
    if [ -z "$profile" ]; then
      echo "missing profile"
      exit 1
    fi

    shift
    clear_old_zen_configs "$profile"
    ;;
  -new)
    profile=$1
    if [ -z "$profile" ]; then
      echo "missing profile"
      exit 1
    fi
    shift
    create_firefox_profile "$profile"
    ;;
  -del)
    profile=$1
    if [ -z "$profile" ]; then
      echo "missing profile"
      exit 1
    fi
    shift
    delete_firefox_profile "$profile"
    ;;
  -profiles)
    get_firefox_profiles
    ;;
  -p)
    profile=$1
    if [ -z "$profile" ]; then
      echo "missing profile"
      exit 1
    fi
    config="$2"
    ff_ultima="$3"
    if [ -n "$config" ]; then
      shift
    else
      echo "missing config"
      exit 1
    fi
    if [ -n "$ff_ultima" ]; then
      shift
    fi
    shift
    config_firefox "$profile" "$config" "$ff_ultima"
    ;;
  -coding) config_firefox "coding" ;;
  -def) config_firefox "default" ;;
  -dev) config_firefox "dev" ;;
  -main) config_firefox "main" ;;
  -rec) config_firefox "rec" ;;
  -rgt) config_firefox "rgt" ;;
  -social) config_firefox "social" "dev" ;;
  -upd) install_essentials update ;;
  -clear)
    profile=$1
    if [ -z "$profile" ]; then
      echo "missing profile"
      exit 1
    fi

    shift
    clear_old_firefox_configs "$profile"
    ;;
  -backup)
    profile=$1
    if [ -z "$profile" ]; then
      echo "missing profile"
      exit 1
    fi

    shift
    backup_profile_history "firefox" "$profile"
    ;;
  -clear-all)
    clear_old_firefox_configs "coding"
    clear_old_firefox_configs "default"
    # clear_old_firefox_configs "dev"
    clear_old_firefox_configs "main"
    clear_old_firefox_configs "rec"
    # clear_old_firefox_configs "rgt"
    # clear_old_firefox_configs "social"
    ;;
  -zen-clear-all)
    clear_old_zen_configs "code"
    # clear_old_zen_configs "coding"
    # clear_old_zen_configs "default"
    clear_old_zen_configs "debug"
    clear_old_zen_configs "dev"
    clear_old_zen_configs "jellyfin"
    clear_old_zen_configs "main"
    clear_old_zen_configs "rec"
    clear_old_zen_configs "rgt"
    ;;
  -all)
    config_firefox "coding" &&
      config_firefox "default" "coding" &&
      # config_firefox "dev" &&
      config_firefox "main" &&
      config_firefox "rec" &&
      # config_firefox "rgt" &&
      # config_firefox "social" "dev" &&
      echo "All profiles completed!"
    ;;
  -zen-all)
    config_zen "code" "coding" &&
      # config_zen "default" "coding" &&
      config_zen "debug" "coding" &&
      config_zen "dev" &&
      config_zen "jellyfin" "rec" &&
      config_zen "main" &&
      config_zen "rec" &&
      config_zen "rgt" &&
      # config_zen "social" "dev" &&
      echo "All profiles completed!"
    ;;
  *) echo "Unavailable command... $curr" ;;
  esac
done
