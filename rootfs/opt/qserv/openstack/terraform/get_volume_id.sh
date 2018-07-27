#!/bin/bash
# Number of first volume
export TF_VAR_firstVolume=100
# Get volume list

volume_list=`openstack volume list -c ID -c Display\ Name -f csv | grep vol-qserv | tr , =`
volume_list=`echo ${volume_list} | sed -e 's/\"\ \"/\",\"/g'`
volume_list={${volume_list}}
export TF_VAR_volumeId="${volume_id}"
