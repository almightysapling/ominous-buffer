import <mutex.ash>
import <questsave.ash>

string[string] settings;
file_to_map(my_name()+"/settings.txt",settings);
int burnMinutes=settings["burnMinutes"].to_int();
int logMinutes=settings["logMinutes"].to_int();

int minutesToRollover(){
 int GMT=to_int(now_to_string("HHmm"))-to_int(now_to_string("Z"));
 if (GMT<0)GMT+=2400;
 if (GMT>2399)GMT-=2400;
 string GMTs=to_string(GMT);
 while (length(GMTs)<4) GMTs="0"+GMTs;
 GMT=to_int(substring(GMTs,0,2))*60+to_int(substring(GMTs,2));
 GMT=210-GMT;
 if (GMT<0) GMT+=24*60;
 return GMT;
}

void earlyOut(){ 
 unlockMutex("_break");
 print_html("<b><font color=000000>Entering runlevel: </font><font color=FF0000>0</font></b>");
 set_property("chatbotScript","");
 cli_execute("maximize adv -tie");
 if(!(mutexFree("_abortNow")))cli_execute("exit");
 exit;
}

void cashMeat(){
 cli_execute("cleanup");
 item needle=$item[giant needle];
 string smashBot="csend "+to_string(item_amount(needle))+" "+to_string(needle);
 foreach castle in $items[wolf mask, rave whistle, twinkly nugget]
 smashBot+=", "+to_string(item_amount(castle))+" "+to_string(castle);
 smashBot+=" to smashbot || wad";
 needle=$item[Warm Subject Gift Certificate];
 use(item_amount(needle),needle);
 cli_execute(smashBot);
 int meatGained=my_meat()-500000;
 int totalDMS;
 if (meatGained<0){
/*  totalDMS=min(floor((0-1)*meatGained/1000),closet_amount(to_item("dense meat stack")));
  if (totalDMS==0) return;
  take_closet(totalDMS,$item[dense meat stack]);
  autosell(totalDMS,$item[dense meat stack]);*/
 }else{
  totalDMS=floor(meatGained/1000);
  if (totalDMS==0) return;
  string exe="make "+to_string(totalDMS)+" dense meat stack";
  cli_execute(exe);
  if (totalDMS<15) take_closet(15-totalDMS,$item[dense meat stack]);
  else put_closet(totalDMS-15,$item[dense meat stack]);
  cli_execute("kmail 15 dense meat stack to Ominous Buffer || ");
 }
 if (my_meat()<490000) chat_private(settings["mainbot"],"FUNDS");
}

void main(){try{
 print("Starting Bot","red");
 unlockMutex("_adventuring");
 lockMutex("_abortNow");
 loadSettings("nunsVisits;_breakfast;_autod");

 string meatfarm_ccs = "default";
 string meatfarm_fam = "leprechaun";

 if (get_property("_breakfast")==""){
  int[int,int] dailybuffs;
  file_to_map(my_name()+"/dailybuffs.txt",dailybuffs);
  clear(dailybuffs);
  map_to_file(dailybuffs,"dailybuffs.txt");
  string rumpus = visit_url("clan_rumpus.php");
  int camp_mp_gain;
  int camp_mp;
  int[item] campground = get_campground();
  if (campground[$item[Frobozz Real-Estate Company Instant House (TM)]] == 1) camp_mp = 40;
  else if (campground[$item[Newbiesport Tent]] == 1) camp_mp = 10;
  else if (campground[$item[Barskin Tent]] == 1) camp_mp = 20;
  else if (campground[$item[Cottage]] == 1) camp_mp = 30;
  else if (campground[$item[BRICKO pyramid]] == 1) camp_mp = 35;
  else if (campground[$item[Sandcastle]] == 1) camp_mp = 50;
  else if (campground[$item[House of Twigs and Spit]] == 1) camp_mp = 60;
  else if (campground[$item[Gingerbread House]] == 1) camp_mp = 70;
  else if (campground[$item[Hobo Fortress]] == 1) camp_mp = 85;
  camp_mp_gain = camp_mp;
  if (campground[$item[pagoda plans]] == 1) camp_mp_gain += camp_mp;
  if (stat_bonus_tomorrow() == $stat[mysticality]) camp_mp_gain += camp_mp;
  if (campground[$item[Beanbag chair]] == 1) camp_mp_gain += 30;
  set_property("campmp",camp_mp_gain);
  int rollmp = my_mp();
  set_property("rollmp",rollmp);
  if (contains_text(rumpus,"rump3_3")){
   visit_url("clan_rumpus.php?action=click&spot=3&furni=3");
   visit_url("clan_rumpus.php?action=click&spot=3&furni=3");
   visit_url("clan_rumpus.php?action=click&spot=3&furni=3");
  }
  if (contains_text(rumpus,"rump3_1")){
   visit_url("clan_rumpus.php?action=click&spot=3&furni=1");
   visit_url("clan_rumpus.php?action=click&spot=3&furni=1");
   visit_url("clan_rumpus.php?action=click&spot=3&furni=1");
  }
  if (contains_text(rumpus,"rump1_4")) visit_url("clan_rumpus.php?action=click&spot=1&furni=4");
  if (contains_text(rumpus,"rump4_2")) visit_url("clan_rumpus.php?action=click&spot=4&furni=2");
  if (contains_text(rumpus,"rump9_3")) visit_url("clan_rumpus.php?action=click&spot=9&furni=3");
  if (contains_text(rumpus,"rump4_1")) visit_url("clan_rumpus.php?action=click&spot=4&furni=1");
  if (contains_text(rumpus,"rump3_2")) visit_url("clan_rumpus.php?preaction=jukebox&whichsong=1");
  if (contains_text(rumpus,"rump9_2")){
   visit_url("clan_rumpus.php?preaction=buychips&whichbag=1");
   visit_url("clan_rumpus.php?preaction=buychips&whichbag=2");
   visit_url("clan_rumpus.php?preaction=buychips&whichbag=3");
  }
  if (contains_text(rumpus,"ballpit")) visit_url("clan_rumpus.php?action=click&spot=7");
  if (get_property("sidequestOrchardCompleted") != "none") visit_url("store.php?whichstore=h");
  if (get_property("sidequestArenaCompleted") != "none") visit_url("postwarisland.php?action=concert&pwd&option=2");
  retrieve_item(6,$item[supernova champagne]);
  drink(6,$item[supernova champagne]);
  retrieve_item(1,$item[can of swiller]);
  drink(1,$item[can of swiller]);  
  set_property("_breakfast", "1");
 }
 cli_execute("maximize mp, 200mp regen max -tie");
 lockMutex("_forcedOut");
 lockMutex("_logoutNow");
 int lastCheck=0;
 if (get_property("chatbotScript")!=settings["chatbotScript"]){
  waitq(3);
  set_property("chatbotScript",settings["chatbotScript"]);
 }
 print("Initialization Complete","green");
 print("Bot Started","blue");
 if (get_property("_autod")==""){
  while (!(mutexFree("_logoutNow"))){
   if (minutesToRollover()<burnMinutes) unlockMutex("_logoutNow");
   waitq(2);
  }
  requestMutex("_adventuring");
  lockMutex("_logoutNow");
  if (mutexFree("_forcedOut")) earlyOut();
  cli_execute("maximize meat");
  cli_execute("familiar "+meatfarm_fam);
  print("Daily Adventuring","red");
  while (my_adventures() > 130){
   adventure(1,$location[giant's castle]);
   while((my_mp()+get_property("campmp"))>get_property("rollmp")) {
    if((have_skill($skill[empathy of the newt]))&&(have_effect($effect[empathy])<1000)) use_skill(1,$skill[empathy of the newt]);
    if(my_class()==$class[Sauceror])break;
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
 while (!(mutexFree("_logoutNow"))){
  if ((minutesToRollover()<logMinutes)&&(mutexFree("_adventuring"))) unlockMutex("_logoutNow");
  waitq(2);
 }
 earlyOut();
}finally{
 print("Script Halted");
}}