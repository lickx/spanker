
integer g_iChannel;
integer g_iHandle = 0;

integer g_iLinkMesh;
integer SIDE_LEFT = 0;
integer SIDE_RIGHT = 1;

integer g_iLinkLeft;
integer g_iCountLeft;
integer g_iTimeLeft;

integer g_iLinkRight;
integer g_iCountRight;
integer g_iTimeRight;

integer NUM_STAGES = 10;
integer TIME_HEAL = 20;
float   NEAR_DIST = 10.0; //10.0=whisper, 20.0=say/chat, 100.0=shout distance

integer g_iTimerRLV;
integer g_iRlvLocked = FALSE;
integer g_iRlvOn = FALSE;

string g_sCurAnim = "";
string g_sTexture; // autodetected

list g_lSpankSounds;
list g_lMoanSounds;

SetRed(integer iFace, integer iIntensity)
{
    float fAlpha = ((1.0 / NUM_STAGES) * iIntensity);
    llSetLinkPrimitiveParamsFast(g_iLinkMesh, [PRIM_TEXTURE, iFace, g_sTexture, <1,1,1>, <0,0,0>, 0,
                                            PRIM_COLOR, iFace, <1,1,1>, fAlpha]);
}

MakeSound()
{
    string sSpankSound;
    string sMoanSound;
    integer iNumSounds = llGetListLength(g_lSpankSounds);
    if (iNumSounds > 0)
        sSpankSound = llList2String(g_lSpankSounds, (integer)llFrand(iNumSounds));
    iNumSounds = llGetListLength(g_lMoanSounds);
    if (iNumSounds > 0)
        sMoanSound = llList2String(g_lMoanSounds, (integer)llFrand(iNumSounds));
    if (sSpankSound != "") llTriggerSound(sSpankSound, 0.5+llFrand(0.5));
    if (sMoanSound != "") {
        integer iProbability = (integer)llFrand(20);
        if (iProbability % 5 == 0)
            llTriggerSound(sMoanSound, 0.5+llFrand(0.5));
    }
}

Reset()
{
    llSetTimerEvent(0.0);
    g_iCountLeft = 0;
    SetRed(SIDE_LEFT, g_iCountLeft);
    g_iCountRight = 0;
    SetRed(SIDE_RIGHT, g_iCountRight);
    if (g_iRlvOn && g_iRlvLocked) {
        llOwnerSay("@detach=y");
        g_iRlvLocked = FALSE;
    }
}

HitLeft()
{
    if (g_iCountLeft < NUM_STAGES) {
        if (g_iRlvOn && !g_iRlvLocked) {
            llOwnerSay("@detach=n");
            g_iRlvLocked = TRUE;
        }
        g_iCountLeft++;
        SetRed(SIDE_LEFT, g_iCountLeft);
        g_iTimeLeft = llGetUnixTime() + TIME_HEAL;
        llSetTimerEvent(1.0);
    }
    MakeSound();
    llStartAnimation("spank body");
    llStartAnimation("spank left");
}

HitRight()
{
    if (g_iCountRight < NUM_STAGES) {
        if (g_iRlvOn && !g_iRlvLocked) {
            llOwnerSay("@detach=n");
            g_iRlvLocked = TRUE;
        }
        g_iCountRight++;
        SetRed(SIDE_RIGHT, g_iCountRight);
        g_iTimeRight = llGetUnixTime() + TIME_HEAL;
        llSetTimerEvent(1.0);
    }
    MakeSound();
    llStartAnimation("spank body");
    llStartAnimation("spank right");
}

ReloadSounds()
{
    integer i;
    g_lSpankSounds = [];
    g_lMoanSounds = [];
    for (i = 0; i < llGetInventoryNumber(INVENTORY_SOUND); i++) {
        string sName = llGetInventoryName(INVENTORY_SOUND, i);
        if (~llSubStringIndex(llToUpper(sName), "SPANK")) g_lSpankSounds += sName;
        else g_lMoanSounds += sName;
        llPreloadSound(sName);
    }
}

default
{
    state_entry()
    {
        g_iLinkLeft = osGetLinkNumber("left");
        g_iLinkRight = osGetLinkNumber("right");
        g_iLinkMesh = osGetLinkNumber("mesh");
        g_sTexture = llList2String(llGetLinkPrimitiveParams(g_iLinkMesh, [PRIM_TEXTURE, 0]), 0);
        Reset();
        if (llGetAttached()) llRequestPermissions(llGetOwner(), PERMISSION_TRIGGER_ANIMATION | PERMISSION_TAKE_CONTROLS);
        // RLV detection:
        g_iChannel = 9999 + llRound(llFrand(9999999.0));
        g_iHandle = llListen(g_iChannel, "", "", "");
        g_iTimerRLV = llGetUnixTime() + 120;
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
        if (iPerms & PERMISSION_TAKE_CONTROLS) llTakeControls(CONTROL_DOWN, TRUE, TRUE);
    }

    touch_end(integer i)
    {
        key kAV = llDetectedKey(0);
        vector vAVPos = llList2Vector(llGetObjectDetails(kAV, [OBJECT_POS]), 0);
        if (llVecDist(llGetPos(), vAVPos) > NEAR_DIST) {
            if (llGetAgentSize(kAV) != ZERO_VECTOR) llRegionSayTo(kAV, 0, "You're too far away!");
            else llInstantMessage(kAV, "You're too far away!");
            return;
        }
        integer iLink = llDetectedLinkNumber(0);
        if (iLink==g_iLinkLeft) HitLeft();
        else if (iLink==g_iLinkRight) HitRight();
    }

    timer()
    {
        integer iTimeStamp = llGetUnixTime();

        if (g_iTimerRLV) {
            if (g_iTimerRLV > iTimeStamp) llOwnerSay("@versionnew="+(string)g_iChannel);
            else {
                // no rlv detected, we'll do without
                g_iTimerRLV = 0;
                g_iRlvOn = FALSE;
                g_iRlvLocked = FALSE;
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
        if (g_iCountLeft==0 && g_iCountRight==0 && g_iTimerRLV==0) {
            if (g_iRlvOn && g_iRlvLocked) {
                llOwnerSay("@detach=y");
                g_iRlvLocked = FALSE;
            }
            llSetTimerEvent(0.0);
        }
    }

    listen(integer iChannel, string sName, key kID, string sMsg)
    {
        if (llGetOwnerKey(kID) != llGetOwner()) return;

        if (~llSubStringIndex(sMsg, "RLV")) {
            // RLV detected w00t
            llSetTimerEvent(0.0);
            g_iTimerRLV = 0; // Reset RLV detection timer
            g_iRlvOn = TRUE;
            llListenRemove(g_iHandle);
            g_iHandle = 0;
        }
    }

    changed(integer iWhat)
    {
        if (iWhat & CHANGED_INVENTORY) ReloadSounds();
    }

    link_message(integer iLink, integer iSide, string sMethod, key kID)
    {
        // note: sMethod TBI; could be HAND, CANE etc
        if (iSide == 0) HitLeft();
        else if (iSide == 1) HitRight();
        else if (iSide == -1) {
            // no side specified, apply to both
            HitLeft();
            HitRight();
        }
    }
}