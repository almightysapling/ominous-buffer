boolean lockMutex(string mutex){
 if (get_property(mutex)==""){
  set_property(mutex,"L");
  return true;
 }else{
  return false;
 }
}

boolean mutexFree(string mutex){
 if (get_property(mutex)==""){
  return true;
 }else{
  return false;
 }
}

void unlockMutex(string mutex){
 set_property(mutex,"");
}

void requestMutex(string mutex){
 if (!lockMutex(mutex)) {print("Waiting for free mutex: "+mutex);}
 else return;
 while (!lockMutex(mutex)) waitq(2);
}