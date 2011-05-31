record message{
	string sender;
	int senderId;
	string date;
	int id;
	string text;
	int meat;
	int[item] things;
};

boolean kmail(string to, string message, int meat, int[item] stuff){
 if (meat > my_meat()){
  print("Not enough meat to send.");
  return false;
 }
 string itemstring = "";
 int j = 0;
 string[int] itemstrings;
 foreach i in stuff{
  if (is_tradeable(i)||is_giftable(i)){
   j=j+1;
   itemstring=itemstring+"&howmany"+j+"="+stuff[i]+"&whichitem"+j+"="+to_int(i);
   if (j>10){
    itemstrings[count(itemstrings)]=itemstring;
    itemstring='';
    j=0;
   }
  }
 }
 if (itemstring!="") itemstrings[count(itemstrings)]=itemstring;
 if (count(itemstrings)==0) itemstrings[0]="";
 foreach q in itemstrings{
  string url=visit_url("sendmessage.php?pwd=&action=send&towho="+to+"&message="+message+"&sendmeat="+meat+itemstrings[q]);
  if (contains_text(url,"That player cannot receive Meat or items")){
   print("Player may not receive meat/items.");
   return false;
  }
  if (!contains_text(url,"Message sent.")){
   print("Unknown error. The message probably did not go through.");
   return false;
  }
 }
 return true;
}

boolean kmail(string to, string message, int[item] stuff){
 return kmail(to,message,0,stuff);
}

boolean kmail(string to, string message, int meat){
 int[item] nothing; 
 return kmail(to,message,meat,nothing);
}

boolean kmail(string to, string message){
 int[item] nothing;
 return kmail(to,message,0,nothing);
}

string findAttachments(string kmail){
 matcher kmailattachments=create_matcher("<center>(.+)",kmail);
 if(kmailattachments.find()) return kmailattachments.group(1);
 return "";		
}

string substring(string source, string start, string end){
 if (start!=""){
  if (!source.contains_text(start)) return "";
  source=substring(source,index_of(source,start)+length(start));
 }
 if (end=="") return source;
 if (!source.contains_text(end)) return "";
 return substring(source,0,index_of(source,end));
}

message[int] parseMail(){
 message[int] parsedmail;
 string temp=visit_url("messages.php");
 if (contains_text(temp,"There are no messages in this mailbox."))
  return parsedmail;
 temp=substring(temp,index_of(temp,"checkbox name=\"")+15);
 string[int] km=split_string(temp,"checkbox name=\"");
 for i from 0 upto (count(km)-1){
  parsedmail[i+1].id=to_int(substring(km[i],3,index_of(km[i],"\"")));
  parsedmail[i+1].text=substring(km[i],"<blockquote>","</blockquote>");
  if (contains_text(parsedmail[i+1].text,"<center>"))
     parsedmail[i+1].text=substring(parsedmail[i+1].text,"","<center>");
  temp=substring(km[i],index_of(km[i],"showplayer.php"));
  parsedmail[i+1].sender=substring(temp,">","</a>");
  parsedmail[i+1].senderId=to_int(substring(temp,"(#",")"));
  temp=substring(km[i],index_of(km[i],"<b>Date:</b> ")+13);
  parsedmail[i+1].date=substring(temp,"","<");
  string table=findAttachments(km[i]);
  parsedmail[i+1].meat=extract_meat(table);
  parsedmail[i+1].things=extract_items(table);	
 }
 return parsedmail;
}

boolean deleteMail(int id){
 string del=visit_url("messages.php?the_action=delete&box=Inbox&pwd&sel"+id+"=checked");
 if (contains_text(del,"1 message deleted.")){
  return true;
 }
 return false;
}

void junkMail(string dump){
 message[int] mail=parseMail();
 for i from 1 upto (count(mail)) if (mail[i].sender==dump) deleteMail(mail[i].id);	
 return;
}
