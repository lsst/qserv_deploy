#!/bin/bash

# Number of first volume
export TF_VAR_firstVolume=100

# Get volume list
volume_name=vol-qserv-

volume_list=`openstack volume list -c ID -c Display\ Name -f csv | grep ${volume_name} | awk -F\, '{ print $2";"$1 }' |tr , =`
volume_list=`echo ${volume_list} | sed -e 's/\"\ \"/\",\"/g' | sed -e "s/\${volume_name}//g"`
volume_list={${volume_list}}
export TF_VAR_volumeId="${volume_list}"
