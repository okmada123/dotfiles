#!/usr/bin/env bash
set -eu

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Check if the script is running as root and ask whether to continue
if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
  echo -e "${YELLOW}Warning:${NC} This script is running as root."
  read -r -p "Do you really want to continue as root? [y/N] " reply
  reply="${reply:-N}"
  if [[ ! "$reply" =~ ^[Yy]$ ]]; then
    echo -e "${RED}Aborting.${NC}"
    exit 1
  fi
fi

# Display the HOME directory and ask the user to confirm it
echo -e "${CYAN}Detected HOME directory:${NC} ${BOLD}${HOME}${NC}"
read -r -p "Is this the home directory where you want to create symlinks? [Y/n] " reply
reply="${reply:-Y}"
if [[ ! "$reply" =~ ^[Yy]$ ]]; then
  echo -e "${RED}Aborting.${NC}"
  exit 1
fi

# Determine and print the directory where this script is located
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
echo -e "${CYAN}Script directory:${NC} ${BOLD}${SCRIPT_DIR}${NC}, ${CYAN}script name:${NC} ${BOLD}${SCRIPT_NAME}${NC}"

# Collect all files from the script directory into an array
files_array=()
while IFS= read -r line; do
  # Parse ls -la output: skip the first line (total) and extract filename (last field)
  # Skip lines starting with 'd' (directories) and 'total'
  [[ "$line" =~ ^total ]] && continue
  [[ "$line" =~ ^d ]] && continue
  
  # Extract filename (last field after all spaces)
  filename=$(echo "$line" | awk '{print $NF}')
  
  # Skip . and ..
  [[ "$filename" == "." ]] || [[ "$filename" == ".." ]] && continue
  
  # Construct full path
  file="${SCRIPT_DIR}/${filename}"
  
  # Skip if not a file (e.g., directories)
  [[ ! -f "$file" ]] && continue
  
  # Skip .gitignore and this script itself
  if [[ "$filename" == ".gitignore" ]] || [[ "$filename" == "$SCRIPT_NAME" ]]; then
    continue
  fi
  
  # Skip .git directory (though this should be caught by -f check above)
  if [[ "$filename" == ".git" ]]; then
    continue
  fi
  
  # Add filename to array
  files_array+=("$filename")
done < <(ls -la "${SCRIPT_DIR}")

# Dotfiles to be symlinked
echo -e "${CYAN}Dotfiles to be symlinked:${NC}"
for filename in "${files_array[@]}"; do
  echo -e "  ${BOLD}${filename}${NC}"
done
echo ""

# Iterate over the array and process each file
for filename in "${files_array[@]}"; do
  # Construct full path
  file="${SCRIPT_DIR}/${filename}"
  
  # Process the file: check if it exists in home directory, backup if needed, create symlink
  home_file="${HOME}/${filename}"
  
  # Determine what will happen
  action_msg=""
  if [[ -e "$home_file" ]]; then
    if [[ -L "$home_file" ]]; then
      action_msg="${YELLOW}File ${BOLD}${filename}${NC}${YELLOW} exists as a symlink in ${HOME}. It will be replaced with a symlink to ${file}.${NC}"
    else
      action_msg="${YELLOW}File ${BOLD}${filename}${NC}${YELLOW} exists in ${HOME}. It will be backed up to ${BOLD}${home_file}.bkp${NC}${YELLOW} and replaced with a symlink to ${file}.${NC}"
    fi
  else
    action_msg="${CYAN}File ${BOLD}${filename}${NC}${CYAN} does not exist in ${HOME}. A symlink will be created pointing to ${file}.${NC}"
  fi
  
  # Ask for permission
  echo ""
  echo -e "$action_msg"
  read -r -p "$(echo -e ${CYAN}Proceed?${NC} [Y/n] ) " reply
  reply="${reply:-Y}"
  if [[ ! "$reply" =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Skipping ${BOLD}${filename}${NC}${YELLOW}.${NC}"
    continue
  fi
  
  # Create backup if file exists and is not already a symlink to our target
  if [[ -e "$home_file" ]]; then
    # Check if it's already the correct symlink
    if [[ -L "$home_file" ]] && [[ "$(readlink -f "$home_file")" == "$(readlink -f "$file")" ]]; then
      echo -e "  ${GREEN}✓${NC} ${BOLD}${filename}${NC} is already correctly symlinked. ${CYAN}Skipping.${NC}"
      continue
    fi
    
    # Create backup
    echo -e "  ${BLUE}Creating backup:${NC} ${BOLD}${home_file}.bkp${NC}"
    mv "$home_file" "${home_file}.bkp"
  fi
  
  # Create symlink
  echo -e "  ${BLUE}Creating symlink:${NC} ${BOLD}${home_file}${NC} ${CYAN}->${NC} ${BOLD}${file}${NC}"
  ln -s "$file" "$home_file"
  echo -e "  ${GREEN}✓${NC} ${BOLD}${filename}${NC} ${GREEN}symlinked successfully.${NC}"
done
