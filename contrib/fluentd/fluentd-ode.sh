#!/bin/sh
if [ -f "/etc/elsa_vars.sh" ]; then
DATA_DIR=`grep --only-matching --perl-regex "(?<=DATA_DIR\=).*" /etc/elsa_vars.sh`
elif [ -f "/usr/local/elsa/build/distro/common/vars.sh" ]; then
DATA_DIR=`grep --only-matching --perl-regex "(?<=DATA_DIR\=).*" /usr/local/elsa/build/distro/common/vars.sh`
else
DATA_DIR=/data
fi
fluent_dir=/usr/local/elsa/contrib/fluentd
if [ "x$DATA_DIR" == "x" ]; then
 DATA_DIR=/data
fi
DATA_DIR="${DATA_DIR%\"}"
DATA_DIR="${DATA_DIR#\"}"
# Directory creation for file processing

create_fluentd_dirs() {
if [ ! -d $DATA_DIR ]; then
mkdir $DATA_DIR
fi
if [ -d $DATA_DIR/fluentd ]; then
echo "fluentd directories already exists"
else
mkdir $DATA_DIR/fluentd
mkdir $DATA_DIR/fluentd/json_log
mkdir $DATA_DIR/fluentd/apache_log
mkdir $DATA_DIR/fluentd/netflow_log
mkdir $DATA_DIR/fluentd/custom_log
mkdir $DATA_DIR/fluentd/json_log/in_files
mkdir $DATA_DIR/fluentd/json_log/out_files
mkdir $DATA_DIR/fluentd/json_log/out_files/old_files

mkdir $DATA_DIR/fluentd/apache_log/in_files
mkdir $DATA_DIR/fluentd/apache_log/out_files
mkdir $DATA_DIR/fluentd/apache_log/out_files/old_files

mkdir $DATA_DIR/fluentd/netflow_log/in_files
mkdir $DATA_DIR/fluentd/netflow_log/out_files
mkdir $DATA_DIR/fluentd/netflow_log/out_files/old_files

mkdir $DATA_DIR/fluentd/custom_log/in_files
mkdir $DATA_DIR/fluentd/custom_log/out_files
mkdir $DATA_DIR/fluentd/custom_log/out_files/old_files

chmod -R 777 $DATA_DIR/fluentd
fi
}
#Start changes for Fluentd
install_td_agent() {
echo " Fluentd plugin creation start ........."
if [ -f "/etc/td-agent/td-agent.conf" ]; then
echo " td-agent is already installed, please remove the existing setup for new install";
exit 1
else
        codename=`lsb_release --codename | cut -f2`
       if [ "$codename" = "trusty" ]; then
        curl -L https://td-toolbelt.herokuapp.com/sh/install-ubuntu-trusty-td-agent2.sh | sh
        elif [ "$codename" = "precise" ]; then
        curl -L https://td-toolbelt.herokuapp.com/sh/install-ubuntu-precise-td-agent2.sh | sh
        elif [ "$codename" = "lucid" ]; then
        curl -L https://td-toolbelt.herokuapp.com/sh/install-ubuntu-lucid-td-agent2.sh | sh
		else
		curl -L https://td-toolbelt.herokuapp.com/sh/install-redhat-td-agent2.sh | sh
        fi
fi
}
cp_td_agent_conf(){
 if [ -f "/etc/td-agent/td-agent.conf" ]; then
        mv /etc/td-agent/td-agent.conf /etc/td-agent/td-agent_old.conf
fluentdir=$DATA_DIR/fluentd
echo "
#setting for json
# source for multi file input
<source>
type tail
format json
read_from_head true
path $fluentdir/json_log/in_files/*
pos_file $fluentdir/json_log/out_files/json.log.pos
tag json000
</source>
# Source as single file
#<source>
#type tail
#format json
#path $fluentdir/json_log/in_files/json.log
#pos_file $fluentdir/json_log/out_files/json.log.pos
#tag json000
#</source>
# Source as stream
#<source>
#type tcp
#format json
#port 5170
#bind 0.0.0.0
#tag json000
#</source>

<filter json000>
  type record_transformer
  renew_record true
 keep_keys startTime,endTime,srcMac,destMac,srcIp,destIp,srcPort,destPort,protocol,app,hlApp,security,packetsCaptured,bytesCaptured,terminationReason,empty,boxId,networks,srcLocation,destLocation
</filter>
<match json000>
  type flatten_hash
  add_tag_prefix flattened.
  separator _
</match>
<match flattened.json000.**>
  type file
format json_ltsv
append true
delimiter ","
label_delimiter "="
path $fluentdir/json_log/out_files/json
buffer_type file
buffer_path $fluentdir/json_log/out_files/buffer
time_slice_format  out
append true
flush_interval  1s
</match>

###################
# Setting for Apache
###################
# source for multi file input
<source>
 type tail
 format apache
 read_from_head true
 path $fluentdir/apache_log/in_files/*
 pos_file $fluentdir/apache_log/out_files/apache.log.pos
 tag apache000
</source>
# Source as single file
#<source>
#type tail
#format apache
#path $fluentdir/apache_log/in_files/apache.log
#pos_file $fluentdir/apache_log/out_files/apache.log.pos
#tag apache000
#</source>
# Source as stream
#<source>
#type tcp
#format apache2
#port 5170
#bind 0.0.0.0
#tag apache000
#</source>

<filter apache000>
  type record_transformer
  renew_record true
 keep_keys host,user,method,path,code,size,referer,agent
</filter>
<match apache000>
  type flatten_hash
  add_tag_prefix flattened.
  separator _
</match>
<match flattened.apache000.**>
type file
format apache_ltsv
append true
delimiter ","
label_delimiter "="
path $fluentdir/apache_log/out_files/apache
buffer_type file
buffer_path $fluentdir/apache_log/out_files/buffer
time_slice_format  out
append true
flush_interval  1s
</match>

###################
# Setting for Netflow
###################
# source for multi file input
<source>
 type tail
 format none
 message_key 
 read_from_head true
 path $fluentdir/netflow_log/in_files/*
 pos_file $fluentdir/netflow_log/out_files/netflow.log.pos
 tag net000
</source>

# Source as single file

#<source>
#type tail
#format none
#message_key
#path $fluentdir/netflow_log/in_files/netflow.log
#pos_file $fluentdir/netflow_log/out_files/netflow.log.pos
#tag net000
#</source>


# Source as stream

#<source>
#type tcp
#message_key 
#format none
#port 5170
#bind 0.0.0.0
#tag net000
#</source>

<match net000>
type file
format netflow_ltsv
path $fluentdir/netflow_log/out_files/netflow
buffer_type file
buffer_path $fluentdir/netflow_log/out_files/buffer
time_slice_format out
append true
flush_interval  1s
</match>


###################
# Setting for Custom 
###################
# source for multi file input

<source>
type tail
format none
message_key 
read_from_head true
path $fluentdir/custom_log/in_files/*
pos_file $fluentdir/custom_log/out_files/custom.log.pos
tag custom000
</source>

# Source as single file
#<source>
# type tail
#format none
#message_key 
#path $fluentdir/custom_log/in_files/custom.log
#pos_file $fluentdir/custom_log/out_files/custom.log.pos
#tag custom000
#</source>

# Source as stream

#<source>
#type tcp
#message_key 
#format none
#port 5170
#bind 0.0.0.0
#tag custom000
#</source>

<match custom000>
type file
format custom_ltsv
path $fluentdir/custom_log/out_files/custom
buffer_type file
buffer_path $fluentdir/custom_log/out_files/buffer
time_slice_format out
append true
flush_interval  1s
</match> " > /etc/td-agent/td-agent.conf
 else
     echo "td-agent conf file not copied properly"
     exit 1
 fi
 
 echo "copying Custom Plugin's ..."
if [ ! -d /etc/td-agent/plugin ]; then
   mkdir /etc/td-agent/plugin
fi
cp $fluent_dir/plugin/*.rb /etc/td-agent/plugin/

echo "successfully copied Custom Plugin's ......"

}
install_ruby() {
echo "Fluentd plugin installation start ......"
# Ruby and ruby gems Installation
if [ "$codename" = "trusty" ] || [ "$codename" = "precise" ] || [ "$codename" = "lucid" ]; then
echo "installing Ruby and Rubygems for Ubuntu"
yes | apt-get install ruby1.9.1-dev
yes | apt-get install ruby1.9.1
echo "Ruby & gems installed for Ubuntu"
fi
}
install_flatten_hash() {
echo "installing flatten Hash Plug-in ...."
gem install gem-path
gem install fluent-plugin-flatten-hash
gem_path=`gem path fluent-plugin-flatten-hash`
cp $gem_path/lib/fluent/plugin/*.rb  /etc/td-agent/plugin/
echo "flatten Hash plugin installed ...."
}

fluentd_logrotate() {
if [ -d /etc/logrotate.d ]; then
echo "$DATA_DIR/fluentd/apache_log/out_files/apache.out.log {
           rotate 5
           missingok
           size=1k
           compress
           olddir $DATA_DIR/fluentd/apache_log/out_files/old_files
           notifempty
           create 640 td-agent td-agent
            }" > /etc/logrotate.d/fluentd_apache

                echo "$DATA_DIR/fluentd/json_log/out_files/json.out.log {
           rotate 5
           missingok
           size=1k
           compress
           olddir $DATA_DIR/fluentd/json_log/out_files/old_files
           notifempty
           create 640 td-agent td-agent
            }" > /etc/logrotate.d/fluentd_json

echo "$DATA_DIR/fluentd/netflow_log/out_files/netflow.out.log {
           rotate 5
           missingok
           size=1k
           compress
           olddir $DATA_DIR/fluentd/netflow_log/out_files/old_files
           notifempty
           create 640 td-agent td-agent
            }" > /etc/logrotate.d/fluentd_netflow

echo "$DATA_DIR/fluentd/custom_log/out_files/custom.out.log {
           rotate 5
           missingok
           size=1k
           compress
           olddir $DATA_DIR/fluentd/custom_log/out_files/old_files
           notifempty
            create 640 td-agent td-agent
            }" > /etc/logrotate.d/fluentd_custom
else
                echo "WARNING: No /etc/logrotate.d directory not found, not installing Fluentd utility log rotation"
        fi
}

exec_func(){
	RETVAL=1
	FUNCTION=$1
	echo "Executing $FUNCTION"
	$FUNCTION
	RETVAL=$?
	if [ $RETVAL -eq 0 ]; then
	        echo "$FUNCTION success"
	else
	        echo "$FUNCTION FAIL" 
	fi
	}
echo "Running td-agent setup.."
  #node functions
    for FUNCTION in "create_fluentd_dirs" "install_td_agent" "cp_td_agent_conf" "install_ruby" "install_flatten_hash" "fluentd_logrotate"; do
	  exec_func $FUNCTION
    done
