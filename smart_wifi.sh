#!/bin/sh

# Write your user key and ip here
USER_KEY="RTjC-NdpBnwuQN1xE84pYSANSWSPCkVbpixp3XOY"
LIGHT_IP="192.168.31.27"

# Write your phone`s mac here
ARRAY_PHONE_MACS=(28:A0:2B:2B:94:91 AC:29:3A:C4:DB:FA)
# Write your light num which you want control  here
HUE_NUM='1'


SUNSET_TIME='18'
SUNRISE_TIME='8'
WAKEUP_TIME='23'
SLEEP_INTERVAL='3' 
#-----------------------------------------

openflag=0
closeflag=0
flickerflag=0
return_value=0
findmaster=0


parse_json(){
    echo "${1//\"/}" | sed "s/.*$2:\([^,}]*\).*/\1/"
}


get_light_status(){
    rec_buff=`curl  http://$LIGHT_IP/api/$USER_KEY/lights/$HUE_NUM`
    rec_buff=$(parse_json $rec_buff "state")
    rec_buff=$(parse_json $rec_buff "state")
    rec_buff=$(parse_json $rec_buff "on")
    echo $rec_buff 
}

find_mac()
{
    iwinfo wl1 assoclist | grep WPA2 | awk '{print $1}' | while read MAC1 
    do
        # echo $MAC1
        for i in ${ARRAY_PHONE_MACS[@]}
        do
            if [ $MAC1 = '28:A0:2B:2B:94:91' ]; then
                return 1
            fi
        done

        if [ $MAC1 = '28:A0:2B:2B:94:91' ]; then
            return 1
        fi
    done
    # return 0
}

light_flicke()
{

    if [ $current_light_state = 'true' ]; then
        curl -X PUT -d '{"on":false}' http://$LIGHT_IP/api/$USER_KEY/lights/$HUE_NUM/state
    fi
    sleep 0.5
    curl -X PUT -d '{"on":true}' http://$LIGHT_IP/api/$USER_KEY/lights/$HUE_NUM/state
    sleep 0.5
    curl -X PUT -d '{"on":false}' http://$LIGHT_IP/api/$USER_KEY/lights/$HUE_NUM/state
    sleep 0.5
    curl -X PUT -d '{"on":true}' http://$LIGHT_IP/api/$USER_KEY/lights/$HUE_NUM/state
    sleep 0.5
    if [ $current_light_state = 'false' ]; then
        curl -X PUT -d '{"on":false}' http://$LIGHT_IP/api/$USER_KEY/lights/$HUE_NUM/state
    if

}


#Main Process:  dead loop,  exec find_mac() every interval seconds
while [ 1 -lt 2 ]
do  
    
    find_mac
    findmaster=$?
    echo  "find reslut:" $findmaster 
    
   
    hour=`date "+%H"`
    minute=`date "+%M"`

    current_light_state=$(get_light_status)
    #----------------------------------------------
    # find master connected the router then light on 

    if [ $findmaster -eq 1 ] && [ $hour -ge $SUNSET_TIME ] && [ $openflag -eq 0 ];then
        curl -X PUT -d '{"on":true}' http://$LIGHT_IP/api/$USER_KEY/lights/$HUE_NUM/state
        echo trn on
        openflag=1 
    # find master left the router then light off 
    elif [$findmaster -eq 0 ] && [ $current_light_state = 'true' ];then
        curl -X PUT -d '{"on":false}' http://$LIGHT_IP/api/$USER_KEY/lights/$HUE_NUM/state
        echo trn off
        openflag=0
        closeflag=0

    fi

    #  light off at sleep time 
    elif [ $hour -eq SLEEP_TIME ] && [ $closeflag -eq 0 ];then
        closeflag=1
        curl -X PUT -d '{"on":false}' http://$LIGHT_IP/api/$USER_KEY/lights/$HUE_NUM/state
        echo trn off
    fi

   
    if [ $hour -eq 8 ] ;then
        openflag=0
        closeflag=0
    fi


    #----------------------------------------------

    #----------------------------------------------
     # light flicker at sharp time
    if [ [ $minute -eq 0 ] && [ $flickerflag -eq 0 ] && [ $hour -ge WAKEUP_TIME ]; then
        light_flicke
        flickerflag=1
    fi
    if [ $minute -eq 1 ] ;then
        flickerflag=0
    fi

     sleep $SLEEP_INTERVAL
done
 
