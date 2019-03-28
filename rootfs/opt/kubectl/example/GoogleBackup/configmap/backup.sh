set -e
set -x

echo "Start backup"

gcloud auth activate-service-account --key-file=/secret-backup/neural-theory-215601-53bf50004612.json

MYSQL_SOCK="mysql/mysql.sock"
gsutil -m rsync -P -x "$MYSQL_SOCK" -r /qserv/data gs://qserv-backup/qserv-dev/"$HOSTNAME"

STATUS_FILE="/tmp/$HOSTNAME-backup-ok"
touch "$STATUS_FILE"
gsutil -m cp -r "$STATUS_FILE" gs://qserv-backup/qserv-dev/results/

echo "Succeed backup"
while true
do
    sleep 10000
done
