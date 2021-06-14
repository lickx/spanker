key REMOTE_MAGIC = "de6e3a3d-be8d-4cc8-b5da-73517c1de2cb";
integer REMOTE_CH = 73517;

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

HitLeft(integer iPlaySound, integer iPlayAnim)
{
    if (g_iRlvOn && !g_iRlvLocked) {
        llOwnerSay("@detach=n");
        g_iRlvLocked = TRUE;
    }
    g_iCountLeft++;
    string sTexture = GetTexture(g_iCountLeft-1);
    SetTexture(SIDE_LEFT, sTexture);
    if (iPlaySound) PlayRandomSound();
    if (iPlayAnim) PlayRandomAnim();
    g_iTimeLeft = llGetUnixTime() + TIME_HEAL;
    llSetTimerEvent(1.0);
}

HitRight(integer iPlaySound, integer iPlayAnim)
{
    if (g_iRlvOn && !g_iRlvLocked) {
        llOwnerSay("@detach=n");
        g_iRlvLocked = TRUE;
    }
    g_iCountRight++;
    string sTexture = GetTexture(g_iCountRight-1);
    SetTexture(SIDE_RIGHT, sTexture);
    if (iPlaySound) PlayRandomSound();
    if (iPlayAnim) PlayRandomAnim();
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
        llListen(REMOTE_CH, "", "", "");
        // RLV detection:
        g_iTimeRLV = llGetUnixTime() + 120;
        llSetTimerEvent(30.0);
        llOwnerSay("@versionnew="+(string)REMOTE_CH);
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
        if (iLink==g_iLinkLeft && g_iCountLeft < g_iNumOfStages) HitLeft(TRUE, TRUE);
        if (iLink==g_iLinkRight && g_iCountRight < g_iNumOfStages) HitRight(TRUE, TRUE);
    }

    timer()
    {
        integer iTimeStamp = llGetUnixTime();
        
        if (g_iTimeRLV) {
            if (g_iTimeRLV > iTimeStamp) llOwnerSay("@versionnew="+(string)REMOTE_CH);
            else {
                // no rlv detected, we'll do without
                g_iTimeRLV = 0;
                g_iRlvOn = FALSE;
                g_iRlvLocked = FALSE;
                llSetTimerEvent(0.0);
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
            return;
        }
        
        list lParams = llParseString2List(sMsg, ["|"], []);
        if (llGetListLength(lParams) <= 1) return;
        key kMagic = llList2Key(lParams, 0);
        if (kMagic != REMOTE_MAGIC) return;
        string sCmd = llList2String(lParams, 1);
        if (sCmd == "hit") {
            integer iPlaySound = TRUE;
            if (~llListFindList(lParams, ["no_sound"])) iPlaySound = FALSE;
            integer iPlayAnim = TRUE;
            if (~llListFindList(lParams, ["no_anim"])) iPlayAnim = FALSE;
            // we just hit both sides. maybe we can alternate this instead?
            integer iGotHit;
            if (g_iCountLeft < g_iNumOfStages) {
                HitLeft(iPlaySound, iPlayAnim);
                iGotHit++;
            }
            if (g_iCountRight < g_iNumOfStages) {
                HitRight(iPlaySound, iPlayAnim);
                iGotHit++;
            }
            if (iGotHit) {
                PlayRandomSound();
                PlayRandomAnim();
            }
        } else if (sCmd == "hit_l" && g_iCountLeft < g_iNumOfStages) {
            integer iPlaySound = TRUE;
            if (~llListFindList(lParams, ["no_sound"])) iPlaySound = FALSE;
            integer iPlayAnim = TRUE;
            if (~llListFindList(lParams, ["no_anim"])) iPlayAnim = FALSE;
            HitLeft(iPlaySound, iPlayAnim);
        } else if (sCmd == "hit_r" && g_iCountRight < g_iNumOfStages) {
            integer iPlaySound = TRUE;
            if (~llListFindList(lParams, ["no_sound"])) iPlaySound = FALSE;
            integer iPlayAnim = TRUE;
            if (~llListFindList(lParams, ["no_anim"])) iPlayAnim = FALSE;
            HitRight(iPlaySound, iPlayAnim);
        } else if (sCmd == "load_theme") {
            // load a theme with marks and switch to sounds with prefix sound_prefix
            // msg syntax: REMOTE_HUD,"load_theme",sound_prefix,key1,key2 (up to 8 texture keys)
            //TODO: sound_prefix is a string and can be "default", "crop", "paddle" etc
            //      it will fill a list with sounds to use from inventory starting with this prefix
            //SetupSoundPrefix(llList2String(lParams, 2));
            
            list lTheme = llList2List(lParams, 3, -1);
            integer iLen = llGetListLength(lTheme);
            if (iLen == 0) return;
            if (iLen > 8) {
                lTheme = llList2List(lTheme, 0, 7);
                iLen = 8;
            }
            integer iMat;
            // Fill theme prim with iLen total provided textures
            for (iMat = 0; iMat < iLen; iMat++) {
                llSetLinkPrimitiveParamsFast(g_iLinkTheme, [PRIM_TEXTURE, iMat, (string)llList2Key(lTheme, iMat), <1,1,1>, <0,0,0>, 0]);
            }
            // Fill remaining textures with blanks if we got less than 8
            if (iLen < 8) {
                for (iMat = iLen; iMat < 8; iMat++) {
                    llSetLinkPrimitiveParamsFast(g_iLinkTheme, [PRIM_TEXTURE, iMat, TEXTURE_TRANSPARENT, <1,1,1>, <0,0,0>, 0]);
                }
            }
            g_iNumOfStages = iLen;
        }
    }
}