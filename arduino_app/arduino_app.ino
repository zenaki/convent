#include <SoftwareSerial.h>

SoftwareSerial bluetooth(2,3); // rx, tx

int no_unit = 1;
int cmH2O_maks = 36;
int cmH2O_min = 4;
int cmH2O_now = 0;
int BPM = 0;
int E_ratio = 1;
int up = 1;

void setup() {
  Serial.begin(115200);
  bluetooth.begin(115200);
}

void loop() {
  if(cmH2O_now<36 && up == 1){
    cmH2O_now+=2;
  }else if(cmH2O_now>4 && up == 0){
    cmH2O_now-=2;
  }
  if(cmH2O_now >= 36)
  {
    up = 0;
  }else if(cmH2O_now <= 4)
  {
    up = 1;
  }
  sendBTData();
//  bluetooth.print("t");
//  Serial.print("t");
//  bluetooth.print("e");
//  Serial.print("e");
//  bluetooth.print("s");
//  Serial.print("s");
//  bluetooth.println("t");
//  Serial.println("t");
  delay(100);
}

void sendBTData()
{
  Serial.print("no_unit = ");
  Serial.print(no_unit);
  Serial.print(", cmH2O_maks = ");
  Serial.print(cmH2O_maks);
  Serial.print(", cmH2O_min = ");
  Serial.print(cmH2O_min);
  Serial.print(", cmH2O_now = ");
  Serial.print(cmH2O_now);
  Serial.print(", BPM = ");
  Serial.print(BPM);
  Serial.print(", E_ratio = ");
  Serial.print(E_ratio);
  Serial.println();
  
  Serial.print(no_unit);
  bluetooth.print(no_unit);
  if(cmH2O_maks < 10){
    Serial.print("0");
    bluetooth.print("0");
    Serial.print(cmH2O_maks);
    bluetooth.print(cmH2O_maks);
  }
  else if(cmH2O_maks >= 10) {
    Serial.print(cmH2O_maks);
    bluetooth.print(cmH2O_maks);
  }
  if(cmH2O_min < 10){
    Serial.print("0");
    bluetooth.print("0");
    Serial.print(cmH2O_min);
    bluetooth.print(cmH2O_min);
  }
  else if(cmH2O_min >= 10) {
    Serial.print(cmH2O_min);
    bluetooth.print(cmH2O_min);
  }
  if(cmH2O_now < 10){
    Serial.print("0");
    bluetooth.print("0");
    Serial.print(cmH2O_now);
    bluetooth.print(cmH2O_now);
  }
  else if(cmH2O_now >= 10) {
    Serial.print(cmH2O_now);
    bluetooth.print(cmH2O_now);
  }
  Serial.print(BPM);
  bluetooth.print(BPM);
  Serial.println(E_ratio); //jika 1 = 1:1, jika 2 = 1:2
  bluetooth.println(E_ratio); //jika 1 = 1:1, jika 2 = 1:2
}
