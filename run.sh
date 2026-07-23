#!/bin/bash

# Based on: Felipe Avelar (https://github.com/FelipeFMA)
# Original code: Nguyen Khac Trung Kien (https://github.com/trung-kieen)
# Web implementation by: Luna Heip (https://github.com/Revecoa)

# Description: Plays ASCII animation of Bad Apple!! synced with optional audio

# As of 23 July 2026, an online version is available on:
# https://revecoa.skydinse.net/badapple.sh
# Usage: bash <(curl -sL https://revecoa.skydinse.net/badapple.sh) [options]


URL_RESOURCES="https://revecoa.skydinse.net/badapple"


# Usage and arguments
usage() {
    echo
    echo "Usage: command [options]"
    echo "  -h, --help              Display this help message"
    echo "  -o, --offline           Play in offline mode (only available if run locally)"
    echo "  -s, --skip              Skip connection checks"
    echo "  -m, --mpv [true|false]  Toggles playing audio using mpv"
    echo "  -u, --url (url)         Use custom base URL for online mode"
    echo
    exit 0
}


# Default values
OFFLINE=false
SKIP_CHECK=false
USE_MPV=""
FRAME_TIME=0.033333


badapple() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                usage
                ;;
            -o|--offline)
                OFFLINE=true
                shift
                ;;
            -s|--skip)
                SKIP_CHECK=true
                shift
                ;;
            -m|--mpv)
                if [[ "$2" == "true" || "$2" == "false" ]]; then
                    USE_MPV=$2
                    echo "Use mpv for playback: $USE_MPV"
                    shift 2
                else
                    USE_MPV=true
                    echo "Use mpv for playback: $USE_MPV"
                    shift
                fi
                ;;
            -u|--url)
                if [[ -n "$2" ]]; then
                    URL_RESOURCES=$2
                    echo "Use base url: $2"
                    shift 2
                else
                    echo "Error: -u/--url requires a url."
                    usage
                fi
                ;;
            *)
                echo "Unknown option: $1"
                usage
                ;;
        esac
    done


    # Interactive prompt if -m/--mpv was not provided
    if [[ -z "$USE_MPV" ]]; then
        read -p "Do you want to use mpv to play sound? You need mpv installed. (y/n): " choice
        if [[ $choice =~ ^[Yy]$ ]]; then
            USE_MPV=true
        else
            USE_MPV=false
        fi
    fi


    # If mpv is to be used, check if it's installed
    if [[ $USE_MPV == true ]] && ! command -v mpv &> /dev/null; then
        echo -e "\nmpv is not installed. Please install it to use this feature.\n"
        exit 1
    fi


    # Cleanup temporary files automatically when the script exits or is aborted (Ctrl+C)
    cleanup() {
        [[ ! $OFFLINE == true ]] && rm -rf "$FRAMES_DIR"
        # Kill background mpv if it's still running
        if [ -n "$MPV_PID" ]; then kill "$MPV_PID" 2>/dev/null || true; fi
        # Restore cursor
        tput cnorm
    }
    trap cleanup EXIT


    # Get frames
    # Online mode
    if [[ $OFFLINE == false ]]; then
        TAR_URL="${URL_RESOURCES}/frames.tar.gz"
        AUDIO_LOCATION="${URL_RESOURCES}/bad_apple.mp3"

        # Check if server is reachable
        if [[ $SKIP_CHECK == false ]]; then
            echo "Checking server connection..."

            # Check if server is reachable
            response=$(curl -s -o /dev/null -w "%{http_code}" -L --connect-timeout 5 "$TAR_URL")
            curl_exit_status=$?

            if [ $curl_exit_status -ne 0 ]; then
                echo "Failed to reach server at $URL_RESOURCES (curl exit status: $curl_exit_status). Re-running script in offline mode."
                sleep 1
                badapple "$@" "-o"
                exit 0
            fi

            if [[ "$response" -lt 200 || "$response" -ge 400 ]]; then
                echo "Failed to reach server at $URL_RESOURCES (HTTP response code: $response). Re-running script in offline mode."
                sleep 1
                badapple "$@" "-o"
                exit 0
            fi
        fi

        echo "Playing in online mode"

        # Pre-Download all frames (Required for playing in sync)
        # Create a temporary directory in shared memory (RAM disk) for fast read times
        FRAMES_DIR="/dev/shm/badapple_$$"
        if [ ! -d "/dev/shm" ]; then
            FRAMES_DIR="/tmp/badapple_$$" # Fallback if /dev/shm doesn't exist
        fi
        mkdir -p "$FRAMES_DIR"

        echo "Buffering frames into memory for smooth playback..."
        # Fetch the tarball from server and extract it directly into RAM
        if ! curl -s -f "$TAR_URL" | tar -xzf - --strip-components=1 -C "$FRAMES_DIR"; then
            echo "Error: Could not download the frames archive from the server."
            exit 1
        fi

    # Offline mode
    else
        echo "Playing in offline mode"

        FRAMES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/frames-ascii"
        AUDIO_LOCATION="$(dirname "$FRAMES_DIR")/bad_apple.mp3"

        if [[ ! -d "$FRAMES_DIR" ]]; then
            echo "No local frames directory found in $FRAMES_DIR. Please clone the entire project to run this script locally."
            exit 1
        fi
    fi


    # Start audio
    if [[ $USE_MPV == true ]]; then
        mpv "$AUDIO_LOCATION" > /dev/null 2>&1 &
        MPV_PID=$!
    fi


    # Clear screen and hide cursor
    printf "\033c"
    tput civis 2>/dev/null


    # Load all frame paths into a Bash array to eliminate disk I/O bottlenecks during playback
    echo "Loading frames into memory..."
    frames=()
    while IFS= read -r f; do frames+=("$f"); done < <(ls -v "$FRAMES_DIR"/out*.jpg.txt)

    # Playback loop setup using high-precision built-in Bash epoch variables
    start_time=$EPOCHREALTIME
    frame_idx=0
    total_frames=${#frames[@]}

    tput clear

    while [ $frame_idx -lt $total_frames ]; do
        tput cup 0 0
        # Print frames
        printf "%s" "$(<"${frames[$frame_idx]}")"
        
        ((frame_idx++))
        
        # Calculate absolute target time for the next frame relative to the video start timestamp
        next_frame_target=$(echo "$start_time + ($frame_idx * $FRAME_TIME)" | bc)
        current_time=$EPOCHREALTIME
        
        sleep_time=$(echo "$next_frame_target - $current_time" | bc)
        
        # Only sleep if the execution is ahead of schedule. If lagging behind, drop/skip sleeping to catch up
        if (( $(echo "$sleep_time > 0" | bc) )); then
            sleep "$sleep_time"
        fi
    done



    # Restore cursor when done
    tput cnorm
    exit 0
}

badapple "$@"
exit 0
