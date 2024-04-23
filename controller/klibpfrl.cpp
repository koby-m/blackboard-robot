#include "klibpfrl.h"
#include <SPI.h>
#include <Arduino.h>

/* +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
  
  setupKeypad()

    Sets appropriate pinModes to simulate the 8 I/O pins of a PMOD port

+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+ */
void setupKeypad() {
  pinMode(2,OUTPUT);
  pinMode(3,OUTPUT);
  pinMode(4,OUTPUT);
  pinMode(5,OUTPUT);

  pinMode(6,INPUT);
  pinMode(7,INPUT);
  pinMode(8,INPUT);
  pinMode(9,INPUT);

  return;
}

/* +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
  
  getKeypadRaw()

    Returns a 16-bit number corresponding to which keys are pressed on the keypad

+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+ */
unsigned int getKeypadRaw() {

    unsigned int data = 0; // data to be returned
    byte c; // iterator
    byte k; // iterator

    for(c = 0; c < 4; c++) { 
      
      for(k = 0; k < 4; k++) { // drive the KYPD
        if(k == c) {
          digitalWrite(k + 2, LOW);
        } else {
          digitalWrite(k + 2, HIGH);
        }
      }

      for(k = 0; k < 4; k++) { // read the KYPD
        data = data << 1;
        data |= ~(digitalRead(k + 6)) & 1;
      }
      
      delay(1);

    }

    return data;
}

/* +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
  
  getKeypad()

    Returns the integer value of the pressed key on the keypad

+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+ */
int getKeypad() {
    
    unsigned int pressed = getKeypadRaw();
    byte place = 0;
    
    int keys[17] = {        1, 4, 7, 0,     // Array of keypad values with their respective keys
                            2, 5, 8, 0xF,       // However, notice that the array is mirrored and rotated
                            3, 6, 9, 0xE,
                            0xA, 0xB, 0xC, 0xD,
                        
                            -1 };   

    while(bitIndex(pressed, place) == 0 && place < 16) { // scan by bitIndex which buttons are pressed, incrementing until pressed button is found
        place += 1;
    }

    return keys[place];
}

/* +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
  
  waitForKey()

    Waits until a key is pressed and returns it once it is

+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+ */
int waitForKey() {
  int key;

  // wait until a key is pressed
  while(getKeypad() == -1);

  key = getKeypad();
  // print the key
  Serial.println(getKeypad(),HEX);

  // wait until the key is released
  while(getKeypad() != -1);
  delay(20); //db

  return key;
}

/* +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
  
  bitIndex()

    Indexes a passed value's bits like an array

+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+ */
bool bitIndex(int num, unsigned int index) {
  num = num >> (index) & 1;
	return num;
}

/* +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
  
  setupJoystick()

    Sets pin modes to accomodate joystick

+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+ */
void setupJoystick() {
  SPI.begin(); // initialization of SPI port
  SPI.setDataMode(SPI_MODE0); // configuration of SPI communication in mode 0
  SPI.setClockDivider(SPI_CLOCK_DIV16); // configuration of clock at 1MHz

  pinMode(10,OUTPUT);

  return;
}

/* +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
  
  getJoystick()

    Returns x-value, y-value, and button states to passed arguments

+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+ */
void getJoystick(float& x, float& y, int& button) {
  byte data[5];
  byte c; // iterator

  digitalWrite(10, LOW); // activate CS line

  delayMicroseconds(15); 

  for (int c = 0; c < 5; c++) { // get 5 bytes of data
    data[c] = SPI.transfer(0);
    delayMicroseconds(10); 
  }
  
  digitalWrite(10, HIGH); // deactivate CS line
  delay(10);

  x = (data[1] << 8) | data[0]; 
  y = (data[3] << 8) | data[2]; 

  button = (data[4] & 1) | (data[4] & 2); //0: no button, 1: trigger, 2: joystick
  if (button == 3) {                      //4: both
    button++;
  }
  return;
}