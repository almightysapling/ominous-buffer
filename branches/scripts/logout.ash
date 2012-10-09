import <shared.ash>

void main(){
 saveSettings(earlySave);
 set_property("chatbotScript","");
 if(get_property("_shutdownBufferOnly")!="1"){
  chat_private(turtleBot,"logout");
  chat_private(sauceBot,"logout");
 }
}