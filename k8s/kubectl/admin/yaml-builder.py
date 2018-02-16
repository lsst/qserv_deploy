#!/usr/bin/env python3
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
import os
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

    logger = logging.getLogger()

    # create console handler and set level to debug
    console = logging.StreamHandler()
    # create formatter
    formatter = logging.Formatter('%(asctime)s %(levelname)-8s %(name)-15s %(message)s')
    # add formatter to ch
    console.setFormatter(formatter)

    logger.handlers = [console]
    logger.setLevel(levels.get(verbosity, logging.DEBUG))


def _get_container_id(container_name):
    for i, container in enumerate(yaml_data['spec']['containers']):
        if container['name'] == container_name:
            return i
    return None


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
        if 'volumeMounts' not in yaml_data['spec']['containers'][container_id]:
            yaml_data['spec']['containers'][container_id]['volumeMounts'] = []

        volume_mounts = yaml_data['spec']['containers'][container_id]['volumeMounts']
        volume_mount = {'mountPath': container_dir, 'name': volume_name}
        volume_mounts.append(volume_mount)


def _add_volume(host_dir, volume_name):
    if 'volumes' not in yaml_data['spec']:
        yaml_data['spec']['volumes'] = []
    volume = {'hostPath': {'path': host_dir},
              'name': volume_name}
    volumes = yaml_data['spec']['volumes']
    volumes.append(volume)


def _add_emptydir_volume(volume_name):
    if 'volumes' not in yaml_data['spec']:
        yaml_data['spec']['volumes'] = []

    volume = {'emptyDir': {},
              'name': volume_name}
    volumes = yaml_data['spec']['volumes']
    volumes.append(volume)


if __name__ == "__main__":
    try:

        parser = argparse.ArgumentParser(description='Create k8s pods configuration file from template')

        parser.add_argument('-v', '--verbose', dest='verbose', default=[],
                            action='append_const', const=None,
                            help='More verbose output, can use several times.')
        parser.add_argument('-i', '--ini', dest='iniFile',
                            required=True, metavar='PATH',
                            help='ini file used to fill yaml template')
        parser.add_argument('-r', '--resource', dest='resourcePath',
                            required=True, metavar='PATH',
                            help='path to resource directory (i.e. shell '
                            'scripts) inserted inside yaml')
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

        resourcePath = args.resourcePath
        yaml.add_representer(str, _str_presenter)

        yaml_data['metadata']['name'] = config.get('spec', 'pod_name')
        yaml_data['spec']['hostname'] = config.get('spec', 'pod_name')

        # Configure master
        #
        container_id = _get_container_id('master')
        if container_id is not None:
            container = yaml_data['spec']['containers'][container_id]
            # Use 'script' to create terminal for su
            command = ["script", "--return", "--quiet", "--command",
                "su qserv -c 'sh /config-start/xrootd-start.sh'"]
            # Uncomment line below for debugging purpose
            # command = ["tail", "-f", "/dev/null"]
            container['command'] = command
            container['image'] = config.get('spec', 'image')
            yaml_data['spec']['containers'][container_id] = container

        # Configure mysql-proxy
        #
        container_id = _get_container_id('myproxy')
        if container_id is not None:
            container = yaml_data['spec']['containers'][container_id]
            container['image'] = config.get('spec', 'image')

        # Configure worker
        #
        container_id = _get_container_id('worker')
        if container_id is not None:
            yaml_data['spec']['containers'][container_id]['image'] = config.get('spec', 'image')
            # Use 'script' to create terminal for su
            command = ["script", "--return", "--quiet", "--command",
                "su qserv -c 'sh /config-start/xrootd-start.sh'"]
            yaml_data['spec']['containers'][container_id]['command'] = command

        # Configure mariadb
        #
        container_id = _get_container_id('mariadb')
        if container_id is not None:
            yaml_data['spec']['containers'][container_id]['image'] = config.get('spec', 'image_mariadb')
            command = ["sh", "/config-start/mariadb-start.sh"]
            yaml_data['spec']['containers'][container_id]['command'] = command

        yaml_data['spec']['nodeSelector']['kubernetes.io/hostname'] = config.get('spec', 'host')

        # Attach log-dir to containers
        #
        if config.get('spec', 'host_log_dir'):
            volume_name = 'log-volume'
            mount_path = '/qserv/run/var/log'
            _add_volume(config.get('spec', 'host_log_dir'), volume_name)
            _mount_volume('master', mount_path, volume_name)
            _mount_volume('mariadb', mount_path, volume_name)
            _mount_volume('worker', mount_path, volume_name)

        # Attach tmp-dir to containers
        #
        if config.get('spec', 'host_tmp_dir'):
            volume_name = 'tmp-volume'
            mount_path = '/qserv/run/tmp'
            _add_volume(config.get('spec', 'host_tmp_dir'), volume_name)
            _mount_volume('master', mount_path, volume_name)
            _mount_volume('mariadb', mount_path, volume_name)
            _mount_volume('worker', mount_path, volume_name)

        # Attach data-dir to containers
        #
        data_volume_name = 'data-volume'
        data_mount_path = '/qserv/data'
        if config.get('spec', 'host_data_dir'):
            _add_volume(config.get('spec', 'host_data_dir'), data_volume_name)
        else:
            _add_emptydir_volume(data_volume_name)

        _mount_volume('mariadb', data_mount_path, data_volume_name)
        _mount_volume('master', data_mount_path, data_volume_name)
        # xrootd mmap/mlock *.MYD files and need to access mysql.sock
        # qserv-wmgr require access to mysql.sock
        _mount_volume('worker', data_mount_path, data_volume_name)

        # Attach qserv-run-dir to master and worker container
        #
        run_volume_name = 'run-volume'
        run_mount_path = '/qserv/run'
        _add_emptydir_volume(run_volume_name)
        _mount_volume('worker', run_mount_path, run_volume_name)
        _mount_volume('master', run_mount_path, run_volume_name)

        # initContainer
        #
        yaml_data['spec']['initContainers'] = []
        run_volume_name = 'run-volume'
        run_mount_path = '/qserv/run'
        if _get_container_id('master') is not None:

            # initContainer: configure qserv-run-dir using qserv image
            #
            init_container = dict()
            command = ["script", "--return", "--quiet", "--command",
                "su qserv -c 'bash /config/qserv-configure.sh'"]
            init_container['command'] = command
            init_container['env'] = []
            init_container['env'].append({'name': 'NODE_TYPE',
                'value': 'master'})
            init_container['env'].append({'name': 'QSERV_MASTER',
                'value': config.get('spec', 'master_hostname')})
            init_container['image'] = config.get('spec', 'image')
            init_container['imagePullPolicy'] = 'Always'
            init_container['name'] = 'init-run-dir'
            init_container['volumeMounts'] = []
            init_container['volumeMounts'].append({'mountPath': run_mount_path,
                'name': run_volume_name})
            init_container['volumeMounts'].append({'mountPath':
                "/config/", 'name': 'config-qserv-configure'})
            yaml_data['spec']['initContainers'].append(init_container)

            # initContainer: configure qserv-data-dir using mariadb image
            #
            init_container = dict()
            command = ["sh", "/config-mariadb/mariadb-configure.sh"]
            init_container['command'] = command
            init_container['image'] = config.get('spec', 'image_mariadb')
            init_container['imagePullPolicy'] = 'Always'
            init_container['name'] = 'init-data-dir'
            init_container['volumeMounts'] = []
            init_container['volumeMounts'].append({'mountPath': data_mount_path,
                'name': data_volume_name})
            init_container['volumeMounts'].append({'mountPath':
                "/config-mariadb/", 'name': 'config-mariadb-configure'})
            init_container['volumeMounts'].append({'mountPath':
                "/config-sql", 'name': 'config-master-sql'})
            yaml_data['spec']['initContainers'].append(init_container)

        if _get_container_id('worker') is not None:

            # initContainer: configure qserv-run-dir using qserv image
            #
            init_container = dict()

            command = ["script", "--return", "--quiet", "--command",
                "su qserv -c 'bash /config/qserv-configure.sh'"]
            init_container['command'] = command
            env = dict()
            env['name'] = 'QSERV_MASTER'
            env['value'] = config.get('spec', 'master_hostname')
            init_container['env'] = [env]
            init_container['image'] = config.get('spec', 'image')
            init_container['imagePullPolicy'] = 'Always'
            init_container['name'] = 'init-run-dir'
            init_container['volumeMounts'] = []
            init_container['volumeMounts'].append({'mountPath': run_mount_path,
                'name': run_volume_name})
            init_container['volumeMounts'].append({'mountPath':
                "/config/", 'name': 'config-qserv-configure'})
            yaml_data['spec']['initContainers'].append(init_container)

            # initContainer: configure qserv-data-dir using mariadb image
            #
            init_container = dict()
            command = ["sh", "/config-mariadb/mariadb-configure.sh"]
            init_container['command'] = command
            init_container['image'] = config.get('spec', 'image_mariadb')
            init_container['imagePullPolicy'] = 'Always'
            init_container['name'] = 'init-data-dir'
            init_container['volumeMounts'] = []
            init_container['volumeMounts'].append({'mountPath': data_mount_path,
                'name': data_volume_name})
            init_container['volumeMounts'].append({'mountPath':
                "/config-mariadb/", 'name': 'config-mariadb-configure'})
            init_container['volumeMounts'].append({'mountPath':
                "/config-sql", 'name': 'config-worker-sql'})
            yaml_data['spec']['initContainers'].append(init_container)


        with open(args.yamlFile, 'w') as f:
            f.write(yaml.dump(yaml_data, default_flow_style=False))

    except Exception as exc:
        logging.critical('Exception occurred: %s', exc, exc_info=True)
        sys.exit(1)
