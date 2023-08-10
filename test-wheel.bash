#!/usr/bin/env bash

my_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
. "$my_dir/python.bash"

venv=$(mktemp -d)
echo "→ Setting up a virtual environment in $venv using python '$(which python3)' ($(python3 --version))..."
python3 -m venv "$venv"
source "$venv/$activate_path"
python -m pip install -U pip
pip install pytest

cleanup=true

trap '
  failed_pids=()
  for pid in $(jobs -p); do
    if kill -0 $pid >/dev/null 2>&1; then
      echo "Process $pid is still running."
    else
      exit_status=$?
      if [[ $exit_status -eq 0 ]]; then
        echo "Process $pid exited with zero status."
      else
        echo "Process $pid exited with nonzero status ($exit_status)."
        failed_pids+=("$pid")
      fi
    fi
  done
  
  if [[ -n $(jobs -p) ]]; then
    echo "→ Killing $(jobs -p)"
    kill $(jobs -p)
  fi

  if [[ "$cleanup" == "true" ]]; then
    echo "→ Removing $venv"; rm -rf "$venv"
  fi

  if [[ ${#failed_pids[@]} -gt 0 ]]; then
    echo "The following background processes exited with nonzero status: ${failed_pids[@]}"
    exit 1
  fi
  ' EXIT

while [[ $# -gt 0 ]]; do
  case $1 in
    -w|--wheels-dir)
      echo "→ Installing wheels from $2 ..."
      pip install --no-deps "$2"/*
      shift
      shift
      ;;
    -b|--background)
      echo "→ Launching Background Task $2 ..."
      $2 &
      sleep 5
      shift
      shift
      ;;
    -f|--foreground)
      echo "→ Starting $2 ..."
      $2
      shift
      shift
      ;;
    -c|--cleanup)
      echo "The temporary virtual will be deleted: $2"
      cleanup=$2
      shift
      shift
      ;;
  esac
done

exit 0
