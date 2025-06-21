#!/usr/bin/env bash

## Simplified user.js updater
## Apply overrides to existing user.js file

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
NC='\033[0m'

# Defaults
OVERRIDES_DIR=""
PROFILE_PATH="."
BACKUP='multiple'

usage() {
  echo "Usage: $0 -o OVERRIDES_DIR [-p PROFILE] [-b] [-h]"
  echo ""
  echo "Required Arguments:"
  echo "    -o OVERRIDES_DIR Path to directory containing override .js files"
  echo ""
  echo "Optional Arguments:"
  echo "    -p PROFILE       Path to Firefox profile directory (default: current directory)"
  echo "    -b               Only keep one backup file"
  echo "    -h               Show this help"
  exit 1
}

add_overrides_from_dir() {
  local dir="$1"
  if [ ! -d "$dir" ]; then
    echo -e "${ORANGE}Warning: Override directory not found: ${dir}${NC}"
    return 1
  fi

  local override_count=0
  for f in "$dir"/*.js; do
    if [ -f "$f" ]; then
      echo "" >>user.js
      cat "$f" >>user.js
      echo -e "Status: ${GREEN}Override file appended:${NC} $(basename "$f")"
      ((override_count++))
    fi
  done

  if [ $override_count -eq 0 ]; then
    echo -e "${ORANGE}Warning: No .js files found in override directory${NC}"
  fi
}

# Parse arguments
while getopts ":ho:p:b" opt; do
  case $opt in
  h) usage ;;
  o) OVERRIDES_DIR="$OPTARG" ;;
  p) PROFILE_PATH="$OPTARG" ;;
  b) BACKUP='single' ;;
  \?)
    echo -e "${RED}Invalid option: -$OPTARG${NC}" >&2
    usage
    ;;
  :)
    echo -e "${RED}Option -$OPTARG requires an argument${NC}" >&2
    exit 1
    ;;
  esac
done

# Validate required arguments
if [ -z "$OVERRIDES_DIR" ]; then
  echo -e "${RED}Error: -o argument (overrides directory) is required${NC}"
  usage
fi

# Change to profile directory
cd "$PROFILE_PATH" || {
  echo -e "${RED}Error: Cannot access profile directory: $PROFILE_PATH${NC}"
  exit 1
}

# Check if user.js exists
if [ ! -f "user.js" ]; then
  echo -e "${RED}Error: user.js file not found in profile directory: $PROFILE_PATH${NC}"
  exit 1
fi

# Backup existing user.js
mkdir -p userjs_backups
bakname="userjs_backups/user.js.backup.$(date +"%Y-%m-%d_%H%M")"
[ "$BACKUP" = 'single' ] && bakname='userjs_backups/user.js.backup'
cp user.js "$bakname"
echo -e "Status: ${GREEN}user.js backed up to: $bakname${NC}"

# Apply overrides
add_overrides_from_dir "$OVERRIDES_DIR"

echo -e "${GREEN}Process completed successfully!${NC}"
echo -e "Profile: ${ORANGE}$PROFILE_PATH${NC}"
echo -e "Overrides applied from: ${ORANGE}$OVERRIDES_DIR${NC}"
