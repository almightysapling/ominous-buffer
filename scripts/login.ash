import <kmail.ash>
import <questsave.ash>
import <games.ash>

string chatbotScript="buffbot.ash";
int logMinutes=3;
int burnMinutes=20;

boolean prompted=false;
int farmbuff=0;

record userinfo{
 int userid;
 string nick;
 boolean[string] multis;
 int gender;//0:unregistered 1: third 2: unknown 3:androgynous 4:male 5:female 6:inanimate
 int flags;//see flag bits
 string[string] buffpacks;
 int[int] buffs;
 float lastMath;
 string lastTime;
 string lastTrigger;
};
//flag bits
int noFlag=1;
int isAdmin=2;
int isBuffer=4;
int noLimit=8;
int blacklist=16;
int whitelist=32;
int inClan=64;
int receivedCake=128;
int inAssociate=256;
int highAssociate=512;

userinfo[string] userdata;

string meatfarm_fam="leprechaun";
string stasis_fam="star starfish";
int lastCheck=-255;

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

int[item] gift;
gift[$item[black forest cake]] = 1;
gift[$item[bulky buddy box]] = 1;

string to_commad(int i){
 string s=to_string(i);
 string c;
 for l from length(s) downto 1 {
  if((l<length(s))&&((length(s)-l)%3==0))c=","+c;
  c=s.char_at(l-1)+c;
 }
 return c;
}

void updateDC(){
 file_to_map("userdata.txt",userdata);
 int served=get_property('sauceCasts').to_int()+get_property('tamerCasts').to_int()+get_property('totalCastsEver').to_int();
 int days=get_property('totalDaysCasting').to_int();
 string avg=to_string(served*1.0/days);
 if (index_of(avg,'.')+3<length(avg)) avg=substring(avg,0,index_of(avg,'.')+3);
 string s="managecollection.php?action=changetext&pwd&newtext=";
 s+="Over "+to_commad(served)+" casts served since 2011!\n";
 s+="Daily Avg: "+avg+"\n\n";
 s+="More information on buffs offered can be found on the following pages:\n";
 s+="http://kol.coldfront.net/thekolwiki/index.php/Buff\n";
 s+="Casts Remaining of limited skills listed below:\n";
 s+="Managerial Manipulation: "+to_int(3-userdata["*"].buffs[62])+"\n";
 visit_url(s);
}

void updateLimits(){
 file_to_map("userdata.txt",userdata);
 string s="managecollection.php?action=modifyshelves&pwd="+my_hash()+"&newname12=";
 s+=to_string(50-userdata["*"].buffs[6026]);
 buffer n;
 if((50-userdata["*"].buffs[6026])>10) n=visit_url(s);
 s="managecollectionshelves.php?pwd&action=arrange";
 if ((50-userdata["*"].buffs[6026])<11) s+="&whichshelf4502="+to_string(51-userdata["*"].buffs[6026]);
 s+="&whichshelf4503="+to_string(6-userdata["*"].buffs[6028]);
 s+="&whichshelf4497="+to_string(11-userdata["*"].buffs[6020]);
 s+="&whichshelf4498="+to_string(11-userdata["*"].buffs[6021]);
 s+="&whichshelf4499="+to_string(11-userdata["*"].buffs[6022]);
 s+="&whichshelf4500="+to_string(11-userdata["*"].buffs[6023]);
 s+="&whichshelf4501="+to_string(11-userdata["*"].buffs[6024]);
 n=visit_url(s);
 s="62:"+to_string(userdata["*"].buffs[62])+":";
 s+="6020:"+to_string(userdata["*"].buffs[6020])+":";
 s+="6021:"+to_string(userdata["*"].buffs[6021])+":";
 s+="6022:"+to_string(userdata["*"].buffs[6022])+":";
 s+="6023:"+to_string(userdata["*"].buffs[6023])+":";
 s+="6024:"+to_string(userdata["*"].buffs[6024])+":";
 s+="6026:"+to_string(userdata["*"].buffs[6026])+":";
 s+="6028:"+to_string(userdata["*"].buffs[6028])+":";
 set_property("_limitBuffs",s);
}

void processLimits(){
 file_to_map("userdata.txt",userdata);
 string limits=get_property("_limitBuffs");
 if (limits=="")return;
 string[int] limit=split_string(limits,':');
 int y=count(limit)/2;
 if (y<1) return;
 for x from 0 to y-1 userdata["*"].buffs[to_int(limit[x*2])]=to_int(limit[x*2+1]);
 map_to_file(userdata,"userdata.txt");
}

void checkapps(){
 int n=now_to_string("HH").to_int()*60+now_to_string("mm").to_int();
 if (n>1200) n-=1440;
 if (n<lastCheck) return;
// print("checking");
 lastCheck=n+5;
 boolean acceptall=true;
 matcher appcheck=create_matcher("y <b>(\\d+)</b> p", visit_url("clan_office.php"));	
 if ((appcheck.find()) && (acceptall)){
  matcher applicants = create_matcher("who=(\\d+)\">(.+?)<", visit_url("clan_applications.php"));
  while (applicants.find()){
   print("Accepting "+applicants.group(2)+" into the clan.");
   visit_url("clan_applications.php?request"+applicants.group(1)+"=1&action=process");
   visit_url("clan_members.php?pwd="+my_hash()+"&action=modify&level"+applicants.group(1)+"=7&title"+applicants.group(1)+"=Cake&pids[]="+applicants.group(1));
   if ((userdata[group(applicants,2)].flags&receivedCake)==receivedCake) return;
   retrieve_item(1,$item[black forest cake]);
   retrieve_item(1,$item[bulky buddy box]);
   /**/kmail(applicants.group(1),"Welcome to Black Mesa! We'd really like to get to know you, so when you get a chance, please hop into chat to say \"hello.\" If you're new to the game and don't know how to do this, let me show you:\n\n Do you see the rightmost frame in your browser? At the top, there is a link that reads \"Enter the Chat.\" Click on that. Now you should have a small bar at the bottom of that frame that you can type into. To get to our clan's channel, simply enter \"/c clan\". And that's it! Now, if you have any questions, just ask in chat, and someone should be able to answer. Enjoy!\n\n P.S. I'm the clan's everything-bot. Primarily, I'm good for buffing. Ask around if you have questions.",0,gift);
   chat_clan("Everybody give a warm welcome to "+applicants.group(2)+", our newest member!");
   file_to_map("userdata.txt",userdata);
   userdata[group(applicants,2)].userid=group(applicants,1).to_int();
   userdata[group(applicants,2)].flags|=(inClan|receivedCake);
   map_to_file(userdata,"userdata.txt");
  }
 }
}

void sendMeat(string who, int amount){
 while(get_property("_isadventuring")!="") {waitq(1);}
 set_property("_isadventuring","1");
 take_closet(amount,$item[dense meat stack]);
 string sender="town_sendgift.php?pwd="+my_hash()+"&towho="+who+"&note=You won the Lotto!&insidenote=A winner is you!&whichpackage=1&howmany1="+amount.to_string()+"&whichitem1="+$item[dense meat stack].to_int().to_string();
 sender+="&fromwhere=0&action=Yep.";
 visit_url(sender);
 set_property("_isadventuring","");
}

void gRR(){
 gameData game=loadGame();
 if (!game.gameStarted){
  
 }else{

 }
}

void gWS(){
 gameData game=loadGame();
 if(game.intervals==-1){
  string winner;
  string word;
  foreach k,v in game.players if(v==2) winner=k; else word=k;
  chat_clan("Winner! "+winner+" won with '"+word+"'!");
  chat_private(game.host,"Winner of wordshot: "+winner);
 }
 closeGame();
}

void checkLotto(){
 int[string] books;
 file_to_map("books.txt",books);
 int event=0;
 int time=minutesToRollover();
 if (time<books["Event1"]) event=1;
 if (time<books["Event2"]) event=2;
 if (time<books["Event3"]) event=3;
 if (event<1) return;
 books["Event"+event.to_string()]=0;
 books["nextLotto"]+=2;
 books["thisLotto"]+=14;
 boolean[string] inClan=who_clan();
 remove inClan["Ominous Buffer"];
 remove inClan["MesaChat"];
 string[int] clannies;
 foreach name in inClan clannies[count(clannies)]=name;
 int num=count(clannies);
 if (num<1){
  map_to_file(books,"books.txt");
  return;
 }
 float perc;
 if (num>11){
  perc=1.0+(num/2)*0.16;
 }else{
  perc=num*2.0/(1.0+num);
 }
 int d=ceil((100/perc)*num);
 print("Event @ "+now_to_string("HH:mm")+" for "+books["thisLotto"].to_string());
 print(num.to_string()+"players: Rolling D"+d.to_string());
 chat_clan("Time for the Lotto! Right now it's for "+books["thisLotto"].to_commad()+",000 meat! We have "+num.to_string()+(num!=1?" players":" player")+" now (d"+d.to_string()+"). Good luck!");
 d=random(d);
 print("Rolled: "+d.to_string());
 waitq(20);
 chat_clan("/em rolls "+to_string(d+1)+".");
 waitq(7);
 if (d<num){
  print("Winner:"+clannies[d]);
  chat_clan("A winner!");
  waitq(7);
  file_to_map("userdata.txt",userdata);
  for i from 5 downto 2 userdata["*"].buffpacks["winner"+i.to_string()]=userdata["*"].buffpacks["winner"+to_string(i-1)];
  userdata["*"].buffpacks["winner1"]=clannies[d]+": "+books["thisLotto"].to_commad()+",000";
  string buf="account.php?action=Update&tab=profile&pwd="+my_hash()+"&actions[]=quote&quote=Black Mesa Buffbot. Serving all your AT, TT, and S needs.";
  buf+="\n\nCheck DC for casts remaining of limited use skills.\n\nLast Five Lotto Winners:";
  for i from 1 to 5 if (userdata["*"].buffpacks["winner"+i.to_string()]!="") buf+="\n"+userdata["*"].buffpacks["winner"+i.to_string()];
  visit_url(buf);
  chat_clan(clannies[d]+" wins the lotto and takes home "+books["thisLotto"].to_string()+",000 meat! See you again soon!");
  sendMeat(clannies[d],books["thisLotto"]);
  books["thisLotto"]=books["nextLotto"]-1;
  books["nextLotto"]=1;
 }else{
  print("No winner.");
  chat_clan("Sorry, folks, no winners today. Better luck next time. See you again soon!");
 }
 map_to_file(books,"books.txt");
}

void burn(){
 file_to_map("userdata.txt",userdata);
 if ((userdata["*"].buffs[6020]< 10) || (userdata["*"].buffs[6023]< 10) || (userdata["*"].buffs[6028]< 5)){
  int price_thing = mall_price($item[recording of The Ballad of Richie Thingfinder]);
  int price_chorale = mall_price($item[recording of Chorale of Companionship]);
  int price_inigo = mall_price($item[recording of Inigo's Incantation of Inspiration]);
  int thing = 530;
  int chorale = 533;
  int inigo = 716;
  int best;
  int next_best;
  int worst;
  int bestmax = 10;
  int nextmax = 10;
  int worstmax = 10;
  switch (max(max(price_thing,price_chorale),price_inigo)){
   case price_thing:
    best = thing;
    switch (max(price_chorale,price_inigo)){
     case price_chorale:
      next_best = chorale;
      worst = inigo;
      worstmax = 5;
      break;
     default:
      next_best = inigo;
      worst = chorale;
      nextmax = 5;
      break;
    }
    break;
   case price_chorale:
    best = chorale;
    switch (max(price_thing,price_inigo)){
     case price_thing:
      next_best = thing;
      worst = inigo;
      worstmax = 5;
      break;
     default:
      next_best = inigo;
      worst = thing;
      nextmax = 5;
      break;
    }
    break;
   default:
    bestmax=5;
    best = inigo;
    switch (price_thing>price_chorale){
     case true:
      next_best = thing;
      worst = chorale;
      break;
     default:
      next_best = chorale;
      worst = thing;
      break;
    }
    break;
  }
  if(userdata["*"].buffs[6020]+userdata["*"].buffs[6023]+userdata["*"].buffs[6028]<25){
   visit_url("volcanoisland.php?action=tuba&pwd");
   visit_url("choice.php?whichchoice=409&option=1&pwd");
   visit_url("choice.php?whichchoice=410&option=2&pwd");
   visit_url("choice.php?whichchoice=412&option=3&pwd");
   visit_url("choice.php?whichchoice=418&option=3&pwd");
   while ((my_mp() > 800) && (bestmax - userdata["*"].buffs[to_int(to_skill(to_effect(best)))] != 0)){
    visit_url("choice.php?whichchoice=440&whicheffect=" + best + "&times=1&option=1&pwd="+my_hash());
    userdata["*"].buffs[to_int(to_skill(to_effect(best)))]+=1;
   }
   while ((my_mp() > 800) && (nextmax - userdata["*"].buffs[to_int(to_skill(to_effect(next_best)))] != 0)){
    visit_url("choice.php?whichchoice=440&whicheffect=" + next_best + "&times=1&option=1&pwd="+my_hash());
    userdata["*"].buffs[to_int(to_skill(to_effect(next_best)))]+=1;
   }
   while ((my_mp() > 800) && (worstmax - userdata["*"].buffs[to_int(to_skill(to_effect(worst)))] != 0)){
    visit_url("choice.php?whichchoice=440&whicheffect=" + worst + "&times=1&option=1&pwd="+my_hash());
    userdata["*"].buffs[to_int(to_skill(to_effect(worst)))]+=1;
   }
   visit_url("choice.php?whichchoice=440&option=2&pwd="+my_hash());
   map_to_file(userdata,"userdata.txt");
   updateLimits();
  }
 }
 int to_burn = my_mp()-800;
 if(to_burn<0) return;
 skill farmingbuff = $skill[Polka of Plenty];
 switch (farmbuff){
  case 0:
   farmingbuff = $skill[Fat Leon's Phat Loot Lyric];
   farmbuff+=1;
   break;
  case 1:
   farmingbuff = $skill[Polka of Plenty];
   farmbuff+=1;
   break;
  default:
   farmingbuff = $skill[Cantata of Confrontation];
   farmbuff=0;
 }
 int casts_to_use = ceil(to_float(to_burn)/(mp_cost(farmingbuff)));
 casts_to_use = max((casts_to_use/3),1);
 int currentmp = my_mp();
 while (my_mp() == currentmp)
  use_skill(casts_to_use,farmingbuff,"Ominous Tamer");
 currentmp = my_mp();
 while (my_mp() == currentmp)
  use_skill(casts_to_use,farmingbuff,"Ominous Sauceror");
 currentmp = my_mp();
 while (my_mp() == currentmp)
  use_skill(casts_to_use,farmingbuff);
}

void handleMeat(){
 cli_execute("use 0 warm subject gift certificate");
 cli_execute("autosell 0 thin black candle, 0 heavy d, 0 original g, 0 disturbing fanfic, 0 furry fur, 0 awful poetry journal, 0 chaos butterfly, 0 plot hole, 0 probability potion, 0 procrastination potion, 0 angry farmer candy, 0 mick's icyvapohotness rub");
 cli_execute("csend 0 wolf mask, 0 rave whistle, 0 giant needle, 0 twinkly nugget to smashbot || wads");
 int totalDMS=floor(my_meat()/1000)-500;
 if (totalDMS>0){
  string exe="make "+to_string(totalDMS)+" dense meat stack";
  cli_execute(exe);
  put_closet(item_amount($item[dense meat stack]),$item[dense meat stack]);
 }
 int[string] books;
 file_to_map("books.txt",books);
// books["Meat"+now_to_string("yDDD")]=totalDMS-18;
 int eventTimeCap=minutesToRollover();
 int event1=random(eventTimeCap-35)+30;
 int event2=random(eventTimeCap-35)+30;
 int event3=random(eventTimeCap-35)+30;
 while ((event2-event1<60)&&(event1-event2<60))event2=random(eventTimeCap-35)+30;
 while (((event3-event1<60)&&(event1-event3<60))||((event3-event2<60)&&(event2-event3<60)))event3=random(eventTimeCap-35)+30;
 books["Event1"]=event1;
 books["Event2"]=event2;
 books["Event3"]=event3;
 map_to_file(books,"books.txt");
}

void main(){try{
 print("Starting Login...");
 if (get_property("_thisBreakfast")==""){
  int[string] lifetime;
  file_to_map("OB_lifetime.txt",lifetime);
  file_to_map("userdata.txt",userdata);
  foreach name in userdata{
   foreach skilln,amt in userdata[name].buffs lifetime[skilln.to_string()]+=amt;
   clear(userdata[name].buffs);
   userdata[name].lastTrigger="";
  }
  for i from 1 to 6 {remove userdata["*"].buffpacks[i.to_string()];}
  map_to_file(userdata,"userdata.txt");
  lifetime["*"]=0;
  foreach skilln in lifetime if(skilln!="*") lifetime["*"]+=lifetime[skilln];
  map_to_file(lifetime,"OB_lifetime.txt");
  set_property("_thisBreakfast","1");
 }//per-PC-breakfast
 loadSettings("_breakfast;_limitBuffs;nunsVisits;ducks;rolladv;rollmp;_currentDeals");
 processLimits();
 updateLimits();
 updateDC();
 if (get_property("chatbotScript")==""){
  waitq (2);
 }
 set_property("chatbotScript",chatbotScript);
 set_property("_isadventuring","");
 string rumpus = visit_url("clan_rumpus.php");
 int camp_mp_gain;
 int rollmp;
 int rolladv;
 camp_mp_gain=to_int(numeric_modifier("base resting mp")*(1+numeric_modifier("resting mp percent")/100));
 int clanadv = 0;
 if (contains_text(rumpus,"rump1_1.gif") || contains_text(rumpus,"rump1_2.gif"))
  clanadv += 3;
 if (contains_text(rumpus,"rump2_3.gif"))
  clanadv += 5;
 if (contains_text(rumpus,"rump4_3.gif"))
  clanadv += 1;
//BREAKFAST
 if (get_property("_breakfast") == ""){
  set_property("_isadventuring","yes");
  handleMeat();
  set_property("totalDaysCasting",get_property("totalDaysCasting").to_int()+1);
  int ducks;
  switch (get_property("sidequestFarmCompleted")){
   case "fratboy":
    ducks=15;
    break;
   case "hippy":
    ducks=10;
    break;
   default:
    ducks=5;
  }
  set_property("ducks",ducks);
  int rolladv = numeric_modifier("adventures");
  set_property("rolladv",rolladv);
  rollmp = my_maxmp()-1000;
  set_property("rollmp",rollmp);
  cli_execute("maximize exp, -1000combat");
  print ("Visiting clan rumpus room.", "blue");
  if (contains_text(rumpus,"rump3_3.gif")){
   visit_url("clan_rumpus.php?action=click&spot=3&furni=3");
   visit_url("clan_rumpus.php?action=click&spot=3&furni=3");
   visit_url("clan_rumpus.php?action=click&spot=3&furni=3");
  }
  if (contains_text(rumpus,"rump3_1.gif")){
   visit_url("clan_rumpus.php?action=click&spot=3&furni=1");
   visit_url("clan_rumpus.php?action=click&spot=3&furni=1");
   visit_url("clan_rumpus.php?action=click&spot=3&furni=1");
  }
  if (contains_text(rumpus,"rump1_4.gif"))
   visit_url("clan_rumpus.php?action=click&spot=1&furni=4");
  if (contains_text(rumpus,"rump4_2.gif"))
   visit_url("clan_rumpus.php?action=click&spot=4&furni=2");
  if (contains_text(rumpus,"rump9_3.gif"))
   visit_url("clan_rumpus.php?action=click&spot=9&furni=3");
  if (contains_text(rumpus,"rump4_1.gif"))
   visit_url("clan_rumpus.php?action=click&spot=4&furni=1");
  if (contains_text(rumpus,"rump3_2.gif"))
   visit_url("clan_rumpus.php?preaction=jukebox&whichsong=1");
  if (contains_text(rumpus,"rump9_2.gif")){
   visit_url("clan_rumpus.php?preaction=buychips&whichbag=1");
   visit_url("clan_rumpus.php?preaction=buychips&whichbag=2");
   visit_url("clan_rumpus.php?preaction=buychips&whichbag=3");
  }
  if (contains_text(rumpus,"ballpit.gif"))
   visit_url("clan_rumpus.php?preaction=ballpit");
  print ("Finishing other breakfast functions.", "blue");
  if (get_property("sidequestOrchardCompleted") != "none")
   visit_url("store.php?whichstore=h");
  if (get_property("sidequestArenaCompleted") != "none")
   visit_url("postwarisland.php?action=concert&option=2");
  if (item_amount($item[Burrowgrub hive])>0)
   use(1,$item[Burrowgrub hive]);
  if (item_amount($item[Cheap toaster])>0)
   for i from 1 to 3 use(1,$item[Cheap toaster]);
  visit_url("volcanoisland.php?action=npc");
  if (item_amount($item[fisherman's sack])>1) use(1,$item[Fisherman's sack]);
  string bounty=visit_url("bhh.php");
  if (index_of(bounty,"discarded pacifiers")>0)
   visit_url("bhh.php?pwd="+my_hash()+"&action=takebounty&whichitem=2415");
  for i from 1 to 5
   (!hermit(1, $item[Ten-leaf clover]));
  if(item_amount($item[supernova champagne])<6) retrieve_item(6,$item[supernova champagne]);
  if(item_amount($item[can of swiller])<1) retrieve_item(1,$item[can of swiller]);
  if (have_skill($skill[Lunch Break]))
   (!use_skill(1,$skill[Lunch Break]));
  cli_execute("uneffect cantata");
  if (have_skill($skill[ode to booze]))
   (!use_skill(1,$skill[ode to booze]));
  drink(6,$item[supernova champagne]);
  drink(1,$item[can of swiller]);
  cli_execute("uneffect ode");
  if (have_skill($skill[Sonata of Sneakiness]))
   (!use_skill(1,$skill[Sonata of Sneakiness]));
  if ((have_effect($effect[Dreams and Lights])<1)&&(have_effect($effect[Arcane in the Brain])<1)){
   while(have_effect($effect[Dreams and Lights])<1) (!adventure(1,$location[Haunted Gallery]));
   cli_execute("uneffect sonata");
   retrieve_item(1,$item[llama lama gong]);
   cli_execute("gong mole");
   if (!adventure(8,$location[Mt. Molehill])){
    print("Arcane in the Brain Error","red");
   }
  }
  set_property("_breakfast", "1");
 } //shared-breakfast

 cli_execute("familiar "+stasis_fam);
 cli_execute("maximize mp");
 set_property("_isadventuring","");
 print("Entering wait cycle.","green");
 while (MinutesToRollover()>(burnMinutes+3)){
  checkapps();
  switch (gameType()){
   case gameRoulette:
    gRR();
    break;
   case gameWordshot:
    gWS();
    break;
   default:
    
    break;
  }
  checkLotto();
  waitq(5);
 }
 if (MinutesToRollover()>burnMinutes) waitq(60);
 file_to_map("userdata.txt",userdata);
 while(get_property("_isadventuring")=="yes") waitq(1);
 set_property("_isadventuring","yes");
 print("Using excess adventures before rollover.","red");
 while (have_effect($effect[Shape of...Mole!])>0)
  (!adventure(1,$location[Mt. Molehill]));
 if (!adventure(1,$location[Mt. Molehill])){}
 visit_url("choice.php?pwd="+my_hash()+"&whichchoice=277&option=1");
 burn();
 cli_execute("maximize meat, +1000combat, -tie");
 cli_execute("familiar "+meatfarm_fam);
 while (my_adventures()>(190-(40+to_int(get_property("rolladv"))+clanadv))){
  if (adventure(1,$location[giant's castle])){}
  burn();
 }
 burn();
 updateDC();
 cli_execute("uneffect cantata");
 cli_execute("familiar "+stasis_fam);
 cli_execute("outfit birthday suit");
 cli_execute("maximize mp");
 set_property("_isadventuring","");
 chat_private("Ominous Tamer","CASTRQ");
 chat_private("Ominous Sauceror","CASTRQ");
 checkapps();
 waitq((MinutesToRollover()-logMinutes-5)*60);
 chat_clan("Rollover's coming. If you still need buffs, please request them in the next five minutes.");
 checkapps();
 waitq((MinutesToRollover()-logMinutes)*60);
 visit_url("bhh.php");
 chat_clan("Remember to turn in your bounties, overdrink, and equip your rollover gear\!");
 cli_execute("maximize adv -tie");
 cli_execute("set chatbotScript=");
 saveSettings("totalDaysCasting;totalCastsEver;sauceCasts;tamerCasts");
 checkapps();
 cli_execute("exit");
}finally{
 print("Script Halted");
}}