# Bluetooth Test for Arduino and HC-05 Module

Simple program to display walking state with the LED on the Arduino

## Usage

After uploading the program to the Arduino make sure:

* HC-05 TXD pin is connected to Arduino pin 10
* HC-05 GND pin is connected to Arduino GND pin
* HC-05 VCC pin is connected to Arduino 3.3V or 5V pin

Once all of those conditions are met connect the pedometer app to the
HC-05 module through Bluetooth. The device name should be HC-05 and
the pin defaults to `1234`. Once connected the app should send a signal
every time the pedestrian status changes.
