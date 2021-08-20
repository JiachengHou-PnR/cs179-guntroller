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

// SETTINGS INPUT PIN numbers
const int MOUSE_ON_OFF_PIN     = 7; // Turns mouse function on/off
const int SENSITIVITY_UP_PIN   = 4; // Makes mouse more sensitive
const int SENSITIVITY_DOWN_PIN = 3; // Makes mouse less sensitive
const int MOUSE_RESET_PIN      = 5; // Reset mouse cursor position

// GAME INPUT PIN numbers
const int TRIGGER_PIN          = 1; // Left mouse click

// OUTPUT PIN numbers
const int MOUSE_LED_PIN        = 13;// Status LED for mouse function

// CONSTANTS
const byte MOVE_RATIO_HEIGHT = 2;   // The vertical moving speed ratio of the mouse
const byte MOVE_RATIO_WIDTH  = 3;   // The horizontal moving speed ratio of the mouse
const byte SINGLE_MOVE_LIMIT = 127; // The max value for a single Mouse.move(), i.e. sizeof(byte)/2
const float RESET_MOVE_RATIO = 0.7; // Reduce mouse moved vals

// VARIABLES
// Sensors readings
float acce_x, acce_y, acce_z;       // Data from accelerometer
float gyro_x, gyro_y, gyro_z;       // Data from gyroscope

// Mouse on off
int mouseState = LOW;               // Mouse function state
bool lastMouseButtonState;
bool currentMouseButtonState;

// Mouse sensitivity
byte sensitivity = 5;                // Mouse moving sensitivity 1-10
bool lastSensUpButtonState;
bool currentSensUpButtonState;
bool lastSensDownButtonState;
bool currentSensDownButtonState;

// Mouse reset
int mouseMovedVal_x;
int mouseMovedVal_y;
bool lastResetButtonState;
bool currentResetButtonState;

// Bluetooth pedometer
int currentWalkingState = -1;

// Game input button states
bool triggerButtonState;

// Keycodes
char move_forward = 'w';

void setup(void) {
  pinMode(MOUSE_ON_OFF_PIN, INPUT);
  pinMode(SENSITIVITY_UP_PIN, INPUT);
  pinMode(SENSITIVITY_DOWN_PIN, INPUT);
  pinMode(MOUSE_RESET_PIN, INPUT);
  pinMode(TRIGGER_PIN, INPUT);

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

  // Mouse reset button
  lastResetButtonState    = currentResetButtonState;
  currentResetButtonState = digitalRead(MOUSE_RESET_PIN);

  // Trigger button
  triggerButtonState = !digitalRead(TRIGGER_PIN);
}

void getMouseState()
{
  if (lastMouseButtonState == HIGH && currentMouseButtonState == LOW) {
    // toggle state of LED
    mouseState = !mouseState;

    // Print current state
    Serial.print("The on/off button is pressed, mouse function is ");
    if (mouseState)
      Serial.println("ON");
    else
      Serial.println("OFF");
    Serial.println("");

    // Reset mouseMovedVals when turning mouse function on
    if (mouseState)
      resetMouseMovedVals();

    // control LED arccoding to the toggled state
    digitalWrite(MOUSE_LED_PIN, mouseState);
  }
}

void getMouseSensitivity()
{
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

    if (sensitivity++ >= 10)
      sensitivity = 10;

    Serial.println(sensitivity);
    Serial.println("");
  }
  else if (lastSensDownButtonState == HIGH && currentSensDownButtonState == LOW) {
    Serial.print("Sens DOWN button is pressed, new sensitivity is ");

    // Decrease sensitivity
    if (sensitivity-- <= 1)
      sensitivity = 1;

    Serial.println(sensitivity);
    Serial.println("");
  }
}


void processMouseReset()
{
  // Mouse reset button is pressed
  if (lastResetButtonState == HIGH && currentResetButtonState == LOW) {
    // Print message
    Serial.println("Reset button pressed, mouse position and traveled values resetted.");

    // Move mouse opposite to where it has been moved
    moveMouse(-mouseMovedVal_x, -mouseMovedVal_y, false);

    // Reset mouseMovedVals
    resetMouseMovedVals();
  }
}

void processMouseState()
{
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
    //printSensorReadings();

    // Move mouse cursor
    moveMouse(gyro_z, gyro_x, true);
  }
}

void processGameInput()
{
  if (triggerButtonState) {
    if (!Mouse.isPressed(MOUSE_LEFT)) {
      Mouse.press(MOUSE_LEFT);
    }
  } else {
    if (Mouse.isPressed(MOUSE_LEFT)) {
      Mouse.release(MOUSE_LEFT);
    }
  }
}

void processBluetooth()
{
  if (Bluetooth.available() > 0) {
    currentWalkingState = Bluetooth.read();
    if (currentWalkingState >= 1) {
      Keyboard.press(move_forward);
      Serial.println("Received walking signal");
    } else if (currentWalkingState == 0) {
      Keyboard.release(move_forward);
      Serial.println("Received stopping signal");
    }
    Serial.println("");
  }
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

void resetMouseMovedVals() {
  mouseMovedVal_x = 0;
  mouseMovedVal_y = 0;
}

void moveMouse(float x, float y, bool fromSensor) {
  // Calculate values (these are SIGNED byte values)
  int xVal = fromSensor ? -x * MOVE_RATIO_WIDTH  * sensitivity : x * RESET_MOVE_RATIO;
  int yVal = fromSensor ?  y * MOVE_RATIO_HEIGHT * sensitivity : y * RESET_MOVE_RATIO;

  // Set moving limit
  if (fromSensor)
  {
    if (mouseMovedVal_x >  SINGLE_MOVE_LIMIT * MOVE_RATIO_WIDTH)
      xVal = (xVal > 0) ? 0 : xVal;
    if (mouseMovedVal_x < -SINGLE_MOVE_LIMIT * MOVE_RATIO_WIDTH)
      xVal = (xVal < 0) ? 0 : xVal;
    if (mouseMovedVal_y >  SINGLE_MOVE_LIMIT * MOVE_RATIO_HEIGHT)
      yVal = (yVal > 0) ? 0 : yVal;
    if (mouseMovedVal_y < -SINGLE_MOVE_LIMIT * MOVE_RATIO_HEIGHT)
      yVal = (yVal < 0) ? 0 : yVal;
  }

  Serial.print("xVal: ");
  Serial.print(xVal);
  Serial.print(", yVal: ");
  Serial.println(yVal);

  // Move mouse
  // If vals exceeds single move limit, move mouse in multiple calls
  while (xVal > SINGLE_MOVE_LIMIT)
  {
    Mouse.move(SINGLE_MOVE_LIMIT, 0, 0);
    xVal -= SINGLE_MOVE_LIMIT;
  }
  while (xVal < -SINGLE_MOVE_LIMIT)
  {
    Mouse.move(-SINGLE_MOVE_LIMIT, 0, 0);
    xVal += SINGLE_MOVE_LIMIT;
  }
  while (yVal > SINGLE_MOVE_LIMIT)
  {
    Mouse.move(0, SINGLE_MOVE_LIMIT, 0);
    yVal -= SINGLE_MOVE_LIMIT;
  }
  while (yVal < -SINGLE_MOVE_LIMIT)
  {
    Mouse.move(0, -SINGLE_MOVE_LIMIT, 0);
    yVal += SINGLE_MOVE_LIMIT;
  }
  // Move mouse if moved vals are within a single move limit
  Mouse.move(xVal, yVal, 0);

  // Record moved values
  mouseMovedVal_x += xVal;
  mouseMovedVal_y += yVal;

  Serial.print("mouseMovedVal_x: ");
  Serial.print(mouseMovedVal_x);
  Serial.print(", mouseMovedVal_y: ");
  Serial.println(mouseMovedVal_y);
}

void loop()
{
  getButtonStates();
  getMouseState();
  getMouseSensitivity();
  processMouseReset();
  processMouseState();
  processBluetooth();
  processGameInput();
  delay(15);
}
