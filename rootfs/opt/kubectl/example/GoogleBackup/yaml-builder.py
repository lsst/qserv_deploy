#!/usr/bin/env python3

# LSST Data Management System
# Copyright 2019 LSST Corporation.
#
# This product includes software developed by the
# LSST Project (http://www.lsst.org/).
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the LSST License Statement and
# the GNU General Public License along with this program.  If not,
# see <http://www.lsstcorp.org/LegalNotices/>.

"""
Create k8s pods configuration files

@author Fabrice Jammes, IN2P3
"""

from __future__ import absolute_import, division, print_function

# -------------------------------
#  Imports of standard modules --
# -------------------------------
import argparse
try:
    import configparser
except ImportError:
    import ConfigParser as configparser  # python2
import logging
import sys
import warnings
import yaml

# ----------------------------
# Imports for other modules --
# ----------------------------

# -----------------------
# Exported definitions --
# -----------------------

# --------------------
# Local definitions --
# --------------------

# Support dumping of long strings as block literals or folded blocks in yaml
#

_LOG = logging.getLogger()

def _str_presenter(dumper, data):
    if len(data.splitlines()) > 1:  # check for multiline string
        return dumper.represent_scalar('tag:yaml.org,2002:str', data,
                                       style='|')
    return dumper.represent_scalar('tag:yaml.org,2002:str', data)

def _config_logger(verbose):
    """
    Configure the logger
    """
    verbosity = len(verbose)
    levels = {0: logging.WARNING, 1: logging.INFO, 2: logging.DEBUG}

    warnings.filterwarnings("ignore")

    # create console handler and set level to debug
    console = logging.StreamHandler()
    # create formatter
    formatter = logging.Formatter('%(asctime)s %(levelname)-8s %(name)-15s %(message)s')
    # add formatter to ch
    console.setFormatter(formatter)

    _LOG.handlers = [console]
    _LOG.setLevel(levels.get(verbosity, logging.DEBUG))

if __name__ == "__main__":
    try:

        parser = argparse.ArgumentParser(
            description='Create k8s pods configuration file from template')

        parser.add_argument('-v', '--verbose', dest='verbose', default=[],
                            action='append_const', const=None,
                            help='More verbose output, can use several times.')
        parser.add_argument('-T', '--tier', dest='tier',
                            required=True,
                            help='tier to backup (qserv, czar, repl-db)')
        parser.add_argument('-r', '--replica-count', dest='replica_count',
                            metavar='N', type=int,
                            required=False, default=1,
                            help='number of replica to backup, default to %(default)s')
        parser.add_argument('-R', '--restore', dest='restore', action='store_true',
                             default=False,
                             help='Launch restore procedure instead of backup by default'
                             )
        parser.add_argument('-t', '--template', dest='templateFile',
                            required=True, metavar='PATH',
                            help='yaml template file')
        parser.add_argument('-o', '--output', dest='yamlFile',
                            required=True, metavar='PATH',
                            help='pod configuration file, in yaml')
        parser.add_argument('-V', '--volumeclaimname', dest='volume_claim_name',
                            required=False, default="qserv-data",
                            help='name for volume claim')

        args = parser.parse_args()

        _config_logger(args.verbose)

        config = configparser.RawConfigParser()

        with open(args.templateFile, 'r') as f:
            yaml_data = yaml.load(f)

        yaml.add_representer(str, _str_presenter)

        yaml_data_tpl = yaml_data['spec']['template']['spec']

        tier = args.tier

        yaml_data['metadata']['name'] = tier
        yaml_data['metadata']['labels']['tier'] = tier
        yaml_data['spec']['replicas'] = args.replica_count
        yaml_data['spec']['selector']['matchLabels']['tier'] = tier
        yaml_data['spec']['template']['metadata']['labels']['tier'] = tier

        if args.restore:
            cmd = '/config-backup-start/restore.sh'
        else:
            cmd = '/config-backup-start/backup.sh'
        yaml_data['spec']['template']['spec']['containers'][0]['command'] = [ 'sh', cmd ]
        yaml_data['spec']['template']['spec']['containers'][0]['volumeMounts'][0]['name'] = args.volume_claim_name
        yaml_data['spec']['volumeClaimTemplates'][0]['metadata']['name'] = args.volume_claim_name

        with open(args.yamlFile, 'w') as f:
            f.write(yaml.dump(yaml_data, default_flow_style=False))

    except Exception as exc:
        logging.critical('Exception occurred: %s', exc, exc_info=True)
        sys.exit(1)
