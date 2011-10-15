record gameData{
 int[string] players;
 string[int] data;
 boolean gameStarted;
 int roundOver;
 int intervals;
 string host;
};
/*
About gamesavedata["."]:
 gamesavedata["."].data[0] contains the gameId of the current running game, or 0 if there isn't one.
 gamesavedata["."].players[gameId] contains the gameType of the gameId.
*/
gameData[string] gamesavedata;
int gameNone=0;
int gameRoulette=1;
int gameWordshot=2;
int gameLotto=4;

string startGame(int gType, int ivals, boolean started, string host){
 file_to_map("gameMode.txt",gamesavedata);
 string gId=count(gamesavedata).to_string();
 while(gamesavedata contains gId) gId=to_string(gId.to_int()+1);
 int now=now_to_string("HH").to_int()*60+now_to_string("mm").to_int();
 gamesavedata["."].players[gId]=gType;
 gamesavedata[gId].players[":SYSTEM"]=0;
 gamesavedata[gId].intervals=ivals;
 gamesavedata[gId].roundOver=now+ivals;
 gamesavedata[gId].gameStarted=started;
 gamesavedata[gId].host=host;
 gamesavedata["."].data[0]=gId;
 map_to_file(gamesavedata,"gameMode.txt");
 return gId;
}
string startGame(int gType){
 return startGame(gType,3,false,":SYSTEM");
}

gameData loadGame(string gId){
 gameData tmp;
 file_to_map("gameMode.txt",gamesavedata);
 if (gamesavedata contains gId) return gamesavedata[gId];
 return tmp;
}
gameData loadGame(){
 string t=gamesavedata["."].data[0];
 return loadGame(t);
}

boolean saveGame(gameData game){
 file_to_map("gameMode.txt",gamesavedata);
 string t=gamesavedata["."].data[0];
 if (t=="") return false;
 gamesavedata[t]=game;
 map_to_file(gamesavedata,"gameMode.txt");
 return true;
}

int gameType(){
 file_to_map("gameMode.txt",gamesavedata);
 string t=gamesavedata["."].data[0];
 if (t=="") return 0;
 return gamesavedata["."].players[t];
}

string pauseGame(gameData game){
 file_to_map("gameMode.txt",gamesavedata);
 string t=gamesavedata["."].data[0];
 if (!saveGame(game)) t="";
 gamesavedata["."].data[0]="";
 map_to_file(gamesavedata,"gameMode.txt");
 return t;
}
string pauseGame(){
 string t=gamesavedata["."].data[0];
 if (gamesavedata contains t) return pauseGame(gamesavedata[t]);
 return "";
}

gameData resumeGame(string gId){
 file_to_map("gameMode.txt",gamesavedata);
 pauseGame();
 gameData tmp;
 if (!(gamesavedata contains gId)) return tmp;
 gamesavedata["."].data[0]=gId;
 map_to_file(gamesavedata,"gameMode.txt");
 return gamesavedata[gId];
}

void closeGame(string gId){
 file_to_map("gameMode.txt",gamesavedata);
 if(!(gamesavedata contains gId)) return;
 remove gamesavedata[gId];
 remove gamesavedata["."].players[gId];
 gamesavedata["."].data[0]="";
 map_to_file(gamesavedata,"gameMode.txt");
}
void closeGame(){
 file_to_map("gameMode.txt",gamesavedata);
 closeGame(gamesavedata["."].data[0]);
}

void closeAllGames(){
 clear(gamesavedata);
 gamesavedata["."].data[0]="";
 gamesavedata["."].gameStarted=false;
 gamesavedata["."].intervals=0;
 map_to_file(gamesavedata,"gameMode.txt");
}

string startWordshot(int l,string h){
 gameData game=loadGame(startGame(gameWordshot,0,true,h));
 if (l==0) l=random(3)+4;
 l=min(max(2,l),10);
 boolean[string] bigList;
 string[int] words;
 file_to_map("wordshot/"+l+".txt",bigList);
 foreach w in bigList words[count(words)]=w;
 l=count(words);
 h=words[random(l)];
 game.players[h]=1;
 print("Word: "+h);
 game.intervals=3;
 game.roundOver=0;
 saveGame(game);
 return gamesavedata["."].data[0];
}
string startWordshot(string host){
 return startWordshot(0,host);
}

void russianRoulette(string sender, string msg){
print("RR");
 matcher m;
 int now=now_to_string("HH").to_int()*60+now_to_string("mm").to_int();
 gameData game=loadGame();
 int v=-1;
 if (!game.gameStarted&&(sender!=":SYSTEM")){//Get contestants, until time is up.
  m=create_matcher("(?i)(i am|\\Win\\W|i'll play)",msg);
  if((!find(m))||(game.roundOver<now))return;
  game.players[sender]=0;
  saveGame(game);
 }else if(sender!=":SYSTEM"){
  m=create_matcher("(\\d+)",msg);
  if(find(m)) v=group(m,1).to_int();
  foreach p,val in game.players if(val==v){
   chat_clan(p+" has "+val+".");
   return;
  }
 }
print("Players: "+count(game.players).to_string());
 if(!(game.players contains sender))return;
 if((sender!=":SYSTEM")&&(v>0)&&(v<=(count(game.players)-1))&&(game.players[sender]==0)) game.players[sender]=v;
 if(sender!=":SYSTEM"){
  saveGame(game);
  return;
 }
 v=count(game.players)-1;
 switch(msg){
  case "START":
   chat_clan("Okay, looks like we are starting with "+v.to_string()+" players.");
   wait(5);
   chat_clan("Everybody: 1-"+v.to_string()+"!");
   game.gameStarted=true;
   game.roundOver=now+game.intervals+1;
   foreach p in game.players game.players[p]=0;
   saveGame(game);
   break;
  case "MORE":
   if (game.gameStarted) chat_clan("1 more minute guys. Make your choices.");
   else chat_clan("Anybody else?");
   game.roundOver=now+2;
   saveGame(game);
   break;
  case "MOVE":
   chat_clan("Okay, times up.");
   string t;
   int nextn=1;
   boolean f;
   foreach pn,num in game.players if (num==0) {
    f=false;
    while (!f){
     f=true;
     foreach pn2,num2 in game.players if (num2==nextn) f=false;
     if (!f) nextn+=1;
    }
    game.players[pn]=nextn;
    chat_clan(pn+" is "+nextn.to_int()+".");
   } //fall through
  case "NEXT":
   chat_clan("Let's roll...");
   wait(3);
   int l=random(v)+1;
   string loser;
   foreach pn,num in game.players if (num==v) loser=pn;
   chat_clan("Rolling 1d"+v.to_string()+" for myself gives "+l.to_string()+". "+loser+" is out!");
   remove game.players[loser];
   foreach pn in game.players game.players[pn]=0;
   saveGame(game);
   break;
  default:
   
   break;
 }
 saveGame(game);
}

string wordshot(string sender, string guess){
 gameData game=loadGame();
 if(game.intervals==-1)return guess;
 string word;
 foreach k,v in game.players if (v==1) word=k;
 if(guess.contains_text(" ")||(guess.length()!=word.length())){
  return guess;
 }
 boolean[string]wordList;
 file_to_map("wordshot/"+word.length()+".txt");
 int[string] koldict;
 file_to_map("koldict.txt",koldict);
 if ((!(wordList contains guess))&&(!(koldict contains guess))){
  chat_private(sender,guess+" isn't a valid word.");
  return "x";
 }
 if (guess==word){
  game.players[sender]=2;
  game.intervals=-1;
  saveGame(game);
  return "x";
 }
 int[string] breakW;
 int[string] breakG;
 for x from 1 to length(word) breakW[char_at(word,x-1)]+=1;
 for x from 1 to length(word) breakG[char_at(guess,x-1)]+=1;
 int m=0;
 foreach k,v in breakW if (breakG contains k) m+=min(breakG[k],v);
 chat_private(sender,m.to_string());
 if (m>game.intervals) {
  game.intervals=m;
  chat_clan("We have a"+(m==8?"n ":" ")+m.to_string()+"!");
 }
 if (m==0){
  if(game.roundOver==0) chat_clan("First 0!");
  game.roundOver+=1;
 }
 saveGame(game);
 return "x";
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
  closeGame();
 }
}

void coreGameCycle(){
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
}