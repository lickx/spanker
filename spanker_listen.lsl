
/*

 Small API for 3rd party stuff to interface with the spanker
 -----------------------------------------------------------

 All messages send to the listener need to be prefixed with PREFIX
 1st parameter is the method used, can be HAND or CANE or anything else
 2nd parameter is optional LEFT or RIGHT, if omitted will default to both

 Example:

   llRegionSayTo(g_kTarget, CHANNEL, PREFIX+"|HAND|LEFT");

 The following channels can be used:
 
  -5550555 = bottom
  -6660666 = chest

*/

string PREFIX = "spanker-1.0";

integer CHANNEL = -5550555;

default
{
    state_entry()
    {
        llListen(CHANNEL, "", "", "");
    }

    on_rez(integer i)
    {
        if (llGetAttached()) llResetScript();
    }

    listen(integer iChannel, string sName, key kID, string sMsg)
    {
        list lParams = llParseString2List(sMsg, ["|"], []);
        string sPrefix = llList2String(lParams, 0);
        if (sPrefix != PREFIX) return;

        string sMethod;
        if (llGetListLength(lParams) >= 2) {
            sMethod = llToUpper(llList2String(lParams, 1));
        } else return;

        integer iSide = -1;
        if (llGetListLength(lParams) == 3) {
            iSide = (llToUpper(llList2String(lParams, 2)) == "RIGHT");
        }
        
        llMessageLinked(LINK_THIS, iSide, sMethod, NULL_KEY);
    }
}