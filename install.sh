#!/bin/bash
# =============================================================================
# Wear Time Tracker - Install Script
# =============================================================================
# Reads variables.env and produces ready-to-deploy Home Assistant files
# in the output/ directory with your entity values substituted in.
#
# Usage:
#   1. Copy variables.env and fill in your values
#   2. Run: ./install.sh
#   3. Copy output/wear_time_tracker.yaml into your HA packages/ directory
#   4. Use output/dashboard.yaml cards in your Lovelace dashboard
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VARS_FILE="$SCRIPT_DIR/variables.env"
OUTPUT_DIR="$SCRIPT_DIR/output"

# --- Preflight checks --------------------------------------------------------

if [ ! -f "$VARS_FILE" ]; then
    echo "Error: variables.env not found."
    echo "Fill in your entity values in variables.env, then re-run this script."
    exit 1
fi

# Source the variables (comments and blank lines are ignored by bash)
source "$VARS_FILE"

# Validate required variables are set and not empty
missing=()
for var in NOTIFY_SERVICE TTS_SERVICE DEFAULT_SPEAKER PRESENCE_SENSOR DEVICE_NAME; do
    if [ -z "${!var:-}" ]; then
        missing+=("$var")
    fi
done

if [ ${#missing[@]} -gt 0 ]; then
    echo "Error: The following required variables are not set in variables.env:"
    for var in "${missing[@]}"; do
        echo "  - $var"
    done
    exit 1
fi

# --- Derive computed values --------------------------------------------------

DEVICE_NAME_UPPER=$(echo "$DEVICE_NAME" | tr '[:lower:]' '[:upper:]')

# --- Generate output ---------------------------------------------------------

mkdir -p "$OUTPUT_DIR"

for template in wear_time_tracker.yaml dashboard.yaml; do
    if [ ! -f "$SCRIPT_DIR/$template" ]; then
        echo "Warning: $template not found, skipping."
        continue
    fi

    sed \
        -e "s|__NOTIFY_SERVICE__|${NOTIFY_SERVICE}|g" \
        -e "s|__TTS_SERVICE__|${TTS_SERVICE}|g" \
        -e "s|__DEFAULT_SPEAKER__|${DEFAULT_SPEAKER}|g" \
        -e "s|__PRESENCE_SENSOR__|${PRESENCE_SENSOR}|g" \
        -e "s|__DEVICE_NAME_UPPER__|${DEVICE_NAME_UPPER}|g" \
        -e "s|__DEVICE_NAME__|${DEVICE_NAME}|g" \
        "$SCRIPT_DIR/$template" > "$OUTPUT_DIR/$template"

    echo "  Generated: output/$template"
done

# --- Summary -----------------------------------------------------------------

echo ""
echo "Done! Your configured files are in: $OUTPUT_DIR/"
echo ""
echo "Next steps:"
echo "  1. Enable packages in your configuration.yaml (if not already):"
echo "       homeassistant:"
echo "         packages: !include_dir_named packages"
echo ""
echo "  2. Copy the package file into your HA config:"
echo "       cp output/wear_time_tracker.yaml /path/to/ha-config/packages/"
echo ""
echo "  3. Add the dashboard cards from output/dashboard.yaml to a"
echo "     Lovelace dashboard view (paste into raw YAML editor)."
echo ""
echo "  4. Restart Home Assistant to load the new entities."
echo ""
echo "  Substitutions applied:"
echo "    Notification service:  $NOTIFY_SERVICE"
echo "    TTS service:           $TTS_SERVICE"
echo "    Default speaker:       $DEFAULT_SPEAKER"
echo "    Presence sensor:       $PRESENCE_SENSOR"
echo "    Device name:           $DEVICE_NAME ($DEVICE_NAME_UPPER)"
