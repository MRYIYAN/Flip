# Importar servidor para la conexión del ESP32 y la red

from flask import Flask, request
import subprocess

app = Flask(__name__)
@app.route('ESP32.py', methods = ['POST'])
def upload ():
    script = request.dat.decode('utf-8')
    with open('received_script.ps1', 'w') as f:
        f.write(script)
    subprocess.run(["powershell", "-ExecutionPolicy", "Bypass", "-File","receivedscript.ps1"])
    return "Script recibido y ejecutado" 
if __name__ == '__main__':
    app.run(host='0.0.0.0', port =8080)