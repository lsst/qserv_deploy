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
Create k8s Persistent Volumes and Persitent Volume Claims
For Google existing Persistent Disks

@author Fabrice Jammes, IN2P3
"""

# -------------------------------
#  Imports of standard modules --
# -------------------------------
import argparse
import os.path
import sys
import yaml

def _build_yaml(pvc_name, pd_name, output_dir, template_dir):

        tpl_fname = 'pd.tpl.yaml'

        yaml_tpl = os.path.join(template_dir, tpl_fname)
        with open(yaml_tpl, 'r') as f:
            yaml_storage = list(yaml.load_all(f))

        pv_name = "pv-{}".format(pvc_name)

        yaml_storage[0]['metadata']['name'] = pv_name
        yaml_storage[0]['spec']['gcePersistentDisk']['pdName'] = "{}".format(pd_name)
        yaml_storage[1]['metadata']['name'] = "{}".format(pvc_name)
        yaml_storage[1]['spec']['volumeName'] = pv_name

        yaml_fname = "{}.yaml".format(pvc_name)
        yaml_fname = os.path.join(output_dir, yaml_fname)
        with open( yaml_fname, "w") as f:
            f.write(yaml.dump_all(yaml_storage, default_flow_style=False))

if __name__ == "__main__":
    try:

        parser = argparse.ArgumentParser(description="Create k8s Persistent Volumes and Claims")

        dir=os.path.dirname(os.path.abspath(__file__))

        parser.add_argument('-n', '--pvc_name', dest='pvc_name',
                            required=True, metavar='<pvcName>',
                            help='Name of the pvc')
        parser.add_argument('-d', '--pdname', dest='pd_name',
                            required=True, metavar='<pdName>',
                            help='pd name')
        parser.add_argument('-t', '--templateDir', dest='template_dir',
                            default=dir,
                            required=False, metavar='<templateDir>',
                            help='yaml template directory')
        parser.add_argument('-o', '--outputDir', dest='output_dir',
                            default=dir,
                            required=False, metavar='<outputDir>',
                            help='Output directory for generated yaml files')

        args = parser.parse_args()

        _build_yaml(args.pvc_name, args.pd_name, args.output_dir, args.template_dir)

    except Exception as e:
        print(e)
        sys.exit(1)

