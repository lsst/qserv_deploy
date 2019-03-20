set -e
set -x

echo "Start restore"

gcloud auth activate-service-account --key-file=/secret-backup/neural-theory-215601-53bf50004612.json

gsutil -m rsync -P -r gs://qserv-backup/qserv-dev/"$HOSTNAME" /qserv/data 

# Google bucket do not preserve uid/gid for directories
chown -R 1000:1000 /qserv/data

STATUS_FILE="/tmp/$HOSTNAME-restore-ok"
touch "$STATUS_FILE"
gsutil -m cp -r "$STATUS_FILE" gs://qserv-backup/qserv-dev/results/

echo "Succeed restore"
while true
do
    sleep 10000
done
