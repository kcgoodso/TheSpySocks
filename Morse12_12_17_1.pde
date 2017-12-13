/* 
 Fade an LED using a potentiometer in Arduino
 by using Firmata 
 
 by Afroditi Psarra
 November 2017
 */

import ddf.minim.*;
import processing.serial.*;
import cc.arduino.*;
import ddf.minim.ugens.*;

Arduino arduino;
Minim minim;
AudioOutput out;
Oscil wave;

boolean outgoingMessage = false;
String outBeeps = "";
int outTime = 0;
int outWait = 0;
boolean outFlash;
boolean outBetween;

boolean inFlash = false;
int inTime = 0;
String inMorse = "";

int inbox[] = {10, 10, 720, 50};
int outbox[] = {10, 70, 720, 50};

int inLight[] = {inbox[0] + inbox[2] + 10, inbox[1], 50, inbox[3]};
int outLight[] = {outbox[0] + outbox[2] + 10, outbox[1], 50, outbox[3]};

String inMessage = "Incoming Message: ";
String outMessage = "Sos";

int pot = 0; //potentiometer pin A2
int motor = 17; //MotorPort

char[] english = { 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l',
                  'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 
                  'y', 'z', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '0'};
                  
String[] morse = { ".-", "-...", "-.-.", "-..", ".", "..-.", "--.", "....", "..", 
                ".---", "-.-", ".-..", "--", "-.", "---", ".---.", "--.-", ".-.",
                "...", "-", "..-", "...-", ".--", "-..-", "-.--", "--..", ".----",
                "..---", "...--", "....-", ".....", "-....", "--...", "---..", "----.",
                "-----"};
char dot = '.';
char dash = '-';

int dotBreak = 100;
int dashBreak = dotBreak*3;
int betweenBreak = dotBreak;
int barBreak = dotBreak*3;
int spaceBreak = dotBreak;

int errorBreak = 10;
int inDashBreak = dashBreak;
int inBarBreak = barBreak;

int testCount = 0;

void setup() {
  //Window Setup
  //325 x 140
  size(800, 130);
  noStroke();
  background(0);
  
  inTime = millis();
  //ArduinoSetup
  //println(Arduino.list());
  arduino = new Arduino(this, Arduino.list()[0], 57600); //<>//
  minim = new Minim(this);
  out = minim.getLineOut();
  wave = new Oscil( 440, 0.5f, Waves.SINE );
  wave.patch( out );
}

void keyPressed() {
  if(outgoingMessage) {
    return;
  }
  int keyIndex = -1;
  if (key >= 'A' && key <= 'Z') {
    keyIndex = key;
  } else if (key >= 'a' && key <= 'z') {
    keyIndex = key;
  } else if (key >= '0' && key <= '9') {
    keyIndex = key;
  } else if (key == ' ' || key == '_') {
    keyIndex = -3;
  } else if (key == ENTER || key == RETURN) {
    keyIndex = -2;
  } else if (key == DELETE || key == BACKSPACE) {
    keyIndex = -4;
  }
  
  textSize(32);
  if (keyIndex == -2) {
    SendSignal();
  } else if (keyIndex == -4) {
    if(outMessage.length() > 0) {
      outMessage = outMessage.substring(0, outMessage.length() - 1);
    }
  } else if(keyIndex != -1 && textWidth(outMessage) <= 690) {
    if(keyIndex == -3) {
      outMessage += '_';
    } else {
      outMessage += char(keyIndex);
    }
  }
}

void draw() {
  background(0);
  textSize(32);
  
  
  //Computer-to-Sock
  if(outgoingMessage && millis() > outTime+outWait) { //Check to see if it should be sending a message
    if(outBeeps == "") {
      outgoingMessage = false;
    } else {
      if(outBetween) {
        outBetween = false;
        outFlash = false;
        outWait = betweenBreak;
        outTime = millis();
      } else {
        char c = outBeeps.charAt(0);
        if(outBeeps.length() > 1) {
          outBeeps = outBeeps.substring(1);
        } else {
          outBeeps = "";
        }
        if(c == '.') {
          outFlash = true;
          outWait = dotBreak;
        } else if (c == '-') {
          outFlash = true;
          outWait = dashBreak;
        } else if (c == '|') {
          outFlash = false;
          outWait = barBreak;
        } else if (c == '_') {
          outFlash = false;
          outWait = spaceBreak;
        }
        print(c);
        outTime = millis();
        outBetween = true;
      }
    }
  }
  
  if(outFlash) {
    arduino.digitalWrite(11, arduino.HIGH);
    fill(255,255,0);
  } else {
    arduino.digitalWrite(11, arduino.LOW);
    fill(255, 255, 0, 100);
  }
  
  rectArray(outLight);
  fill(255);
  rectArray(outbox);
  fill(0);
  text(outMessage, outbox[0] + 5, outbox[1]+(outbox[3]*.7)); 
  
  //Sock-to-Computer
  int potVal = arduino.analogRead(pot);
  println(potVal);
  //if(mousePressed) {
  if(potVal < 100 || potVal > 900) { //Sending a Signal
    if(!inFlash) {
      int now = millis();
      if(now - inTime > inBarBreak) {
        int a = getIndexOfMorse(inMorse);
        if(a != -1) {
          inMessage += english[a];
          if(textWidth(inMessage) >= 650) {
            inMessage = inMessage.substring(1);
          }
          inTime = now;
        }
        inMorse = "";
      }
    }
    inFlash = true;
  } else {
    if(inFlash) {
     int now = millis();
     if(now - inTime > inDashBreak) {
       inMorse += "-";
     } else {
       inMorse += ".";
     }
     inTime = now;
    }
    inFlash = false;
  }
  
  if(inFlash) {
    wave.setFrequency(1000);
    fill(255,255,0);
  } else {
    wave.setFrequency(0);
    fill(255, 255, 0, 100);
  }
  rectArray(inLight);
  fill(255);
  rectArray(inbox);
  fill(0);
  text(inMessage, inbox[0] + 5, inbox[1]+(inbox[3]*.7)); 
  //text(inMorse, inbox[0] + 5, inbox[1]+(inbox[3]*.7)); 
  delay(9);
}

void rectArray(int box[]) {
  rect(box[0], box[1], box[2], box[3]);
}

//Gets ready for an output signal; converts string to dots and dashes
void SendSignal() {
  outBeeps = "";
  println();
  String lowerMessage = outMessage.toLowerCase();
  for(int i = 0; i < lowerMessage.length(); i++) {
    char current = lowerMessage.charAt(i);
    print(current);
    if(current == '_') {
      outBeeps += "_|";
    } else {
      int pos = getIndexOfCode(current);
      outBeeps += morse[pos] + "|";
    }
  }
  println();
  outgoingMessage = true; //Begin Sending Message
  outTime = millis();
  outMessage = "";
}

int getIndexOfCode(char c) {
  for(int i = 0; i < english.length; i++) {
    if(english[i] == c) {
      return i;
    }
  }
  return -1;
}

int getIndexOfMorse(String pat) {
  for(int i = 0; i < morse.length; i++) {
    if(morse[i].equals(pat)) {
      return i;
    }
  }
  return -1;
}