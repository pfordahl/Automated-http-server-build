#!/bin/bash
#
# NOTE1: You must have AWS API tools installed as well as curl installed on the
#		machine you are running this script on.
#
# Note2: Make sure you add your keys and SG for your install.
#

secgroup=temp-gp
seckey=temp-key-pair
servertemp=instance.tmp
key=temp-key-pair.pem
user=ec2-user
sshoptions="-oStrictHostKeyChecking=no"
sshkeypath=~/.ssh/


#Create in instance
ec2-run-instances --instance-type t1.micro --group $secgroup --region us-east-1 --key $seckey --instance-initiated-shutdown-behavior stop ami-fb8e9292 > $servertemp

#We will now use the script below to name the instance so we can find it.
instanceID=`cat $servertemp | grep INSTANCE | awk 'BEGIN{FS=" "} {print $2}'`

ec2-create-tags  $instanceID --tag Name=Linux-Web-1


echo "server ID:" $instanceID
#Checking to see if the server is running before continuing on.
until [ `ec2-describe-instances $instanceID | awk 'BEGIN{FS=" "} {print $6}'` == "running" ]
do
	
		echo "Waiting 10secs for server to enter running"
		sleep 10
done

#Checking to see if the SYSTEMSTATUS has entered a passed state before moving on.
until [ `ec2-describe-instance-status $instanceID | grep SYSTEMSTATUS | awk 'BEGIN{FS=" "} {print $3}'` == "passed" ]
do
	echo "Waiting for SYSTEMSTATUS to enter passed"
	echo "Sleeping for 30sec"
	sleep 30
done

#Waiting to see if the INSTANCESTATUS has entered a passed state before moving on.
until [ `ec2-describe-instance-status $instanceID | grep INSTANCESTATUS | awk 'BEGIN{FS=" "} {print $3}'` == "passed" ]
do
	echo "Waiting for INSTANCESTATUS to enter passed"
	echo "Sleeping for 30sec"
	sleep 30
done

#Setting the variables for the  SSH connection
serverstatus=`ec2-describe-instances $instanceID | awk 'BEGIN{FS=" "} {print $6}'`
serverdns=`ec2-describe-instances $instanceID | awk 'BEGIN{FS=" "} {print $4}' | grep ec2`
echo "Server:"$instanceID "is" $serverstatus

 ssh -t -t  -i $sshkeypath$key $sshoptions $user@$serverdns <<stop >tempssh.tmp
	sudo yum install httpd -y
	sudo su root
	sudo echo "Hello the server is up" > /var/www/html/index.html 
	sudo service httpd restart
	exit
	exit
stop

#Check to see if the site was set-up
wwwsite=`curl http://$serverdns`

if
	[ "$wwwsite" == "Hello the server is up" ]
then
	echo "The server is up and the site has been changed"
else
	echo "Something went wrong please check the site or the tempssh.tmp"
fi
rm $servertemp
