class ScrnFire extends KFFire;

var byte  MaxPenetrations;  // how many enemies can penetrate a single bullet
var float PenDmgReduction;   // penetration damage scale. 1.0 - no reduction, 0.75 - 25% reduction (75% damage remaining)
// if the damaged pawn is still alive, an additional scale gets applied, depending from the remaining health.
// 0.0005 - zed with 1000 health reduce the remaining damage by half (0.0005 * 1000 = 0.5)
var float PenDmgReductionByHealth;

var transient int KillCountPerTrace;


// should be called by the weapon when after the fire mode change (e.g., switch from full- to semi-auto)
function FireModeChanged() ;
function AdjustZedDamage(KFMonster Zed, out float Damage);

function DoTrace(Vector Start, Rotator Dir)
{
    local Vector X,Y,Z, End, HitLocation, HitNormal, ArcEnd;
    local Actor Other;
    local byte HitCount, PenCounter;
    local float HitDamage, HitMomentum;
    local array<int>    HitPoints;
    local array<Actor>    IgnoreActors;
    local KFPawn HitPawn;
    local KFMonster Zed;
    local int i;
    local bool bWasDecapitated;

    KillCountPerTrace = 0;

    MaxRange();

    Weapon.GetViewAxes(X, Y, Z);
    if ( Weapon.WeaponCentered() ) {
        ArcEnd = (Instigator.Location + Weapon.EffectOffset.X * X + 1.5 * Weapon.EffectOffset.Z * Z);
    }
    else {
        ArcEnd = (Instigator.Location + Instigator.CalcDrawOffset(Weapon) + Weapon.EffectOffset.X * X +
        Weapon.Hand * Weapon.EffectOffset.Y * Y + Weapon.EffectOffset.Z * Z);
    }

    X = Vector(Dir);
    End = Start + TraceRange * X;
    HitDamage = DamageMax;
    HitMomentum = Momentum;

    // HitCount isn't a number of max penetration. It is just to be sure we won't stuck in infinite loop
    while( ++HitCount < 127 && HitDamage >= DamageMin )
    {
        Zed = none;
        HitPawn = none;

        Other = Instigator.HitPointTrace(HitLocation, HitNormal, End, HitPoints, Start,, 1);
        if( Other == none ) {
            break;
        }
        else if( Other==Instigator || Other.Base == Instigator ) {
            IgnoreActors[IgnoreActors.Length] = Other;
            Other.SetCollision(false);
            Start = HitLocation;
            continue;
        }
        else if ( Other.bWorldGeometry || Other == Level ) {
            if( KFWeaponAttachment(Weapon.ThirdPersonActor) != None )
                KFWeaponAttachment(Weapon.ThirdPersonActor).UpdateHit(Other,HitLocation,HitNormal);
            break;
        }

        Zed = KFMonster(Other);
        if ( Zed != none ) {
            IgnoreActors[IgnoreActors.Length] = Other;
            Other.SetCollision(false);
        }
        else if( ExtendedZCollision(Other) != none && Other.Owner != none ) {
            IgnoreActors[IgnoreActors.Length] = Other;
            IgnoreActors[IgnoreActors.Length] = Other.Owner;
            Other.SetCollision(false);
            Other.Owner.SetCollision(false);
            Zed = KFMonster(Other.Owner);
        }
        else {
            HitPawn = KFPawn(Other);
        }

        if (HitPawn != none) {
            if(!HitPawn.bDeleteMe) {
                 HitPawn.ProcessLocationalDamage(int(HitDamage), Instigator, HitLocation, HitMomentum*X,DamageType,
                        HitPoints);
            }
            IgnoreActors[IgnoreActors.Length] = Other;
            IgnoreActors[IgnoreActors.Length] = HitPawn.AuxCollisionCylinder;
            Other.SetCollision(false);
            HitPawn.AuxCollisionCylinder.SetCollision(false);
        }
        else if (Zed != none) {
            bWasDecapitated = Zed.bDecapitated;
            AdjustZedDamage(Zed, HitDamage);
            Zed.TakeDamage(HitDamage, Instigator, HitLocation, HitMomentum*X, DamageType);
            if (Zed == none || Zed.Health <= 0 || (!bWasDecapitated && Zed.bDecapitated)) {
                ++KillCountPerTrace;
            }
            else if (Zed != none && PenDmgReductionByHealth > 0) {
                HitDamage *= 1.0 - PenDmgReductionByHealth * Zed.Health;
                HitMomentum *= 1.0 - PenDmgReductionByHealth * Zed.Health;
            }
        }
        else {
            Other.TakeDamage(HitDamage, Instigator, HitLocation, HitMomentum*X, DamageType);
            break;
        }

        if (++PenCounter > MaxPenetrations)
            break;

        HitDamage *= PenDmgReduction;
        HitMomentum *= PenDmgReduction;
        Start = HitLocation;
    }

    // Turn the collision back on for any actors we turned it off
    if ( IgnoreActors.Length > 0 )
    {
        for (i=0; i<IgnoreActors.Length; i++)
        {
            if ( IgnoreActors[i] != none )
                IgnoreActors[i].SetCollision(true);
        }
    }
}

defaultproperties
{
    MaxPenetrations=0
    PenDmgReduction=0.500000
    PenDmgReductionByHealth=0.0005  // zed with 100 hp remaining reduces the following damage by 5%
    DamageMin=10  // the bullet cannot over-penetrate the body if its leftover damage is lower than DamageMin
}
