#include <WiFi.h>
#include <WiFiUdp.h>
#include <HTTPClient.h>

const char* ssid = "YOUR_SSID";      // Red WiFi abierta
const char* password = "";           // Red WiFi abierta (sin contraseña)
const char* serverName = "http://YOUR_MOBILE_IP:8080/upload";  // Dirección del servidor en el móvil

WiFiUDP udp;
const int udpPort = 12345;  // Puerto UDP para recibir datos

void setup() {
  Serial.begin(115200);
  WiFi.begin(ssid, password);

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("Connected to WiFi");

  udp.begin(udpPort);

  // Leer datos del Flipper Zero y enviarlos al servidor HTTP
  while (true) {
    int packetSize = udp.parsePacket();
    if (packetSize) {
      char packetBuffer[255];
      int len = udp.read(packetBuffer, 255);
      if (len > 0) {
        packetBuffer[len] = '\0';

        // Enviar los datos al servidor HTTP
        
        HTTPClient http;
        http.begin(serverName);
        http.addHeader("Content-Type", "text/plain");
        int httpResponseCode = http.POST(packetBuffer);

        if (httpResponseCode > 0) {
          String response = http.getString();
          Serial.println(httpResponseCode);
          Serial.println(response);
        } else {
          Serial.println("Error in HTTP request");
        }
        http.end();
      }
    }
  }
}

void loop() {
  // Nada que hacer aquí
}
