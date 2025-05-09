/**
 * Dual-Magnum 44 with attached laser sights
 *
 * @author PooSH, 2012
 */

class ScrnDualMK23Laser extends ScrnDualMK23Pistol
    dependson(ScrnLocalLaserDot)
    config(user);


var const   class<ScrnLocalLaserDot>    LaserDotClass;
var         ScrnLocalLaserDot           RightDot, LeftDot;             // The first person laser site dot

var()       class<InventoryAttachment>  LaserAttachmentClass;      // First person laser attachment class
var         Actor                       RightLaserAttachment, LeftLaserAttachment; // First person laser attachment

var         byte                        LaserType;       //current laser type

var         float                         FireSpotRenrerTime;         // how long to render RightDot after weapon fire (after that RightDot will be put in the center of the screen)

var float LaserRecoilReduction;

replication
{
    reliable if(Role < ROLE_Authority)
        ServerSetLaserType;
}


simulated function PostBeginPlay()
{
    super.PostBeginPlay();
    bFindSingleGun = false;
}

simulated function Destroyed()
{
    if (RightDot != None)
        RightDot.Destroy();
    if (LeftDot != None)
        LeftDot.Destroy();

    if (RightLaserAttachment != None)
        RightLaserAttachment.Destroy();
    if (LeftLaserAttachment != None)
        LeftLaserAttachment.Destroy();

    super.Destroyed();
}

// Use alt fire to switch laser type
simulated function AltFire(float F)
{
    PlaySound(sound'KF_9MMSnd.NineMM_AltFire1',SLOT_Misc,100);
    ToggleLaser();
}

//bring Laser to current state, which is indicating by LaserType
simulated function ApplyLaserState()
{
    if( Role < ROLE_Authority  )
        ServerSetLaserType(LaserType);

    if ( ScrnLaserDualWeaponAttachment(ThirdPersonActor) != none )
        ScrnLaserDualWeaponAttachment(ThirdPersonActor).SetLaserType(LaserType);
    if ( ScrnLaserDualWeaponAttachment(altThirdPersonActor) != none )
        ScrnLaserDualWeaponAttachment(altThirdPersonActor).SetLaserType(LaserType);

    AdjustRecoil();

    if ( !Instigator.IsLocallyControlled() )
        return;

    if( LaserType > 0 ) {
        if (RightDot == None)
            RightDot = Spawn(LaserDotClass, self);
        if (LeftDot == None)
            LeftDot = Spawn(LaserDotClass, self);
        RightDot.SetLaserType(LaserType);
        LeftDot.SetLaserType(LaserType);
        // adjust 1-st person laser color
        ConstantColor'ScrnTex.Laser.LaserColor'.Color = LeftDot.GetLaserColor();
        if ( RightLaserAttachment == none ) {
            //MK23s Tip bone is rotated to the side, so change it
            SetBoneRotation('Tip_Right', rot(0, 16384, 0));
            RightLaserAttachment = Spawn(LaserAttachmentClass,self,,,);
            AttachToBone(RightLaserAttachment,'Tip_Right');
        }
        if ( LeftLaserAttachment == none ) {
            //MK23s Tip bone is rotated to the side, so change it
            SetBoneRotation('Tip_Left', rot(0, 16384, 0));
            LeftLaserAttachment = Spawn(LaserAttachmentClass,self,,,);
            AttachToBone(LeftLaserAttachment,'Tip_Left');
        }
        RightLaserAttachment.bHidden = false;
        LeftLaserAttachment.bHidden = false;
    }
    else {
        if ( RightLaserAttachment != none )
            RightLaserAttachment.bHidden = true;
        if ( LeftLaserAttachment != none )
            LeftLaserAttachment.bHidden = true;
        if (RightDot != None)
            RightDot.Destroy();
        if (LeftDot != None)
            LeftDot.Destroy();
    }
}

// Toggle laser on or off
simulated function ToggleLaser()
{
    if( !Instigator.IsLocallyControlled() )
        return;

    if ( LaserType == 0 )
        LaserType = 2; // green
    else
        LaserType = 0;

    ApplyLaserState();
}

simulated function BringUp(optional Weapon PrevWeapon)
{
    ApplyLaserState();
    Super.BringUp(PrevWeapon);
}

simulated function bool PutDown()
{
    TurnOffLaser();
    return super.PutDown();
}

simulated function DetachFromPawn(Pawn P)
{
    TurnOffLaser();
    Super.DetachFromPawn(P);
}

simulated function TurnOffLaser()
{
    if( !Instigator.IsLocallyControlled() )
        return;

    if( Role < ROLE_Authority  )
        ServerSetLaserType(0);

    //don't change Laser type here, because we need to restore it state
    //when next time weapon will be brought up
    if ( RightLaserAttachment != none )
        RightLaserAttachment.bHidden = true;
    if ( LeftLaserAttachment != none )
        LeftLaserAttachment.bHidden = true;

    if (RightDot != None)
        RightDot.Destroy();
    if (LeftDot != None)
        LeftDot.Destroy();

    AdjustRecoil();
}



// Set the new fire mode on the server
function ServerSetLaserType(byte NewLaserType)
{
    LaserType = NewLaserType;
    if ( ScrnLaserDualWeaponAttachment(ThirdPersonActor) != none )
        ScrnLaserDualWeaponAttachment(ThirdPersonActor).SetLaserType(LaserType);
    if ( ScrnLaserDualWeaponAttachment(altThirdPersonActor) != none )
        ScrnLaserDualWeaponAttachment(altThirdPersonActor).SetLaserType(LaserType);
    AdjustRecoil();
}

simulated function AdjustRecoil()
{
    local KFFire f;

    f = KFFIre(FireMode[0]);
    if ( LaserType == 0 ) {
        f.maxVerticalRecoilAngle = f.default.maxVerticalRecoilAngle;
        f.maxHorizontalRecoilAngle = f.default.maxHorizontalRecoilAngle;
    }
    else {
        // reduced recoild while using laser sights
        f.maxVerticalRecoilAngle = f.default.maxVerticalRecoilAngle * LaserRecoilReduction;
        f.maxHorizontalRecoilAngle = f.default.maxHorizontalRecoilAngle * LaserRecoilReduction;
    }
}

simulated function RenderOverlays( Canvas Canvas )
{
    local int i;
    local Vector StartTrace, EndTrace;
    local Vector HitLocation, HitNormal;
    local Actor Other;
    local vector X,Y,Z;
    local coords C;
    local KFFire KFM;
    local array<Actor> HitActors;

    if (Instigator == None)
        return;

    if ( Instigator.Controller != None )
        Hand = Instigator.Controller.Handedness;

    if ((Hand < -1.0) || (Hand > 1.0))
        return;

    // draw muzzleflashes/smoke for all fire modes so idle state won't
    // cause emitters to just disappear
    for ( i = 0; i < NUM_FIRE_MODES; ++i ) {
        if (FireMode[i] != None)
            FireMode[i].DrawMuzzleFlash(Canvas);
    }

    KFM = KFFire(FireMode[0]);

    SetLocation( Instigator.Location + Instigator.CalcDrawOffset(self) );
    SetRotation( Instigator.GetViewRotation() + ZoomRotInterp);


    // Handle drawing the laser dot
    if ( RightDot != None )
    {
        //move RightDot during fire animation too  -- PooSH
        if( bIsReloading || (Level.TimeSeconds < KFM.LastFireTime + FireSpotRenrerTime
            && ((!bAimingRifle && KFM.FireAnim == 'FireLeft')
                 || (bAimingRifle && KFM.FireAimedAnim == 'FireLeft_Iron'))) )
        {
            C = GetBoneCoords('Tip_Right');
            X = C.XAxis;
            Y = C.YAxis;
            Z = C.ZAxis;
        }
        else
            GetViewAxes(X, Y, Z);

        StartTrace = Instigator.Location + Instigator.EyePosition();
        EndTrace = StartTrace + 65535 * X;

        while (true) {
            Other = Trace(HitLocation, HitNormal, EndTrace, StartTrace, true);
            if ( ROBulletWhipAttachment(Other) != none ) {
                HitActors[HitActors.Length] = Other;
                Other.SetCollision(false);
                StartTrace = HitLocation + X;
            }
            else {
                if (Other != None && Other != Instigator && Other.Base != Instigator )
                    EndBeamEffect = HitLocation;
                else
                    EndBeamEffect = EndTrace;
                break;
            }
        }
        // restore collision
        for ( i=0; i<HitActors.Length; ++i )
            HitActors[i].SetCollision(true);

        RightDot.SetLocation(EndBeamEffect - X*RightDot.ProjectorPullback);

        if(  Pawn(Other) != none ) {
            RightDot.SetRotation(Rotator(X));
            RightDot.SetDrawScale(RightDot.default.DrawScale * 0.5);
        }
        else if( HitNormal == vect(0,0,0) ) {
            RightDot.SetRotation(Rotator(-X));
            RightDot.SetDrawScale(RightDot.default.DrawScale);
        }
        else {
            RightDot.SetRotation(Rotator(-HitNormal));
            RightDot.SetDrawScale(RightDot.default.DrawScale);
        }
    }

    if ( LeftDot != None )
    {
        //move LeftDot during fire animation too  -- PooSH
        if( bIsReloading || (Level.TimeSeconds < KFM.LastFireTime + FireSpotRenrerTime
            && ((!bAimingRifle && KFM.FireAnim == 'FireRight')
                 || (bAimingRifle && KFM.FireAimedAnim == 'FireRight_Iron'))) )
        {
            C = GetBoneCoords('Tip_Left');
            X = C.XAxis;
            Y = C.YAxis;
            Z = C.ZAxis;
        }
        else
            GetViewAxes(X, Y, Z);

        StartTrace = Instigator.Location + Instigator.EyePosition();
        EndTrace = StartTrace + 65535 * X;

        while (true) {
            Other = Trace(HitLocation, HitNormal, EndTrace, StartTrace, true);
            if ( ROBulletWhipAttachment(Other) != none ) {
                HitActors[HitActors.Length] = Other;
                Other.SetCollision(false);
                StartTrace = HitLocation + X;
            }
            else {
                if (Other != None && Other != Instigator && Other.Base != Instigator )
                    EndBeamEffect = HitLocation;
                else
                    EndBeamEffect = EndTrace;
                break;
            }
        }
        // restore collision
        for ( i=0; i<HitActors.Length; ++i )
            HitActors[i].SetCollision(true);

        LeftDot.SetLocation(EndBeamEffect - X*LeftDot.ProjectorPullback);

        if(  Pawn(Other) != none ) {
            LeftDot.SetRotation(Rotator(X));
            LeftDot.SetDrawScale(LeftDot.default.DrawScale * 0.5);
        }
        else if( HitNormal == vect(0,0,0) ) {
            LeftDot.SetRotation(Rotator(-X));
            LeftDot.SetDrawScale(LeftDot.default.DrawScale);
        }
        else {
            LeftDot.SetRotation(Rotator(-HitNormal));
            LeftDot.SetDrawScale(LeftDot.default.DrawScale);
        }
    }

    //PreDrawFPWeapon();    // Laurent -- Hook to override things before render (like rotation if using a staticmesh)

    bDrawingFirstPerson = true;
    Canvas.DrawActor(self, false, false, DisplayFOV);
    bDrawingFirstPerson = false;
}

//copy-pasted from M14EBR
exec function SwitchModes()
{
    ToggleLaser();
}

//copy-pasted from M14EBR
simulated function SetZoomBlendColor(Canvas c)
{
    local Byte    val;
    local Color   clr;
    local Color   fog;

    clr.R = 255;
    clr.G = 255;
    clr.B = 255;
    clr.A = 255;

    if( Instigator.Region.Zone.bDistanceFog )
    {
        fog = Instigator.Region.Zone.DistanceFogColor;
        val = 0;
        val = Max( val, fog.R);
        val = Max( val, fog.G);
        val = Max( val, fog.B);
        if( val > 128 )
        {
            val -= 128;
            clr.R -= val;
            clr.G -= val;
            clr.B -= val;
        }
    }
    c.DrawColor = clr;
}

function bool HandlePickupQuery( pickup Item )
{
    if ( ClassIsChildOf(Item.InventoryType, Class'MK23Pistol')
            || ClassIsChildOf(Item.InventoryType, Class'DualMK23Pistol') )
    {
        if( LastHasGunMsgTime < Level.TimeSeconds && PlayerController(Instigator.Controller) != none )
        {
            LastHasGunMsgTime = Level.TimeSeconds + 0.5;
            PlayerController(Instigator.Controller).ReceiveLocalizedMessage(Class'KFMainMessages', 1);
        }

        return true;
    }

    return Super(KFWeapon).HandlePickupQuery(Item);
}

function DropFrom(vector StartLocation)
{
    ClearDoubleAmmo();
    //just drop this weapon, don't split it on single guns
    super(KFWeapon).DropFrom(StartLocation);
}

function GiveTo( pawn Other, optional Pickup Pickup )
{
    // remember it once to stop calling the function on every tick
    bBotControlled = !Other.IsHumanControlled();

    Super(KFWeapon).GiveTo(Other, Pickup);

    LeftGunAmmoRemaining = MagAmmoRemaining / 2;
    CheckDoubleAmmo(Other);
}

// double ammo capacity if carrying both laser + non-laser mk23
static function bool CheckDoubleAmmo(Pawn Owner, optional KFWeapon IgnoreWeapon)
{
    local ScrnDualMK23Laser myself;
    local Inventory Inv;
    local int c;
    local bool bOthers, bDoubleAmmo;

    if (Owner == none) {
        return false;  // wtf?
    }

    for (Inv = Owner.Inventory; Inv != none && ++c < 1000; Inv = Inv.Inventory) {
        if (Inv == IgnoreWeapon)
            continue;

        if (ScrnMK23Pistol(Inv) != none) {
            bOthers = true;
        }
        else if (ScrnDualMK23Pistol(Inv) != none) {
            if (ScrnDualMK23Laser(Inv) != none) {
                myself = ScrnDualMK23Laser(Inv);
            }
            else {
                bOthers = true;
            }
        }
        if (bOthers && myself != none)
            break;  // found everything we've been looking for
    }

    if (!bOthers) {
        if (myself != none) {
            myself.SetDoubleAmmo(false);
        }
        return false;
    }

    bDoubleAmmo = myself != none;
    for (Inv = Owner.Inventory; Inv != none && ++c < 1000; Inv = Inv.Inventory) {
        if (Inv == IgnoreWeapon)
            continue;

        if (ScrnMK23Pistol(Inv) != none) {
            ScrnMK23Pistol(Inv).SetDoubleAmmo(bDoubleAmmo);
        }
        else if (ScrnDualMK23Pistol(Inv) != none) {
            ScrnDualMK23Pistol(Inv).SetDoubleAmmo(bDoubleAmmo);
        }
    }
    return bDoubleAmmo;
}


defaultproperties
{
    LaserType=2
    LaserRecoilReduction=0.5
    LaserAttachmentClass=class'ScrnLaserAttachmentFirstPerson'
    LaserDotClass=class'ScrnLocalLaserDot'
    Weight=5.000000
    Description="Yeah! One in each hand! Now with laser attachment."
    bIsTier3Weapon=True
    DemoReplacement=None
    InventoryGroup=4
    PickupClass=class'ScrnDualMK23LaserPickup'
    AttachmentClass=class'ScrnDualMK23LaserAttachment'
    ItemName="Laser Dual MK23"
    FireSpotRenrerTime=0.9
    Priority=160
}
