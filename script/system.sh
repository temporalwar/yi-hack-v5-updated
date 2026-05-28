#!/bin/sh

# 0.4.1

CONF_FILE="etc/system.conf"

if [ -d "/tmp/sd/yi-hack-v5" ]; then
        YI_HACK_PREFIX="/tmp/sd/yi-hack-v5"
elif [ -d "/home/yi-hack-v5" ]; then
        YI_HACK_PREFIX="/home/yi-hack-v5"
fi

YI_HACK_VER=$(cat /tmp/sd/yi-hack-v5/version)
MODEL_SUFFIX=$(cat /home/app/.camver)

YI_HACK_UPGRADE_PATH="/tmp/sd/$MODEL_SUFFIX"

get_config()
{
    key=$1
    grep -w $1 $YI_HACK_PREFIX/$CONF_FILE | cut -d "=" -f2 | awk 'NR==1 {print; exit}'
}

export LD_LIBRARY_PATH=/lib:/usr/lib:/home/lib:/home/app/locallib:/home/hisiko/hisilib:/tmp/sd/yi-hack-v5/lib:/home/yi-hack-v5/lib
export PATH=/usr/bin:/usr/sbin:/bin:/sbin:/home/base/tools:/home/yi-hack-v5/bin:/home/app/localbin:/home/base:/tmp/sd/yi-hack-v5/bin:/tmp/sd/yi-hack-v5/sbin:/tmp/sd/yi-hack-v5/usr/bin:/tmp/sd/yi-hack-v5/usr/sbin:/home/yi-hack-v5/sbin

#if [ ! -L "/var/run/utmp" ]; then
#  ln -sf /dev/null /var/run/utmp
#fi

# Upgrade wpa_supplicant modules - after 0.4.1 baseline
if [ -f $YI_HACK_PREFIX/wpa/wpa_supplicant_upgrade ]; then
	ifconfig wlan0 up
    echo "---backing up wpa---"
    cp /home/base/tools/wpa_supplicant $YI_HACK_PREFIX/wpa/wpa_supplicant_backup
    cp /home/base/tools/wpa_cli $YI_HACK_PREFIX/wpa/wpa_cli_backup
    cp /home/base/tools/wpa_passphrase $YI_HACK_PREFIX/wpa/wpa_passphrase_backup
    killall watch_process
    killall wpa*
    mv /tmp/sd/yi-hack-v5/wpa/*.so* /home/lib/
    mv /tmp/sd/yi-hack-v5/wpa/wpa_supplicant /home/base/tools/
    mv /tmp/sd/yi-hack-v5/wpa/wpa_cli /home/base/tools/
    mv /tmp/sd/yi-hack-v5/wpa/wpa_passphrase /home/base/tools/
    rm $YI_HACK_PREFIX/wpa/wpa_supplicant_upgrade
    reboot
    echo "---wpa upgrade done---"
else
	echo "---no wpa upgrade---"
fi

#reversing symlinks
if [ -L "/var/run/utmp" ]; then
  rm /var/run/utmp
  reboot
fi

if [ ! -L "~/.ash_history" ]; then
  ln -sf /dev/null ~/.ash_history
fi

if [ ! -L "/home/yi-hack-v5/.ash_history" ]; then
  ln -sf /dev/null /home/yi-hack-v5/.ash_history
fi

ulimit -s 1024
mkdir /dev/shm

# Remove core files, if any
rm -f $YI_HACK_PREFIX/bin/core
rm -f $YI_HACK_PREFIX/www/cgi-bin/core

touch /tmp/httpd.conf

if [ -f $YI_HACK_UPGRADE_PATH/yi-hack-v5/fw_upgrade_in_progress ]; then
    echo "#!/bin/sh" > /tmp/fw_upgrade_2p.sh
    echo "# Complete fw upgrade and restore configuration" >> /tmp/fw_upgrade_2p.sh
    echo "sleep 1" >> /tmp/fw_upgrade_2p.sh
    echo "cd $YI_HACK_UPGRADE_PATH" >> /tmp/fw_upgrade_2p.sh
    echo "cp -rf * .." >> /tmp/fw_upgrade_2p.sh
    echo "cd .." >> /tmp/fw_upgrade_2p.sh
    echo "rm -rf $YI_HACK_UPGRADE_PATH" >> /tmp/fw_upgrade_2p.sh
    echo "rm $YI_HACK_PREFIX/fw_upgrade_in_progress" >> /tmp/fw_upgrade_2p.sh
    echo "sync" >> /tmp/fw_upgrade_2p.sh
    echo "sync" >> /tmp/fw_upgrade_2p.sh
    echo "sync" >> /tmp/fw_upgrade_2p.sh
    echo "reboot" >> /tmp/fw_upgrade_2p.sh
    sh /tmp/fw_u
