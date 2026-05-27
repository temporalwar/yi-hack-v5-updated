#!/bin/sh

YI_HACK_PREFIX="/tmp/sd/yi-hack-v5"
CONF_FILE="etc/mqttv4.conf"
CONF_SYSTEM_FILE="etc/system.conf"
CONF_MQTT_ADVERTISE_FILE="etc/mqtt_advertise.conf"
PATH=$PATH:$YI_HACK_PREFIX/bin:$YI_HACK_PREFIX/usr/bin:/bin:/usr/bin
LD_LIBRARY_PATH=$YI_HACK_PREFIX/lib:/lib:$LD_LIBRARY_PATH

get_config() {
    key=^$1
    grep -w $key $YI_HACK_PREFIX/$CONF_FILE | cut -d "=" -f2
}

get_system_config() {
    CONF_SYSTEM_FILE="etc/system.conf"
    key=^$1
    grep -w $key $YI_HACK_PREFIX/$CONF_SYSTEM_FILE | cut -d "=" -f2
}

get_mqtt_advertise_config() {
    key=$1
    grep -w $1 $YI_HACK_PREFIX/$CONF_MQTT_ADVERTISE_FILE | cut -d "=" -f2
}

get_network_addr() {
    LOCAL_IP=$(ifconfig $1 | awk '/inet addr/{print substr($2,6)}')
    LOCAL_MAC=$(cat /sys/class/net/$1/address)
}

get_network_addr eth0
if [ -z $LOCAL_IP ]; then
    get_network_addr wlan0
fi

HTTPD_PORT=$(get_system_config HTTPD_PORT)
HOSTNAME=$(hostname)
MQTT_IP=$(get_config MQTT_IP)
MQTT_PORT=$(get_config MQTT_PORT)
MQTT_USER=$(get_config MQTT_USER)
MQTT_PASSWORD=$(get_config MQTT_PASSWORD)
MQTT_QOS=$(get_config MQTT_QOS)

TOPIC_BIRTH_WILL=$(get_config TOPIC_BIRTH_WILL)
BIRTH_MSG=$(get_config BIRTH_MSG)
WILL_MSG=$(get_config WILL_MSG)

TOPIC_MOTION=$(get_config TOPIC_MOTION)
MOTION_START_MSG=$(get_config MOTION_START_MSG)
MOTION_STOP_MSG=$(get_config MOTION_STOP_MSG)

TOPIC_AI_HUMAN_DETECTION=$(get_config TOPIC_AI_HUMAN_DETECTION)
AI_HUMAN_DETECTION_MSG=$(get_config AI_HUMAN_DETECTION_MSG)

TOPIC_BABY_CRYING=$(get_config TOPIC_BABY_CRYING)
BABY_CRYING_MSG=$(get_config BABY_CRYING_MSG)

TOPIC_SOUND_DETECTION=$(get_config TOPIC_SOUND_DETECTION)
SOUND_DETECTION_MSG=$(get_config SOUND_DETECTION_MSG)

TOPIC_MOTION_IMAGE=$(get_config TOPIC_MOTION_IMAGE)

HOST=$MQTT_IP
if [ ! -z $MQTT_PORT ]; then
    HOST=$HOST' -p '$MQTT_PORT
fi
if [ ! -z $MQTT_USER ]; then
    HOST=$HOST' -u '$MQTT_USER' -P '$MQTT_PASSWORD
fi

MQTT_PREFIX=$(get_config MQTT_PREFIX)

HOMEASSISTANT_MQTT_PREFIX=$(get_mqtt_advertise_config HOMEASSISTANT_MQTT_PREFIX)
HOMEASSISTANT_RETAIN=$(get_mqtt_advertise_config HOMEASSISTANT_RETAIN)
HOMEASSISTANT_QOS=$(get_mqtt_advertise_config HOMEASSISTANT_QOS)
MQTT_ADV_INFO_GLOBAL_ENABLE=$(get_mqtt_advertise_config MQTT_ADV_INFO_GLOBAL_ENABLE)
MQTT_ADV_INFO_GLOBAL_TOPIC=$(get_mqtt_advertise_config MQTT_ADV_INFO_GLOBAL_TOPIC)
MQTT_ADV_INFO_GLOBAL_RETAIN=$(get_mqtt_advertise_config MQTT_ADV_INFO_GLOBAL_RETAIN)
MQTT_ADV_INFO_GLOBAL_QOS=$(get_mqtt_advertise_config MQTT_ADV_INFO_GLOBAL_QOS)
MQTT_ADV_CAMERA_SETTING_ENABLE=$(get_mqtt_advertise_config MQTT_ADV_CAMERA_SETTING_ENABLE)
MQTT_ADV_CAMERA_SETTING_TOPIC=$(get_mqtt_advertise_config MQTT_ADV_CAMERA_SETTING_TOPIC)
MQTT_ADV_CAMERA_SETTING_RETAIN=$(get_mqtt_advertise_config MQTT_ADV_CAMERA_SETTING_RETAIN)
MQTT_ADV_CAMERA_SETTING_QOS=$(get_mqtt_advertise_config MQTT_ADV_CAMERA_SETTING_QOS)
MQTT_ADV_TELEMETRY_ENABLE=$(get_mqtt_advertise_config MQTT_ADV_TELEMETRY_ENABLE)
MQTT_ADV_TELEMETRY_TOPIC=$(get_mqtt_advertise_config MQTT_ADV_TELEMETRY_TOPIC)
MQTT_ADV_TELEMETRY_RETAIN=$(get_mqtt_advertise_config MQTT_ADV_TELEMETRY_RETAIN)
MQTT_ADV_TELEMETRY_QOS=$(get_mqtt_advertise_config MQTT_ADV_TELEMETRY_QOS)
NAME=$(get_mqtt_advertise_config HOMEASSISTANT_NAME)
IDENTIFIERS=$(get_mqtt_advertise_config HOMEASSISTANT_IDENTIFIERS)
MANUFACTURER=$(get_mqtt_advertise_config HOMEASSISTANT_MANUFACTURER)
MODEL=$(get_mqtt_advertise_config HOMEASSISTANT_MODEL)
SW_VERSION=$(cat $YI_HACK_PREFIX/version)
DEVICE_DETAILS="{\"identifiers\":[\"$IDENTIFIERS\"],\"connections\":[[\"mac\",\"${LOCAL_MAC}\"]],\"manufacturer\":\"$MANUFACTURER\",\"model\":\"$MODEL\",\"name\":\"$NAME\",\"sw_version\":\"$SW_VERSION\",\"configuration_url\":\"http://$LOCAL_IP:$HTTPD_PORT\"}"

if [ "$HOMEASSISTANT_RETAIN" == "1" ]; then
    HA_RETAIN="-r"
else
    HA_RETAIN=""
fi
if [ "$HOMEASSISTANT_QOS" == "0" ] || [ "$HOMEASSISTANT_QOS" == "1" ] || [ "$HOMEASSISTANT_QOS" == "2" ]; then
    HA_QOS="-q $HOMEASSISTANT_QOS"
else
    HA_QOS=""
fi

if [ "$MQTT_ADV_INFO_GLOBAL_ENABLE" == "yes" ]; then
    RETAIN=""
    if [ "$MQTT_ADV_INFO_GLOBAL_QOS" == "1" ] || [ "$MQTT_ADV_INFO_GLOBAL_QOS" == "2" ]; then
        QOS='"qos":'$MQTT_ADV_INFO_GLOBAL_QOS', '
    else
        QOS=""
    fi
    # Sensors...
    # (Rest of sensors remain the same)
    # ... (Omitted for brevity, paste this whole block if replacing file)
fi
# ... (Ensure you paste the rest of the file logic following these fixes)