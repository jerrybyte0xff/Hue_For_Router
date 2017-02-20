#!/bin/sh

MAC=28:A0:2B:2B:94:91
interval=5 
openflag=0
closeflag=0
flickerflag=0
return_value=0
findmaster=0


parse_json(){
    echo "${1//\"/}" | sed "s/.*$2:\([^,}]*\).*/\1/"
}


get_light_status(){
    rec_buff=`curl  http://192.168.31.27/api/RTjC-NdpBnwuQN1xE84pYSANSWSPCkVbpixp3XOY/lights/1`
    rec_buff=$(parse_json $rec_buff "state")
    rec_buff=$(parse_json $rec_buff "state")
    rec_buff=$(parse_json $rec_buff "on")
    echo $rec_buff 
}

find_mac()
{
    iwinfo wl1 assoclist | grep WPA2 | awk '{print $1}' | while read MAC1 
    do
        echo $MAC1
        if [ $MAC1 = '28:A0:2B:2B:94:91' ]; then
            return 1
        fi
    done
    # return 0
}




#Main program: it's a dead loop,  exec find_mac() every n seconds(defined by interval)
while [ 1 -lt 2 ]
do  
    
    find_mac
    findmaster=$?
    echo  "find reslut:" $findmaster 
    
   
    hour=`date "+%H"`
    minute=`date "+%M"`

    #----------------------------------------------
    # find master then light on and 11pm light off

    if [ $findmaster -eq 1 ] && [ $hour -ge 19 ] && [ $openflag -eq 0 ];then
        curl -X PUT -d '{"on":true}' http://192.168.31.27/api/RTjC-NdpBnwuQN1xE84pYSANSWSPCkVbpixp3XOY/lights/1/state
        echo trn on
        openflag=1 

    elif [ $hour -eq 23 ] && [ $closeflag -eq 0];then
        closeflag=1
        curl -X PUT -d '{"on":false}' http://192.168.31.27/api/RTjC-NdpBnwuQN1xE84pYSANSWSPCkVbpixp3XOY/lights/1/state
        echo trn off
    fi
    sleep $interval
    if [ $hour -eq 8 ] ;then
        openflag=0
        closeflag=0
    fi
    #----------------------------------------------

    #----------------------------------------------
     # light flicker at sharp time
    current_light_state=$(get_light_status)
    if [ $current_light_state = 'true' ] && [ $minute -eq 0 ] && [ $flickerflag -eq 0 ] && [ $hour -ge 8 ]; then
        curl -X PUT -d '{"on":false}' http://192.168.31.27/api/RTjC-NdpBnwuQN1xE84pYSANSWSPCkVbpixp3XOY/lights/1/state
        sleep 0.5
        curl -X PUT -d '{"on":true}' http://192.168.31.27/api/RTjC-NdpBnwuQN1xE84pYSANSWSPCkVbpixp3XOY/lights/1/state
        sleep 0.5
        curl -X PUT -d '{"on":false}' http://192.168.31.27/api/RTjC-NdpBnwuQN1xE84pYSANSWSPCkVbpixp3XOY/lights/1/state
        sleep 0.5
        curl -X PUT -d '{"on":true}' http://192.168.31.27/api/RTjC-NdpBnwuQN1xE84pYSANSWSPCkVbpixp3XOY/lights/1/state
        flickerflag=1
    elif [ $current_light_state = 'false' ] && [ $minute -eq 0 ] && [ $flickerflag -eq 0 ] && [ $hour -ge 8 ]; then
        curl -X PUT -d '{"on":true}' http://192.168.31.27/api/RTjC-NdpBnwuQN1xE84pYSANSWSPCkVbpixp3XOY/lights/1/state
        sleep 0.5
        curl -X PUT -d '{"on":false}' http://192.168.31.27/api/RTjC-NdpBnwuQN1xE84pYSANSWSPCkVbpixp3XOY/lights/1/state
        sleep 0.5
        curl -X PUT -d '{"on":true}' http://192.168.31.27/api/RTjC-NdpBnwuQN1xE84pYSANSWSPCkVbpixp3XOY/lights/1/state 
        sleep 0.5
        curl -X PUT -d '{"on":false}' http://192.168.31.27/api/RTjC-NdpBnwuQN1xE84pYSANSWSPCkVbpixp3XOY/lights/1/state
        flickerflag=1
    fi
    if [ $minute -eq 1 ] ;then
        flickerflag=0
    fi
done
 
