#!/bin/bash
# Number of first volume
export TF_VAR_firstVolume=100
# Get volume list
openstack volume list | grep vol-qserv >> volume.txt

nb_ligne=`wc -l $CLUSTER_CONFIG_DIR"/terraform/volume.txt"| grep -o "^[0-9]\+"`
volume_id="{\""
nb_ligne=$(($nb_ligne -1))
for i in `seq 1 ${nb_ligne}`
do
	ligne=`sed -n "${i} p" "$CLUSTER_CONFIG_DIR/terraform/volume.txt"`
	ID=`(expr substr "$ligne" 3 36)`
	nb_volume=`(expr substr "$ligne" 41 30)`
	nb_volume=`echo ${nb_volume} | cut -d'|' -f1 | grep -o "[0-9]\+"`
	volume_id=${volume_id}${nb_volume}"\" = \"${ID}\",\""
done

nb_ligne=$(($nb_ligne + 1))
ligne=`sed -n "${nb_ligne} p" "$CLUSTER_CONFIG_DIR/terraform/volume.txt"`
ID=`(expr substr "$ligne" 3 36)`
nb_volume=`(expr substr "$ligne" 41 30)`
nb_volume=`echo ${nb_volume} | cut -d'|' -f1 | grep -o "[0-9]\+"`
volume_id=${volume_id}${nb_volume}"\" = \"${ID}\"}"

export TF_VAR_volumeId="${volume_id}"

rm volume.txt
