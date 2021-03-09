class ScrnKrissMMedicGun extends KrissMMedicGun;

var         name             ReloadShortAnim;
var         float             ReloadShortRate;

var transient bool  bShortReload;

// copy-pasted to add (MagCapacity+1)
simulated function bool AllowReload()
{
    UpdateMagCapacity(Instigator.PlayerReplicationInfo);

    if ( KFInvasionBot(Instigator.Controller) != none && !bIsReloading &&
        MagAmmoRemaining < MagCapacity && AmmoAmount(0) > MagAmmoRemaining )
        return true;

    if ( KFFriendlyAI(Instigator.Controller) != none && !bIsReloading &&
        MagAmmoRemaining < MagCapacity && AmmoAmount(0) > MagAmmoRemaining )
        return true;


    if( FireMode[0].IsFiring() || FireMode[1].IsFiring() ||
           bIsReloading || MagAmmoRemaining > MagCapacity ||
           ClientState == WS_BringUp ||
           AmmoAmount(0) <= MagAmmoRemaining ||
                   (FireMode[0].NextFireTime - Level.TimeSeconds) > 0.1 )
        return false;
    return true;
}

exec function ReloadMeNow()
{
    local float ReloadMulti;
    
    if(!AllowReload())
        return;
    if ( bHasAimingMode && bAimingRifle )
    {
        FireMode[1].bIsFiring = False;

        ZoomOut(false);
        if( Role < ROLE_Authority)
            ServerZoomOut(false);
    }
    
    if ( KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo) != none && KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo).ClientVeteranSkill != none )
        ReloadMulti = KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo).ClientVeteranSkill.Static.GetReloadSpeedModifier(KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo), self);
    else
        ReloadMulti = 1.0;
        
    bIsReloading = true;
    ReloadTimer = Level.TimeSeconds;
    bShortReload = MagAmmoRemaining > 0;
    if ( bShortReload )
        ReloadRate = Default.ReloadShortRate / ReloadMulti;
    else
        ReloadRate = Default.ReloadRate / ReloadMulti;
        
    if( bHoldToReload )
    {
        NumLoadedThisReload = 0;
    }
    ClientReload();
    Instigator.SetAnimAction(WeaponReloadAnim);
    if ( Level.Game.NumPlayers > 1 && KFGameType(Level.Game).bWaveInProgress && KFPlayerController(Instigator.Controller) != none &&
        Level.TimeSeconds - KFPlayerController(Instigator.Controller).LastReloadMessageTime > KFPlayerController(Instigator.Controller).ReloadMessageDelay )
    {
        KFPlayerController(Instigator.Controller).Speech('AUTO', 2, "");
        KFPlayerController(Instigator.Controller).LastReloadMessageTime = Level.TimeSeconds;
    }
}

simulated function ClientReload()
{
    local float ReloadMulti;
    if ( bHasAimingMode && bAimingRifle )
    {
        FireMode[1].bIsFiring = False;

        ZoomOut(false);
        if( Role < ROLE_Authority)
            ServerZoomOut(false);
    }
    
    if ( KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo) != none && KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo).ClientVeteranSkill != none )
        ReloadMulti = KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo).ClientVeteranSkill.Static.GetReloadSpeedModifier(KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo), self);
    else
        ReloadMulti = 1.0;
        
    bIsReloading = true;
    if (MagAmmoRemaining <= 0)
    {
        PlayAnim(ReloadAnim, ReloadAnimRate*ReloadMulti, 0.1);
    }
    else if (MagAmmoRemaining >= 1)
    {
        PlayAnim(ReloadShortAnim, ReloadAnimRate*ReloadMulti, 0.1);
    }
}

function AddReloadedAmmo()
{
    local int a;
    
    UpdateMagCapacity(Instigator.PlayerReplicationInfo);

    a = MagCapacity;
    if ( bShortReload )
        a++; // 1 bullet already bolted
    
    if ( AmmoAmount(0) >= a )
        MagAmmoRemaining = a;
    else
        MagAmmoRemaining = AmmoAmount(0);

    if ( PlayerController(Instigator.Controller) != none && KFSteamStatsAndAchievements(PlayerController(Instigator.Controller).SteamStatsAndAchievements) != none )
    {
        KFSteamStatsAndAchievements(PlayerController(Instigator.Controller).SteamStatsAndAchievements).OnWeaponReloaded();
    }
}
        
    
defaultproperties
{
    ReloadShortAnim="Reload"
    ReloadShortRate=1.89//2.276
    ReloadAnim="Reload"
    ReloadAnimRate=1.2
    ReloadRate=3.05 //3.33
    
    HealAmmoCharge=0
    AmmoRegenRate=0.25 // down from 0.2
    Weight=5.000000
    FireModeClass(0)=Class'ScrnBalanceSrv.ScrnKrissMFire'
    FireModeClass(1)=Class'ScrnBalanceSrv.ScrnKrissMAltFire'
    PickupClass=Class'ScrnBalanceSrv.ScrnKrissMPickup'
    bReduceMagAmmoOnSecondaryFire=False
    ItemName="Kriss Medic Gun SE"
}
