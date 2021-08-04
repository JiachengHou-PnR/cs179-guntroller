/* Simple program to test pedometer app
 *
 * Connect TXD pin of the HC-05 module to pin 10 on the arduino.
 * If the app detects walking the arduino will turn on the built-in
 * LED and set pin 13 to high and when the app stops detecting
 * walking the arduino will turn off the LED and set pin 13 to low.
 */
#include <SoftwareSerial.h>

SoftwareSerial Bluetooth(10, 11); // RX | TX

int input = -1;

void setup() {
    pinMode(LED_BUILTIN, OUTPUT);
    Serial.begin(9600);
    Bluetooth.begin(9600);
    Serial.println("Starting program");
}

void loop() {
    while (Bluetooth.available() == 0) {}
    delay(500);
    while (Bluetooth.available() > 0) {
        input = Bluetooth.read();
        if (input == 1) {
            digitalWrite(LED_BUILTIN, HIGH);
            Serial.println("Received walking signal");
        } else if (input == 0) {
            digitalWrite(LED_BUILTIN, LOW);
            Serial.println("Received stopping signal");
        } else if (input != -1) {
            Serial.write(input);
        }
    }
}
