class ScrnMK23Pickup extends MK23Pickup;

var class<KFWeapon> DualInventoryType; // dual class

function inventory SpawnCopy( pawn Other ) {
    local Inventory CurInv;
	local KFWeapon PistolInInventory;

    For( CurInv=Other.Inventory; CurInv!=None; CurInv=CurInv.Inventory ) {
		PistolInInventory = KFWeapon(CurInv);
        if( PistolInInventory != None && (PistolInInventory.class == default.InventoryType 
				|| ClassIsChildOf(default.InventoryType, PistolInInventory.class)) )
		{
			// destroy the inventory to force parent SpawnCopy() to make a new instance of class
			// we specified below
            if( Inventory!=None )
				Inventory.Destroy();
            // spawn dual guns instead of another instance of single
            InventoryType = DualInventoryType;
			// Make dualies to cost twice of lowest value in case of PERKED+UNPERKED pistols
			SellValue = 2 * min(SellValue, PistolInInventory.SellValue);
            AmmoAmount[0]+= PistolInInventory.AmmoAmount(0);
            MagAmmoRemaining+= PistolInInventory.MagAmmoRemaining;
            CurInv.Destroyed();
            CurInv.Destroy();
            Return Super(KFWeaponPickup).SpawnCopy(Other);
        }
    }
    InventoryType = Default.InventoryType;
    Return Super(KFWeaponPickup).SpawnCopy(Other);
}

function bool CheckCanCarry(KFHumanPawn Hm) {
    local Inventory CurInv;
    local bool bHasSinglePistol;
	local float AddWeight;

    AddWeight = class<KFWeapon>(default.InventoryType).default.Weight;
    for ( CurInv = Hm.Inventory; CurInv != none; CurInv = CurInv.Inventory ) {
        if ( CurInv.class == default.DualInventoryType ) {
            //already have duals, can't carry a single
            LastCantCarryTime = Level.TimeSeconds + 0.5;
            PlayerController(Hm.Controller).ReceiveLocalizedMessage(Class'KFMainMessages', 2);
            return false; 
        }
        else if ( CurInv.class == default.InventoryType ) {
            bHasSinglePistol = true;
            AddWeight = default.DualInventoryType.default.Weight - AddWeight;
            break;
        }
    }

    if ( !Hm.CanCarry(AddWeight) ) {
        LastCantCarryTime = Level.TimeSeconds + 0.5;
        PlayerController(Hm.Controller).ReceiveLocalizedMessage(Class'KFMainMessages', 2);

        return false;
    }

    return true;
}

defaultproperties
{
     DualInventoryType=Class'ScrnBalanceSrv.ScrnDualMK23Pistol'
     Weight=3.000000
     Description="Match grade 45 caliber pistol. Good balance between power, ammo count and rate of fire. Damage is near to Magnum's, but has no bullet penetration."
     ItemName="MK23 SE"
     ItemShortName="MK23 SE"
     InventoryType=Class'ScrnBalanceSrv.ScrnMK23Pistol'
}
