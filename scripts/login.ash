import <shared.ash>
invokeResourceMan(__FILE__);
string chatbotScript="buffbot.ash";
int logMinutes=3;
int burnMinutes=40;

boolean prompted=false;
int farmbuff=0;

string meatfarm_fam="leprechaun";
string stat_fam="hovering sombrero";
int lastCheck=0;

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

void updateProfile(){
 int[string]books;
 update(books,"books.txt");
 string buf="account.php?action=Update&tab=profile&pwd="+my_hash()+"&actions[]=quote&quote=Black Mesa Buffbot. Serving all your AT, TT, and S needs.";
 buf+="\n\nCheck DC for casts remaining of limited use skills.\n\nCurrent Lotto for "+to_commad(14+books["thisLotto"])+",000 meat!\nLast Five Lotto Winners:";
 string wintext=get_property("winners");
 string[int] winners=split_string(wintext,"::");
 for i from 0 upto count(winners)-1 buf+="\n"+winners[i];
 claimResource("adventuring");
 visit_url(buf);
 freeResource("adventuring");
}

void checkRaffle(){
 set_property("_checkedRaffle","y");
 checkOut(gamesavedata,"gameMode.txt");
 if(!(gamesavedata contains "raffle")){
  commit("gameMode.txt");
  return;
 }
 gameData g=gamesavedata["raffle"];
 g.players[":end"]-=1;
 if(g.players[":end"]<1){
  g.endRaffle();
  commit("gameMode.txt");
  return;
 }
 g.raffleAnnounce();
 gamesavedata["raffle"]=g;
 commit(gamesavedata,"gameMode.txt");
}

void sendMeat(string who, int amount){
 claimResource("adventuring");
 take_closet(amount,$item[dense meat stack]);
 string sender="town_sendgift.php?pwd="+my_hash()+"&towho="+who+"&note=You won the Lotto!&insidenote=A winner is you!&whichpackage=1&howmany1="+amount.to_string()+"&whichitem1="+$item[dense meat stack].to_int().to_string();
 sender+="&fromwhere=0&action=Yep.";
 visit_url(sender);
 freeResource("adventuring");
}

void checkLotto(){
 int[string] books;
 checkOut(books,"books.txt");
 int event=0;
 int time=minutesToRollover();
 if(time<books["Event1"])event=1;
 if(time<books["Event2"])event=2;
 if(time<books["Event3"])event=3;
 if(event<1){
  commit("books.txt");
  return;
 }
 books["Event"+event.to_string()]=0;
 books["nextLotto"]+=2;
 books["thisLotto"]+=14;
 boolean[string] inClan=who_clan();
 remove inClan["Ominous Buffer"];
 remove inClan["MesaChat"];
 remove inClan["Acoustic_shadow"];
 string[int] clannies;
 foreach name in inClan clannies[count(clannies)]=name;
 int num=count(clannies);
 if(num<1){
  set_property("books",books["Event1"].to_string()+"::"+books["Event2"].to_string()+"::"+books["Event3"].to_string()+"::"+books["nextLotto"].to_string()+"::"+books["thisLotto"].to_string());
  commit(books,"books.txt");
  updateProfile();
  return;
 }
 float perc;
 if(num>7){
  perc=1.4+(num/2)*0.24;
 }else{
  perc=0.4+num*2.0/(1.0+num);
 }
 if(perc>4) perc=4;
 if(books["thisLotto"]>2500)perc=min(5,perc+2);
 int d=ceil((100/perc)*num);
 d=d+random(10)-random(10);
 print("Event @ "+now_to_string("HH:mm")+" for "+books["thisLotto"].to_string());
 print(num.to_string()+"players: Rolling D"+d.to_string());
 chat_clan("Time for the Lotto! Right now it's for "+books["thisLotto"].to_commad()+",000 meat! We have "+num.to_string()+(num!=1?" players":" player")+" now (d"+d.to_string()+"). Good luck!");
 d=random(d);
 print("Rolled: "+d.to_string());
 waitq(20);
 chat_clan("/em rolls "+to_string(d+1)+".");
 waitq(7);
 string endsentence="!";
 if(d<num){
  print("Winner:"+clannies[d]);
  chat_clan("A winner!");
  waitq(7);
  checkOut(userdata,"userdata.txt");
  for i from 5 downto 2 if(userdata["*"].buffpacks contains ("winner"+to_string(i-1)))userdata["*"].buffpacks["winner"+i.to_string()]=userdata["*"].buffpacks["winner"+to_string(i-1)];
  userdata["*"].buffpacks["winner1"]=clannies[d]+": "+books["thisLotto"].to_commad()+",000";
  commit(userdata,"userdata.txt");
  string wintext="";
  for i from 1 to 5 if(userdata["*"].buffpacks contains ("winner"+i.to_string()))wintext+=userdata["*"].buffpacks["winner"+i.to_string()]+"::";
  set_property("winners",wintext);
  chat_clan(clannies[d]+" wins the lotto and takes home "+books["thisLotto"].to_commad()+",000 meat! See you again soon!");
  sendMeat(clannies[d],books["thisLotto"]);
  books["thisLotto"]=books["nextLotto"]-1;
  books["nextLotto"]=1;  
 }else{
  print("No winner.");
  chat_clan("Just what I thought. Everyone here is a loser. And probably "+insultCore()+" as well.");
 }
 set_property("books",books["Event1"].to_string()+"::"+books["Event2"].to_string()+"::"+books["Event3"].to_string()+"::"+books["nextLotto"].to_string()+"::"+books["thisLotto"].to_string());
 commit(books,"books.txt");
 updateProfile();
}

void makeRecords(){
 claimResource("adventuring");
 print("Recording leftover music.");
 checkOut(userdata,"userdata.txt");
 if(userdata["*"].buffs[6026]<50){//Donho
  if(userdata["*"].buffs[6026]<25){
   while(my_mp()<(25-userdata["*"].buffs[6026])*75)cli_execute("use mmj");
   visit_url("volcanoisland.php?action=tuba&pwd");
   visit_url("choice.php?whichchoice=409&option=1&pwd");
   visit_url("choice.php?whichchoice=410&option=2&pwd");
   visit_url("choice.php?whichchoice=412&option=3&pwd");
   visit_url("choice.php?whichchoice=418&option=3&pwd");
   visit_url("choice.php?whichchoice=440&whicheffect=614&times="+to_string(25-userdata["*"].buffs[6026])+"&option=1&pwd");
   userdata["*"].buffs[6026]=25;
   visit_url("choice.php?pwd&whichchoice=440&option=2");
  }
  while(my_mp()<max(50-userdata["*"].buffs[6026],0)*75)cli_execute("use mmj");
  visit_url("volcanoisland.php?action=tuba&pwd");
  visit_url("choice.php?whichchoice=409&option=1&pwd");
  visit_url("choice.php?whichchoice=410&option=2&pwd");
  visit_url("choice.php?whichchoice=412&option=3&pwd");
  visit_url("choice.php?whichchoice=418&option=3&pwd");
  visit_url("choice.php?whichchoice=440&whicheffect=614&times="+to_string(50-userdata["*"].buffs[6026])+"&option=1&pwd");
  userdata["*"].buffs[6026]=50;
  visit_url("choice.php?pwd&whichchoice=440&option=2");
 }
 print("Donho's complete");
 if(userdata["*"].buffs[6028]<5){//Inigo
  while(my_mp()<(5-userdata["*"].buffs[6028])*100)cli_execute("use mmj");
  visit_url("volcanoisland.php?action=tuba&pwd");
  visit_url("choice.php?whichchoice=409&option=1&pwd");
  visit_url("choice.php?whichchoice=410&option=2&pwd");
  visit_url("choice.php?whichchoice=412&option=3&pwd");
  visit_url("choice.php?whichchoice=418&option=3&pwd");
  visit_url("choice.php?whichchoice=440&whicheffect=716&times="+to_string(5-userdata["*"].buffs[6028])+"&option=1&pwd");
  userdata["*"].buffs[6028]=5;
  visit_url("choice.php?pwd&whichchoice=440&option=2");
 }
 print("Inigo's complete");
 for song from 6020 to 6024 if(userdata["*"].buffs[song]<10){
  while(my_mp()<(10-userdata["*"].buffs[song])*50)cli_execute("use mmj");
  visit_url("volcanoisland.php?action=tuba&pwd");
  visit_url("choice.php?whichchoice=409&option=1&pwd");
  visit_url("choice.php?whichchoice=410&option=2&pwd");
  visit_url("choice.php?whichchoice=412&option=3&pwd");
  visit_url("choice.php?whichchoice=418&option=3&pwd");
  visit_url("choice.php?whichchoice=440&whicheffect="+song.to_skill().to_effect().to_int()+"&times="+to_string(10-userdata["*"].buffs[song])+"&option=1&pwd");
  userdata["*"].buffs[song]=10;
  visit_url("choice.php?pwd&whichchoice=440&option=2");
 }
 print("Hobopolis complete");
 commit(userdata,"userdata.txt");
 updateLimits();
 freeResource("adventuring");
}

void doBounty(){
 claimResource("adventuring");
 string bounty=visit_url("bhh.php");
 matcher m=create_matcher("(40 billy|5 burned|40 coal|5 discard|20 disint|11 non-E|5 sammich|6 bits of)",bounty);
 if(!m.find()){
  freeResource("adventuring");
  return;
 }
 int b;
 switch(m.group(1)){
  case "40 billy":b=2409;break;
  case "5 burned":b=2106;break;
  case "40 coal":b=2105;break;
  case "5 discard":b=2415;break;
  case "20 disint":b=2470;break;
  case "11 non-E":b=2107;break;
  case "5 sammich":b=2412;break;
  case "6 bits of":b=2471;break;
  default: freeResource("adventuring");return;
 }
 int oldLucre=item_amount($item[filthy lucre]);
 visit_url("bhh.php?pwd&action=takebounty&whichitem="+b.to_string());
 while((my_adventures()-get_property("rolladv").to_int()>0)&&(item_amount($item[filthy lucre])==oldLucre)){
  if(adventure(1,b.to_item().bounty)){}
 }
 visit_url("bhh.php");
 freeResource("adventuring");
}

void burn(){
 int to_burn=my_mp()-800;
 if(to_burn<0)return;
 skill farmingbuff=$skill[Polka of Plenty];
 switch(farmbuff){
  case 0:
   farmingbuff=$skill[Fat Leon's Phat Loot Lyric];
   farmbuff+=1;
   break;
  case 1:
   farmingbuff=$skill[Polka of Plenty];
   farmbuff+=1;
   break;
  default:
   farmingbuff=$skill[Cantata of Confrontation];
   farmbuff=0;
 }
 int casts_to_use=ceil(to_float(to_burn)/(mp_cost(farmingbuff)));
 casts_to_use=max((casts_to_use/3),1);
 use_skill(casts_to_use,farmingbuff);
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
 foreach name,user in userdata if( ((user.lastTime.contains_text(today))||(user.lastTime.contains_text(yest))) &&
  ((name!="Ominous Buffer")&&(name!="Ominous Tamer")&&(name!="Ominous Sauceror")) ){
  user.wallet+=100;
  totspent+=100;
 }
 commit(userdata,"userdata.txt");
 cli_execute("use 0 warm subject gift certificate");
 cli_execute("autosell 0 thin black candle, 0 heavy d, 0 original g, 0 disturbing fanfic, 0 furry fur, 0 awful poetry journal, 0 chaos butterfly, 0 plot hole, 0 probability potion, 0 procrastination potion, 0 angry farmer candy, 0 mick's icyvapohotness rub");
 cli_execute("csend 0 wolf mask, 0 rave whistle, 0 giant needle, 0 twinkly nugget to smashbot || wads");
 int totalDMS=floor(my_meat()/1000)-500;
 if(totalDMS>0){
  string exe="make "+to_string(totalDMS)+" dense meat stack";
  cli_execute(exe);
  put_closet(item_amount($item[dense meat stack]),$item[dense meat stack]);
 }
 int[string] books;
 checkOut(books,"books.txt");
 books[now_to_string("yDDD")+"ear"]=totalDMS-18;
 books[now_to_string("yDDD")+"div"]=totspent;
 int eventTimeCap=minutesToRollover();
 int event1=random(eventTimeCap-15)+30;
 int event2=random(eventTimeCap-15)+30;
 int event3=random(eventTimeCap-15)+30;
 if(minutesToRollover()>180){
  while((event2-event1<60)&&(event1-event2<60))event2=random(eventTimeCap-35)+30;
  while(((event3-event1<60)&&(event1-event3<60))||((event3-event2<60)&&(event2-event3<60)))event3=random(eventTimeCap-35)+30;
 }
 books["Event1"]=event1;
 books["Event2"]=event2;
 books["Event3"]=event3;
 set_property("books",books["Event1"].to_string()+"::"+books["Event2"].to_string()+"::"+books["Event3"].to_string()+"::"+books["nextLotto"].to_string()+"::"+books["thisLotto"].to_string());
 commit(books,"books.txt");
}

void cleanPC(){
 cleanResources();
 int[string] lifetime;
 checkOut(lifetime,"OB_lifetime.txt");
 checkOut(userdata,"userdata.txt");
 foreach name in userdata{
  foreach skilln,amt in userdata[name].buffs lifetime[skilln.to_string()]+=amt;
  clear(userdata[name].buffs);
  userdata[name].lastTrigger="";
 }
 for i from 1 to 6 {remove userdata["*"].buffpacks[i.to_string()];}
 commit(userdata,"userdata.txt");
 lifetime["*"]=0;
 foreach skilln in lifetime if(skilln!="*")lifetime["*"]+=lifetime[skilln];
 commit(lifetime,"OB_lifetime.txt");
 int[string]books;
 checkOut(books,"books.txt");
 books["Event1"]=0;
 books["Event2"]=0;
 books["Event3"]=0;
 commit(books,"books.txt");
 set_property("_thisBreakfast","1");
}

void processQuestData(boolean rp){
 //Lotto
 int[string] books;
 checkOut(books,"books.txt");
 matcher m=create_matcher("(\\d+)::(\\d+)::(\\d+)::(\\d+)::(\\d+)",get_property("books"));
 if(m.find()){
  if(!rp){
   books["Event1"]=m.group(1).to_int();
   books["Event2"]=m.group(2).to_int();
   books["Event3"]=m.group(3).to_int();
  }
  books["nextLotto"]=m.group(4).to_int();
  books["thisLotto"]=m.group(5).to_int();
 }
 set_property("books",books["Event1"]+"::"+books["Event2"]+"::"+books["Event3"]+"::"+books["nextLotto"]+"::"+books["thisLotto"]);
 commit(books,"books.txt");
 //Limited Buffs
 checkOut(userdata,"userdata.txt");
 string limits=get_property("_limitBuffs");
 if(limits!=""){
  userdata["*"].buffs[62]=to_int(limits);
 }
 limits=visit_url("skills.php");
 m=create_matcher("(\\d+)>[^>]+?\\((\\d+)\\s*/",limits);
 while(m.find()) userdata["*"].buffs[m.group(1).to_int()]=m.group(2).to_int();
 string[int] wintext=split_string(get_property("winners"),"::");
 foreach i,s in wintext if(length(s)>1)userdata["*"].buffpacks["winner"+s.char_at(0)]=s.substring(2);
 wintext=split_string(get_property("admins"),"::");
 foreach i,s in wintext if(s.length()>0)setUF(s,isAdmin);
 commit(userdata,"userdata.txt");
 updateProfile();
}

void nightlyPaperwork(){
 string n=now_to_string("yyyyMMdd");
 int[string]books;
 claimResource("backup/"+n+"b.txt");
 update(books,"books.txt");
 commit(books,"backup/"+n+"b.txt");
 claimResource("backup/"+n+"u.txt");
 update(userdata,"userdata.txt");
 commit(userdata,"backup/"+n+"u.txt");
}

void clearBuffs(){
 for i from 6000 to 6030{
  if((i==6006)||(i==6010))continue;
  if(i.to_skill().to_effect().have_effect()>0)cli_execute("uneffect "+i.to_skill().to_effect().to_string());
 }
}

void dailyBreakfast(){
 string rumpus=visit_url("clan_rumpus.php");
 int camp_mp_gain;
 int rollmp;
 int rolladv=numeric_modifier("adventures");
 camp_mp_gain=to_int(numeric_modifier("base resting mp")*(1+numeric_modifier("resting mp percent")/100.0));
 if(contains_text(rumpus,"rump1_1.gif")||contains_text(rumpus,"rump1_2.gif"))rolladv+=3;
 if(contains_text(rumpus,"rump2_3.gif"))rolladv+=5;
 if(contains_text(rumpus,"rump4_3.gif"))rolladv+=1;
 checkMail();
 set_property("totalDaysCasting",get_property("totalDaysCasting").to_int()+1);
 set_property("rolladv",rolladv);
 rollmp = my_maxmp()-1000;
 set_property("rollmp",rollmp);
 cli_execute("familiar "+stat_fam);
 cli_execute("maximize exp, -1000combat");
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
 if(item_amount($item[Burrowgrub hive])>0)use(1,$item[Burrowgrub hive]);
 if(item_amount($item[Cheap toaster])>0)for i from 1 to 3 use(1,$item[Cheap toaster]);
 visit_url("volcanoisland.php?action=npc");
 if(item_amount($item[fisherman's sack])>1)use(1,$item[Fisherman's sack]);
 for i from 1 to 5 (!hermit(1, $item[Ten-leaf clover]));
 if(item_amount($item[supernova champagne])<6)retrieve_item(6,$item[supernova champagne]);
 if(item_amount($item[can of swiller])<1)retrieve_item(1,$item[can of swiller]);
 if(have_skill($skill[Lunch Break])) (!use_skill(1,$skill[Lunch Break]));
 clearBuffs();
 if(have_skill($skill[ode to booze])) (!use_skill(1,$skill[ode to booze]));
 drink(6,$item[supernova champagne]);
 drink(1,$item[can of swiller]);
 clearBuffs();
 if((have_skill($skill[Sonata of Sneakiness]))&&(have_effect($effect[Sonata of Sneakiness])<1))(!use_skill(1,$skill[Sonata of Sneakiness]));
 if((have_effect($effect[Dreams and Lights])<1)||((have_effect($effect[Dreams and Lights])<9)&&(have_effect($effect[Arcane in the Brain])<1))){
  while(have_effect($effect[Dreams and Lights])<9)(!adventure(1,$location[Haunted Gallery]));
  clearBuffs();
  retrieve_item(1,$item[llama lama gong]);
  cli_execute("gong mole");
  if(!adventure(8,$location[Mt. Molehill])){
   print("Arcane in the Brain Error","red");
  }
 }
 handleMeat();
 set_property("_breakfast","1");
}

void main(){try{
 print("Starting Login...");
 claimResource("science");
 run_combat();//Just in casies.
 if(get_property("_thisBreakfast")=="")cleanPC();
 claimResource("adventuring");
 set_property("chatbotScript",chatbotScript);
 processQuestData(loadSettings(ignorePile));
 updateLimits();
 updateDC();
 set_property("_bufferOnly","");
 if(get_property("_breakfast")=="")dailyBreakfast();
 cli_execute("maximize mp");
 if(get_property("_checkedRaffle")=="")checkRaffle();
 freeResource("adventuring");
 freeResource("science");
 print("Entering wait cycle.","green");
 int n;
 while(MinutesToRollover()>(burnMinutes+3)){
  coreGameCycle();
  checkLotto();
  n=now_to_string("HH").to_int()*60+now_to_string("mm").to_int();
  if(n>=lastCheck){
   lastCheck=n+10;
   if(lastCheck>1439)lastCheck-=1440;
   checkApps();
   checkMail();
   checkData();
  }
  waitq(5);
 }
 if(MinutesToRollover()>burnMinutes)waitq(60);
 claimResource("science");
 claimResource("adventuring");
 print("Using excess adventures before rollover.","red");
 if(have_effect($effect[Shape of...Mole!])>0){
  while(have_effect($effect[Shape of...Mole!])>0)(!adventure(1,$location[Mt. Molehill]));
  if(!adventure(1,$location[Mt. Molehill])){}
  visit_url("choice.php?pwd="+my_hash()+"&whichchoice=277&option=1");
 }
 makeRecords();
 int burnTurns=150-to_int(get_property("rolladv"));
/* while(my_fullness()<10){
  eatsilent();
 }*/
 doBounty();
 if((my_adventures()-burnTurns)>0){
  burn();
  cli_execute("familiar "+meatfarm_fam);
  cli_execute("maximize meat, +1000combat, -tie");
  while(my_adventures()-burnTurns>0){
   if(adventure(1,$location[giant's castle])){}
   if(my_adventures()-burnTurns>12)burn();
  }
  burn();
 }
 updateDC();
 clearBuffs();
 cli_execute("familiar "+stat_fam);
 cli_execute("outfit birthday suit");
 cli_execute("maximize mp");
 freeResource("adventuring");
 freeResource("science");
 chat_private("Ominous Tamer","CASTRQ");
 chat_private("Ominous Sauceror","CASTRQ");
 checkApps();
 waitq((MinutesToRollover()-logMinutes-5)*60);
 chat_clan("Rollover's coming. If you still need buffs, please request them in the next five minutes.");
 checkApps();
 waitq((MinutesToRollover()-logMinutes)*60);
 chat_clan("Remember to turn in your bounties, overdrink, and equip your rollover gear\!");
 cli_execute("maximize adv -tie");
 saveSettings(nightlySave);
 set_property("_bufferOnly","1");
 nightlyPaperwork();
 checkApps();
 set_property("chatbotScript","");
 cli_execute("exit");
}finally{
 print("Script Halted");
 saveSettings(earlySave);
 releaseResources();
}}