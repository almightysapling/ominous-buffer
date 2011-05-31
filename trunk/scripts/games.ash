/*
see r2
*/
record gameData{
 int[string] players;
 boolean gameStarted;
 int roundOver;
 int intervals;
 string host;
};
/*
 for gamesavedata[0], players holds the information for other games.
 players["0"] contains the gameId of the current running game, or 0 if there isn't one.
 players[gameId] contains the gameType of the gameId.
*/
gameData[int] gamesavedata;
file_to_map("gameMode.txt",gamesavedata);
int gameNone=0;
int gameRoulette=1;
int gameWordshot=2;

int startGame(int gType, int ivals, boolean started, string host){
 file_to_map("gameMode.txt",gamesavedata);
 int gId=count(gamesavedata);
 int now=now_to_string("HH").to_int()*60+now_to_string("mm").to_int();
 gamesavedata[0].players[gId.to_string()]=gType;
 gamesavedata[gId].players["SYSTEM"]=0;
 gamesavedata[gId].intervals=ivals;
 gamesavedata[gId].roundOver=now+ivals;
 gamesavedata[gId].gameStarted=started;
 gamesavedata[gId].host=host;
 gamesavedata[0].players["0"]=gId;
 map_to_file(gamesavedata,"gameMode.txt");
 return gId;
}
int startGame(int gType){
 return startGame(gType,3,false,":SYSTEM");
}

gameData loadGame(int gId){
 gameData tmp;
 if (gId==0) return tmp;
 if (gamesavedata contains gId) return gamesavedata[gId];
 return tmp;
}
gameData loadGame(){
 int t=gamesavedata[0].players["0"];
 return loadGame(t);
}

boolean saveGame(gameData game){
 file_to_map("gameMode.txt",gamesavedata);
 int t=gamesavedata[0].players["0"];
 if (t==0) return false;
 gamesavedata[t]=game;
 map_to_file(gamesavedata,"gameMode.txt");
 return true;
}

int gameType(){
 int t=gamesavedata[0].players["0"];
 if (t==0) return 0;
 return gamesavedata[0].players[t.to_string()];
}

int pauseGame(gameData game){
 file_to_map("gameMode.txt",gamesavedata);
 int t=gamesavedata[0].players["0"];
 if (!saveGame(game)) t=0;
 gamesavedata[0].players["0"]=0;
 map_to_file(gamesavedata,"gameMode.txt");
 return t;
}
int pauseGame(){
 int t=gamesavedata[0].players["0"];
 if (t==0) return 0;
 if (gamesavedata contains t) return pauseGame(gamesavedata[t]);
 return 0;
}

gameData resumeGame(int gId){
 file_to_map("gameMode.txt",gamesavedata);
 pauseGame();
 gameData tmp;
 if (!(gamesavedata contains gId)) return tmp;
 gamesavedata[0].players["0"]=gId;
 map_to_file(gamesavedata,"gameMode.txt");
 return gamesavedata[gId];
}

void closeGame(int gId){
 file_to_map("gameMode.txt",gamesavedata);
 if (gId==0) return;
 remove gamesavedata[gId];
 remove gamesavedata[0].players[gId.to_string()];
 gamesavedata[0].players["0"]=0;
 map_to_file(gamesavedata,"gameMode.txt");
}
void closeGame(){
 closeGame(gamesavedata[0].players["0"]);
}

void closeAllGames(){
 clear(gamesavedata);
 gamesavedata[0].players["0"]=0;
 gamesavedata[0].gameStarted=false;
 gamesavedata[0].intervals=0;
 map_to_file(gamesavedata,"gameMode.txt");
}

int startWordshot(int l,string h){
 gameData game=loadGame(startGame(gameWordshot,0,true,h));
 if (l==0) l=random(2)+5;
 l=min(max(5,l),7);
 string list=visit_url("http://clubefl.gr/games/wordox/"+l.to_string()+".html");
 matcher m;
 switch (l){
  case 5: m=create_matcher("</b>([\\w\\s\\r\\n]+)</p>",list);
          break;
  case 6:
  case 7: m=create_matcher("<br>([\\w\\s\\r\\n]+)<br>[\\s\\r\\n]*<br>",list);
          break;
 }
 if (m.find()){
  list=m.group(1);
  remove game.players["SYSTEM"];
  string[int] bigList=split_string(list,"\\W");
  l=count(bigList);
  list="";
  while(list=="") list=bigList[random(l)];
  game.players[list]=1;
  game.intervals=3;
  game.roundOver=0;
  saveGame(game);
 }else{
  closeGame();
  return -1;
 }
 return gamesavedata[0].players["0"];
}
int startWordshot(string host){
 return startWordshot(0,host);
}