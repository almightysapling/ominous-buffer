import <shared.ash>

string chatbotScript="buffbot.ash";
int logMinutes=3;
int burnMinutes=20;

boolean prompted=false;
int farmbuff=0;

string meatfarm_fam="leprechaun";
string stat_fam="hovering sombrero";
int lastCheck=0;

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
gift[$item[black forest cake]]=1;
gift[$item[bulky buddy box]]=1;

void processLimits(){
 checkOut(userdata,"userdata.txt");
 string limits=get_property("_limitBuffs");
 if (limits=="")return;
 string[int] limit=split_string(limits,':');
 int y=count(limit)/2;
 if (y<1) return;
 for x from 0 to y-1 userdata["*"].buffs[to_int(limit[x*2])]=to_int(limit[x*2+1]);
 commit(userdata,"userdata.txt");
}

void checkApps(){
 boolean acceptall=true;
 matcher appcheck=create_matcher("y <b>(\\d+)</b> p", visit_url("clan_office.php"));	
 if ((appcheck.find()) && (acceptall)){
  matcher applicants = create_matcher("who=(\\d+)\">(.+?)<", visit_url("clan_applications.php"));
  while (applicants.find()){
   print("Accepting "+applicants.group(2)+" into the clan.");
   visit_url("clan_applications.php?request"+applicants.group(1)+"=1&action=process");
   visit_url("clan_members.php?pwd="+my_hash()+"&action=m-odify&level"+applicants.group(1)+"=7&title"+applicants.group(1)+"=Cake&pids[]="+applicants.group(1));
   if ((userdata[group(applicants,2)].flags&receivedCake)==receivedCake) return;
   retrieve_item(1,$item[black forest cake]);
   retrieve_item(1,$item[bulky buddy box]);
   /**/kmail(applicants.group(1),"Welcome to Black Mesa! We'd really like to get to know you, so when you get a chance, please hop into chat to say \"hello.\" If you're new to the game and don't know how to do this, let me show you:\n\n Do you see the rightmost frame in your browser? At the top, there is a link that reads \"Enter the Chat.\" Click on that. Now you should have a small bar at the bottom of that frame that you can type into. To get to our clan's channel, simply enter \"/c clan\". And that's it! Now, if you have any questions, just ask in chat, and someone should be able to answer. Enjoy!\n\n P.S. I'm the clan's everything-bot. Primarily, I'm good for buffing. Ask around if you have questions.",0,gift);
   chat_clan("Everybody give a warm welcome to "+applicants.group(2)+", our newest member!");
   checkOut(userdata,"userdata.txt");
   userdata[group(applicants,2)].userid=group(applicants,1).to_int();
   userdata[group(applicants,2)].flags|=(inClan|receivedCake);
   commit(userdata,"userdata.txt");
  }
 }
}

void raffleAnnounce(gameData g){
 string s="RAFFLE!\n";
 s+=g.host+" is raffling away the following prizes!\n";
 foreach i,a in g.players if (i.char_at(0)!=":") s+=i.to_string()+" ("+a.to_string()+")\n";
 if (g.players[":meat"]>0) s+="And "+g.players[":meat"].to_commad()+" meat!\n";
 s+="Tickets cost "+g.intervals.to_string()+" meat each and ";
 if (g.players[":end"]==1) s+="today is your last day to buy!";
  else s+="the raffle ends in "+g.players[":end"].to_string()+" days.";
 s+=g.data[0];
 announceClan(s);
}

void issueTickets(gameData g,string w,int amount){
 int lastTicket=count(g.data);
 for i from lastTicket+1 upto lastTicket+amount g.data[i]=w;
 string r="Thank you for your interest in the raffle. You have purchased the following tickets:\n";
 r+=to_string(lastTicket+1);
 if(amount>1) r+="-"+to_string(lastTicket+amount);
 r+="\nGood luck!";
 kmail(w,r);
 g.players[":meat"]+=(g.intervals/20)*amount;
}

void endRaffle(gameData g){
 deleteAnnouncement();
 checkOut(userdata,"userdata.txt");
 chat_clan("A Raffle House is Us!");
 int numtix=count(g.data);
 wait(5);
 chat_clan("We managed to sell "+numtix.to_commad()+" tickets for a total of "+to_commad(numtix*g.intervals)+" meat!");
 chat_clan("And the winner is...");
 if (numtix>1) numtix=random(numtix)+1;
  else numtix=1;
 wait(10);
 chat_clan(g.data[numtix]+" with ticket number "+numtix.to_commad()+".");
 chat_clan("Well, that's all folks, have fun and better luck next time!");
 int[item] reward;
 foreach it,amt in g.players if(it.char_at(0)!=":") reward[it.to_item()]=amt;
 int toPull=ceil(g.players[":meat"]*1.0/1000);
 cli_execute("closet take "+toPull.to_string()+" dense meat stack");
 cli_execute("autosell * dense meat stack");
 if (!kmail(g.data[numtix],"Congratulations, you've got the golden ticket!",g.players[":meat"],reward)){
  g.players[":meat"]=max(0,g.players[":meat"]-50*count(reward));
  string send;
  foreach it,amt in reward {
   send="town_sendgift.php?pwd="+my_hash()+"&towho="+g.data[numtix]+"&note=You won the Raffle!&insidenote=A winner is you! Collect your meat from OB's Wallet!&whichpackage=1&howmany1="+amt.to_string()+"&whichitem1="+it.to_int().to_string();
   send+="&fromwhere=0&action=Yep.";
   visit_url(send);
  }
  userdata[g.data[numtix]].wallet+=g.players[":meat"];
 }
 remove gamesavedata["raffle"];
 commit(gamesavedata,"gameMode.txt");
 commit(userdata,"userdata.txt");
}

void checkMail(){
 checkOut(userdata,"userdata.txt");
 message[int] mail=parseMail();
 matcher mx;
 string build;
 while (item_amount($item[plain brown wrapper])>0){
  break;
 }
 foreach i,m in mail{
  if ((m.sender=="smashbot")||(m.sender=="ominous tamer")||(m.sender=="ominous sauceror")){
   deleteMail(m.id);
   continue;
  }
  mx=create_matcher("(?i)donat(?:e|ation)",m.text);
  if (mx.find()){
   deleteMail(m.id);
   if (m.things[$item[dense meat stack]]>0) {
    cli_execute("autosell "+m.things[$item[dense meat stack]].to_string()+" dense meat stack");
    m.meat+=m.things[$item[dense meat stack]]*1000;
    remove m.things[$item[dense meat stack]];
   }
   userdata[m.sender].donated+=m.meat;
   build="";
   foreach it,amount in m.things if ((it.to_int()>4496)&&(it.to_int()<4504)) continue;
    else build+=amount+" "+it+", ";
   cli_execute("display put "+build);
   print("Arranging items");
   build="managecollectionshelves.php?pwd&action=arrange";
   foreach it in m.things if ((it.to_int()>4496)&&(it.to_int()<4504)) continue;
    else build+="&whichshelf"+it.to_int().to_string()+"=13";
   visit_url(build);
   print("Donation accepted.");
   continue;
  }
  build="-";
  mx=create_matcher("(?i)raffle\\s?(start|stop|cancel|add|\\+)?",m.text);
  if (mx.find()){
   build=mx.group(1)==""?"start":mx.group(1).to_lower_case();
  }
  mx=create_matcher("(?i)(start|stop|cancel|add|\\+)?\\s?raffle",m.text);
  if (mx.find()){
   build=mx.group(1)==""?"start":mx.group(1).to_lower_case();
  }
  if (build!="-"){
   deleteMail(m.id);
   checkOut(gamesavedata,"gameMode.txt");
   gameData game;
   if (gamesavedata contains "raffle"){
    game=gamesavedata["raffle"];
    switch (build){
     case "start":
      build="Sorry, but there is already a raffle in play. It ends in ";
      build+=game.players[":end"].to_string()+(game.players[":end"]==1?" day.\n":" days.\n");
      build+="Wait until the current raffle is over, or, if you'd like to add to the current raffle, send the items back with the message \"Raffle +\"";
      kmail(m.sender,build,m.meat,m.things);
      break;
     case "stop":case "end":
      game.endRaffle();
      break;
     case "cancel":
      //CANCEL RAFFLE
      break;
     case "add":case "+":
      build="Added the following items to "+game.host+"'s raffle:\n";
      foreach it,amt in m.things{
       game.players[it.to_string()]+=amt;
       build+=it.to_string()+" ("+amt.to_string()+")\n";
      }
      game.players[":meat"]+=m.meat;
      build+="meat ("+m.meat.to_string()+")\n";
      kmail(m.sender,build);
      break;
     default:
      if (m.sender==game.host){
       game.players[":meat"]+=m.meat;
       build+="Meat added to raffle value. ("+m.meat.to_string()+")\n";
       kmail(m.sender,build);
       break;
      }
      if (m.things contains $item[plain brown wrapper])break;
      if (m.meat==0)break;
      int numt=m.meat/game.intervals;
      m.meat=m.meat-(numt*game.intervals);
      if (m.meat>0) if (!kmail(m.sender,"Considering the cost of tickets, this is what was left over.",m.meat)) {
       userdata[m.sender].wallet+=m.meat;
       kmail(m.sender,"Your refund failed to send, so I'll hold it for you for now: "+m.meat.to_string()+" meat.");
      }
      game.issueTickets(m.sender,numt);
      break;
    }
   }else{
/*
raffle gameData{
 int[string] players; [item name]=amount for winner;
                      [":end"]=days remaining;
                      [":meat"]=meat portion of prize;
 string[int] data; [ticketnumber]=playername
 boolean gameStarted; UNUSED;
 int roundOver; TICKETS SOLD
 int intervals; COST
 string host; HOST
};
*/
    switch (build){
     case "start":
      game.host=m.sender;
      game.roundOver=0;
      mx=create_matcher("(?i)(?:price|cost):\\s?(\\d+)",m.text);
      game.intervals=100;
      if (mx.find()) game.intervals=min(max(floor(mx.group(1).to_int()/100)*100,100),5000);
      mx=create_matcher("(?i)(?:time|duration|length):\\s?(\\d+)\\s?days?",m.text);
      game.players[":end"]=7;
      if (mx.find()) game.players[":end"]=min(max(mx.group(1).to_int(),2),14);
      foreach thing,amt in m.things game.players[thing.to_string()]=amt;
      game.players[":meat"]=m.meat;
      mx=create_matcher("(?i)(?:message|text|quote):\\s\"(.+?)\"",m.text);
      if (mx.find())game.data[0]=mx.group(1);
/*      gamesavedata["raffle"]=game;
      raffleAnnounce(game); LEAVE OUT UNTIL READY TO ROLL*/
      break;
     case "stop":case "end":
      if (getUF(m.sender,isAdmin)) chat_private(m.sender,"There is no raffle in play.");
      else chat_private(m.sender,"You don't have that privelage.");
      break;
     case "cancel":
      if (getUF(m.sender,isAdmin)) chat_private(m.sender,"There is no raffle in play.");
      else chat_private(m.sender,"You don't have that privelage.");
      break;
     case "add":case "+":
      kmail(m.sender,"There is no raffle in play; therefore, you can't add to it.",m.meat,m.things);
      break;
     default:
      if (m.meat>0) kmail(m.sender,"You sent me this?",m.meat);
      break;
    }
   }
   commit(gamesavedata,"gameMode.txt");
   continue;
  }
 }
 commit(userdata,"userdata.txt");
}

void checkRaffle(){
 set_property("_checkedRaffle","y");
 checkOut(gamesavedata,"gameMode.txt");
 if (!(gamesavedata contains "raffle")){
  commit("gameMode.txt");
  return;
 }
 gameData g=gamesavedata["raffle"];
 g.players[":end"]-=1;
 if (g.players[":end"]<1) {
  g.endRaffle();
  commit("gameMode.txt");
  return;
 }
 g.raffleAnnounce();
 gamesavedata["raffle"]=g;
 commit(gamesavedata,"gameMode.txt");
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
 if (!game.gameStarted){}else{}
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
 checkOut(books,"books.txt");
 int event=0;
 int time=minutesToRollover();
 if (time<books["Event1"]) event=1;
 if (time<books["Event2"]) event=2;
 if (time<books["Event3"]) event=3;
 if (event<1){
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
 if (num<1){
  commit(books,"books.txt");
  return;
 }
 float perc;
 if (num>7){
  perc=1.4+(num/2)*0.24;
 }else{
  perc=0.4+num*2.0/(1.0+num);
 }
 if (perc>4) perc=4;
 if (books["thisLotto"]>2500)perc=min(5,perc+2);
 int d=ceil((100/perc)*num);
 print("Event @ "+now_to_string("HH:mm")+" for "+books["thisLotto"].to_string());
 print(num.to_string()+"players: Rolling D"+d.to_string());
 chat_clan("Time for the Lotto! Right now it's for "+books["thisLotto"].to_commad()+",000 meat! We have "+num.to_string()+(num!=1?" players":" player")+" now (d"+d.to_string()+"). Good luck!");
 d=random(d);
 print("Rolled: "+d.to_string());
 waitq(20);
 chat_clan("/em rolls "+to_string(d+1)+".");
 waitq(7);
 string endsentence="!";
 if (d<num){
  print("Winner:"+clannies[d]);
  while (checkRep("A winner"+endsentence)!=-1) switch (endsentence){
   case "!":
    endsentence="!!";
    break;
   case "!!":
    endsentence="!!!";
    break;
   case "!!!":
    endsentence="...";
    break;
   default:
    endsentence=".";
    break;   
  }
  chat_clan("A winner"+endsentence);
  waitq(7);
  checkOut(userdata,"userdata.txt");
  for i from 5 downto 2 if (userdata["*"].buffpacks contains ("winner"+to_string(i-1))) userdata["*"].buffpacks["winner"+i.to_string()]=userdata["*"].buffpacks["winner"+to_string(i-1)];
  userdata["*"].buffpacks["winner1"]=clannies[d]+": "+books["thisLotto"].to_commad()+",000";
  commit(userdata,"userdata.txt");
  string buf="account.php?action=Update&tab=profile&pwd="+my_hash()+"&actions[]=quote&quote=Black Mesa Buffbot. Serving all your AT, TT, and S needs.";
  buf+="\n\nCheck DC for casts remaining of limited use skills.\n\nLast Five Lotto Winners:";
  for i from 1 to 5 if (userdata["*"].buffpacks contains ("winner"+i.to_string())) buf+="\n"+userdata["*"].buffpacks["winner"+i.to_string()];
  visit_url(buf);
  chat_clan(clannies[d]+" wins the lotto and takes home "+books["thisLotto"].to_string()+",000 meat! See you again soon!");
  sendMeat(clannies[d],books["thisLotto"]);
  books["thisLotto"]=books["nextLotto"]-1;
  books["nextLotto"]=1;
 }else{
  print("No winner.");
  while (checkRep("Sorry, folks, no winners today. Better luck next time. See you again soon"+endsentence)!=-1)switch (endsentence){
   case "!":
    endsentence="!!";
    break;
   case "!!":
    endsentence="!!!";
    break;
   case "!!!":
    endsentence="...";
    break;
   default:
    endsentence=".";
    break;   
  }
  chat_clan("Sorry, folks, no winners today. Better luck next time. See you again soon"+endsentence);
 }
 commit(books,"books.txt");
}

void burn(){
 update(userdata,"userdata.txt");
 if ((userdata["*"].buffs[6020]< 10) || (userdata["*"].buffs[6023]< 10) || (userdata["*"].buffs[6028]< 5)){
  int price_thing = mall_price($item[recording of The Ballad of Richie Thingfinder]);
  int price_chorale = mall_price($item[recording of Chorale of Companionship]);
  int price_inigo = mall_price($item[recording of Inigo's Incantation of Inspiration]);
  int thing=530;
  int chorale=533;
  int inigo=716;
  int best;
  int next_best;
  int worst;
  int bestmax=10;
  int nextmax=10;
  int worstmax=10;
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
 int tryL=0;
 while (my_mp() == currentmp){
  use_skill(casts_to_use,farmingbuff,"Ominous Tamer");
  tryL+=1;
  if (tryL>5) break;
 }
 tryL=0;
 currentmp = my_mp();
 while (my_mp() == currentmp){
  use_skill(casts_to_use,farmingbuff,"Ominous Sauceror");
  tryL+=1;
  if (tryL>5) break;
 }
 tryL=0;
 currentmp = my_mp();
 while (my_mp() == currentmp){
  use_skill(casts_to_use,farmingbuff);
  tryL+=1;
  if (tryL>5) break;
 }
}

void handleMeat(){
 string today=now_to_string("MMMM d, yyyy");
 matcher mx=create_matcher("(\\w+) (\\d+), (\\d+)",today);
 if (!mx.find()) return;
 int month;
 int day=mx.group(2).to_int();
 int year=mx.group(3).to_int();
 switch (mx.group(1)){
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
  switch (month){
   case 1:case 3:case 5:case 7:case 8:case 10:case 12: day=31; break;
   case 2: if (isleapyear) day=29; else day=28; break;
   default: day=30;
  }
 }
 string yest=" "+day.to_string()+", "+year.to_string();
 switch (month){
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
 if (totalDMS>0){
  string exe="make "+to_string(totalDMS)+" dense meat stack";
  cli_execute(exe);
  put_closet(item_amount($item[dense meat stack]),$item[dense meat stack]);
 }
 int[string] books;
 checkOut(books,"books.txt");
 books[now_to_string("yDDD")+"ear"]=totalDMS-18;
 books[now_to_string("yDDD")+"div"]=totspent;
 int eventTimeCap=minutesToRollover();
 int event1=random(eventTimeCap-35)+30;
 int event2=random(eventTimeCap-35)+30;
 int event3=random(eventTimeCap-35)+30;
 while ((event2-event1<60)&&(event1-event2<60))event2=random(eventTimeCap-35)+30;
 while (((event3-event1<60)&&(event1-event3<60))||((event3-event2<60)&&(event2-event3<60)))event3=random(eventTimeCap-35)+30;
 books["Event1"]=event1;
 books["Event2"]=event2;
 books["Event3"]=event3;
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
 foreach skilln in lifetime if(skilln!="*") lifetime["*"]+=lifetime[skilln];
 commit(lifetime,"OB_lifetime.txt");
 set_property("_thisBreakfast","1");
}

void dailyBreakfast(){
 string rumpus=visit_url("clan_rumpus.php");
 int camp_mp_gain;
 int rollmp;
 int rolladv=numeric_modifier("adventures");
 camp_mp_gain=to_int(numeric_modifier("base resting mp")*(1+numeric_modifier("resting mp percent")/100));
 if (contains_text(rumpus,"rump1_1.gif")||contains_text(rumpus,"rump1_2.gif")) rolladv+=3;
 if (contains_text(rumpus,"rump2_3.gif")) rolladv+=5;
 if (contains_text(rumpus,"rump4_3.gif")) rolladv+=1;
 set_property("_isadventuring","yes");
 checkMail();
 handleMeat();
 set_property("totalDaysCasting",get_property("totalDaysCasting").to_int()+1);
 set_property("rolladv",rolladv);
 rollmp = my_maxmp()-1000;
 set_property("rollmp",rollmp);
 cli_execute("familiar "+stat_fam);
 cli_execute("maximize exp, -1000combat");
 print("Visiting clan rumpus room.", "blue");
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
}

void main(){try{
 print("Starting Login...");
 if (get_property("_thisBreakfast")=="") cleanPC();
 loadSettings("_breakfast;_limitBuffs;nunsVisits;rolladv;rollmp;_currentDeals");
 processLimits();
 updateLimits();
 updateDC();
 if (get_property("chatbotScript")=="") waitq (2);
 set_property("chatbotScript",chatbotScript);
 set_property("_isadventuring","");
 if (get_property("_breakfast")=="") dailyBreakfast();
 cli_execute("maximize mp");
 set_property("_isadventuring","");
 if (get_property("_checkedRaffle")=="") checkRaffle();
 print("Entering wait cycle.","green");
 int n;
 while (MinutesToRollover()>(burnMinutes+3)){
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
  n=now_to_string("HH").to_int()*60+now_to_string("mm").to_int();
  if (n<15) n+=1440;
  if (n>=(lastCheck+15)){
   if (n>1439) n-=1440;
   lastCheck=n+15;
   checkApps();
   checkMail();
  }
  waitq(5);
 }
 if (MinutesToRollover()>burnMinutes) waitq(60);
 while(get_property("_isadventuring")=="yes") waitq(1);
 set_property("_isadventuring","yes");
 print("Using excess adventures before rollover.","red");
 while (have_effect($effect[Shape of...Mole!])>0)
  (!adventure(1,$location[Mt. Molehill]));
 if (!adventure(1,$location[Mt. Molehill])){}
 visit_url("choice.php?pwd="+my_hash()+"&whichchoice=277&option=1");
 burn();
 cli_execute("familiar "+meatfarm_fam);
 cli_execute("maximize meat, +1000combat, -tie");
 int burnTurns=150-to_int(get_property("rolladv"));
 while (my_adventures()-burnTurns>0){
  if (adventure(1,$location[giant's castle])){}
  if (my_adventures()-burnTurns>12) burn();
 }
 burn();
 updateDC();
 cli_execute("uneffect cantata");
 cli_execute("familiar "+stat_fam);
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
 checkApps();
 cli_execute("exit");
}finally{
 print("Script Halted");
 releaseResources();
}}