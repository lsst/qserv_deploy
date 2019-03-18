gcloud auth activate-service-account --key-file=/secret-backup/neural-theory-215601-53bf50004612.json
rm /qserv/data/mysql/mysql.sock
gsutil -m rsync -r /qserv/data gs://qserv-backup/qserv-dev/$HOSTNAME
