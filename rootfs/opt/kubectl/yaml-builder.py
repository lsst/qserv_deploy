#!/usr/bin/env python3

# LSST Data Management System
# Copyright 2014 LSST Corporation.
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


def _str_to_bool(s):
    if s == 'True':
        return True
    elif s == 'False':
        return False
    else:
        raise ValueError


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


def _get_container_id(container_name):
    for i, container in enumerate(yaml_data_tpl['containers']):
        if container['name'] == container_name:
            return i
    return None

def _get_init_container_id(container_name):
    for i, container in enumerate(yaml_data_tpl['initContainers']):
        if container['name'] == container_name:
            return i
    return None

def _set_env(container, env_name, env_value):
    _set = False
    for i, env in enumerate(container['env']):
        if env['name'] == env_name:
            env['value'] = env_value
            _set = True
            break
    if not _set:
        _LOG.log(logging.WARNING, "Unable to set env variable %s", env_name)

def _is_czar():
    name = yaml_data['metadata']['name']
    return name == 'czar'


def _mount_volume(container_name, container_dir, volume_name):
    """
    Map host_dir to container_dir in pod configuration
    using volume technology
    @param container_name: container name in yaml file
    @param container_dir: directory in container
    @param volume_name: name of volume made containing host_dir
    """
    container_id = _get_container_id(container_name)
    if container_id is not None:
        if 'volumeMounts' not in yaml_data_tpl['containers'][container_id]:
            yaml_data_tpl['containers'][container_id]['volumeMounts'] = []

        volume_mounts = yaml_data_tpl['containers'][container_id]['volumeMounts']
        volume_mount = {'mountPath': container_dir, 'name': volume_name}
        volume_mounts.append(volume_mount)


def _add_volume(host_dir, volume_name):
    if 'volumes' not in yaml_data_tpl:
        yaml_data_tpl['volumes'] = []
    if host_dir:
        volume = {'hostPath': {'path': host_dir},
                  'name': volume_name}
    else:
        volume = {'emptyDir': {},
                  'name': volume_name}
    volumes = yaml_data_tpl['volumes']
    volumes.append(volume)


def _add_emptydir_volume(volume_name):
    _add_volume(None, volume_name)


if __name__ == "__main__":
    try:

        parser = argparse.ArgumentParser(
            description='Create k8s pods configuration file from template')

        parser.add_argument('-v', '--verbose', dest='verbose', default=[],
                            action='append_const', const=None,
                            help='More verbose output, can use several times.')
        parser.add_argument('-i', '--ini', dest='iniFile',
                            required=True, metavar='PATH',
                            help='ini file used to fill yaml template')
        parser.add_argument('-t', '--template', dest='templateFile',
                            required=True, metavar='PATH',
                            help='yaml template file')
        parser.add_argument('-o', '--output', dest='yamlFile',
                            required=True, metavar='PATH',
                            help='pod configuration file, in yaml')

        args = parser.parse_args()

        _config_logger(args.verbose)

        config = configparser.RawConfigParser()

        with open(args.iniFile, 'r') as f:
            config.readfp(f)

        with open(args.templateFile, 'r') as f:
            yaml_data = yaml.load(f)

        yaml.add_representer(str, _str_presenter)

        yaml_data_tpl = yaml_data['spec']['template']['spec']

        # Configure cmsd and xrootd
        #
        if yaml_data['metadata']['name'] in ['qserv', 'xrootd-mgr-0', 'xrootd-mgr-1']:

            container_id = _get_container_id('xrootd')
            if container_id is not None:
                container = yaml_data_tpl['containers'][container_id]
                container['image'] = config.get('spec', 'qserv_image')

            container_id = _get_container_id('cmsd')
            if container_id is not None:
                container = yaml_data_tpl['containers'][container_id]
                container['image'] = config.get('spec', 'qserv_image')

        # Configure czar and worker
        #
        if yaml_data['metadata']['name'] in ['czar', 'qserv']:

            if yaml_data['metadata']['name'] == 'qserv':
                yaml_data['spec']['replicas'] = int(config.get('spec', 'replicas'))

            kind = _str_to_bool(config.get('spec', 'kind'))
            gke = _str_to_bool(config.get('spec', 'gke'))
            volumeClaimTemplates = yaml_data['spec']['volumeClaimTemplates']
            
            if gke or kind:
                volumeClaimTemplates[0]['spec']['resources'] = dict()
                vct_resources = volumeClaimTemplates[0]['spec']['resources']
                vct_resources['requests'] = dict()
                if not config.get('spec', 'storage_size'):
                    raise ValueError('Undefined storage size in env-infra.sh')
                vct_resources['requests']['storage'] = config.get('spec',
                                                                'storage_size')
            else:
                storage_class = "qserv-local-storage"
                volumeClaimTemplates[0]['spec']['storageClassName'] = storage_class

            # Configure mysql-proxy
            #
            container_id = _get_container_id('proxy')
            if container_id is not None:
                container = yaml_data_tpl['containers'][container_id]
                container['image'] = config.get('spec', 'qserv_image')

            # Configure wmgr
            #
            container_id = _get_container_id('wmgr')
            if container_id is not None:
                container = yaml_data_tpl['containers'][container_id]
                container['image'] = config.get('spec', 'qserv_image')

            # Configure mariadb
            #
            container_id = _get_container_id('mariadb')
            if container_id is not None:
                container = yaml_data_tpl['containers'][container_id]
                container['image'] = config.get('spec', 'qserv_image')
                if _is_czar() and config.get('spec', 'mem_request'):
                    container['resources'] = dict()
                    resources = container['resources']
                    resources['requests'] = dict()
                    resources['requests']['memory'] = config.get('spec', 'mem_request')

            # Configure replication worker
            #
            container_id = _get_container_id('repl')
            if container_id is not None:
                container = yaml_data_tpl['containers'][container_id]
                container['image'] = config.get('spec', 'repl_image')

            # initContainer: configure qserv-data-dir using mariadb qserv_image
            #
            container_id = _get_init_container_id('init-data-dir')
            if container_id is not None:
                yaml_data_tpl['initContainers'][container_id]['image'] = config.get('spec', 'qserv_image')

            # Attach tmp-dir to containers
            #
            volume_name = 'tmp-volume'
            mount_path = '/qserv/run/tmp'
            _add_emptydir_volume(volume_name)

            _mount_volume('mariadb', mount_path, volume_name)
            _mount_volume('proxy', mount_path, volume_name)
            _mount_volume('wmgr', mount_path, volume_name)

        # Configure replication controller
        #
        elif yaml_data['metadata']['name'] == 'repl-ctl':
            container_id = _get_container_id('repl')
            container = yaml_data_tpl['containers'][container_id]
            container['image'] = config.get('spec', 'repl_image')
            _set_env(container, 'WORKER_COUNT', config.get('spec', 'replicas'))

        # Configure replication database
        #
        elif yaml_data['metadata']['name'] == 'repl-db':
            container_id = _get_container_id('mariadb')
            container = yaml_data_tpl['containers'][container_id]
            container['image'] = config.get('spec', 'mariadb_image')

        with open(args.yamlFile, 'w') as f:
            f.write(yaml.dump(yaml_data, default_flow_style=False))

    except Exception as exc:
        logging.critical('Exception occurred: %s', exc, exc_info=True)
        sys.exit(1)
