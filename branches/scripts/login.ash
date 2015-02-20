import <shared.ash>
string chatbotScript="buffbot.ash";
int logMinutes=3;
int burnMinutes=50;

void systemCall(string command){
 chat_private(my_name(),command);
}

void checkRaffle(){
 set_property("_checkedRaffle","y");
 checkOut(gamesavedata,"gameMode.txt");
 if(!(gamesavedata contains "raffle"))return;
 gameData g=gamesavedata["raffle"];
 g.players[":end"]-=1;
 if(g.players[":end"]<1)g.endRaffle();
 g.raffleAnnounce();
 gamesavedata["raffle"]=g;
 commit(gamesavedata,"gameMode.txt");
}

void checkProperties(){
 if(get_property("_forceShutdown")=="shutdown"){
  burnMinutes=minutesToRollover();
  logMinutes=minutesToRollover();
 }
 if(get_property("_forceShutdown")=="burn"){
  burnMinutes=minutesToRollover();
 }
}

void resetEvents(int[string] books){
 int[int] e;
 e[1]=0;
 e[2]=0;
 e[3]=0;
 int limit=minutesToRollover()-30;
 if(limit>2){
  foreach i in e e[i]=random(limit)+15;
  int tries=0;
  while((e[2]-e[1]<60)&&(e[1]-e[2]<60)&&(tries<10)){
   e[2]=random(limit)+15;
   tries+=1;
  }
  tries=0;
  while((tries<10)&&(((e[3]-e[1]<60)&&(e[1]-e[3]<60))||((e[3]-e[2]<60)&&(e[2]-e[3]<60)))){
   e[3]=random(limit)+15;
   tries+=1;
  }
 }
 limit=3;
 foreach i,v in e if(books["Event"+i]!=0)books["Event"+i]=v;
 foreach i in e if(books["Event"+i]==0)limit-=1;
 print_html("<font color=\"olive\">Setting times for </font><font color=\""+(limit>0?"green\">":"red\">")+limit+"</font><font color=\"olive\"> lotto event(s).</font>");
}

void handleMeat(){
 string today=now_to_string("MMMM d, yyyy");
 matcher mx=create_matcher("(\\w+) (\\d+), (\\d+)",today);
 if(!mx.find())return;
 int month;
 int day=mx.group(2).to_int();
 int year=mx.group(3).to_int();
 switch(mx.group(1)){
  case "January": month=1; break;
  case "February": month=2; break;
  case "March": month=3; break;
  case "April": month=4; break;
  case "May": month=5; break;
  case "June": month=6; break;
  case "July": month=7; break;
  case "August": month=8; break;
  case "September": month=9; break;
  case "October": month=10; break;
  case "November": month=11; break;
  case "December": month=12; break;
 }
 day-=1;
 if(day==0){
  month-=1;
  if(month==0){
   year-=1;
   month=12;
  }
  boolean isleapyear=(year-4*(year/4))==0;
  isleapyear=isleapyear&((year-100*(year/100))==0);
  isleapyear=isleapyear|((year-400*(year/400))==0);
  switch(month){
   case 1:case 3:case 5:case 7:case 8:case 10:case 12: day=31; break;
   case 2: if(isleapyear)day=29; else day=28; break;
   default: day=30;
  }
 }
 string yest=" "+day.to_string()+", "+year.to_string();
 switch(month){
  case 1: yest="January"+yest; break;
  case 2: yest="February"+yest; break;
  case 3: yest="March"+yest; break;
  case 4: yest="April"+yest; break;
  case 5: yest="May"+yest; break;
  case 6: yest="June"+yest; break;
  case 7: yest="July"+yest; break;
  case 8: yest="August"+yest; break;
  case 9: yest="September"+yest; break;
  case 10: yest="October"+yest; break;
  case 11: yest="November"+yest; break;
  case 12: yest="December"+yest; break; 
 }
 checkOut(userdata,"userdata.txt");
 int totspent=0;
 foreach name in userdata if(((userdata[name,"lastTime"].contains_text(today))||(userdata[name,"lastTime"].contains_text(yest)))&&(name!="BuffSphere")){
  sysInc(name,"meat",100);
  totspent+=100;
 }
 commit(userdata,"userdata.txt");
 cli_execute("mallsell 0 snow queen crown @ 400");
 cli_execute("autosell 0 crazy little Turkish delight, 0 ga-ga radio, 0 ram's face lager, 0 ram horns, 0 ram stick, 0 yeti fur");
 int totalDMS=floor(my_meat()/1000)-500;
 if(totalDMS>0){
  string exe="make "+to_string(totalDMS)+" dense meat stack";
  cli_execute(exe);
  put_closet(item_amount($item[dense meat stack]),$item[dense meat stack]);
 }
 int[string] books;
 checkOut(books,"books.txt");
 books[now_to_string("yyyyMMdd")]=totalDMS-19-(totspent/100);
 books["avg"]=(books["avg"]*4+totalDMS-19)/5;
 commit(books,"books.txt");
 if(totalDMS<0){
  take_closet(totalDMS,$item[dense meat stack]);
  cli_execute("autosell * dense meat stack");
 }
}

void updateFaxes(){
 string[string] fax;
 string faxes=visit_url("http://www.hogsofdestiny.com/faxbot/faxbot.xml");
 matcher m=create_matcher("<name>([^<]+?)</name>\n<actual_name>.+?</actual_name>\n<command>(.+?)</command>",faxes);
 boolean hostFound=false; 
 while(m.find()){
  fax[to_lower_case(m.group(1))]=m.group(2);
  hostFound=true;
 }
 if(!hostFound)return;
 commit(fax,"faxnames.txt");
}

void processQuestData(boolean rp){
 //Lotto
 int[string] books;
 checkOut(books,"books.txt");
 matcher m=create_matcher("(\\d+)::(\\d+)",get_property("books"));
 if(m.find()){
  books["thisLotto"]=m.group(1).to_int();
  books["nextLotto"]=m.group(2).to_int();
 }
 if(!rp) for i from 0 to 2 books["Event"+to_string(i+1)]=(get_property("lottos").to_int()>i?-1:0);
 else{
  for i from 0 to 2 books["Event"+to_string(i+1)]=-1;
  set_property("lottos",2);
 }
 resetEvents(books);
 commit(books,"books.txt");
 //Limited Buffs
 checkOut(userdata,"userdata.txt");
 string limits=get_property("_limitBuffs");
 if(limits!="")userdata["*","#62"]=limits;
 limits=visit_url("skills.php");
 m=create_matcher("(\\d+)>[^>]+?\\((\\d+)\\s*/",limits);
 while(m.find())userdata["*","#"+m.group(1)]=m.group(2);
 string[int] wintext=split_string(get_property("winners"),"::");
 foreach i,s in wintext if(length(s)>1)userdata["*","winner"+to_string(i+1)]=s;
 wintext=split_string(get_property("admins"),"::");
 foreach i,s in wintext if(s.length()>0)userdata[s,"permission"]="admin";
 commit(userdata,"userdata.txt");
 updateProfile();
}

void breakfast(){
 string rumpus=visit_url("clan_rumpus.php");
 checkMail();
 deMole();
 set_property("totalDaysCasting",get_property("totalDaysCasting").to_int()+1);
 cli_execute("maximize exp, -100 combat");
 print("Visiting clan rumpus room.", "blue");
 if(contains_text(rumpus,"rump3_3.gif")){
  visit_url("clan_rumpus.php?action=click&spot=3&furni=3");
  visit_url("clan_rumpus.php?action=click&spot=3&furni=3");
  visit_url("clan_rumpus.php?action=click&spot=3&furni=3");
 }
 if(contains_text(rumpus,"rump3_1.gif")){
  visit_url("clan_rumpus.php?action=click&spot=3&furni=1");
  visit_url("clan_rumpus.php?action=click&spot=3&furni=1");
  visit_url("clan_rumpus.php?action=click&spot=3&furni=1");
 }
 if(contains_text(rumpus,"rump1_4.gif"))visit_url("clan_rumpus.php?action=click&spot=1&furni=4");
 if(contains_text(rumpus,"rump4_2.gif"))visit_url("clan_rumpus.php?action=click&spot=4&furni=2");
 if(contains_text(rumpus,"rump9_3.gif"))visit_url("clan_rumpus.php?action=click&spot=9&furni=3");
 if(contains_text(rumpus,"rump4_1.gif"))visit_url("clan_rumpus.php?action=click&spot=4&furni=1");
 if(contains_text(rumpus,"rump3_2.gif"))visit_url("clan_rumpus.php?preaction=jukebox&whichsong=1");
 if(contains_text(rumpus,"rump9_2.gif")){
  visit_url("clan_rumpus.php?preaction=buychips&whichbag=1");
  visit_url("clan_rumpus.php?preaction=buychips&whichbag=2");
  visit_url("clan_rumpus.php?preaction=buychips&whichbag=3");
 }
 if(contains_text(rumpus,"ballpit.gif"))visit_url("clan_rumpus.php?preaction=ballpit");
 print("Finishing other breakfast functions.","blue");
 visit_url("store.php?whichstore=h");
 if(get_property("sidequestArenaCompleted")!="none")visit_url("postwarisland.php?action=concert&option=2");
 if(item_amount($item[burrowgrub hive])>0)use(1,$item[burrowgrub hive]);
 if(item_amount($item[cheap toaster])>0)for i from 1 to 3 use(1,$item[cheap toaster]);
 if(item_amount($item[festive warbear bank])>0)use(1,$item[festive warbear bank]);
 visit_url("volcanoisland.php?action=npc");
 if(item_amount($item[fisherman's sack])>1)use(1,$item[fisherman's sack]);
 for i from 1 to 5 (!hermit(1,$item[ten-leaf clover]));
 if(have_skill($skill[Lunch Break]))(!use_skill(1,$skill[lunch break]));
 retrieve_item(7,$item[eggnog]);
 retrieve_item(1,$item[ram's face lager]);
 clearBuffs(6014);
 if(have_skill($skill[the ode to booze]))(!use_skill(1,$skill[the ode to booze]));
 while(inebriety_limit()-my_inebriety()>2)drink(1,$item[eggnog]);
 while(inebriety_limit()-my_inebriety()>0)drink(1,$item[ram's face lager]);
 clearBuffs();
 retrieve_item(7,$item[bunch of square grapes]);
 retrieve_item(1,$item[handful of nuts and berries]);
 retrieve_item(1,$item[milk of magnesium]);
 use(1,$item[milk of magnesium]);
 eatsilent(7,$item[bunch of square grapes]);
 eatsilent(1,$item[handful of nuts and berries]);
 /* When $/adv>1400:
 retrieve_item(4,$item[wrecked generator]);
 retrieve_item(2,$item[feliz navidad]);
 clearBuffs(6014);
 if(have_skill($skill[ode to booze]))(!use_skill(1,$skill[ode to booze]));
 while(inebriety_limit()-my_inebriety()>4)drink(1,$item[wrecked generator]);
 while(inebriety_limit()-my_inebriety()>1)drink(1,$item[feliz navidad]);
 clearBuffs();
 retrieve_item(4,$item[coffee pixie stick);
 retrieve_item(1,$item[mojo filter]);
 use(3,$item[coffee pixie stick]);
 use(1,$item[mojo filter]);
 use(1,$item[coffee pixie stick]);
// retrieve_item(1,$item[queen's cookie]);
// retrieve_item(3,$item[spectral pickle]);
// retrieve_item(1,$item[super salad]);
// retrieve_item(2,$item[handful of nuts and berries]);
// retrieve_item(1,$item[milk of magnesium]);
 use(1,$item[milk of magnesium]);
 eatsilent(1,$item[queen's cookie]); 
 eatsilent(3,$item[spectral pickle]); 
 eatsilent(1,$item[super salad]); 
 eatsilent(1,$item[handful of nuts and berries]); 
 */ 
 if((have_skill($skill[the sonata of sneakiness]))&&(have_effect($effect[the sonata of sneakiness])<1))(!use_skill(1,$skill[the sonata of sneakiness]));
 if((have_effect($effect[dreams and lights])<1)||((have_effect($effect[dreams and lights])<9)&&(have_effect($effect[arcane in the brain])<1))){
  while(have_effect($effect[dreams and lights])<9)(!adventure(1,$location[the haunted gallery]));
  clearBuffs();
  retrieve_item(1,$item[llama lama gong]);
  cli_execute("gong mole");
  if(!adventure(8,$location[mt. molehill])){
   print("Arcane in the Brain Error","red");
  }
 }
 handleMeat();
 updateFaxes();
 set_property("_breakfast","1");
}

void cleanPC(){
 int[string] lifetime;
 checkOut(lifetime,"lifetime.txt");
 checkOut(userdata,"userdata.txt");
 foreach name in userdata{
  foreach sk,amt in userdata[name] if(sk.char_at(0)=="#"){
   if(name=="*")lifetime[sk]+=amt.to_int();
   remove userdata[name,sk];
  }
  userdata[name,"lastTrigger"]="";
 }
 commit(userdata,"userdata.txt");
 lifetime["*"]=0;
 foreach sk in lifetime if(sk!="*")lifetime["*"]+=lifetime[sk];
 commit(lifetime,"lifetime.txt");
 set_property("_thisBreakfast","1");
}

void prepareScript(){
 processQuestData(loadSettings(ignorePile));
 updateLimits();
 updateDC();
 if(get_property("_checkedRaffle")=="")checkRaffle();
}

void main(){try{
 run_combat();
 cli_execute("autoattack none; ccs default;");
 print("Starting Login...","olive");
 set_property("!day",gameday_to_int());
 set_property("chatbotScript",chatbotScript);
 print("Purge pending requests","olive");
 waitq(30);
 print("Time up, continue logging in.","olive");
 set_property("_lockChat","1");
 prepareScript();
 if(get_property("_thisBreakfast")=="")cleanPC();
 if(get_property("_breakfast")=="")breakfast();
 set_property("_lockChat","");
 systemCall("outfit buff");
 print("Entering wait cycle.","green");
 int m=burnMinutes+1;
 while(m>burnMinutes){
  m=minutesToRollover();
  checkProperties();
  if((m%5)==0){
   systemCall("check");
  }
  waitq(31);
 }
 print("Using excess adventures before rollover.","blue");
 systemCall("record");
 systemCall("bounty");
 while(my_adventures()>burnTurns){
  m=my_adventures()-5;
  systemCall("adventure");
  while(my_adventures()>m)waitq(15);
 }
 systemCall("outfit buff");
 systemCall("apps");
 waitq((MinutesToRollover()-logMinutes-5)*60);
 if(MinutesToRollover()<10)chat_clan("Rollover's coming. If you still need buffs, please request them in the next five minutes.");
 systemCall("apps");
 waitq((MinutesToRollover()-logMinutes)*60);
 if(MinutesToRollover()<10)chat_clan("Remember to turn in your bounties, overdrink, and equip your rollover gear\!");
 print("Logging out","blue");
 systemCall("logout");
 errorFree=true;
}finally{
 if(!errorFree)print("ABRUPT STOP","red");
 print("Script Halted @R-"+minutesToRollover(),"red");
 saveSettings(earlySave);
}}