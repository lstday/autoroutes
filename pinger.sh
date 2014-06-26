#!/bin/bash

. /etc/firewall/autoroutes/routes.var
ssval=$maxval;
hval=$maxval;
ssc=1;
hc=1;

while true; do
	if ifconfig $ssif 1>/dev/null 2>/dev/null; then
		css=`ping -c 1 -I $ssif $ssgw 2>/dev/null |grep -o -e '[0-9] received' |grep -o -e '[0-9]'`
		if [ -z $css ]; then
			css=0;
		fi
	else css=0;
	fi
	if ifconfig $hif 1>/dev/null 2>/dev/null; then
		ch=`ping -c 1 -I $hif $hgw 2>/dev/null |grep -o -e '[0-9] received' |grep -o -e '[0-9]'`
		if [ -z $ch ]; then
			ch=0;
		fi
	else ch=0;
	fi
	
if [ "$css" -eq 1 ]; then
        [ "$ssval" -lt "$maxval" ] && ssval=$(($ssval+$incr));
else
        [ "$ssval" -ge "$threshholdval" ] && ssval=$(($ssval-$decr));
        [ "$ssval" -lt "$threshholdval" ] && ssval=0;
fi

if [ "$ch" -eq 1 ]; then
        [ "$hval" -lt "$maxval" ] && hval=$(($hval+$incr));
else
        [ "$hval" -ge "$threshholdval" ] && hval=$(($hval-$decr));
        [ "$hval" -lt "$threshholdval" ] && hval=0;
fi

[ "$ssval" -eq "$maxval" ] && touch $ssfile && ssc=1;
[ "$ssval" -eq 0 ] && [ -f "$ssfile" ] && rm $ssfile && ssc=0;

[ "$hval" -eq "$maxval" ] && touch $hfile && hc=1;
[ "$hval" -eq 0 ] && [ -f "$hfile" ] && rm $hfile && hc=0;

echo pss:$ssval\; ph:$hval\; ess:$ssc\; eh:$hc  > /tmp/pinger.current
(echo $hval; echo $ssval; echo "") > /tmp/mrtg.pinger

[ "$css" -eq 1 ] && [ "$ch" -eq 1 ] && sleep 1;
done;
