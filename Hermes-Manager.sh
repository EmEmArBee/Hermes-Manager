#!/bin/bash
# ─────────────────────────────────────────────────────────────────
#  hermes-manager  —  Interactive Hermes CLI Manager
#  github.com/EmEmArBee/Hermes-Manager/
#  GNU GPLv3
#  Requirements: whiptail (apt install whiptail)
#  Install:      sudo cp hermes-manager /usr/local/bin/hermes-manager
#                chmod +x /usr/local/bin/hermes-manager
# ─────────────────────────────────────────────────────────────────

HERMES_BASE="$HOME/.hermes"
PROFILES_DIR="$HERMES_BASE/profiles"
SCRIPT_PATH="$(realpath "$0")"

# ANSI colors for terminal output
R='\033[0;31m' G='\033[0;32m' Y='\033[1;33m'
C='\033[0;36m' W='\033[0m'

run() {
    echo -e "${C}▶ $*${W}"
    eval "$@"
}

pause() {
    echo ""
    read -rp "  [Press Enter to continue]"
}

# ══════════════════════════════════════════════════════════════════
#  PROFILE DISCOVERY — runs at every startup
# ══════════════════════════════════════════════════════════════════
discover_profiles() {
    PROFILES=("default")

    if [ -d "$PROFILES_DIR" ]; then
        while IFS= read -r -d '' dir; do
            name="$(basename "$dir")"
            PROFILES+=("$name")
        done < <(find "$PROFILES_DIR" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)
    fi
}

profile_path() {
    if [ "$1" = "default" ]; then
        echo "$HERMES_BASE"
    else
        echo "$PROFILES_DIR/$1"
    fi
}

# ══════════════════════════════════════════════════════════════════
#  FIRST-RUN: offer to install
# ══════════════════════════════════════════════════════════════════
check_install() {
    local INSTALL_TARGET="/usr/local/bin/hermes-manager"

    # Already installed at target path — skip
    [ "$SCRIPT_PATH" = "$INSTALL_TARGET" ] && return

    # Already installed somewhere else in PATH — skip
    command -v hermes-manager &>/dev/null && return

    whiptail --title "🚀 hermes-manager — First Run" \
        --yesno "hermes-manager is not installed system-wide yet.\n\nInstall it to /usr/local/bin/hermes-manager\nso you can run it from anywhere with 'hermes-manager'?" \
        10 62 || return

    if sudo cp "$SCRIPT_PATH" "$INSTALL_TARGET" && sudo chmod +x "$INSTALL_TARGET"; then
        whiptail --title "✅ Installed" \
            --msgbox "Installed successfully!\nYou can now run:  hermes-manager" 8 52
    else
        whiptail --title "❌ Error" \
            --msgbox "Installation failed.\nTry manually:\n  sudo cp \"$SCRIPT_PATH\" $INSTALL_TARGET" 10 58
    fi
}

# ══════════════════════════════════════════════════════════════════
#  MAIN MENU
# ══════════════════════════════════════════════════════════════════
main_menu() {
    while true; do
        CHOICE=$(whiptail --title "⚡ Hermes Manager" \
            --menu "Select an area:" 20 64 7 \
            "1" "👤  Profiles" \
            "2" "🩺  Hermes Doctor" \
            "3" "🔄  Hermes Update" \
            "4" "🌐  Gateway — Stop / Restart ALL" \
            "5" "⚙️   Hermes General Commands" \
            "6" "🔀  Quick Profile Switcher" \
            "Q" "❌  Quit" \
            3>&1 1>&2 2>&3) || exit 0

        case "$CHOICE" in
            1) menu_profiles ;;
            2) run hermes doctor; pause ;;
            3) run hermes update; pause ;;
            4) menu_gateway_all ;;
            5) menu_hermes_general ;;
            6) quick_switcher ;;
            Q) exit 0 ;;
        esac
    done
}

# ══════════════════════════════════════════════════════════════════
#  PROFILES — list + rescan option
# ══════════════════════════════════════════════════════════════════
menu_profiles() {
    while true; do
        # Build menu items dynamically from discovered profiles
        local ITEMS=()
        local i=1
        for P in "${PROFILES[@]}"; do
            if [ "$P" = "default" ]; then
                ITEMS+=("$i" "default  (main profile)")
            else
                ITEMS+=("$i" "$P")
            fi
            (( i++ ))
        done
        ITEMS+=("R" "🔍  Re-scan profiles")
        ITEMS+=("B" "← Back")

        local ROWS=$(( ${#PROFILES[@]} + 4 ))
        [ "$ROWS" -gt 18 ] && ROWS=18

        CHOICE=$(whiptail --title "👤 Profiles" \
            --menu "Select a profile:" "$ROWS" 54 "$(( ROWS - 4 ))" \
            "${ITEMS[@]}" \
            3>&1 1>&2 2>&3) || return

        case "$CHOICE" in
            R)
                discover_profiles
                whiptail --title "🔍 Scan complete" \
                    --msgbox "Found ${#PROFILES[@]} profile(s):\n$(printf '  • %s\n' "${PROFILES[@]}")" \
                    $(( ${#PROFILES[@]} + 6 )) 48
                ;;
            B) return ;;
            *)
                local IDX=$(( CHOICE - 1 ))
                menu_profile_detail "${PROFILES[$IDX]}"
                ;;
        esac
    done
}

# ══════════════════════════════════════════════════════════════════
#  SINGLE PROFILE PANEL
# ══════════════════════════════════════════════════════════════════
menu_profile_detail() {
    local PROF="$1"
    local PPATH=$(profile_path "$PROF")

    while true; do
        CHOICE=$(whiptail --title "👤 Profile: $PROF" \
            --menu "What do you want to do?" 22 64 10 \
            "ED" "📝  EDIT files" \
            "BK" "💾  BACKUP files" \
            "RM" "🗑️   REMOVE files" \
            "IM" "📥  Import SOUL.md from another profile" \
            "G1" "▶️   Gateway status" \
            "G2" "🔁  Gateway restart" \
            "G3" "⏹️   Gateway stop" \
            "P1" "🔀  Activate this profile" \
            "IN" "ℹ️   Show paths" \
            "B"  "← Back" \
            3>&1 1>&2 2>&3) || return

        case "$CHOICE" in
            ED) menu_edit_profile "$PROF" ;;
            BK) menu_backup_profile "$PROF" ;;
            RM) menu_remove_profile "$PROF" ;;
            IM) import_soul "$PROF" ;;
            G1) run hermes gateway status --profile "$PROF"; pause ;;
            G2) run hermes gateway restart --profile "$PROF"; pause ;;
            G3) run hermes gateway stop --profile "$PROF"; pause ;;
            P1) run hermes profile use "$PROF"; pause ;;
            IN) show_paths_one "$PROF" ;;
            B)  return ;;
        esac
    done
}

# ══════════════════════════════════════════════════════════════════
#  EDIT
# ══════════════════════════════════════════════════════════════════
menu_edit_profile() {
    local PROF="$1"
    local PPATH=$(profile_path "$PROF")

    while true; do
        CHOICE=$(whiptail --title "📝 EDIT — $PROF" \
            --menu "Which file?" 13 55 4 \
            "1" "SOUL.md" \
            "2" "config.yaml" \
            "3" ".env" \
            "B" "← Back" \
            3>&1 1>&2 2>&3) || return

        case "$CHOICE" in
            1) nano "$PPATH/SOUL.md" ;;
            2) nano "$PPATH/config.yaml" ;;
            3) nano "$PPATH/.env" ;;
            B) return ;;
        esac
    done
}

# ══════════════════════════════════════════════════════════════════
#  BACKUP
# ══════════════════════════════════════════════════════════════════
menu_backup_profile() {
    local PROF="$1"
    local PPATH=$(profile_path "$PROF")

    while true; do
        CHOICE=$(whiptail --title "💾 BACKUP — $PROF" \
            --menu "Which file?" 12 55 3 \
            "1" "config.yaml" \
            "2" "SOUL.md" \
            "B" "← Back" \
            3>&1 1>&2 2>&3) || return

        case "$CHOICE" in
            1) backup_file "$PPATH/config.yaml" "config" "$PROF" "$PPATH" ;;
            2) backup_file "$PPATH/SOUL.md"     "SOUL"   "$PROF" "$PPATH" ;;
            B) return ;;
        esac
    done
}

backup_file() {
    local SRC="$1"
    local TYPE="$2"
    local PROF="$3"
    local PPATH="$4"
    local DEFAULT_NAME="${TYPE}_${PROF}_$(date +%Y%m%d)"
    local EXT
    [ "$TYPE" = "config" ] && EXT=".yaml" || EXT=".md"

    local DEST_NAME
    DEST_NAME=$(whiptail --title "💾 Backup $TYPE — $PROF" \
        --inputbox "Backup filename (no extension):" \
        8 60 "$DEFAULT_NAME" 3>&1 1>&2 2>&3) || return

    local DEST="$PPATH/${DEST_NAME}${EXT}"

    if cp "$SRC" "$DEST"; then
        whiptail --title "✅ Backup OK" --msgbox "Saved to:\n$DEST" 8 68
    else
        whiptail --title "❌ Error" --msgbox "Could not copy:\n$SRC" 8 55
    fi
}

# ══════════════════════════════════════════════════════════════════
#  REMOVE
# ══════════════════════════════════════════════════════════════════
menu_remove_profile() {
    local PROF="$1"
    local PPATH=$(profile_path "$PROF")

    while true; do
        CHOICE=$(whiptail --title "🗑️  REMOVE — $PROF" \
            --menu "Which file do you want to delete?" 13 58 4 \
            "1" "SOUL.md" \
            "2" "config.yaml" \
            "3" ".env" \
            "B" "← Back" \
            3>&1 1>&2 2>&3) || return

        case "$CHOICE" in
            1) remove_file "$PPATH/SOUL.md"     "SOUL.md"     "$PROF" ;;
            2) remove_file "$PPATH/config.yaml" "config.yaml" "$PROF" ;;
            3) remove_file "$PPATH/.env"        ".env"        "$PROF" ;;
            B) return ;;
        esac
    done
}

remove_file() {
    local TARGET="$1"
    local FNAME="$2"
    local PROF="$3"

    whiptail --title "⚠️  WARNING" \
        --yesno "Are you sure you want to delete:\n\n  $TARGET\n\nThis operation is IRREVERSIBLE.\nMake a backup first!" \
        12 65 || return

    if rm "$TARGET"; then
        whiptail --title "✅ Deleted" --msgbox "$FNAME has been deleted." 7 50
    else
        whiptail --title "❌ Error" --msgbox "Could not delete:\n$TARGET" 8 55
    fi
}

# ══════════════════════════════════════════════════════════════════
#  IMPORT SOUL.md
# ══════════════════════════════════════════════════════════════════
import_soul() {
    local DEST_PROF="$1"
    local DEST_PATH=$(profile_path "$DEST_PROF")

    # Build list of other profiles as source options
    local ITEMS=()
    for P in "${PROFILES[@]}"; do
        [ "$P" = "$DEST_PROF" ] && continue
        ITEMS+=("$P" "$P")
    done

    if [ ${#ITEMS[@]} -eq 0 ]; then
        whiptail --title "ℹ️  No other profiles" \
            --msgbox "No other profiles found to import from." 8 50
        return
    fi

    local SRC_PROF
    SRC_PROF=$(whiptail --title "📥 Import SOUL.md" \
        --menu "Import from which profile?" 14 52 8 \
        "${ITEMS[@]}" \
        3>&1 1>&2 2>&3) || return

    local SRC_PATH=$(profile_path "$SRC_PROF")

    whiptail --title "⚠️  Confirm import" \
        --yesno "Overwrite SOUL.md of '$DEST_PROF'\nwith the one from '$SRC_PROF'?\n\nThe original will be lost — make a backup first!" \
        10 62 || return

    if cp "$SRC_PATH/SOUL.md" "$DEST_PATH/SOUL.md"; then
        whiptail --title "✅ Imported" \
            --msgbox "SOUL.md copied:\n  $SRC_PROF  →  $DEST_PROF" 8 55
    else
        whiptail --title "❌ Error" --msgbox "Could not copy the file." 8 45
    fi
}

# ══════════════════════════════════════════════════════════════════
#  SHOW PATHS
# ══════════════════════════════════════════════════════════════════
show_paths_one() {
    local PROF="$1"
    local PPATH=$(profile_path "$PROF")
    local INFO
    INFO="── $PROF ──\n\n"
    INFO+="  Settings : $PPATH/config.yaml\n"
    INFO+="  API Keys : $PPATH/.env\n"
    INFO+="  Soul     : $PPATH/SOUL.md\n"
    INFO+="  Cron     : $PPATH/cron/\n"
    INFO+="  Sessions : $PPATH/sessions/\n"
    INFO+="  Logs     : $PPATH/logs/\n"
    whiptail --title "ℹ️  Paths — $PROF" --msgbox "$INFO" 14 68
}

# ══════════════════════════════════════════════════════════════════
#  GATEWAY — STOP / RESTART ALL
# ══════════════════════════════════════════════════════════════════
menu_gateway_all() {
    while true; do
        # Build a summary of all profiles for display
        local PROF_LIST
        PROF_LIST=$(printf '%s ' "${PROFILES[@]}")

        CHOICE=$(whiptail --title "🌐 Gateway — All Profiles" \
            --menu "Action (applies to: $PROF_LIST):" 13 62 3 \
            "1" "⏹️   Stop ALL profiles" \
            "2" "🔁  Restart ALL profiles" \
            "B" "← Back" \
            3>&1 1>&2 2>&3) || return

        case "$CHOICE" in
            1)
                local CMD=""
                for P in "${PROFILES[@]}"; do
                    [ -n "$CMD" ] && CMD+=" && "
                    CMD+="hermes gateway stop --profile $P"
                done
                run "$CMD"
                pause
                ;;
            2)
                local CMD=""
                for P in "${PROFILES[@]}"; do
                    [ -n "$CMD" ] && CMD+=" && "
                    CMD+="hermes gateway restart --profile $P"
                done
                run "$CMD"
                pause
                ;;
            B) return ;;
        esac
    done
}

# ══════════════════════════════════════════════════════════════════
#  HERMES GENERAL COMMANDS
# ══════════════════════════════════════════════════════════════════
menu_hermes_general() {
    while true; do
        CHOICE=$(whiptail --title "⚙️  Hermes General Commands" \
            --menu "What do you want to do?" 22 64 10 \
            "1"  "🗨️   Start chat  (hermes)" \
            "2"  "🌐  Start gateway  (hermes gateway)" \
            "3"  "🧙  Setup — Full wizard" \
            "4"  "🤖  Setup — Model / Provider" \
            "5"  "🖥️   Setup — Terminal backend" \
            "6"  "📡  Setup — Gateway" \
            "7"  "🔧  Setup — Tool providers" \
            "8"  "👁️   View current config" \
            "9"  "✏️   Open config in editor" \
            "10" "🔩  Set config value (key/value)" \
            "B"  "← Back" \
            3>&1 1>&2 2>&3) || return

        case "$CHOICE" in
            1)  run hermes; pause ;;
            2)  run hermes gateway; pause ;;
            3)  run hermes setup; pause ;;
            4)  run hermes setup model; pause ;;
            5)  run hermes setup terminal; pause ;;
            6)  run hermes setup gateway; pause ;;
            7)  run hermes setup tools; pause ;;
            8)  run hermes config; pause ;;
            9)  run hermes config edit ;;
            10) set_config_value ;;
            B)  return ;;
        esac
    done
}

set_config_value() {
    local KEY VAL
    KEY=$(whiptail --title "Config set" --inputbox "Key (e.g. model):" 8 50 3>&1 1>&2 2>&3) || return
    VAL=$(whiptail --title "Config set" --inputbox "Value:" 8 50 3>&1 1>&2 2>&3) || return
    run hermes config set "$KEY" "$VAL"
    pause
}

# ══════════════════════════════════════════════════════════════════
#  QUICK PROFILE SWITCHER
# ══════════════════════════════════════════════════════════════════
quick_switcher() {
    local ITEMS=()
    local i=1
    for P in "${PROFILES[@]}"; do
        ITEMS+=("$i" "$P")
        (( i++ ))
    done

    local ROWS=$(( ${#PROFILES[@]} + 4 ))
    [ "$ROWS" -gt 16 ] && ROWS=16

    CHOICE=$(whiptail --title "🔀 Quick Profile Switcher" \
        --menu "Activate profile:" "$ROWS" 50 "$(( ROWS - 4 ))" \
        "${ITEMS[@]}" \
        3>&1 1>&2 2>&3) || return

    local IDX=$(( CHOICE - 1 ))
    local PROF="${PROFILES[$IDX]}"
    run hermes profile use "$PROF"
    pause
}

# ══════════════════════════════════════════════════════════════════
#  ENTRY POINT
# ══════════════════════════════════════════════════════════════════
if ! command -v whiptail &>/dev/null; then
    echo -e "${R}[ERROR]${W} whiptail not found. Install with:"
    echo "  sudo apt install whiptail"
    exit 1
fi

if [ ! -d "$HERMES_BASE" ]; then
    echo -e "${R}[ERROR]${W} Hermes base directory not found: $HERMES_BASE"
    echo "  Is Hermes installed for this user?"
    exit 1
fi

# Discover profiles on startup
discover_profiles

# Offer install on first run
check_install

# Launch
main_menu