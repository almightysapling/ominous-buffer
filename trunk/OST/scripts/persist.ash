import <shared.ash>
string meatfarm_ccs="default";
string meatfarm_fam="leprechaun";

string[string] settings;
file_to_map(my_name()+"/settings.txt",settings);
int burnMinutes=settings["burnMinutes"].to_int();
int logMinutes=settings["logMinutes"].to_int();

int minutesToRollover(){
 int GMT=to_int(now_to_string("HHmm"))-to_int(now_to_string("Z"));
 if(GMT<0)GMT+=2400;
 if(GMT>2399)GMT-=2400;
 string GMTs=to_string(GMT);
 while(length(GMTs)<4)GMTs="0"+GMTs;
 GMT=to_int(substring(GMTs,0,2))*60+to_int(substring(GMTs,2));
 GMT=210-GMT;
 if(GMT<0)GMT+=24*60;
 return GMT;
}

void earlyOut(){ 
 unlockMutex("_break");
 print_html("<b><font color=000000>Entering runlevel: </font><font color=FF0000>0</font></b>");
 set_property("chatbotScript","");
 cli_execute("maximize adv -tie");
 cli_execute("exit");
}

void cashMeat(){
 cli_execute("cleanup");
 cli_execute("csend 0 yeti fur, 0 ram's face lager, 0 insanely spicy bean burrito, 0 bag of cheat-os to Ominous Buffer || ");
 cli_execute("autosell 0 snow queen crown, 0 ga-ga radio, 0 crazy little turkish delight, 0 unrefined mountain stream syrup, 0 ram horns, 0 ram stick");
 int meatGained=my_meat()-500000;
 int totalDMS;
 if(meatGained<0){
/*  totalDMS=min(floor((0-1)*meatGained/1000),closet_amount(to_item("dense meat stack")));
  if(totalDMS==0) return;
  take_closet(totalDMS,$item[dense meat stack]);
  autosell(totalDMS,$item[dense meat stack]);*/
 }else{
  totalDMS=floor(meatGained/1000);
  if(totalDMS==0)return;
  string exe="make "+to_string(totalDMS)+" dense meat stack";
  cli_execute(exe);
  if(totalDMS>15)put_closet(totalDMS-15,$item[dense meat stack]);
  if(totalDMS>0)cli_execute("kmail "+min(15,totalDMS)+" dense meat stack to Ominous Buffer || ");
 }
 if(my_meat()<490000) chat_private(settings["mainbot"],"FUNDS");
}

void machineBreakfast(){
 loadSettings("nunsVisits;_autod");
 int[int,int] dailybuffs;
 file_to_map(my_name()+"/dailybuffs.txt",dailybuffs);
 clear(dailybuffs);
 map_to_file(dailybuffs,my_name()+"/dailybuffs.txt");
 item[item,string,item,item] concs;
 file_to_map("concoctions.txt",concs);
 foreach i,j,k,l in concs{
  if(!contains_text(j,"SAUCE"))continue;
  switch(k){
   case $item[scrumptious reagent]:
    saucePots[l].result=i;
    saucePots[l].scrumdiddly=false;
    saucePots[l].volume=(j.contains_text("SX3")?3:1);
    break;
   case $item[scrumdiddlyumptious solution]:
    saucePots[l].result=i;
    saucePots[l].scrumdiddly=true;
    saucePots[l].volume=(j.contains_text("SX3")?3:1);
    break;
  }
  switch(l){
   case $item[scrumptious reagent]:
    saucePots[k].result=i;
    saucePots[k].scrumdiddly=false;
    saucePots[k].volume=(j.contains_text("SX3")?3:1);
    break;
   case $item[scrumdiddlyumptious solution]:
    saucePots[k].result=i;
    saucePots[k].scrumdiddly=true;
    saucePots[k].volume=(j.contains_text("SX3")?3:1);
    break;
  }
 }
 map_to_file(saucePots,"saucePots.txt");
 set_property("_mbreakfast","1");
}

void accountBreakfast(){
 string rumpus = visit_url("clan_rumpus.php");
 if(contains_text(rumpus,"rump3_3")){
  visit_url("clan_rumpus.php?action=click&spot=3&furni=3");
  visit_url("clan_rumpus.php?action=click&spot=3&furni=3");
  visit_url("clan_rumpus.php?action=click&spot=3&furni=3");
 }
 if(contains_text(rumpus,"rump3_1")){
  visit_url("clan_rumpus.php?action=click&spot=3&furni=1");
  visit_url("clan_rumpus.php?action=click&spot=3&furni=1");
  visit_url("clan_rumpus.php?action=click&spot=3&furni=1");
 }
 if(contains_text(rumpus,"rump1_4"))visit_url("clan_rumpus.php?action=click&spot=1&furni=4");
 if(contains_text(rumpus,"rump4_2"))visit_url("clan_rumpus.php?action=click&spot=4&furni=2");
 if(contains_text(rumpus,"rump9_3"))visit_url("clan_rumpus.php?action=click&spot=9&furni=3");
 if(contains_text(rumpus,"rump4_1"))visit_url("clan_rumpus.php?action=click&spot=4&furni=1");
 if(contains_text(rumpus,"rump3_2"))visit_url("clan_rumpus.php?preaction=jukebox&whichsong=1");
 if(contains_text(rumpus,"rump9_2")){
  visit_url("clan_rumpus.php?preaction=buychips&whichbag=1");
  visit_url("clan_rumpus.php?preaction=buychips&whichbag=2");
  visit_url("clan_rumpus.php?preaction=buychips&whichbag=3");
 }
 if(contains_text(rumpus,"ballpit"))visit_url("clan_rumpus.php?action=click&spot=7");
 if(get_property("sidequestOrchardCompleted")!="none")visit_url("store.php?whichstore=h");
 if(get_property("sidequestArenaCompleted")!="none")visit_url("postwarisland.php?action=concert&pwd&option=2");
 retrieve_item(6,$item[supernova champagne]);
 while(inebriety_limit()-my_inebriety()>2)drink(1,$item[supernova champagne]);
 retrieve_item(1,$item[can of swiller]);
 while(inebriety_limit()-my_inebriety()>0)drink(1,$item[can of swiller]);
 set_property("_breakfast","1");
}

void main(){try{
 print("Starting Bot","red");
 unlockMutex("_adventuring");
 lockMutex("_aborted");
 if(get_property("_mbreakfast")=="")machineBreakfast();
 if(get_property("_breakfast")=="")accountBreakfast();
 cli_execute("maximize mp, 200mp regen max -tie");
 lockMutex("_forcedOut");
 lockMutex("_logoutNow");
 int lastCheck=0;
 if(get_property("chatbotScript")!=settings["chatbotScript"]){
  waitq(3);
  set_property("chatbotScript",settings["chatbotScript"]);
 }
 print("Initialization Complete","green");
 print("Bot Started","blue");
 if(have_effect($effect[Polka of Plenty])<300)chat_private(settings["mainbot"],"RATION MEAT");
 if(have_effect($effect[Carlweather's Cantata of Confrontation])<300)chat_private(settings["mainbot"],"RATION NONCOMBAT");
 if(have_effect($effect[Fat Leon's Phat Loot Lyric])<300)chat_private(settings["mainbot"],"RATION ITEM");
 if(get_property("_autod")==""){
  while(!(mutexFree("_logoutNow"))){
   if(minutesToRollover()<burnMinutes)unlockMutex("_logoutNow");
   waitq(2);
  }
  requestMutex("_adventuring");
  lockMutex("_logoutNow");
  if(mutexFree("_forcedOut"))earlyOut();
  cli_execute("maximize meat");
  cli_execute("familiar "+meatfarm_fam);
  print("Daily Adventuring","red");
  while(my_adventures()>130){
   adventure(1,$location[the icy peak]);
   while(my_mp()>0.9*my_maxmp()) switch(my_class()){
    case $class[sauceror]:
     use_skill(3,$skill[elemental saucesphere],"Ominous Buffer");
     use_skill(3,$skill[elemental saucesphere],"Ominous Tamer");
     use_skill(3,$skill[elemental saucesphere]);
     break;
    case $class[turtle tamer]:
     use_skill(3,$skill[empathy of the newt],"Ominous Buffer");
     use_skill(3,$skill[empathy of the newt],"Ominous Sauceror");
     use_skill(3,$skill[empathy of the newt]);
     break;
   }
  }
  cli_execute("maximize mp, 200mp regen max -tie");
  print("Daily Adventuring Complete","green");
  print("Handling Funds","red");
  cashMeat();
  print("Balance Met","green");
  print("Bot Resumed","blue");
  unlockMutex("_adventuring");
  set_property("_autod","1");
 }
 while(!(mutexFree("_logoutNow"))){
  if((minutesToRollover()<logMinutes)&&(mutexFree("_adventuring")))unlockMutex("_logoutNow");
  waitq(2);
 }
 earlyOut();
}finally{
 print("Script Halted");
}}