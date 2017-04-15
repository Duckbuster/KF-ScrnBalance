class ScrnTab_Profile extends SRTab_Profile;

var localized string strNotATeamChar;


function bool PickModel(GUIComponent Sender)
{
	if ( Controller.OpenMenu(string(Class'ScrnModelSelect'), PlayerRec.DefaultName, Eval(Controller.CtrlPressed, PlayerRec.Race, "")) )
	{
		Controller.ActivePage.OnClose = ModelSelectClosed;
	}

	return true;
}

function ModelSelectClosed( optional bool bCancelled )
{
    local ScrnPlayerController PC;
	local string str;

	if ( bCancelled )
		return;
        
    PC = ScrnPlayerController(PlayerOwner());
	str = Controller.ActivePage.GetDataString();
	if ( str != "" ) {
        if ( PC != none && !PC.IsTeamCharacter(str) ) {
            PC.ClientMessage(strNotATeamChar);
            return;
        }
        super.ModelSelectClosed(bCancelled);
	}
}


function SaveSettings()
{
	local PlayerController PC;
    local ScrnPlayerController ScrnPC;
	local ClientPerkRepLink L;

	PC = PlayerOwner();
    ScrnPC = ScrnPlayerController(PlayerOwner());
	L = Class'ScrnClientPerkRepLink'.Static.FindMe(PC);

	if ( ChangedCharacter!="" )
	{
        if ( ScrnPC != none && !ScrnPC.IsTeamCharacter(ChangedCharacter) ) {
            ScrnPC.ClientMessage(strNotATeamChar);
        }
        else {    
            if ( ScrnPC != none && ScrnPC.PlayerReplicationInfo != none && ScrnPC.PlayerReplicationInfo.Team != none) {
                if ( ScrnPC.PlayerReplicationInfo.Team.TeamIndex == 0 )
                    ScrnPC.RedCharacter = ChangedCharacter;
                else  if ( ScrnPC.PlayerReplicationInfo.Team.TeamIndex == 1 ) 
                    ScrnPC.BlueCharacter = ChangedCharacter;
                ScrnPC.SaveConfig();
            }
            
            if( L!=None )
                L.SelectedCharacter(ChangedCharacter);
            else
            {
                PC.ConsoleCommand("ChangeCharacter"@ChangedCharacter);
                if ( !PC.IsA('xPlayer') )
                    PC.UpdateURL("Character", ChangedCharacter, True);

                if ( PlayerRec.Sex ~= "Female" )
                    PC.UpdateURL("Sex", "F", True);
                else PC.UpdateURL("Sex", "M", True);
            }
        }
		ChangedCharacter = "";
	}

	if ( lb_PerkSelect.GetIndex()>=0 && L!=None ) {
        ScrnPC.SelectVeterancy(L.CachePerks[lb_PerkSelect.GetIndex()].PerkClass);    
    }
}


defaultproperties
{
    strNotATeamChar="Selected character is not avaliable for your team!"
}