#include <Mouse.h>
#include <Keyboard.h>
#include <Adafruit_Sensor.h>
#include <Adafruit_MPU6050.h>
#include <Wire.h>
#include <SoftwareSerial.h>

// Set up a software serial interface for the HC-05 module
SoftwareSerial Bluetooth(10, 11); // RX | TX

// MPU6050
Adafruit_MPU6050 mpu;

// INPUT PIN numbers
const int MOUSE_ON_OFF_PIN = 7;     // Turns mouse function on/off
const int SENSITIVITY_UP_PIN = 4;   // Makes mouse more sensitive
const int SENSITIVITY_DOWN_PIN = 3; // Makes mouse less sensitive

// OUTPUT PIN numbers
const int MOUSE_LED_PIN = 13;       // Status LED for mouse function 

// CONSTANTS
const int MOVE_RATIO_HEIGHT = 2;    // The constant for the vertical moving speed ratio of the mouse 
const int MOVE_RATIO_WIDTH  = -3;   // The constant for the horizontal moving speed ratio of the mouse

// VARIABLES
float acce_x, acce_y, acce_z;       // Data from accelerometer
float gyro_x, gyro_y, gyro_z;       // Data from gyroscope

// Mouse on off
int mouseState = LOW;               // Mouse function state
int lastMouseButtonState;
int currentMouseButtonState;

// Mouse sensitivity
int sensitivity = 5;                // Mouse moving sensitivity 1-10
int lastSensUpButtonState;
int currentSensUpButtonState;
int lastSensDownButtonState;
int currentSensDownButtonState;

// Mouse reset
int initMousePosition;
int lastResetButtonState;
int currentResetButtonState;

// Bluetooth pedometer
int currentWalkingState = -1;



void setup(void) {
  pinMode(MOUSE_ON_OFF_PIN, INPUT);
  pinMode(MOUSE_LED_PIN, OUTPUT);
  currentMouseButtonState = digitalRead(MOUSE_ON_OFF_PIN);

  Serial.begin(115200);
  while (!Serial)
    delay(10); // will pause Zero, Leonardo, etc until serial console opens

  Serial.println("Guntroller Sensor Mouse Test.");

  // Try to initialize!
  if (!mpu.begin()) {
    Serial.println("Failed to find MPU6050 chip");
    while (1) {
      delay(10);
    }
  }
  Serial.println("MPU6050 Found!");

  // MPU6050 parameter settings
  mpu.setAccelerometerRange(MPU6050_RANGE_2_G);
  Serial.print("Accelerometer range set to: ");
  switch (mpu.getAccelerometerRange()) {
    case MPU6050_RANGE_2_G:
      Serial.println("+-2G");
      break;
    case MPU6050_RANGE_4_G:
      Serial.println("+-4G");
      break;
    case MPU6050_RANGE_8_G:
      Serial.println("+-8G");
      break;
    case MPU6050_RANGE_16_G:
      Serial.println("+-16G");
      break;
  }
  mpu.setGyroRange(MPU6050_RANGE_500_DEG);
  Serial.print("Gyro range set to: ");
  switch (mpu.getGyroRange()) {
    case MPU6050_RANGE_250_DEG:
      Serial.println("+- 250 deg/s");
      break;
    case MPU6050_RANGE_500_DEG:
      Serial.println("+- 500 deg/s");
      break;
    case MPU6050_RANGE_1000_DEG:
      Serial.println("+- 1000 deg/s");
      break;
    case MPU6050_RANGE_2000_DEG:
      Serial.println("+- 2000 deg/s");
      break;
  }

  mpu.setFilterBandwidth(MPU6050_BAND_21_HZ);
  Serial.print("Filter bandwidth set to: ");
  switch (mpu.getFilterBandwidth()) {
    case MPU6050_BAND_260_HZ:
      Serial.println("260 Hz");
      break;
    case MPU6050_BAND_184_HZ:
      Serial.println("184 Hz");
      break;
    case MPU6050_BAND_94_HZ:
      Serial.println("94 Hz");
      break;
    case MPU6050_BAND_44_HZ:
      Serial.println("44 Hz");
      break;
    case MPU6050_BAND_21_HZ:
      Serial.println("21 Hz");
      break;
    case MPU6050_BAND_10_HZ:
      Serial.println("10 Hz");
      break;
    case MPU6050_BAND_5_HZ:
      Serial.println("5 Hz");
      break;
  }

  Serial.println("");
  delay(100);

  Bluetooth.begin(9600);
  Serial.println("Started Bluetooth serial interface");

  Mouse.begin();
  Keyboard.begin();
}

void getButtonStates() {
  // Mouse function on/off button
  lastMouseButtonState    = currentMouseButtonState;        // save the last state
  currentMouseButtonState = digitalRead(MOUSE_ON_OFF_PIN);  // read new state

  // Mouse sensitivity up button
  lastSensUpButtonState    = currentSensUpButtonState;
  currentSensUpButtonState = digitalRead(SENSITIVITY_UP_PIN);

  // Mouse seneitivity down button
  lastSensDownButtonState    = currentSensDownButtonState;
  currentSensDownButtonState = digitalRead(SENSITIVITY_DOWN_PIN);
}

void printSensorReadings() {

  Serial.print("Acceleration X: ");
  Serial.print(acce_x);
  Serial.print(", Y: ");
  Serial.print(acce_y);
  Serial.print(", Z: ");
  Serial.print(acce_z);
  Serial.println(" m/s^2");

  Serial.print("Rotation X: ");
  Serial.print(gyro_x);
  Serial.print(", Y: ");
  Serial.print(gyro_y);
  Serial.print(", Z: ");
  Serial.print(gyro_z);
  Serial.println(" rad/s");
  Serial.println("");
}

void loop() {

  getButtonStates();

  if (lastMouseButtonState == HIGH && currentMouseButtonState == LOW) {
    Serial.print("The on/off button is pressed, mouse function is ");

    // toggle state of LED
    mouseState = !mouseState;

    if (mouseState)
      Serial.println("ON");
    else
      Serial.println("OFF");
    Serial.println("");

    // control LED arccoding to the toggled state
    digitalWrite(MOUSE_LED_PIN, mouseState);
  }

  if (lastSensUpButtonState == HIGH && currentSensUpButtonState == LOW &&
      lastSensDownButtonState == HIGH && currentSensDownButtonState == LOW) {
    Serial.print("Sens UP and DOWN buttons are pressed, reset sensitivity to ");

    // Reset sensitivity
    sensitivity = 5;

    Serial.println(sensitivity);
    Serial.println("");
  }
  else if (lastSensUpButtonState == HIGH && currentSensUpButtonState == LOW) {
    Serial.print("Sens UP button is pressed, new sensitivity is ");

    // Increase sensitivity
    
    if(sensitivity++ >= 10)
      sensitivity = 10;

    Serial.println(sensitivity);
    Serial.println("");
  }
  else if (lastSensDownButtonState == HIGH && currentSensDownButtonState == LOW) {
    Serial.print("Sens DOWN button is pressed, new sensitivity is ");

    // Decrease sensitivity
    if(sensitivity-- <= 1)
      sensitivity = 1;

    Serial.println(sensitivity);
    Serial.println("");
  }

  if (mouseState) {
    /* Get new sensor events with the readings */
    sensors_event_t a, g, temp;
    mpu.getEvent(&a, &g, &temp);
    
    acce_x = a.acceleration.x;
    acce_y = a.acceleration.y;
    acce_z = a.acceleration.z;
    gyro_x = g.gyro.x;
    gyro_y = g.gyro.y;
    gyro_z = g.gyro.z;

    /* Print out the values */
    printSensorReadings();
    
    Mouse.move(gyro_z * MOVE_RATIO_WIDTH  * sensitivity, 
               gyro_x * MOVE_RATIO_HEIGHT * sensitivity);
  }

  if (Bluetooth.available() > 0) {
    currentWalkingState = Bluetooth.read();
    if (currentWalkingState >= 1) {
      Keyboard.press('w');
      Serial.println("Received walking signal");
    } else if (currentWalkingState == 0) {
      Keyboard.release('w');
      Serial.println("Received stopping signal");
    }
    Serial.println("");
  }
  
  delay(15);
}
