class ScrnHuskGunProjectile extends HuskGunProjectile;


//overrided to use alternate burning mechanism
simulated function HurtRadius( float DamageAmount, float DamageRadius, class<DamageType> DamageType, float Momentum, vector HitLocation )
{
    local actor Victims;
    local float damageScale, dist;
    local vector dirs;
	local int NumKilled;
	local Pawn P;
	local KFMonster KFMonsterVictim;
	local KFPawn KFP;
	local array<Pawn> CheckedPawns;
	local int i;
	local bool bAlreadyChecked;
	
	//local int OldHealth;

    if ( bHurtEntry )
        return;

    bHurtEntry = true;

    foreach CollidingActors (class 'Actor', Victims, DamageRadius, HitLocation) {
		// null pawn variables here just to be sure they didn't left from previous iteration
		// and waste another day of my life to looking for this fucking bug -- PooSH /totallyPissedOff!!!
		P = none;
		KFMonsterVictim = none;
		KFP = none;

		// don't let blast damage affect fluid - VisibleCollisingActors doesn't really work for them - jag
        if( (Victims != self) && (Victims != Instigator) &&(Hurtwall != Victims)
				&& (Victims.Role == ROLE_Authority) && !Victims.IsA('FluidSurfaceInfo')
				&& ExtendedZCollision(Victims)==None && KFBulletWhipAttachment(Victims)==None )
        {
            dirs = Victims.Location - HitLocation;
            dist = FMax(1,VSize(dirs));
            dirs = dirs/dist;
            damageScale = 1 - FMax(0,(dist - Victims.CollisionRadius)/DamageRadius);
            if ( Instigator == None || Instigator.Controller == None )
                Victims.SetDelayedDamageInstigatorController( InstigatorController );
            if ( Victims == LastTouched )
                LastTouched = None;

			P = Pawn(Victims);

			if( P != none ) {
		        for (i = 0; i < CheckedPawns.Length; i++) {
		        	if (CheckedPawns[i] == P) {
						bAlreadyChecked = true;
						break;
					}
				}

				if( bAlreadyChecked )
				{
					bAlreadyChecked = false;
					P = none;
					continue;
				}

    			if( KFMonsterVictim != none && KFMonsterVictim.Health <= 0 ) {
                    KFMonsterVictim = none;
    			}

				KFMonsterVictim = KFMonster(Victims);
                KFP = KFPawn(Victims);

                if( KFMonsterVictim != none )
                    damageScale *= KFMonsterVictim.GetExposureTo(HitLocation);
                else if( KFP != none )
				    damageScale *= KFP.GetExposureTo(HitLocation);

				CheckedPawns[CheckedPawns.Length] = P;

				if ( damageScale <= 0)
					continue;
			}
			
                
			if ( KFMonsterVictim != none && class'ScrnBalance'.default.Mut.BurnMech != none) {
				class'ScrnBalance'.default.Mut.BurnMech.MakeBurnDamage(
					KFMonsterVictim,
					damageScale * DamageAmount,
					Instigator,
					Victims.Location - 0.5 * (Victims.CollisionHeight + Victims.CollisionRadius) * dirs,
					(damageScale * Momentum * dirs),
					DamageType
				);
			}
			else {
				Victims.TakeDamage
				(
					damageScale * DamageAmount,
					Instigator,
					Victims.Location - 0.5 * (Victims.CollisionHeight + Victims.CollisionRadius) * dirs,
					(damageScale * Momentum * dirs),
					DamageType
				);
			}
			
            // if ( KFMonsterVictim != none ) 
				// log("ScrnHuskGunProjectile.HurtRadius(): Victim = " @ String(Victims) 
					// @ "Damage = " $ String(int(damageScale * DamageAmount)) 
					// @ "("$damageScale$"*"$DamageAmount$")"
					// @ "Perked Damage = " $ String(OldHealth-KFMonsterVictim.Health) @ "("$OldHealth$" - "$KFMonsterVictim.Health$")"
					// ,class.outer.name);			
			
            if (Vehicle(Victims) != None && Vehicle(Victims).Health > 0)
                Vehicle(Victims).DriverRadiusDamage(DamageAmount, DamageRadius, InstigatorController, DamageType, Momentum, HitLocation);

			if( Role == ROLE_Authority && KFMonsterVictim != none && KFMonsterVictim.Health <= 0 )
            {
                NumKilled++;
            }
        }
    }
	/*
    if ( (LastTouched != None) && (LastTouched != self) && (LastTouched != Instigator) &&
        (LastTouched.Role == ROLE_Authority) && !LastTouched.IsA('FluidSurfaceInfo') )
    {
        Victims = LastTouched;
        LastTouched = None;
        dirs = Victims.Location - HitLocation;
        dist = FMax(1,VSize(dirs));
        dirs = dirs/dist;
        damageScale = FMax(Victims.CollisionRadius/(Victims.CollisionRadius + Victims.CollisionHeight),1 - FMax(0,(dist - Victims.CollisionRadius)/DamageRadius));
        if ( Instigator == None || Instigator.Controller == None )
            Victims.SetDelayedDamageInstigatorController(InstigatorController);

        log("Part 2 Doing "$(damageScale * DamageAmount)$" damage to "$Victims);
        Victims.TakeDamage
        (
            damageScale * DamageAmount,
            Instigator,
            Victims.Location - 0.5 * (Victims.CollisionHeight + Victims.CollisionRadius) * dirs,
            (damageScale * Momentum * dirs),
            DamageType
        );
        if (Vehicle(Victims) != None && Vehicle(Victims).Health > 0)
            Vehicle(Victims).DriverRadiusDamage(DamageAmount, DamageRadius, InstigatorController, DamageType, Momentum, HitLocation);
    }
	*/

	if( Role == ROLE_Authority )
    {
        if( NumKilled >= 4 )
        {
            KFGameType(Level.Game).DramaticEvent(0.05);
        }
        else if( NumKilled >= 2 )
        {
            KFGameType(Level.Game).DramaticEvent(0.03);
        }
    }

    bHurtEntry = false;
}

defaultproperties
{
	ImpactDamage=65
    ImpactDamageType=Class'ScrnBalanceSrv.ScrnDamTypeHuskGunProjectileImpact'
	
	Damage=30.000000
    DamageRadius=150.000000
	HeadShotDamageMult=2.2 // up from 1.5
}
