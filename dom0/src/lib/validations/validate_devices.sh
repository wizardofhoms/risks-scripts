
validate_device () {
    local block="$1"

    # And check not already attached to another qube
    ovm=$(qvm-block list | grep "${block}" | awk {'print $4'} | cut -d" " -f1)
    if [[ ${#ovm} -gt 0 ]]; then

        # if [ "${ovm}" == "${vm}" ]; then
        #     echo "Block ${SDCARD_BLOCK} is already attached to ${vm}"
        #     exit 0
        # fi

        echo -e "Block ${SDCARD_BLOCK} is currently attached to ${ovm}."
        echo "Please umount it properly from there and rerun this program."
        return

        # slam tombs open in the vm
        #qvm-run -u user ${ovm} '/usr/local/bin/tomb slam all'

        # umount sdcard from the vm
        #qvm-run -u user ${ovm} '/usr/local/bin/risks umount sdcard'

        # detach the sdcard
        #qvm-block detach ${ovm} ${block}
            #if [ $? != 0 ]; then
        #	echo "Block ${block} can not be detached from ${ovm}. Aborted."
        #	exit
        #fi	
    fi
}
