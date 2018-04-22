class ScrnDamTypeMagnum44Pistol extends DamTypeMagnum44Pistol;

static function AwardKill(KFSteamStatsAndAchievements KFStatsAndAchievements, KFPlayerController Killer, KFMonster Killed )
{
    local SRStatsBase stats;
    
    // do not count kills of decapitated specimens - those are counted in ScoredHeadshot()
    if ( Killed != none && Killed.bDecapitated )
        return;

    stats = SRStatsBase(KFStatsAndAchievements);
    if( stats !=None && stats.Rep!=None )
        stats.Rep.ProgressCustomValue(Class'ScrnBalanceSrv.ScrnPistolKillProgress',1);
}

static function ScoredHeadshot(KFSteamStatsAndAchievements KFStatsAndAchievements, class<KFMonster> MonsterClass, bool bLaserSightedM14EBRKill)
{
    local SRStatsBase stats;
    
    if ( KFStatsAndAchievements != none ) {
        if ( Default.bSniperWeapon )
            KFStatsAndAchievements.AddHeadshotKill(bLaserSightedM14EBRKill);
            
        stats = SRStatsBase(KFStatsAndAchievements);
        if( stats !=None && stats.Rep!=None )
            stats.Rep.ProgressCustomValue(Class'ScrnBalanceSrv.ScrnPistolKillProgress',1);
    }
}

static function AwardDamage(KFSteamStatsAndAchievements KFStatsAndAchievements, int Amount)
{
    local SRStatsBase stats;
    
    stats = SRStatsBase(KFStatsAndAchievements);
    if( stats !=None && stats.Rep!=None )
        stats.Rep.ProgressCustomValue(Class'ScrnBalanceSrv.ScrnPistolDamageProgress',Amount);
}

defaultproperties
{
    WeaponClass=Class'ScrnBalanceSrv.ScrnMagnum44Pistol'
    HeadShotDamageMult=1.20 // v8: up from 1.1
}
