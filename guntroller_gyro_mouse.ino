#include <Mouse.h>
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>
#include <Wire.h>


// MPU6050
Adafruit_MPU6050 mpu;

// Set input pin numbers
const int mouse_button_pin = 7;
// Set output pin numbers
const int mouse_led_pin = 13;

// Constants
const int sensitivity_height = 10;
const int sensitivity_width = 15;

// Variables
float acce_x, acce_y, acce_z;
float gyro_x, gyro_y, gyro_z;
int mouseState = LOW;
int lastButtonState;
int currentButtonState;

void setup(void) {
  pinMode(mouse_button_pin, INPUT);
  pinMode(mouse_led_pin, OUTPUT);
  currentButtonState = digitalRead(mouse_button_pin);

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
}

void loop() {

  lastButtonState    = currentButtonState;      // save the last state
  currentButtonState = digitalRead(mouse_button_pin); // read new state

  if (lastButtonState == HIGH && currentButtonState == LOW) {
    Serial.print("The button is pressed, mouse function is ");

    // toggle state of LED
    mouseState = !mouseState;

    if (mouseState)
      Serial.println("ON");
    else
      Serial.println("OFF");
    Serial.println("");

    // control LED arccoding to the toggled state
    digitalWrite(mouse_led_pin, mouseState);
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
    
    Mouse.move(gyro_z * -sensitivity_width, gyro_x * sensitivity_height);
  }
  
  delay(15);
}
