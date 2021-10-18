from flask import Flask
from flask_accept import accept
import subprocess
app = Flask(__name__)

def get_stats():
    """Return meta data on the i2b2 data based on statistical requirements"""
    p = subprocess.Popen(["pwd"] ,stdout=subprocess.PIPE, stderr=subprocess.STDOUT, universal_newlines=True)
    return [p.communicate()[0], p.returncode]

@app.route('/')
def index():
    return 'Index Page'

@app.route('/stats')
@accept('text/html')
def stats():
    result = get_stats()
    return "<html><body><p>Exitcode: "+str(result[1])+"</p><p>Message Log:<br/>"+result[0].replace("\n","<br/>")+"</p></body></html>"
