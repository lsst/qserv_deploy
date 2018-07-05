apiVersion: v1
kind: PersistentVolume
metadata:
    name: <PV_NAME>
    labels:
        dataid: <DATA_ID>
spec:
    capacity:
        storage: 100Gi # Mandatory, muste be the same in PVC
    volumeMode: Filesystem
    accessModes:
    - ReadWriteOnce
    persistentVolumeReclaimPolicy: Retain
    storageClassName: qserv-local-storage
    local:
        path: <DATA_PATH>
    nodeAffinity:
        required:
            nodeSelectorTerms:
            - matchExpressions:
              - key: kubernetes.io/hostname
                operator: In
                values:
                - <HOSTNAME>
