
integer CHANNEL = 73517;
integer g_iHandle = 0;

integer g_iLinkBum;
integer g_iLinkTheme;

integer g_iLinkLeft;
integer g_iLinkRight;

integer g_iCountLeft;
integer g_iCountRight;

integer g_iTimeLeft;
integer g_iTimeRight;

integer g_iTimeRLV;

integer TIME_HEAL = 10;
integer SIDE_LEFT = 0;
integer SIDE_RIGHT = 1;

integer g_iNumOfStages = 8;
integer g_iRlvLocked = 0;
integer g_iRlvOn = 0;

string g_sCurAnim = "";

string GetTexture(integer iFace)
{
    list l = llGetLinkPrimitiveParams(g_iLinkTheme, [PRIM_TEXTURE, iFace]);
    return (string)llList2Key(l, 0);
}

SetTexture(integer iFace, string sTexture)
{
    llSetLinkPrimitiveParamsFast(g_iLinkBum, [PRIM_TEXTURE, iFace, sTexture, <1,1,1>, <0,0,0>, 0]);
}

PlayRandomAnim()
{
    if (!(llGetPermissions() & PERMISSION_TRIGGER_ANIMATION)) {
        llRequestPermissions(llGetOwner(), PERMISSION_TRIGGER_ANIMATION);
        return;
    }
    integer iNumAnims = llGetInventoryNumber(INVENTORY_ANIMATION);
    if (iNumAnims == 0) return;
    if (g_sCurAnim != "") llStopAnimation(g_sCurAnim);
    if (iNumAnims == 1) g_sCurAnim = llGetInventoryName(INVENTORY_ANIMATION, 0);
    else g_sCurAnim = llGetInventoryName(INVENTORY_ANIMATION, llFrand(iNumAnims));
    llStartAnimation(g_sCurAnim);
}

PlayRandomSound()
{
    integer iNumSounds = llGetInventoryNumber(INVENTORY_SOUND);
    string sSound;
    if (iNumSounds == 0) return;
    else if (iNumSounds == 1) sSound = llGetInventoryName(INVENTORY_SOUND, 0);
    else sSound = llGetInventoryName(INVENTORY_SOUND, llFrand(iNumSounds));
    llPlaySound(sSound, 1.0);
}

Reset()
{
    SetTexture(ALL_SIDES, TEXTURE_TRANSPARENT);
    g_iCountLeft = 0;
    g_iCountRight = 0;
    if (g_iRlvOn && g_iRlvLocked) {
        llOwnerSay("@detach=y");
        g_iRlvLocked = FALSE;
    }
    llSetTimerEvent(0.0);
}

HitLeft()
{
    if (g_iRlvOn && !g_iRlvLocked) {
        llOwnerSay("@detach=n");
        g_iRlvLocked = TRUE;
    }
    g_iCountLeft++;
    string sTexture = GetTexture(g_iCountLeft-1);
    SetTexture(SIDE_LEFT, sTexture);
    PlayRandomSound();
    PlayRandomAnim();
    g_iTimeLeft = llGetUnixTime() + TIME_HEAL;
    llSetTimerEvent(1.0);
}

HitRight()
{
    if (g_iRlvOn && !g_iRlvLocked) {
        llOwnerSay("@detach=n");
        g_iRlvLocked = TRUE;
    }
    g_iCountRight++;
    string sTexture = GetTexture(g_iCountRight-1);
    SetTexture(SIDE_RIGHT, sTexture);
    PlayRandomSound();
    PlayRandomAnim();
    g_iTimeRight = llGetUnixTime() + TIME_HEAL;
    llSetTimerEvent(1.0);
}

default
{
    state_entry()
    {
        g_iLinkLeft = osGetLinkNumber("left");
        g_iLinkRight = osGetLinkNumber("right");
        g_iLinkBum = osGetLinkNumber("bum");
        g_iLinkTheme = LINK_ROOT;
        Reset();
        llPreloadSound("slap");
        if (llGetAttached()) llRequestPermissions(llGetOwner(), PERMISSION_TRIGGER_ANIMATION);
        // RLV detection:
        g_iHandle = llListen(CHANNEL, "", "", "");
        g_iTimeRLV = llGetUnixTime() + 120;
        llSetTimerEvent(30.0);
        llOwnerSay("@versionnew="+(string)CHANNEL);
    }

    on_rez(integer i)
    {
        llResetScript();
    }

    run_time_permissions(integer iPerms)
    {

    }

    touch_end(integer i)
    {
        integer iLink = llDetectedLinkNumber(0);
        if (iLink==g_iLinkLeft && g_iCountLeft < g_iNumOfStages) HitLeft();
        if (iLink==g_iLinkRight && g_iCountRight < g_iNumOfStages) HitRight();
    }

    timer()
    {
        integer iTimeStamp = llGetUnixTime();
        
        if (g_iTimeRLV) {
            if (g_iTimeRLV > iTimeStamp) llOwnerSay("@versionnew="+(string)CHANNEL);
            else {
                // no rlv detected, we'll do without
                g_iTimeRLV = 0;
                g_iRlvOn = FALSE;
                g_iRlvLocked = FALSE;
                llSetTimerEvent(0.0);
                llListenRemove(g_iHandle);
                g_iHandle = 0;
            }
        }

        if (g_iCountLeft && iTimeStamp >= g_iTimeLeft) {
            g_iCountLeft--;
            string sTexture;
            if (g_iCountLeft==0) sTexture = TEXTURE_TRANSPARENT;
            else {
                sTexture = GetTexture(g_iCountLeft-1);
                g_iTimeLeft = llGetUnixTime() + TIME_HEAL;
            }
            SetTexture(SIDE_LEFT, sTexture);
        }
        if (g_iCountRight && iTimeStamp >= g_iTimeRight) {
            g_iCountRight--;
            string sTexture;
            if (g_iCountRight==0) sTexture = TEXTURE_TRANSPARENT;
            else {
                sTexture = GetTexture(g_iCountRight-1);
                g_iTimeRight = llGetUnixTime() + TIME_HEAL;
            }
            SetTexture(SIDE_RIGHT, sTexture);
        }
        if (g_iCountLeft==0 && g_iCountRight==0) {
            if (g_iRlvOn && g_iRlvLocked) {
                llOwnerSay("@detach=y");
                g_iRlvLocked = FALSE;
            }
            llSetTimerEvent(0.0);
            return;
        }
    }
    
    listen(integer iChannel, string sName, key kID, string sMsg)
    {
        if (llGetOwnerKey(kID) != llGetOwner()) return;
        
        if (~llSubStringIndex(sMsg, "RLV")) {
            // RLV detected w00t
            llSetTimerEvent(0.0);
            g_iTimeRLV = 0; // Reset RLV detection timer
            g_iRlvOn = TRUE;
            llListenRemove(g_iHandle);
            g_iHandle = 0;
        }
    }
}