#include "klibwifi.h"
#include <WiFiNINA.h>

/* +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
  
  Access point connection information

+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+ */
char ssid[] = AP_SSID;                // Network name
char pass[] = AP_PASSWORD;           // Network password
byte blackboardAccessPoint[4] = {192,168,4,1};

/* +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
  
  Global variables

+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+ */
int status = WL_IDLE_STATUS;          // the WiFi status
WiFiClient blackboard;                // client class

/* +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
  
  connectToBlackboard()

    Connects to the Blackboard with the provided information above

+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+ */
void connectToBlackboard() {
  byte count = 0;

  while (status != WL_CONNECTED && count != 10) { // wait until connected, or until 10 failed attempts
    Serial.print("Attempting to connect to network: ");
    Serial.println(ssid);
    status = WiFi.begin(ssid, pass);
    delay(5000);
    count++;
  }
  
  if(count != 10) { // if the network was joined
    Serial.print("Local IP: ");
    Serial.println(WiFi.localIP());
    Serial.print("Gateway IP: ");
    Serial.println(WiFi.gatewayIP());

    if(blackboard.connect(blackboardAccessPoint,80)) {
      Serial.println("Successfully connected to access point");
    } else {
      Serial.println("Failed to connected to access point");
    }

  } else { // failed to join the network
    Serial.println("[!] Failed to join the network");
  }

}
/* +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
  
  sendBlackboardData()

    Sends passed data to the Blackboard

+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+ */
void sendBlackboardData(const char data[]) {
  // Serial.print("Nano 33 IoT -> Blackboard: ");
  // Serial.println(data);
  blackboard.write(data);
}
