integer g_iChannel;
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

integer TIME_HEAL = 20;
integer SIDE_LEFT = 0;
integer SIDE_RIGHT = 1;

integer g_iNumOfStages = 10;
integer g_iRlvLocked = 0;
integer g_iRlvOn = 0;

string g_sCurAnim = "";

string TEXTURE = "6228bf3b-180e-410c-b6e9-78b09396a241"; // Fill in your texture UUID here!

list g_lSlapSounds;
list g_lAhSounds;

SetRed(integer iFace, integer iIntensity)
{
    float fAlpha = ((1.0 / g_iNumOfStages) * iIntensity);
    llSetLinkPrimitiveParamsFast(g_iLinkBum, [PRIM_TEXTURE, iFace, TEXTURE, <1,1,1>, <0,0,0>, 0,
                                            PRIM_COLOR, iFace, <1,1,1>, fAlpha]);
}

PlayRandomSound()
{
    string sSlapSound;
    string sAhSound;
    integer iNumSounds = llGetListLength(g_lSlapSounds);
    if (iNumSounds > 1)
        sSlapSound = llList2String(g_lSlapSounds, (integer)llFrand(iNumSounds));
    else if (iNumSounds == 1)
        sSlapSound = llList2String(g_lSlapSounds, 0);
    iNumSounds = llGetListLength(g_lAhSounds);
    if (iNumSounds > 1)
        sAhSound = llList2String(g_lAhSounds, (integer)llFrand(iNumSounds));
    else if (iNumSounds == 1)
        sAhSound = llList2String(g_lAhSounds, 0);
    if (sSlapSound != "") llTriggerSound(sSlapSound, 0.5+llFrand(0.5));
    if (sAhSound != "") {
        integer iProbability = (integer)llFrand(20);
        if (iProbability % 5 == 0)
            llTriggerSound(sAhSound, 0.5+llFrand(0.5));
    }
}

Reset()
{
    llSetLinkTexture(g_iLinkBum, TEXTURE_TRANSPARENT, ALL_SIDES);
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
    if (g_iCountLeft < g_iNumOfStages) {
        if (g_iRlvOn && !g_iRlvLocked) {
            llOwnerSay("@detach=n");
            g_iRlvLocked = TRUE;
        }
        g_iCountLeft++;
        SetRed(SIDE_LEFT, g_iCountLeft);
        g_iTimeLeft = llGetUnixTime() + TIME_HEAL;
        llSetTimerEvent(1.0);
    }
    PlayRandomSound();
    llStartAnimation("spankass");
    llStartAnimation("butt left");
}

HitRight()
{
    if (g_iCountRight < g_iNumOfStages) {
        if (g_iRlvOn && !g_iRlvLocked) {
            llOwnerSay("@detach=n");
            g_iRlvLocked = TRUE;
        }
        g_iCountRight++;
        SetRed(SIDE_RIGHT, g_iCountRight);
        g_iTimeRight = llGetUnixTime() + TIME_HEAL;
        llSetTimerEvent(1.0);
    }
    PlayRandomSound();
    llStartAnimation("spankass");
    llStartAnimation("butt right");
}

ReloadSounds()
{
    integer i;
    list SLAP_SOUND = ["slap", "spank", "hit"];
    g_lSlapSounds = [];
    g_lAhSounds = [];
    for (i = 0; i < llGetInventoryNumber(INVENTORY_SOUND); i++) {
        string sName = llGetInventoryName(INVENTORY_SOUND, i);
        if (llSubStringIndex(llToLower(sName), "slap") >= 0 ||
            llSubStringIndex(llToLower(sName), "spank") >= 0 ||
            llSubStringIndex(llToLower(sName), "hit") >= 0) g_lSlapSounds += sName;
        //else g_lAhSounds += sName;
    }
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
        g_iChannel = 9999 + llRound(llFrand(9999999.0));
        g_iHandle = llListen(g_iChannel, "", "", "");
        g_iTimeRLV = llGetUnixTime() + 120;
        llSetTimerEvent(30.0);
        llOwnerSay("@versionnew="+(string)g_iChannel);
        ReloadSounds();
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
        key kAV = llDetectedKey(0);
        vector vAVPos = llList2Vector(llGetObjectDetails(kAV, [OBJECT_POS]), 0);
        // note: 10.0=whisper, 20.0=say/chat, 100.0=shout distance.
        if (llVecDist(llGetPos(), vAVPos) > 10.0) {
            llRegionSayTo(kAV, 0, "You're too far away!");
            return;
        }
        integer iLink = llDetectedLinkNumber(0);
        if (iLink==g_iLinkLeft) HitLeft();
        if (iLink==g_iLinkRight) HitRight();
    }

    timer()
    {
        integer iTimeStamp = llGetUnixTime();

        if (g_iTimeRLV) {
            if (g_iTimeRLV > iTimeStamp) llOwnerSay("@versionnew="+(string)g_iChannel);
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
            if (g_iCountLeft==0) SetRed(SIDE_LEFT, 0);
            else {
                SetRed(SIDE_LEFT, g_iCountLeft);
                g_iTimeLeft = llGetUnixTime() + TIME_HEAL;
            }
        }
        if (g_iCountRight && iTimeStamp >= g_iTimeRight) {
            g_iCountRight--;
            if (g_iCountRight==0) SetRed(SIDE_RIGHT, 0);
            else {
                SetRed(SIDE_RIGHT, g_iCountRight);
                g_iTimeRight = llGetUnixTime() + TIME_HEAL;
            }
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

    changed(integer iWhat)
    {
        if (iWhat & CHANGED_INVENTORY) ReloadSounds();
    }
}