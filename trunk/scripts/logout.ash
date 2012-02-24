import <shared.ash>

void main(){
 saveSettings(earlySave);
 set_property("chatbotScript","");
 if(get_property("_bufferOnly")!="1"){
  chat_private("ominous tamer","logout");
  chat_private("ominous sauceror","logout");
 }
}