[1mdiff --cc rootfs/opt/kubectl/example/GoogleBackup/yaml-builder.py[m
[1mindex 7dc43cf,93759fd..0000000[m
[1m--- a/rootfs/opt/kubectl/example/GoogleBackup/yaml-builder.py[m
[1m+++ b/rootfs/opt/kubectl/example/GoogleBackup/yaml-builder.py[m
[36m@@@ -2,7 -2,7 +2,7 @@@[m
  [m
  # LSST Data Management System[m
  # Copyright 2014 LSST Corporation.[m
[31m--# [m
[32m++#[m
  # This product includes software developed by the[m
  # LSST Project (http://www.lsst.org/).[m
  #[m
[36m@@@ -10,14 -10,14 +10,14 @@@[m
  # it under the terms of the GNU General Public License as published by[m
  # the Free Software Foundation, either version 3 of the License, or[m
  # (at your option) any later version.[m
[31m--# [m
[32m++#[m
  # This program is distributed in the hope that it will be useful,[m
  # but WITHOUT ANY WARRANTY; without even the implied warranty of[m
  # MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the[m
  # GNU General Public License for more details.[m
[31m--# [m
[31m--# You should have received a copy of the LSST License Statement and [m
[31m--# the GNU General Public License along with this program.  If not, [m
[32m++#[m
[32m++# You should have received a copy of the LSST License Statement and[m
[32m++# the GNU General Public License along with this program.  If not,[m
  # see <http://www.lsstcorp.org/LegalNotices/>.[m
  [m
  """[m
[36m@@@ -131,14 -127,11 +131,14 @@@[m [mif __name__ == "__main__"[m
          yaml_data['metadata']['name'] = tier[m
          yaml_data['metadata']['labels']['tier'] = tier[m
          yaml_data['spec']['replicas'] = args.replica_count[m
[31m--        yaml_data['spec']['selector']['matchLabels']['tier'] = tier [m
[32m++        yaml_data['spec']['selector']['matchLabels']['tier'] = tier[m
          yaml_data['spec']['template']['metadata']['labels']['tier'] = tier[m
  [m
[31m -        #yaml_data['spec']['template']['spec']['containers'][0]['command'] = [ 'sh', '/config-backup/backup.sh' ][m
[31m -        yaml_data['spec']['template']['spec']['containers'][0]['command'] = [ 'sh', '/config-backup/restore.sh' ][m
[32m +        if args.restore:[m
[32m +            cmd = '/config-backup/restore.sh'[m
[32m +        else:[m
[32m +            cmd = '/config-backup/backup.sh'[m
[32m +        yaml_data['spec']['template']['spec']['containers'][0]['command'] = [ 'sh', cmd ][m
          yaml_data['spec']['template']['spec']['containers'][0]['volumeMounts'][0]['name'] = args.volume_claim_name[m
          yaml_data['spec']['volumeClaimTemplates'][0]['metadata']['name'] = args.volume_claim_name[m
  [m
[36m@@@ -147,4 -140,4 +147,4 @@@[m
  [m
      except Exception as exc:[m
          logging.critical('Exception occurred: %s', exc, exc_info=True)[m
[31m--        sys.exit(1)[m
[32m++        sys.exit(1)[m
[1mdiff --git a/rootfs/opt/kubectl/example/GoogleBackup/start.sh b/rootfs/opt/kubectl/example/GoogleBackup/start.sh[m
[1mindex 4e25ca5..4c4675a 100755[m
[1m--- a/rootfs/opt/kubectl/example/GoogleBackup/start.sh[m
[1m+++ b/rootfs/opt/kubectl/example/GoogleBackup/start.sh[m
[36m@@ -102,4 +102,4 @@[m [mtier="repl-db"[m
 YAML_FILE="${OUTDIR}/statefulset-${tier}-backup.yaml"[m
 "$DIR"/yaml-builder.py -T "${tier}" -V "repl-data" -t "$YAML_TPL" -o "$YAML_FILE" $OPT_RESTORE[m
 [m
[31m-kubectl apply -f "${OUTDIR}"[m
\ No newline at end of file[m
[32m+[m[32mkubectl apply -f "${OUTDIR}"[m
