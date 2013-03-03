import <mutex.ash>
import <questsave.ash>

int noflag=1;
int isadmin=2;
int isbuffer=4;
int nolimit=8;

boolean errorMsg=true;
string[string] settings;
file_to_map(my_name()+"/settings.txt",settings);
int[int] isbuff;
file_to_map(my_name()+"/bufffile.txt",isbuff);

void save(int skilln, int amount){
 int[string] totals;
 file_to_map(my_name()+"/tots.txt",totals);
 totals[skilln.to_string()]+=amount;
 totals["*"]+=amount;
 map_to_file(totals,my_name()+"/tots.txt");
}

boolean checkFlag(string sender,int flag){
 int check=settings["admin:*"].to_int()|settings["admin:"+sender].to_int();
 return (check&flag)==flag;
}
boolean checkFlag(int sender,int flag){
 string alias=settings["alias:"+to_string(sender)];
 if (alias=="") alias="*";
 return checkFlag(alias,flag);
}

void stabilize(){
 cli_execute("maximize mp, 1000 mp regen max -tie");
 if (get_property("nunsVisits")!=3){
  if ((my_adventures()<130)||(my_mp()<60)) cli_execute("nuns");
 }
 while((my_mp()<300)&&(my_adventures()!=0))adventure(1,$location[Icy Peak]);
}

void buff (int castee, int sender, int skillnum, int numTurns, int maxTurns, string msg){
 //Buff Precheck
 if (isbuff[skillnum]!=1){
  //NONEXIST ERROR
  msg="N "+msg;
  if(errorMsg)chat_private(settings["mainbot"],msg);
  return;
 }
 if (numTurns==0) numTurns=200;
 
 int[int,int] dailybuffs;
 file_to_map(my_name()+"/dailybuffs.txt",dailybuffs);
 skill msgNew=to_skill(skillnum);
 int limit=maxTurns/settings["tpc"].to_int();
 int casts=ceil(numTurns/settings["tpc"].to_float());
 if((casts>limit)&&(maxTurns>0))casts=limit;
 if((dailybuffs[sender] contains skillnum)&&(maxTurns>0)){
  if((casts+dailybuffs[sender,skillnum])>limit)casts=limit-dailybuffs[sender,skillnum];
 }

 if (casts<1){
  //OVER LIMIT ERROR
  msg="L "+msg;
  if(errorMsg)chat_private(settings["mainbot"],msg);
  return;
 }
 //This is the actual casting function.
 if (use_skill(casts,msgNew,to_string(castee))==true){
  if (skillnum==62) chat_private(settings["mainbot"],"S "+msg);
  dailybuffs[sender,skillnum]+=casts;
  dailybuffs[10,skillnum]+=casts;
  save(skillnum,casts);
  map_to_file(dailybuffs,my_name()+"/dailybuffs.txt");
 }else{
  //BUFFFAIL ERROR
  switch (last_skill_message()){
   case "Selected target cannot receive buffs.":
    msg="R "+msg;
    break;
   case "Selected target is busy fighting.":
    msg="A "+msg;
    break;
   default:
    msg="U "+msg;
    break;
  }
  if(errorMsg)chat_private(settings["mainbot"],msg);
 }
 print("MP Remaining: ","green");
 print(my_mp(),"green");
 if (my_mp()<525) stabilize();
}

void main(string sender, string msg){
 if (msg.char_at(0)=="!"){
  errorMsg=false;
  msg=substring(msg,1);
 }
 string remain="";
 string outbound="";
 if (!checkFlag(sender,noflag)){
  chat_private(sender, "This account does not handle individual user requests. Please visit Ominous Buffer's profile for usage instructions. (#1767127)");
  exit;
 }
 if (checkFlag(sender,isadmin)){
  if(msg=="burn"){ //Run Adventure Burn sequence early.
   unlockMutex("_logoutNow");
   exit;
  }
  if(msg=="logout"){ //shut down scripts, if running
   print("Logging Out","red");
   saveSettings("nunsVisits;_breakfast;_autod;_buffstoday");
   unlockMutex("_forcedOut"); //and log out.
   unlockMutex("_logoutNow");
   if(mutexFree("_abortNow")){
    set_property("chatbotScript","");
    cli_execute("exit"); //sleep duties
   }
   exit;
  }
  if(msg=="halt"){ //Shut down scrips, stay logged in.
   unlockMutex("_abortNow");
   unlockMutex("_forcedOut");
   unlockMutex("_logoutNow");
   exit;
  }
  if(msg=="abort"){ //Stop scripts NOW, stay logged in.
   unlockMutex("_abortNow"); //chatbot stays active
   abort("Scripts Halted");
   exit;
  }
  if(msg=="sleep"){ //Stop scripts, don't perform logout duties, logout
   print("Logging Out","red");
   set_property("chatbotScript","");
   saveSettings("nunsVisits;_breakfast;_autod;_buffstoday");
   cli_execute("exit");
   exit;
  }
  if(length(msg)>4) if(substring(msg,0,4)=="cli "){
   cli_execute(substring(msg,4));
   exit;
  }
  if(length(msg)>6) if(substring(msg,0,6)=="count "){
   remain=substring(msg,6);
   if (remain=="meat"){
    outbound="Liquid: "+to_string(my_meat())+"; DMS: ";
    outbound+=to_string(item_amount($item[dense meat stack])+closet_amount($item[dense meat stack]));
   }else{
    if(to_item(remain)==$item[none]){
     outbound="Item not found";
    }else{
     outbound=remain.to_item().to_string()+": "+to_string(item_amount(to_item(remain)));
    }
   }
   chat_private(sender,outbound);
   exit;
  }
 }
 string[int] pieces=split_string(msg,"\\s");
 if (checkFlag(sender,isbuffer)){
  switch(pieces[0]){
   case "CASTRQ":
    int[string] totals;
    file_to_map(my_name()+"/tots.txt",totals);
    chat_private(sender,'CASTRQ '+to_string(totals["*"]));
    return;
   case "PING":
    chat_private(substring(msg,msg.index_of(" ")+1),"Reply from "+settings["formalName"]+".");
    return;
   case "PROPERTY":
    switch(pieces[1]){
     case "GET":
      chat_private(sender, "PROPERTY "+pieces[2]+" "+get_property(pieces[2]));
      return;
     case "SET":
      set_property(pieces[2],pieces[3]);
      return;
    }
    return;
  }
  if (count(pieces)!=5)return;
  requestMutex("_adventuring");
  print("Request Processing","red");
  buff(to_int(pieces[0]),to_int(pieces[1]),to_int(pieces[2]),to_int(pieces[3]),to_int(pieces[4]),msg);
  print("Homeostasis Acheived","green");
  print("Bot Resumed","blue");
  unlockMutex("_adventuring");
 }
}