integer g_iLinkLeft;
integer g_iLinkRight;

integer g_iCountLeft;
integer g_iCountRight;

integer g_iTimeLeft;
integer g_iTimeRight;

integer TIME_HEAL = 10;
integer SIDE_LEFT = 0;
integer SIDE_RIGHT = 1;

string GetTexture(integer iLink, integer iFace)
{
    list l = llGetLinkPrimitiveParams(iLink, [PRIM_TEXTURE, iFace]);
    return (string)llList2Key(l, 0);
}

SetTexture(integer iLink, integer iFace, string sTexture)
{
    llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_TEXTURE, iFace, sTexture, <1,1,1>, <0,0,0>, 0]);
}

default
{
    state_entry()
    {
        g_iLinkLeft = osGetLinkNumber("left");
        g_iLinkRight = osGetLinkNumber("right");
        SetTexture(LINK_THIS, ALL_SIDES, TEXTURE_TRANSPARENT);
        g_iCountLeft = 0;
        g_iCountRight = 0;
        llSetTimerEvent(0.0);
        llPreloadSound("slap");
        if (llGetAttached()) llRequestPermissions(llGetOwner(), PERMISSION_TRIGGER_ANIMATION);
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
        vector vMyPos = llGetPos();
        key kTheirID = llDetectedKey(0);
        vector vTheirPos = llList2Vector(llGetObjectDetails(kTheirID, [PRIM_POSITION]), 0);
        float fDist = llVecDist(vMyPos, vTheirPos);
        if (fDist > 20.0 && llGetOwner() != kTheirID) return;
        integer iLink = llDetectedLinkNumber(0);
        if (iLink==g_iLinkLeft) {
            if (g_iCountLeft < 8) {
                g_iCountLeft++;
                string sTexture = GetTexture(iLink, g_iCountLeft-1);
                SetTexture(LINK_THIS, SIDE_LEFT, sTexture);
                llPlaySound("slap", 1.0);
                if (llGetPermissions() & PERMISSION_TRIGGER_ANIMATION) llStartAnimation("standing_hit");
                g_iTimeLeft = llGetUnixTime() + TIME_HEAL;
                llSetTimerEvent(1.0);

            } else return;
        } else if (iLink==g_iLinkRight) {
            if (g_iCountRight < 8) {
                g_iCountRight++;
                string sTexture = GetTexture(iLink, g_iCountRight-1);
                SetTexture(LINK_THIS, SIDE_RIGHT, sTexture);
                llPlaySound("slap", 1.0);
                if (llGetPermissions() & PERMISSION_TRIGGER_ANIMATION) llStartAnimation("standing_hit");
                g_iTimeRight = llGetUnixTime() + TIME_HEAL;
                llSetTimerEvent(1.0);
            } else return;
        } else return;
    }

    timer()
    {
        integer iTimeStamp = llGetUnixTime();

        if (g_iCountLeft && iTimeStamp >= g_iTimeLeft) {
            g_iCountLeft--;
            string sTexture;
            if (g_iCountLeft==0) sTexture = TEXTURE_TRANSPARENT;
            else {
                sTexture = GetTexture(g_iLinkLeft, g_iCountLeft-1);
                g_iTimeLeft = llGetUnixTime() + TIME_HEAL;
            }
            SetTexture(LINK_THIS, SIDE_LEFT, sTexture);
        }
        if (g_iCountRight && iTimeStamp >= g_iTimeRight) {
            g_iCountRight--;
            string sTexture;
            if (g_iCountRight==0) sTexture = TEXTURE_TRANSPARENT;
            else {
                sTexture = GetTexture(g_iLinkRight, g_iCountRight-1);
                g_iTimeRight = llGetUnixTime() + TIME_HEAL;
            }
            SetTexture(LINK_THIS, SIDE_RIGHT, sTexture);
        }
        if (g_iCountLeft==0 && g_iCountRight==0) {
            llSetTimerEvent(0.0);
            return;
        }
    }
}