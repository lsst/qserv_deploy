#!/bin/bash

# Get volume list
openstack volume list | grep vol-qserv >> volume.txt

# Add volume in variables.tf
echo "# VOLUME ID
variable \"volume_id\" {
  default = {" >> variables.tf

nb_ligne=`wc -l volume.txt| grep -o "^[0-9]\+"`
for i in `seq 1 ${nb_ligne}`
do
	ligne=`sed -n "${i} p" volume.txt`
	ID=${ligne:1:38}
	nb_volume=${ligne:40}
	nb_volume=`echo ${nb_volume} | cut -d'|' -f1 | grep -o "[0-9]\+"`
	echo "\"${nb_volume}\"=\"${ID}\"" >> variables.tf
done
echo "}
}" >> variables.tf

rm volume.txt

