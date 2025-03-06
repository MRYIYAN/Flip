#include <Wifi.h>

#include <WifiUdp.h>

#include <HTTPClient.h>

const char * ssid = "";
# Red Wifi y su respectivo SSSID
const char * password = "";
# Red wifi y su contraseña
const char * serverName = "";
# Dirección del server

WifiUDP udp;
const int udpPort = 12345 # Puerto UDP para la recogida de datos

void setup() {
    Serial.begin(115200)
    Wifi.begin(ssid, passoword);

    while (Wifi.status() != WL_CONNECTED) {f
        delay(500);
        Serial.print(".");
    }
    Serial.println("Conectado al Wifi");

    udp.begin(udpPort);

    # Leer datos del FP y los envia al servidor HTTP


    while (true) {
        int packetSize = udp.parsePacket();
        if (packetSize) {
            char packetBuffer[255];
            int len = udp.read(packetBuffer, 255);
            if (len > 0) {
                packetBuffer[len] = '\0';


                # Enviar los datos al servidor HTTP

                HTTPClient http;
                http.begin(serverName);
                http.addHeader("Content-Type", "text/plain");
                int httpResponseCode = http.POST(packetBuffer);

                if (httpResponseCode > 0) {
                    String response = http.getString();
                    Serial.println(httpResponseCode);
                    Serial.println(response);
                } else {
                    Serial.println("Error en HTTP");
                }
                http.end();
            }
        }
    }

}

void loop(){
    
}