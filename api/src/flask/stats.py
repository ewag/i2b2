import subprocess

def get_stats():
    """Return meta data on the i2b2 data based on statistical requirements"""
    p = subprocess.Popen(["pwd"] ,stdout=subprocess.PIPE, stderr=subprocess.STDOUT, universal_newlines=True)
    return [p.communicate()[0], p.returncode]
