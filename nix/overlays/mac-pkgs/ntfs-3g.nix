{
  lib,
  stdenv,
  writeScriptBin,
  ntfs3g,
  ...
}:

writeScriptBin "ntfs-3g" ''
  #!/bin/bash
  
  # NTFS-3G wrapper for macOS with macFUSE
  # Provides read-write NTFS support using macFUSE
  
  set -e
  
  DEVICE=""
  MOUNTPOINT=""
  OPTIONS="rw,allow_other,local"
  
  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
      -o)
        if [[ -n "$2" ]]; then
          OPTIONS="$2"
        fi
        shift 2
        ;;
      -*)
        # Add other options to the options string
        OPTIONS="$OPTIONS,$1"
        shift
        ;;
      *)
        if [[ -z "$DEVICE" ]]; then
          DEVICE="$1"
        elif [[ -z "$MOUNTPOINT" ]]; then
          MOUNTPOINT="$1"
        fi
        shift
        ;;
    esac
  done
  
  if [[ -z "$DEVICE" || -z "$MOUNTPOINT" ]]; then
    echo "Usage: ntfs-3g <device> <mountpoint> [options]"
    echo "NTFS-3G for macOS with macFUSE - provides read-write NTFS support"
    exit 1
  fi
  
  # Check if macFUSE is available
  if ! [ -f "/Library/Filesystems/macfuse.fs/Contents/Resources/mount_macfuse" ]; then
    echo "Error: macFUSE is not installed"
    echo "Please install macFUSE via: brew install --cask macfuse"
    echo "After installation, you may need to approve the system extension in System Settings."
    exit 1
  fi
  
  # Create mount point if it doesn't exist
  if [ ! -d "$MOUNTPOINT" ]; then
    echo "Creating mount point: $MOUNTPOINT"
    sudo mkdir -p "$MOUNTPOINT"
  fi
  
  echo "Mounting NTFS device $DEVICE at $MOUNTPOINT with read-write access..."
  
  # Set volume name if not specified
  VOLNAME=$(basename "$MOUNTPOINT")
  if [[ "$OPTIONS" != *"volname="* ]]; then
    OPTIONS="$OPTIONS,volname=$VOLNAME"
  fi
  
  # Use the nixpkgs ntfs-3g with proper macFUSE integration
  exec ${ntfs3g}/bin/ntfs-3g "$DEVICE" "$MOUNTPOINT" -o "$OPTIONS"
'' 