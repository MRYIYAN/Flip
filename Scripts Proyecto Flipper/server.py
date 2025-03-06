
//Impotar servidor para la conexión entre Flipper con ESP32 y la Red
from flask import Flask, request
import subprocess

app = Flask(__name__)

@app.route('/upload', methods=['POST'])
def upload():
    script = request.data.decode('utf-8')
    with open('received_script.ps1', 'w') as f:
        f.write(script)
    subprocess.run(["powershell", "-ExecutionPolicy", "Bypass", "-File", "received_script.ps1"])
    return "Script received and executed"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
