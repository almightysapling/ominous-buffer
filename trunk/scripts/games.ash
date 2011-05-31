/* CHANGELOG:
20110301 Initial creation {
 GLOBAL-
 startGame- create the initial data for a chat game and set the game Mode flag.
 loadGame- returns the game data for game specified (or current game by default)
 saveGame- saves game data to current running game slot
 gameType- returns the type of the current running game
 pauseGame- saves supplied game data, then returns to non-game mode
 resumeGame- pause a current game (if any) and resume gameplay to requested game, return data.
 closeGame- erase specified (or current) game and return control to non-game mode.
 closeAllGames- erase all game data}
*/
record gameData{
 int[string] players;
 boolean gameStarted;
 int roundOver;
 int intervals;
};
/*
 for gamesavedata[0], players holds the information for other games.
 players["0"] contains the gameId of the current running game, or 0 if there isn't one.
 players[gameId] contains the gameType of the gameId.
*/
gameData[int] gamesavedata;
file_to_map("gameMode.txt",gamesavedata);
int gameRoulette=1;
int gameWordshot=2;

int startGame(int gType, int ivals, boolean started){
 file_to_map("gameMode.txt",gamesavedata);
 int gId=count(gamesavedata);
 int now=now_to_string("HH").to_int()*60+now_to_string("mm").to_int();
 gamesavedata[0].players[gId.to_string()]=gType;
 gamesavedata[gId].players["SYSTEM"]=0;
 gamesavedata[gId].intervals=ivals;
 gamesavedata[gId].roundOver=now+ivals;
 gamesavedata[gId].gameStarted=started;
 gamesavedata[0].players["0"]=gId;
 map_to_file(gamesavedata,"gameMode.txt");
 return gId;
}
int startGame(int gType){
 return startGame(gType,3,false);
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