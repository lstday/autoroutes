#!/bin/sh

. /etc/firewall/autoroutes/routes.var

change_routes(){
alter_routes change "$1" "$2"
}

alter_routes(){
cmd="$1";
nets="$2";
gw="$3";
for i in $(echo $nets | tr ',' '\n'); do
        $routecmd $cmd $i via $gw metric 32;
done;
}


while true; do
css=0;
ch=0;
[ -f "$ssfile" ] && css=1;
[ -f "$hfile" ] && ch=1;

if [ "$css" -eq 1 ] && [ "$ch" -eq 1 ]; then
	if [ ! -f /tmp/SS+hackers ]; then
                change_routes "$ssnet" "$ssgw"
                change_routes "$hnet" "$hgw"

		[ -f /tmp/SSonly ] && rm /tmp/SSonly
		[ -f /tmp/hackersonly ] && rm /tmp/hackersonly 

		touch /tmp/SS+hackers

                echo `date`, Route configuration changed to SS + hackers >> $log
                [ -f "$flushfile" ] && rm $flushfile;

                if [ "$debug" -ne 0 ]; then
                        $netstatcmd -rn --inet |grep -v H >> $log
                        echo $delimiter >> $log
                fi
        fi
        [ -f "$flushfile" ] &&  echo `date`, Route configuration changed to SS + hackers >> $log && rm $flushfile;
elif [ "$css" -eq 1 ]; then
	if [ ! -f /tmp/SSonly ]; then
                change_routes "$ssnet" "$ssgw"
                change_routes "$hnet" "$ssgw"

		[ -f /tmp/SS+hackers ] && rm /tmp/SS+hackers
		[ -f /tmp/hackersonly ] && rm /tmp/hackersonly

		touch /tmp/SSonly

                echo `date`, Route configuration changed to SS only >> $log
                [ -f "$flushfile" ] && rm $flushfile;

                if [ "$debug" -ne 0 ]; then
                        $netstatcmd -rn --inet |grep -v W >> $log
                        echo $delimiter >> $log
                fi
        fi
        [ -f "$flushfile" ] && echo `date`, Route configuration changed to SS only >> $log && rm $flushfile;
elif  [ "$ch" -eq 1 ]; then
	if [ ! -f /tmp/hackersonly ]; then
                change_routes "$ssnet" "$hgw"
                change_routes "$hnet" "$hgw"

		/etc/init.d/vtun restart

		[ -f /tmp/SS+hackers ] && rm /tmp/SS+hackers
		[ -f /tmp/SSonly ] && rm /tmp/SSonly

		touch /tmp/hackersonly

                echo `date`, Route configuration changed to hackers only >> $log
                [ -f "$flushfile" ] && rm $flushfile;

                if [ "$debug" -ne 0 ]; then
                        $netstatcmd -rn --inet |grep -v W >> $log
                        echo $delimiter >> $log
                fi
        fi
        [ -f "$flushfile" ] && echo `date`, Route configuration changed to hackers only >> $log && rm $flushfile;
elif [ "$css" -ne 1 ] && [  "$ch" -ne 1 ] && ([ -f /tmp/SS+hackers ] || [ -f /tmp/SSonly ] || [ -f /tmp/hackersonly ]) ; then
        if ! [ -f "$flushfile" ]; then

                echo `date`, Route configuration must be flushed. >> $log

                if [ "$debug" -ne 0 ]; then
                        $netstatcmd -rn --inet |grep -v W >> $log
                        echo $delimiter >> $log
                fi
                touch $flushfile;
        fi
fi

sleep 5;
done;
