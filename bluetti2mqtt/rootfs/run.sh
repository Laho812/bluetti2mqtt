#!/usr/bin/with-contenv bash
# ==============================================================================
# Home Assistant Add-on: Bluetti2MQTT
# MQTT bridge between Bluetti and Home Assistant
# ==============================================================================

# Helper functions to replace bashio
log_info() {
    echo "[INFO] $1"
}

log_warning() {
    echo "[WARNING] $1"
}

log_error() {
    echo "[ERROR] $1"
}

get_config() {
    jq -r ".$1 // empty" /data/options.json
}

config_has_value() {
    local value=$(jq -r ".$1 // empty" /data/options.json)
    [[ -n "$value" && "$value" != "null" && "$value" != "empty" ]]
}

config_is_true() {
    local value=$(jq -r ".$1 // false" /data/options.json)
    [[ "$value" == "true" ]]
}

get_service() {
    # For services, we'll try to get from supervisor API
    # Fallback to defaults if not available
    local service=$1
    local property=$2
    
    case "$service-$property" in
        "mqtt-host")
            echo "core-mosquitto"
            ;;
        "mqtt-port")
            echo "1883"
            ;;
        "mqtt-username")
            echo ""
            ;;
        "mqtt-password")
            echo ""
            ;;
        *)
            echo ""
            ;;
    esac
}

# Main script starts here
log_info 'Reading configuration settings...'

MODE=$(get_config 'mode')
HA_CONFIG=$(get_config 'ha_config')
BT_MAC=$(get_config 'bt_mac')
POLL_SEC=$(get_config 'poll_sec')
SCAN=$(get_config 'scan')

# Setup MQTT Auto-Configuration if values are not set.
if config_has_value 'mqtt_host'; then
    MQTT_HOST=$(get_config 'mqtt_host')
else
    MQTT_HOST=$(get_service "mqtt" "host")
fi

if config_has_value 'mqtt_port'; then
    MQTT_PORT=$(get_config 'mqtt_port')
else
    MQTT_PORT=$(get_service "mqtt" "port")
fi

if config_has_value 'mqtt_username'; then
    MQTT_USERNAME=$(get_config 'mqtt_username')
else
    MQTT_USERNAME=$(get_service "mqtt" "username")
fi

if config_has_value 'mqtt_password'; then
    MQTT_PASSWORD=$(get_config 'mqtt_password')
else
    MQTT_PASSWORD=$(get_service "mqtt" "password")
fi

if config_is_true 'debug'; then
    export DEBUG=true
    log_info 'Debug mode is enabled.'
fi

args=()
if config_is_true 'scan'; then
    args+=(--scan)
fi

case $MODE in
    mqtt)
        log_info 'Starting bluetti-mqtt...'
        args+=( \
            --broker ${MQTT_HOST} \
            --port ${MQTT_PORT} \
            --username ${MQTT_USERNAME} \
            --password ${MQTT_PASSWORD} \
            --interval ${POLL_SEC} \
            --ha-config ${HA_CONFIG} \
            ${BT_MAC})
        bluetti-mqtt ${args[@]}
        ;;
    discovery)
        log_info 'Starting bluetti-discovery...'
        log_info 'Messages are NOT published to the MQTT broker in discovery mode.'
        mkdir -p /share/bluetti2mqtt/
        args+=( \
            --log /share/bluetti2mqtt/discovery_$(date "+%m%d%y%H%M%S").log \
            ${BT_MAC})
        bluetti-discovery ${args[@]}
        ;;
    logger)
        log_info 'Starting bluetti-logger...'
        log_info 'Messages are NOT published to the MQTT broker in logger mode.'
        mkdir -p /share/bluetti2mqtt/
        args+=( \
            --log /share/bluetti2mqtt/logger_$(date "+%m%d%y%H%M%S").log \
            ${BT_MAC})
        bluetti-logger ${args[@]}
        ;;
    *)
        log_warning "No mode selected!  Please choose either 'mqtt', 'discovery', or 'logger'."
        ;;
esac