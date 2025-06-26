{
  lib,
  stdenv,
  writeScriptBin,
  ...
}:

writeScriptBin "ntfs-3g" ''
  #!/bin/bash
  
  # Simple NTFS-3G wrapper for macOS with macFUSE
  # This script provides the ntfs-3g interface that Mounty expects
  
  set -e
  
  DEVICE=""
  MOUNTPOINT=""
  OPTIONS=""
  
  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
      -o)
        OPTIONS="$2"
        shift 2
        ;;
      -*)
        # Other options, add to OPTIONS
        OPTIONS="$OPTIONS $1"
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
    echo "NTFS-3G wrapper for macOS with macFUSE"
    exit 1
  fi
  
  # Check if macFUSE is available
  if ! command -v mount_osxfuse >/dev/null 2>&1 && ! command -v mount_macfuse >/dev/null 2>&1; then
    echo "Error: macFUSE is not installed or not in PATH"
    echo "Please install macFUSE via Homebrew: brew install --cask macfuse"
    exit 1
  fi
  
  echo "Mounting NTFS device $DEVICE at $MOUNTPOINT..."
  
  # Try to use native macOS NTFS support first (read-only)
  if mount -t ntfs "$DEVICE" "$MOUNTPOINT" 2>/dev/null; then
    echo "Mounted $DEVICE at $MOUNTPOINT (read-only)"
    exit 0
  fi
  
  # For now, just show info and suggest using Disk Utility
  echo "Note: This is a basic NTFS-3G wrapper."
  echo "For full read-write NTFS support, please use:"
  echo "1. Disk Utility (for basic access)"
  echo "2. A commercial NTFS driver like Paragon NTFS"
  echo "3. The full ntfs-3g package from Homebrew"
  
  exit 1
'' 