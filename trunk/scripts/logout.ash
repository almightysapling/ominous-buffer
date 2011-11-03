import <shared.ash>

void main(){
 saveSettings(earlySave);
 set_property("chatbotScript","off");
 if(get_property("_bufferOnly")=="1")return;
 chat_private("ominous tamer","logout");
 chat_private("ominous sauceror","logout");
}