import processing.serial.*;
import controlP5.*;
import java.util.regex.*;

PImage img_home,   img_home_off,  img_home_on;
PImage img_pause,  img_pause_off, img_restart;
PImage img_import;
PImage img_bar,    img_bar_2,     img_bar_3;
PImage img_speeds, img_extrusion, img_LayerHeight;

int i = 0;
int speeds          = 100;
int extrusion       = 100;
int ProgressPercent = 100;
int h = hour();
int m = minute();

float z = 0;
float zs = 0;
float NowProgress = 28;

boolean streaming  = false;
boolean stopping   = false;
boolean homing     = false;

String[] gcode;
String Overwrite;
String textValue = "start up Direct Code \n";
String reName = month() +"-"+ day() +" "+ nf(h,2) + nf(m,2);

Serial myPort;
ControlP5 cp5;
Textarea myTextarea;

void setup() {
  size(450, 650, OPENGL);
  PFont myFont = loadFont("MyricaMM-48.vlw");
  
  textFont(myFont);
  color(240);
  myPort = new Serial(this, "COM5", 115200);
  
  cp5 = new ControlP5(this);
  
  img_home = img_home_off   = loadImage("home_Off.png");
  img_home_on               = loadImage("home_On.png");
  img_pause = img_pause_off = loadImage("pause.png");
  img_restart               = loadImage("restart.png");
  img_import                = loadImage("import.png");
  img_bar                   = loadImage("bar.png");
  img_bar_2                 = loadImage("bar_2.png");
  img_bar_3                 = loadImage("bar_3.png");
  img_speeds = img_extrusion = img_LayerHeight = loadImage("button.png");

  myTextarea = cp5.addTextarea("txt")
                  .setPosition(20,465)
                  .setSize(410,160)
                  .setFont(createFont("MyricaM M",18))
                  .setLineHeight(25)
                  .setColor(color(128))
                  .setColorBackground(color(200,100))
                  .setColorForeground(color(255,200));
                  ;
  myTextarea.setText(textValue);
  myTextarea.scroll(1.0);  
    
}


void draw() {
  background (255);
  textSize   (30);
  
  fill(255, 0, 0);
  textAlign(RIGHT);
  text( speeds + ""                ,  -95, 180, width, height );
  text( extrusion + ""             ,  -95, 250, width, height );
  text( String.format( "%1$.2f" ,z), -111, 320, width, height ); 
  textAlign(LEFT);
  
  fill(0, 162, 154);
  text( "Speeds                %", 30, 180, width, height );
  text( "Extrusion             %", 30, 250, width, height );
  text( "Layer Height         mm", 30, 320, width, height );
  
  image( img_home        ,  30,  30,  85, 85);
  image( img_pause       ,  140, 30,  85, 85);
  image( img_import      ,  351, 30,  69, 84);
  image( img_speeds      ,  390, 165, 30, 50);
  image( img_extrusion   ,  390, 235, 30, 50);
  image( img_LayerHeight ,  390, 305, 30, 50);
  image( img_bar         ,  28,  400, 395, 25 );
  image( img_bar_2       ,  NowProgress, 399, 395, 27) ;
  image( img_bar_3       ,  28,  400, 395, 25 );
  
  if(keyPressed && key==' ') {
    myTextarea.scroll((float)mouseX/(float)width);
    }
    
}

void changeHeight(int theValue) {
    myTextarea.setHeight(theValue);
    
}

  
void mousePressed() {
  
  if(mousePressed) { 
      if( mouseX > 30 && mouseX < 115 && mouseY > 30 && mouseY < 115 ){
          myPort.write("G28\n"); homing = true; img_home = img_home_on;
          textValue = textValue + "move home \n";
          myTextarea.setText(textValue);
          myTextarea.scroll(1.0);
       }
  }
   
   if (mousePressed) {
     if( mouseX > 140 && mouseX < 225 && mouseY > 30 && mouseY < 115 ){
       if( streaming && !stopping ){
         streaming = false;
         stopping  = true;
         textValue = textValue + "--------------------------------- \n";
         textValue = textValue + " Pause stream \n";
         textValue = textValue + "--------------------------------- \n";
         myTextarea.setText(textValue);
         myTextarea.scroll(1.0);
         img_pause = img_restart;
       } else {
         streaming = true;
         stopping   = false;
         textValue = textValue + "--------------------------------- \n";
         textValue = textValue + " Resume stream \n";
         textValue = textValue + "--------------------------------- \n";
         myTextarea.setText(textValue);
         myTextarea.scroll(1.0);
         stream();
         img_pause = img_pause_off;
       }
     }
   } 
   
  if (mousePressed) {
     if( mouseX > 351 && mouseX < 414 && mouseY > 30 && mouseY < 114 ){
       if( !streaming ){
         streaming = true;
         stopping  = false;
         gcode = null; i = 0;
         File file = null; 
         textValue = textValue + "Loading ... \n";
         myTextarea.setText(textValue);
         myTextarea.scroll(1.0);
         selectInput("Select a file to process:", "chooseFile", file); 
       }  
     }
   }
   
  if ( mouseX > 390 && mouseX < 420 && mouseY > 165 && mouseY < 189 && speeds < 500 )    { speeds+=5; } 
  else if ( mouseX > 390 && mouseX < 420 && mouseY > 191 && mouseY < 215 && speeds > 0 ) { speeds-=5; } 
 
  if ( mouseX > 390 && mouseX < 420 && mouseY > 235 && mouseY < 259 && extrusion < 1000 )    { extrusion+=10; } 
  else if ( mouseX > 390 && mouseX < 420 && mouseY > 261 && mouseY < 285 && extrusion > 0  ) { extrusion-=10; }
  
  if ( mouseX > 390 && mouseX < 420 && mouseY > 305 && mouseY < 329 && z < 3 )      { z+=0.001; } 
  else if ( mouseX > 390 && mouseX < 420 && mouseY > 331 && mouseY < 355 && z > 0 ) { z-=0.1; } 
   
}


void chooseFile(File choose) {
  if (choose == null) {
    textValue = textValue + "Window was closed or the user hit cancel. \n";
    streaming = false;
    stopping  = true;
    myTextarea.setText(textValue);
    myTextarea.scroll(1.0);
  } else {
    textValue = textValue + "User selected " + choose.getAbsolutePath() + "\n";
    myTextarea.setText(textValue);
    myTextarea.scroll(1.0);
    gcode = loadStrings(choose.getAbsolutePath());
    if (gcode == null) return;
    streaming = true;
    stream();
  }
  
}


void stream() {
  if (!streaming) return;
  
  while (true) {
    // check gcode 
    if (i == gcode.length) {
      streaming = false;
      updateProgressPercent();
      
      Overwrite = "C:\\Users\\masahide chiba\\Desktop\\Overwrite_Gcode\\" + reName + ".txt";
      saveStrings( Overwrite , gcode ); 
      
      return;
    }
    
    // delete comment
    //String[] m = match( gcode[i] , ";.*$" );
    gcode[i] = gcode[i].replaceAll(";.*$","");
    
    if (gcode[i].trim().length() == 0) i++;
    else break;
  }
  
  if( !( speeds   == 100 ) )  { changeFeed(); }
  if( !( extrusion == 100 ) ) { changeExtrusion(); }
  if( !( z == 0.0 )       )   { changeLayerHeight(); }
  
  println(gcode[i]);
  textValue = textValue + (gcode[i]) + "\n";
  myTextarea.setText(textValue);
  myTextarea.scroll(1.0);
  myPort.write(gcode[i] + '\n');
  updateProgressPercent();
  i++;
  
}


void serialEvent(Serial p){
  try {
    String s = p.readStringUntil('\n');
   
    if(s != null) {
      textValue = textValue + "action serialEvent: \n";
      textValue = textValue + s.trim() + "\n";
      myTextarea.setText(textValue);
      myTextarea.scroll(1.0);
       if( homing && s.trim().startsWith("ok") ){
         img_home = img_home_off;
       }
      
      if( streaming ){
        if (s.trim().startsWith("ok")) stream();
        if (s.trim().startsWith("error")) stream(); // XXX: really?
      }
    }
  } catch(RuntimeException e) {
    System.out.println("system.out");
    println(e);
    textValue = textValue + "system.out \n";
    myTextarea.setText(textValue);
    myTextarea.scroll(1.0);
  }
  
}


void changeFeed(){
  String fCode, mFCode;
  //check F code
  fCode = mFCode = getMatchString( "F[0-9]{3,4}" ,gcode[i] );
  
  if( !(fCode == "0") ){
    fCode = fCode.replaceAll( "F" , "" );
    int intFeed = Integer.parseInt( fCode );
    intFeed = (int)((float)intFeed * ( speeds / 100.0));
    println(speeds);
    
    fCode = "F" + String.valueOf(intFeed);
    
    gcode[i] = gcode[i].replaceAll( mFCode , fCode );
  }

}

void changeExtrusion(){
  String eCode, mECode;
  eCode = mECode = getMatchString( "E[0-9]{0,5}[.][0-9]{3,4}" , gcode[i] );
  
  if( !(eCode == "0") ){
    eCode = eCode.replaceAll( "E" , "" );
    float floatExtrude = Float.parseFloat( eCode );
    floatExtrude = floatExtrude * ( extrusion / 100.0);
    println(extrusion);
    
    eCode = "E" + String.valueOf(floatExtrude);
    
    gcode[i] = gcode[i].replaceAll( mECode , eCode );
  }
}

void changeLayerHeight(){
  String zCode, mZCode;
  zCode = mZCode = getMatchString( "Z[1-9]{0,5}[.][0-9]{1,3}" , gcode[i] );
  
  if( !(zCode == "0") ){
    zCode = zCode.replaceAll( "Z" , "" );
    float floatLayerHeight = Float.parseFloat( zCode );
    //zs = zs + z;
    floatLayerHeight = floatLayerHeight + zs;
    println(zs);
    
    zCode = "Z" + String.valueOf(floatLayerHeight);
    
    gcode[i] = gcode[i].replaceAll( mZCode , zCode );
  }
}

String getMatchString(String regex , String target ){
  Pattern pattern = Pattern.compile(regex);
  Matcher matcher = pattern.matcher(target);
  
  if (matcher.find()) {
    return matcher.group(0);
  } else {
    return "0";
  }
  
}


void updateProgressPercent(){
  int gcode_max_length = gcode.length;
  int gcode_now_length = i;
  
  ProgressPercent = (int)( (float)( (float)gcode_now_length / (float)gcode_max_length ) * (float)100.0 );
  NowProgress = 395 * ProgressPercent / 100 + 28;
  
}