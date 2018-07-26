#!/bin/bash

# Number of first volume
echo "first_volume = 100" >> $CLUSTER_CONFIG_DIR/terraform.tfvars
# Get volume list
#openstack volume list | grep vol-qserv >> volume.txt

# Add volume in variables.tf
echo "# volume id
volume_id = {">> $CLUSTER_CONFIG_DIR/terraform.tfvars

nb_ligne=`wc -l $CLUSTER_CONFIG_DIR"/terraform/volume.txt"| grep -o "^[0-9]\+"`

for i in `seq 1 ${nb_ligne}`
do
	ligne=`sed -n "${i} p" "$CLUSTER_CONFIG_DIR/terraform/volume.txt"`
	ID=`(expr substr "$ligne" 3 36)`
	nb_volume=`(expr substr "$ligne" 41 30)`
	nb_volume=`echo ${nb_volume} | cut -d'|' -f1 | grep -o "[0-9]\+"`
	echo "\"${nb_volume}\"=\"${ID}\"" >> $CLUSTER_CONFIG_DIR/terraform.tfvars
done
echo "}" >> $CLUSTER_CONFIG_DIR/terraform.tfvars

rm volume.txt
