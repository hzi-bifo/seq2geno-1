import os
import subprocess
import sys

def test_home(d):
    if d is None:
        raise Exception('ERROR: The environment variable "SEQ2GENO_HOME" not yet set up')
    elif not os.path.exists(d):
        raise Exception('ERROR: {} not existent'.format(d))
    elif not os.path.isfile(os.path.join(d, 'bin', 'seq2geno')):
        raise Exception(
            'ERROR: The environment variable "SEQ2GENO_HOME" looks incorrect')

home=os.environ.get('SEQ2GENO_HOME')
try:
    test_home(home)
except Exception as e:
    sys.exit(str(e))

# the environments
env_yml_dir= os.path.join(home, 'install', 'env_yaml')
env_home= os.path.join(home, 'env')
env_names_f= 'ENV_LIST'
env_names= [l.strip() for l in open(env_names_f, 'r')]

for env_name in env_names:
    env_dir= os.path.join(env_home, env_name)
    if not os.path.exists(env_dir):
        os.makedirs(env_dir)

    ## quick test about the environment
    ## skipped if already there
    if os.path.exists(os.path.join(env_dir, 'conda-meta')):
        continue
    ## install the environment
    print('installing {}...'.format(env_name))
    conda_cmd= ['conda', 'env', 'create', '-f', 
        os.path.join(env_yml_dir, env_name+'.yaml'),
        '--prefix', 
        os.path.join(env_home, env_name)]
    print(' '.join(conda_cmd))
    try:
        subprocess.run(conda_cmd)
    except AttributeError:
        subprocess.call(conda_cmd)
    except Exception as e:
        sys.exit('Errors in the installation of env "{}":\n\t{}'.format(env_name, str(e)))
