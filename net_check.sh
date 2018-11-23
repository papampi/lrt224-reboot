#!/bin/bash
## Check Name resolution and ping

server_1="eu.stratum.slushpool.com 3333"
server_2="google.com 443"
ping_ip="8.8.8.8"
router_ip=$(netstat -rn | grep 'UG' | awk '{print $2}' | grep '^[0-9]\{1,3\}\.')

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

while true
do
  dns_check=0
  ping_ok=0
  no_ping=0
  router_reboot=0

  if ping -c1 "$router_ip"
  then

    while ! nc -vzw1 $server_1  && !  nc -vzw1  $server_2
    do

      if (( ping_ok >= 10 ))
      then
        echo "$(date) - [WARNING] - Name resolution problem while ping is ok, waited 5 minutes, restarting router" | tee -a $DIR/net_check.log
        #reboot router
        #bash $DIR/router-reboot.sh
        dns_check=0
        ping_ok=0
        router_reboot=1
        echo "Waiting 90 sec for router rebooting"
        sleep 90
      fi

      if (( no_ping >= 20 ))
      then
        echo "$(date) - [WARNING] - Name resolution problem and NO Ping, waited 10 minutes, restarting router" | tee -a $DIR/net_check.log
        #reboot router
        #bash $DIR/router-reboot.sh
        dns_check=0
        no_ping=0
        router_reboot=1
        echo "Waiting 90 sec for router rebooting"
        sleep 90
      fi

      if (( router_reboot = 0 ))
      then
        echo "$(date) - [WARNING] - Internet Problem, checking ..." | tee -a $DIR/net_check.log
        if ping -c1 "$ping_ip" # &> /dev/null
        then
          echo "$(date) - [WARNING] - Ping ok, but DNS problem, check again in 30 sec"  | tee -a $DIR/net_check.log
          (( ping_ok++ ))
          echo "DEBUG: Ping OK #$ping_ok"
        else
          echo "$(date) - [WARNING] - No Ping and DNS, network down, check again in 30 sec" | tee -a $DIR/net_check.log
          (( no_ping++ ))
          echo "DEBUG: No Ping #$no_ping"
        fi
        (( dns_check++ ))
        echo "DEBUG: DNS check #$dns_check"
        echo "Sleep 30"
        sleep 30
      else
        echo "Router rebooted"
        router_reboot=0
        while !  ping -c1 "$router_ip"
        do
          echo "Waiting for router to bootup"
          sleep 10
        done
      fi

    done
  fi
  echo "sleep 30"
  sleep 30
done
