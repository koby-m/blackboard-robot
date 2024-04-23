#include "klibwifi.h"
#include "klibpfrl.h"
#include <string.h>

#define LOW_JOYSTICK_THRESHOLD 250
#define HIGH_JOYSTICK_THRESHOLD 750

/* +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
  
  Variables

+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+ */
// For Keypad
int key;
bool keyPressed = false;

// Joystick variables
float x;
float y;
int b;
String joystickCommand = "0000";
String prevJoystickCommand = "0000";

// Sending commands
String command = "0000";
byte commandIndex = 0;

// Command delay
long sendTimestamp = 0;

/* +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
  
  setup()

+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+ */
void setup() {
  // begin serial connection for debug
  Serial.begin(9600);
  //while(!Serial);

  // establish connection to Blackboard ESP32 network
  connectToBlackboard();
  
  // indicate that to the Blackboard that the controller is
  sendBlackboardData("F1F0"); // when disconnected, code is: 0F35

  // set pin modes for PMOD KYPD
  setupKeypad();

  // set pin modes for PMOD JSTK2
  setupJoystick();

}

/* +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
  
  MAIN - loop()

+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+ */
void loop() {

  key = getKeypad();
 
  if(key != -1 && keyPressed == false) { // if a key is currently pressed, but flagged as not pressed, update and append to command string

    if(key < 0xA) { // if it's less than ten, its still represented as an Arabic numeral, so convert to ASCII
      command[commandIndex] = key + 0x30; // append to command
    } else { // otherwise, convert it to its Latin ASCII representation
      command[commandIndex] = key + 0x37; // append to command
    }
    
    commandIndex++; 
    keyPressed = true;
  }

  if(commandIndex == 4) { // if 4 buttons have been hit, send the command string to the Blackboard

    commandIndex = 0; // reset command index for new command to be entered
    Serial.println(command);
    sendBlackboardData(command.c_str());

  }

  if(key == -1 && keyPressed == true) { // if no key is currently pressed, but is flagged as pressed, reset it
    keyPressed = false;
  }

  getJoystick(x,y,b);

  // determine if left or right
  if(x < LOW_JOYSTICK_THRESHOLD) { // LEFT
    joystickCommand = "4000";
  } else if(x > HIGH_JOYSTICK_THRESHOLD) { // RIGHT
    joystickCommand = "4100";
  } else {
    joystickCommand = "4400"; // BRAKE
  }

  // determine if up or down
  if(y < LOW_JOYSTICK_THRESHOLD) { // DOWN
    joystickCommand = "4300";
  } else if(y > HIGH_JOYSTICK_THRESHOLD) { // UP
    joystickCommand = "4200";
  } else if(joystickCommand != "4000" && joystickCommand != "4100" ) { // BRAKE
    joystickCommand = "4400";
  } 

  // determine if button, trigger, or both
  if(b == 1) {
    //Serial.println("BUTTON");
  } else if(b == 2) {
    //Serial.println("TRIGGER");
  } else if(b == 4) {
    //Serial.println("TRIGGER & BUTTON");
  }

  if(joystickCommand != prevJoystickCommand) { // Check to see if joystick command has updated since last send
    sendBlackboardData(joystickCommand.c_str());
    Serial.println(joystickCommand);
    prevJoystickCommand = joystickCommand;
  }

} // hej da
