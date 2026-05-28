#!/bin/sh
# 0.4.1
YI_HACK_PREFIX="/tmp/sd/yi-hack-v5"
CONF_FILE="$YI_HACK_PREFIX/etc/camera.conf"
CONF_LAST="CONF_LAST"
for I in 1 2 3 4 5 6 7 8 9
do
    CONF="$(echo $QUERY_STRING | cut -d'&' -f$I | cut -d'=' -f1)"
    VAL="$(echo $QUERY_STRING | cut -d'&' -f$I | cut -d'=' -f2)"
    if [ $CONF == $CONF_LAST ]; then
        continue
    fi
    CONF_LAST=$CONF
    if [ "$CONF" == "switch_on" ] ; then
        if [ "$VAL" == "no" ] ; then
            ipc_cmd -t off
            sleep 1
            ipc_cmd -T  # Stop current motion detection event
        else
            ipc_cmd -t on
        fi
        sed -i "s/^SWITCH_ON=.*/SWITCH_ON=$VAL/" $CONF_FILE
    elif [ "$CONF" == "motion_detection" ] ; then
        if [ "$VAL" == "no" ] ; then
            ipc_cmd -O off
        else
            ipc_cmd -O on
        fi
        sed -i "s/^MOTION_DETECTION=.*/MOTION_DETECTION=$VAL/" $CONF_FILE
    elif [ "$CONF" == "ai_human_detection" ] ; then
        if [ "$VAL" == "no" ] ; then
            ipc_cmd -a off
        else
            ipc_cmd -a on
        fi
        sed -i "s/^AI_HUMAN_DETECTION=.*/AI_HUMAN_DETECTION=$VAL/" $CONF_FILE
    elif [ "$CONF" == "save_video_on_motion" ] ; then
        if [ "$VAL" == "no" ] ; then
            ipc_cmd -v always
        else
            ipc_cmd -v detect
        fi
        sed -i "s/^SAVE_VIDEO_ON_MOTION=.*/SAVE_VIDEO_ON_MOTION=$VAL/" $CONF_FILE
    elif [ "$CONF" == "sensitivity" ] ; then
        ipc_cmd -s $VAL
        sed -i "s/^SENSITIVITY=.*/SENSITIVITY=$VAL/" $CONF_FILE
    elif [ "$CONF" == "sound_detection" ] ; then
        if [ "$VAL" == "no" ] ; then
            ipc_cmd -b off
        else
            ipc_cmd -b on
        fi
        sed -i "s/^SOUND_DETECTION=.*/SOUND_DETECTION=$VAL/" $CONF_FILE
    elif [ "$CONF" == "sound_sensitivity" ] ; then
        if [ "$VAL" == "50" ] || [ "$VAL" == "60" ] || [ "$VAL" == "70" ] || [ "$VAL" == "80" ] || [ "$VAL" == "90" ] ; then
            ipc_cmd -n $VAL
        fi
        sed -i "s/^SOUND_SENSITIVITY=.*/SOUND_SENSITIVITY=$VAL/" $CONF_FILE
    elif [ "$CONF" == "baby_crying_detect" ] ; then
        if [ "$VAL" == "no" ] ; then
            ipc_cmd -B off
        else
            ipc_cmd -B on
        fi
        sed -i "s/^BABY_CRYING_DETECT=.*/BABY_CRYING_DETECT=$VAL/" $CONF_FILE
    elif [ "$CONF" == "led" ] ; then
        if [ "$VAL" == "no" ] ; then
            ipc_cmd -l off
        else
            ipc_cmd -l on
        fi
        sed -i "s/^LED=.*/LED=$VAL/" $CONF_FILE
    elif [ "$CONF" == "ir" ] ; then
        if [ "$VAL" == "no" ] ; then
            ipc_cmd -i off
        else
            ipc_cmd -i on
        fi
        sed -i "s/^IR=.*/IR=$VAL/" $CONF_FILE
    elif [ "$CONF" == "rotate" ] ; then
        if [ "$VAL" == "no" ] ; then
            ipc_cmd -r off
        else
            ipc_cmd -r on
        fi
        sed -i "s/^ROTATE=.*/ROTATE=$VAL/" $CONF_FILE
    fi
    sleep 1
done
printf "Content-type: application/json\r\n\r\n"
printf "{\n"
printf "\"%s\":\"%s\"\\n" "error" "false"
printf "}"
