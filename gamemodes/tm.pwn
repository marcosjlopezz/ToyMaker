#pragma option -d3
#pragma warning disable 239

//Initial Library
#include <a_samp>

//Neccesary
#undef MAX_PLAYERS
#define MAX_PLAYERS 9

//Includes
#include <Pawn.CMD>
#include <filemanager>
#include <sscanf2>
//#include <PawnPlus>

//Config
#define     MAKER_VERSION           "1.3"

#define     SERVER_NAME             "ToyMaker"

#define     SERVER_INFO             "Release "MAKER_VERSION""
#define     HOSTNAME                "» "SERVER_NAME" [0.3.7] «"

#define     INFO_COLOR              "f6e58d"
#define     COMMANDS_COLOR          "badc58"
#define     ALERT_COLOR             "eb4d4b"

#define     X_ALERT_COLOR           0xeb4d4bff
#define     X_COMMANDS_COLOR        0xbadc58ff
#define     X_INFO_COLOR            0xf6e58dff
#define     SPECIAL_ACTION_PISSING  68

//Macros
#define MAX_TD_EDITOR   5
#define MAX_PTD_EDITOR  19

//Arrays
new CurrentSkin[MAX_PLAYERS];
new Float:ToyPos[MAX_PLAYERS][3];
new Float:ToyRot[MAX_PLAYERS][3];
new Float:ToySize[MAX_PLAYERS][3];
new bool:InToyMaker[MAX_PLAYERS];
new EditorStates:EditorState[MAX_PLAYERS];
new EditorSelectState:SelectedXYZ[MAX_PLAYERS];
new Float:Multiplier[MAX_PLAYERS];

//Info
new ToyModelid[MAX_PLAYERS];
new ToyBone[MAX_PLAYERS];

new ToysBones[][24] = 
{
	{"Espalda"},
	{"Cabeza"},
	{"Brazo izquierdo"},
	{"Brazo derecho"},
	{"Mano izquierda"},
	{"Mano derecha"},
	{"Muslo izquierdo"},
	{"Muslo derecho"},
	{"Pie izquierdo"},
	{"Pie derecho"},
	{"Pantorrilla derecha"},
	{"Pantorrilla izquierda"},
	{"Antebrazo izquierdo"},
	{"Antebrazo derecho"},
	{"Hombro izquierdo"},
	{"Hombro derecho"},
	{"Cuello"},
	{"Boca"}
};

//Others
new SpecialActions[][256] =
{
    {"SPECIAL_ACTION_NONE"},
    {"SPECIAL_ACTION_USEJETPACK"},
    {"SPECIAL_ACTION_DANCE1"},
    {"SPECIAL_ACTION_DANCE2"},
    {"SPECIAL_ACTION_DANCE3"},
    {"SPECIAL_ACTION_DANCE4"},
    {"SPECIAL_ACTION_HANDSUP"},
    {"SPECIAL_ACTION_USECELLPHONE"},
    {"SPECIAL_ACTION_SITTING*"},
    {"SPECIAL_ACTION_STOPUSECELLPHONE"},
    {"SPECIAL_ACTION_DUCK*"},
    {"SPECIAL_ACTION_ENTER_VEHICLE*"},
    {"SPECIAL_ACTION_EXIT_VEHICLE*"},
    {"SPECIAL_ACTION_DRINK_BEER"},
    {"SPECIAL_ACTION_SMOKE_CIGGY"},
    {"SPECIAL_ACTION_DRINK_WINE"},
    {"SPECIAL_ACTION_DRINK_SPRUNK"},
    {"SPECIAL_ACTION_PISSING"},
    {"SPECIAL_ACTION_CUFFED"},
    {"SPECIAL_ACTION_CARRY"}
};

//Dialog
enum
{
    DIALOG_MODEL_ID = 18000,
    DIALOG_SELECT_BONE,
    DIALOG_TOY_NAME,
    DIALOG_MODIFY_MULTIPLIER,
    DIALOG_SPECIAL_ACTION
}

//States
enum EditorSelectState
{
    EDITOR_SEL_NONE,
    EDITOR_SEL_X,
    EDITOR_SEL_Y,
    EDITOR_SEL_Z,
};

enum EditorStates
{
    EDITOR_STATE_NONE,
    EDITOR_STATE_POS,
    EDITOR_STATE_SIZE,
    EDITOR_STATE_ROT,
};

//Textdraws
new Text:ToyEditorTD[MAX_TD_EDITOR] = {Text:INVALID_TEXT_DRAW, ...};
new PlayerText:ToyEditorPTD[MAX_PLAYERS][MAX_PTD_EDITOR] = {PlayerText:INVALID_TEXT_DRAW, ...};

//Functions
stock SendPlayerToysInfo(playerid)
{
    for(new i = 0; i != 120; i++)
    {
        SendClientMessage(playerid, -1, "");
    }

    SendClientMessage(playerid, -1, "{"#COMMANDS_COLOR"}/skin {ffffff}- Cambia tu skin de manera rapida.");
    SendClientMessage(playerid, -1, "{"#COMMANDS_COLOR"}/rtoy {ffffff}- Valores predeterminados del editor.");
    SendClientMessage(playerid, -1, "{"#COMMANDS_COLOR"}/toys {ffffff}- Entrar al creador de accesorios.");
    SendClientMessage(playerid, -1, "{"#COMMANDS_COLOR"}/pc {ffffff}- Usar el editor de toys de SA-MP para ordenador.");
    SendClientMessage(playerid, -1, "{"#COMMANDS_COLOR"}/actions {ffffff}- Usar acciones especiales.");
    SendClientMessage(playerid, -1, "{"#COMMANDS_COLOR"}/anim {ffffff}- Ejecutar una animacion.");
    SendClientMessage(playerid, -1, "{"#COMMANDS_COLOR"}/stop {ffffff}- Detener ejecucion de animacion.");
    return 1;
}

stock ShowPlayerToyMaker(playerid)
{
    UpdateToyMaker(playerid);

    for(new i = 0; i < MAX_TD_EDITOR; i++)
    {
        TextDrawShowForPlayer(playerid, ToyEditorTD[i]);
    }

    for(new i = 0; i < MAX_PTD_EDITOR; i++)
    {
        PlayerTextDrawShow(playerid, ToyEditorPTD[playerid][i]);
    }

    InToyMaker[playerid] = true;
    EditorState[playerid] = EDITOR_STATE_NONE;
    SelectedXYZ[playerid] = EDITOR_SEL_NONE;
    SelectTextDraw(playerid, 0x0000FFFF);
}

stock HidePlayerToyMaker(playerid)
{
    SendPlayerToysInfo(playerid);

    for(new i = 0; i < MAX_TD_EDITOR; i++)
    {
        TextDrawHideForPlayer(playerid, ToyEditorTD[i]);
    }

    for(new i = 0; i < MAX_PTD_EDITOR; i++)
    {
        PlayerTextDrawHide(playerid, ToyEditorPTD[playerid][i]);
    }

    InToyMaker[playerid] = false;
    EditorState[playerid] = EDITOR_STATE_NONE;
    SelectedXYZ[playerid] = EDITOR_SEL_NONE;

    CancelSelectTextDraw(playerid);
}

stock UpdateToyMaker(playerid)
{
    if(CurrentSkin[playerid] > 311) CurrentSkin[playerid] = 0;
    if(CurrentSkin[playerid] < 0) CurrentSkin[playerid] = 311;
    
    new td_str[2048];
    format(td_str, sizeof(td_str), "%d", CurrentSkin[playerid]);
    PlayerTextDrawSetString(playerid, ToyEditorPTD[playerid][14], td_str);
    SetPlayerSkin(playerid, CurrentSkin[playerid]);

    switch(EditorState[playerid])
    {
        case EDITOR_STATE_POS:
        {
            switch(SelectedXYZ[playerid])
            {
                case EDITOR_SEL_X:
                {
                    format(td_str, sizeof(td_str), "%.1f", ToyPos[playerid][0]);
                    PlayerTextDrawSetString(playerid, ToyEditorPTD[playerid][11], td_str);
                }
                case EDITOR_SEL_Y:
                {
                    format(td_str, sizeof(td_str), "%.1f", ToyPos[playerid][1]);
                    PlayerTextDrawSetString(playerid, ToyEditorPTD[playerid][11], td_str);
                }
                case EDITOR_SEL_Z:
                {
                    format(td_str, sizeof(td_str), "%.1f", ToyPos[playerid][2]);
                    PlayerTextDrawSetString(playerid, ToyEditorPTD[playerid][11], td_str);
                }
            }
        }
        case EDITOR_STATE_SIZE:
        {
            switch(SelectedXYZ[playerid])
            {
                case EDITOR_SEL_X:
                {
                    format(td_str, sizeof(td_str), "%.1f", ToySize[playerid][0]);
                    PlayerTextDrawSetString(playerid, ToyEditorPTD[playerid][11], td_str);
                }
                case EDITOR_SEL_Y:
                {
                    format(td_str, sizeof(td_str), "%.1f", ToySize[playerid][1]);
                    PlayerTextDrawSetString(playerid, ToyEditorPTD[playerid][11], td_str);
                }
                case EDITOR_SEL_Z:
                {
                    format(td_str, sizeof(td_str), "%.1f", ToySize[playerid][2]);
                    PlayerTextDrawSetString(playerid, ToyEditorPTD[playerid][11], td_str);
                }
            }
        }
        case EDITOR_STATE_ROT:
        {
            switch(SelectedXYZ[playerid])
            {
                case EDITOR_SEL_X:
                {
                    format(td_str, sizeof(td_str), "%.1f", ToyRot[playerid][0]);
                    PlayerTextDrawSetString(playerid, ToyEditorPTD[playerid][11], td_str);
                }
                case EDITOR_SEL_Y:
                {
                    format(td_str, sizeof(td_str), "%.1f", ToyRot[playerid][1]);
                    PlayerTextDrawSetString(playerid, ToyEditorPTD[playerid][11], td_str);
                }
                case EDITOR_SEL_Z:
                {
                    format(td_str, sizeof(td_str), "%.1f", ToyRot[playerid][2]);
                    PlayerTextDrawSetString(playerid, ToyEditorPTD[playerid][11], td_str);
                }
            }
        }
    }

    RemovePlayerAttachedObject(playerid, 1);

    if(ToyModelid[playerid] != -1)
    {
        SetPlayerAttachedObject(
            playerid, 
            1, 
            ToyModelid[playerid], 
            ToyBone[playerid], 
            
            ToyPos[playerid][0], 
            ToyPos[playerid][1], 
            ToyPos[playerid][2], 
            
            ToyRot[playerid][0], 
            ToyRot[playerid][1], 
            ToyRot[playerid][2], 
            
            ToySize[playerid][0], 
            ToySize[playerid][1], 
            ToySize[playerid][2], 

            0xFFFFFFFF, 0xFFFFFFFF
        );
    }
    return 1;
}

stock ReturnPlayerName(playerid)
{
    new name[32];
    GetPlayerName(playerid, name, 32);
    return name;
}

//Callbacks Player
public OnPlayerEditAttachedObject(playerid, response, index, modelid, boneid, Float:fOffsetX, Float:fOffsetY, Float:fOffsetZ, Float:fRotX, Float:fRotY, Float:fRotZ, Float:fScaleX, Float:fScaleY, Float:fScaleZ)
{
    if(response)
    {
        ToyPos[playerid][0] = fOffsetX;
        ToyPos[playerid][1] = fOffsetY;
        ToyPos[playerid][2] = fOffsetZ;

        ToyRot[playerid][0] = fRotX;
        ToyRot[playerid][1] = fRotY;
        ToyRot[playerid][2] = fRotZ;
                
        ToySize[playerid][0] = fScaleX;
        ToySize[playerid][1] = fScaleY;
        ToySize[playerid][2] = fScaleZ;

        SetPlayerAttachedObject(
            playerid, 
            1, 
            ToyModelid[playerid], 
            ToyBone[playerid], 
                
            ToyPos[playerid][0], 
            ToyPos[playerid][1], 
            ToyPos[playerid][2], 
                
            ToyRot[playerid][0], 
            ToyRot[playerid][1], 
            ToyRot[playerid][2], 
                
            ToySize[playerid][0], 
            ToySize[playerid][1], 
            ToySize[playerid][2], 

            0xFFFFFFFF, 0xFFFFFFFF
        );

        SendClientMessage(playerid, X_INFO_COLOR, "[Info] {ffffff}Se ha actualizado la posicion del objeto.");
    }
    else
    {
        SetPlayerAttachedObject(
            playerid, 
            1, 
            ToyModelid[playerid], 
            ToyBone[playerid], 
                
            ToyPos[playerid][0], 
            ToyPos[playerid][1], 
            ToyPos[playerid][2], 
                
            ToyRot[playerid][0], 
            ToyRot[playerid][1], 
            ToyRot[playerid][2], 
                
            ToySize[playerid][0], 
            ToySize[playerid][1], 
            ToySize[playerid][2], 

            0xFFFFFFFF, 0xFFFFFFFF
        );

        SendClientMessage(playerid, X_INFO_COLOR, "[Info] {ffffff}Has cancelado el editor de PC, no se han guardado los cambios.");
    }

    ShowPlayerToyMaker(playerid);
    return 1;
}

public OnPlayerClickPlayerTextDraw(playerid, PlayerText:playertextid)
{
    if(InToyMaker[playerid])
    {
        if(playertextid == ToyEditorPTD[playerid][0]) //X Posicion
        {
            EditorState[playerid] = EDITOR_STATE_POS;
            SelectedXYZ[playerid] = EDITOR_SEL_X;
        }
        else if(playertextid == ToyEditorPTD[playerid][1]) //Y Posicion
        {
            EditorState[playerid] = EDITOR_STATE_POS;
            SelectedXYZ[playerid] = EDITOR_SEL_Y;
        }
        else if(playertextid == ToyEditorPTD[playerid][2]) //Z Posicion
        {
            EditorState[playerid] = EDITOR_STATE_POS;
            SelectedXYZ[playerid] = EDITOR_SEL_Z;
        }
        else if(playertextid == ToyEditorPTD[playerid][3]) //X Tamaño
        {
            EditorState[playerid] = EDITOR_STATE_SIZE;
            SelectedXYZ[playerid] = EDITOR_SEL_X;
        }
        else if(playertextid == ToyEditorPTD[playerid][4]) //Y Tamaño
        {
            EditorState[playerid] = EDITOR_STATE_SIZE;
            SelectedXYZ[playerid] = EDITOR_SEL_Y;
        }
        else if(playertextid == ToyEditorPTD[playerid][5]) //Z Tamaño
        {
            EditorState[playerid] = EDITOR_STATE_SIZE;
            SelectedXYZ[playerid] = EDITOR_SEL_Z;
        }
        else if(playertextid == ToyEditorPTD[playerid][6]) //X Rotacion
        {
            EditorState[playerid] = EDITOR_STATE_ROT;
            SelectedXYZ[playerid] = EDITOR_SEL_X;
        }
        else if(playertextid == ToyEditorPTD[playerid][7]) //Y Rotacion
        {
            EditorState[playerid] = EDITOR_STATE_ROT;
            SelectedXYZ[playerid] = EDITOR_SEL_Y;
        }
        else if(playertextid == ToyEditorPTD[playerid][8]) //Z Rotacion
        {
            EditorState[playerid] = EDITOR_STATE_ROT;
            SelectedXYZ[playerid] = EDITOR_SEL_Z;
        }
        else if(playertextid == ToyEditorPTD[playerid][9]) //-
        {
            switch(EditorState[playerid])
            {
                case EDITOR_STATE_POS:
                {
                    switch(SelectedXYZ[playerid])
                    {
                        case EDITOR_SEL_X:
                        {
                            ToyPos[playerid][0] += Multiplier[playerid];
                            UpdateToyMaker(playerid);
                        }
                        case EDITOR_SEL_Y:
                        {
                            ToyPos[playerid][1] += Multiplier[playerid];
                            UpdateToyMaker(playerid);
                        }
                        case EDITOR_SEL_Z:
                        {
                            ToyPos[playerid][2] += Multiplier[playerid];
                            UpdateToyMaker(playerid);
                        }
                    }
                }
                case EDITOR_STATE_SIZE:
                {
                    switch(SelectedXYZ[playerid])
                    {
                        case EDITOR_SEL_X:
                        {
                            ToySize[playerid][0] += Multiplier[playerid];
                            UpdateToyMaker(playerid);
                        }
                        case EDITOR_SEL_Y:
                        {
                            ToySize[playerid][1] += Multiplier[playerid];
                            UpdateToyMaker(playerid);
                        }
                        case EDITOR_SEL_Z:
                        {
                            ToySize[playerid][2] += Multiplier[playerid];
                            UpdateToyMaker(playerid);
                        }
                    }
                }
                case EDITOR_STATE_ROT:
                {
                    switch(SelectedXYZ[playerid])
                    {
                        case EDITOR_SEL_X:
                        {
                            ToyRot[playerid][0] += Multiplier[playerid];
                            UpdateToyMaker(playerid);
                        }
                        case EDITOR_SEL_Y:
                        {
                            ToyRot[playerid][1] += Multiplier[playerid];
                            UpdateToyMaker(playerid);
                        }
                        case EDITOR_SEL_Z:
                        {
                            ToyRot[playerid][2] += Multiplier[playerid];
                            UpdateToyMaker(playerid);
                        }
                    }
                }
            }
        }
        else if(playertextid == ToyEditorPTD[playerid][10]) //-
        {
            switch(EditorState[playerid])
            {
                case EDITOR_STATE_POS:
                {
                    switch(SelectedXYZ[playerid])
                    {
                        case EDITOR_SEL_X:
                        {
                            ToyPos[playerid][0] -= Multiplier[playerid];
                            UpdateToyMaker(playerid);
                        }
                        case EDITOR_SEL_Y:
                        {
                            ToyPos[playerid][1] -= Multiplier[playerid];
                            UpdateToyMaker(playerid);
                        }
                        case EDITOR_SEL_Z:
                        {
                            ToyPos[playerid][2] -= Multiplier[playerid];
                            UpdateToyMaker(playerid);
                        }
                    }
                }
                case EDITOR_STATE_SIZE:
                {
                    switch(SelectedXYZ[playerid])
                    {
                        case EDITOR_SEL_X:
                        {
                            ToySize[playerid][0] -= Multiplier[playerid];
                            UpdateToyMaker(playerid);
                        }
                        case EDITOR_SEL_Y:
                        {
                            ToySize[playerid][1] -= Multiplier[playerid];
                            UpdateToyMaker(playerid);
                        }
                        case EDITOR_SEL_Z:
                        {
                            ToySize[playerid][2] -= Multiplier[playerid];
                            UpdateToyMaker(playerid);
                        }
                    }
                }
                case EDITOR_STATE_ROT:
                {
                    switch(SelectedXYZ[playerid])
                    {
                        case EDITOR_SEL_X:
                        {
                            ToyRot[playerid][0] -= Multiplier[playerid];
                            UpdateToyMaker(playerid);
                        }
                        case EDITOR_SEL_Y:
                        {
                            ToyRot[playerid][1] -= Multiplier[playerid];
                            UpdateToyMaker(playerid);
                        }
                        case EDITOR_SEL_Z:
                        {
                            ToyRot[playerid][2] -= Multiplier[playerid];
                            UpdateToyMaker(playerid);
                        }
                    }
                }
            }
        }
        else if(playertextid == ToyEditorPTD[playerid][12])
        {
            CurrentSkin[playerid] --;
            UpdateToyMaker(playerid);
        }
        else if(playertextid == ToyEditorPTD[playerid][13])
        {
            CurrentSkin[playerid] ++;
            UpdateToyMaker(playerid);
        }
        else if(playertextid == ToyEditorPTD[playerid][15])
        {
            ShowPlayerDialog(playerid, DIALOG_MODEL_ID, DIALOG_STYLE_INPUT, "Modelo del Accesorio", "{d1d1d1}Escribe la ID del modelo del accesorio, para establecerlo:", "Seleccionar", "Cerrar");
        }
        else if(playertextid == ToyEditorPTD[playerid][16])
        {
            new dialog[45 * sizeof ToysBones], line_str[45];
			for(new i = 0; i != sizeof ToysBones; i ++)
			{
				format(line_str, sizeof(line_str), "{d1d1d1}%d. %s\n", i + 1, ToysBones[i]);
				strcat(dialog, line_str);
			}

            ShowPlayerDialog(playerid, DIALOG_SELECT_BONE, DIALOG_STYLE_LIST, "Parte del Cuerpo", dialog, "Seleccionar", "Cerrar");
        }
        else if(playertextid == ToyEditorPTD[playerid][17])
        {
            ShowPlayerDialog(playerid, DIALOG_TOY_NAME, DIALOG_STYLE_INPUT, "Exportar - Nombre", "{d1d1d1}Escribe el nombre de este toy para exportar:", "Continuar", "Cerrar");
        }
        else if(playertextid == ToyEditorPTD[playerid][18])
        {
            ShowPlayerDialog(playerid, DIALOG_MODIFY_MULTIPLIER, DIALOG_STYLE_LIST, "Multiplicador", "5.0\n4.0\n3.0\n2.0\n1.0\n0.5\n0.4\n0.3\n0.2\n0.1\n0.09\n0.08\n0.07\n0.06\n0.05\n0.04\n0.03\n0.02\n0.01", "Guardar", "Cerrar");
        }
        return 1;
    }
    return 1;
}

public OnPlayerClickTextDraw(playerid, Text:clickedid)
{
    if(clickedid == Text:INVALID_TEXT_DRAW)
    {
        if(InToyMaker[playerid])
        {
            HidePlayerToyMaker(playerid);
        }
        return 1;
    }
    return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    switch(dialogid)
    {
        case DIALOG_MODEL_ID:
        {
            if(response)
            {
                new toy;
                toy = strval(inputtext);
                ToyModelid[playerid] = toy;
                UpdateToyMaker(playerid);
            }
            return 1;
        }
        case DIALOG_SELECT_BONE:
        {
            if(response)
            {
                ToyBone[playerid] = listitem + 1;
                UpdateToyMaker(playerid);
            }
            return 1;
        }
        case DIALOG_TOY_NAME:
        {
            if(response)
            {
                if(isnull(inputtext))
                {
                    ShowPlayerDialog(playerid, DIALOG_TOY_NAME, DIALOG_STYLE_INPUT, "Exportar - Nombre", "{d1d1d1}Error: no escribiste nada, vuelve a intentarlo:", "Continuar", "Cerrar");
                    return 1;
                }
                
                if(strlen(inputtext) > 16)
                {
                    ShowPlayerDialog(playerid, DIALOG_TOY_NAME, DIALOG_STYLE_INPUT, "Exportar - Nombre", "{d1d1d1}Error: el texto es muy largo, vuelve a intentarlo (Max: 16 Caracteres):", "Continuar", "Cerrar");
                    return 1;
                }

                HidePlayerToyMaker(playerid);

                new File:export, str_text[512];
                format(str_text, 512, "/ToyMaker/Exports/%s.pwn", inputtext);
                export = fopen(str_text, io_write);
                format
                (
                    str_text, 512, 
                    "\
                        \r\n\
                        // Exportado por %s.\r\n\
                        // Nombre: %s\r\n\
                        // Skin: %d\r\n\
                        \r\n\
                        {0, %d, %d %f, %f, %f, %f, %f, %f, %f, %f, %f},\r\n\
                    ", 

                    ReturnPlayerName(playerid),
                    inputtext, 
                    CurrentSkin[playerid],

                    ToyModelid[playerid], 
                    ToyBone[playerid],

                    ToyPos[playerid][0], 
                    ToyPos[playerid][1], 
                    ToyPos[playerid][2], 
                    
                    ToyRot[playerid][0], 
                    ToyRot[playerid][1], 
                    ToyRot[playerid][2], 
                    ToySize[playerid][0], 
                    
                    ToySize[playerid][1], 
                    ToySize[playerid][2]
                );
                fwrite(export, str_text);
                fclose(export);

                SendClientMessage(playerid, X_INFO_COLOR, "[Info] {ffffff}Se ha intentado exportar el archivo.");
                SendClientMessage(playerid, X_ALERT_COLOR, "Si el archivo no aparece en scriptfiles/toymaker/ ha ocurrido un error");
            }
            return 1;
        }
        case DIALOG_MODIFY_MULTIPLIER:
        {
            if(response)
            {
                switch(listitem)
                {
                    case 0: Multiplier[playerid] = 5.0;
                    case 1: Multiplier[playerid] = 4.0;
                    case 2: Multiplier[playerid] = 3.0;
                    case 3: Multiplier[playerid] = 2.0;
                    case 4: Multiplier[playerid] = 1.0;
                    case 5: Multiplier[playerid] = 0.5;
                    case 6: Multiplier[playerid] = 0.4;
                    case 7: Multiplier[playerid] = 0.3;
                    case 8: Multiplier[playerid] = 0.2;
                    case 9: Multiplier[playerid] = 0.1;
                    case 10: Multiplier[playerid] = 0.09;
                    case 11: Multiplier[playerid] = 0.08;
                    case 12: Multiplier[playerid] = 0.07;
                    case 13: Multiplier[playerid] = 0.06;
                    case 14: Multiplier[playerid] = 0.05;
                    case 15: Multiplier[playerid] = 0.04;
                    case 16: Multiplier[playerid] = 0.03;
                    case 17: Multiplier[playerid] = 0.02;
                    case 18: Multiplier[playerid] = 0.01;
                }
            }
            return 1;
        }
        case DIALOG_SPECIAL_ACTION:
        {
            if(response)
            {
                switch(listitem)
                {
                    case 0: SetPlayerSpecialAction(playerid, SPECIAL_ACTION_NONE);
                    case 1: SetPlayerSpecialAction(playerid, SPECIAL_ACTION_USEJETPACK);
                    case 2: SetPlayerSpecialAction(playerid, SPECIAL_ACTION_DANCE1);
                    case 3: SetPlayerSpecialAction(playerid, SPECIAL_ACTION_DANCE2);
                    case 4: SetPlayerSpecialAction(playerid, SPECIAL_ACTION_DANCE3);
                    case 5: SetPlayerSpecialAction(playerid, SPECIAL_ACTION_DANCE4);
                    case 6: SetPlayerSpecialAction(playerid, SPECIAL_ACTION_HANDSUP);
                    case 7: SetPlayerSpecialAction(playerid, SPECIAL_ACTION_USECELLPHONE);
                    case 8: SetPlayerSpecialAction(playerid, SPECIAL_ACTION_SITTING);
                    case 9: SetPlayerSpecialAction(playerid, SPECIAL_ACTION_STOPUSECELLPHONE);
                    case 10: SetPlayerSpecialAction(playerid, SPECIAL_ACTION_DUCK);
                    case 11: SetPlayerSpecialAction(playerid, SPECIAL_ACTION_ENTER_VEHICLE);
                    case 12: SetPlayerSpecialAction(playerid, SPECIAL_ACTION_EXIT_VEHICLE);
                    case 13: SetPlayerSpecialAction(playerid, SPECIAL_ACTION_DRINK_BEER);
                    case 14: SetPlayerSpecialAction(playerid, SPECIAL_ACTION_SMOKE_CIGGY);
                    case 15: SetPlayerSpecialAction(playerid, SPECIAL_ACTION_DRINK_WINE);
                    case 16: SetPlayerSpecialAction(playerid, SPECIAL_ACTION_DRINK_SPRUNK);
                    case 17: SetPlayerSpecialAction(playerid, SPECIAL_ACTION_PISSING);
                    case 18: SetPlayerSpecialAction(playerid, SPECIAL_ACTION_CUFFED);
                    case 19: SetPlayerSpecialAction(playerid, SPECIAL_ACTION_CARRY);
                }
            }
            return 1;
        }
    }
    return 0;
}

public OnPlayerConnect(playerid)
{
    //Limpieza de variables para evitar bugs.
    CurrentSkin[playerid] = -1;
    for(new i = 0; i < 3; i++) ToyPos[playerid][i] = 0.0;
    for(new i = 0; i < 3; i++) ToyRot[playerid][i] = 0.0;
    for(new i = 0; i < 3; i++) ToySize[playerid][i] = 1.0;
    InToyMaker[playerid] = false;
    Multiplier[playerid] = 1.0;

    ToyModelid[playerid] = -1;
    ToyBone[playerid] = 1;

    EditorState[playerid] = EDITOR_STATE_NONE;
    SelectedXYZ[playerid] = EDITOR_SEL_NONE;

    RemovePlayerAttachedObject(playerid, 1);

    for(new i = 0; i < MAX_PTD_EDITOR; i++)
    {
        PlayerTextDrawDestroy(playerid, ToyEditorPTD[playerid][i]);
        ToyEditorPTD[playerid][i] = PlayerText:INVALID_TEXT_DRAW;
    }

    SetPlayerColor(playerid, 0xFFFFFFFF);

    ToyEditorPTD[playerid][0] = CreatePlayerTextDraw(playerid, 33.000000, 39.000000, "X");
    PlayerTextDrawFont(playerid, ToyEditorPTD[playerid][0], 1);
    PlayerTextDrawLetterSize(playerid, ToyEditorPTD[playerid][0], 1.700001, 6.200004);
    PlayerTextDrawTextSize(playerid, ToyEditorPTD[playerid][0], 50.000000, 55.000000);
    PlayerTextDrawSetOutline(playerid, ToyEditorPTD[playerid][0], 0);
    PlayerTextDrawSetShadow(playerid, ToyEditorPTD[playerid][0], 1);
    PlayerTextDrawAlignment(playerid, ToyEditorPTD[playerid][0], 2);
    PlayerTextDrawColor(playerid, ToyEditorPTD[playerid][0], -1);
    PlayerTextDrawBackgroundColor(playerid, ToyEditorPTD[playerid][0], 255);
    PlayerTextDrawBoxColor(playerid, ToyEditorPTD[playerid][0], 255);
    PlayerTextDrawUseBox(playerid, ToyEditorPTD[playerid][0], 1);
    PlayerTextDrawSetProportional(playerid, ToyEditorPTD[playerid][0], 1);
    PlayerTextDrawSetSelectable(playerid, ToyEditorPTD[playerid][0], 1);

    ToyEditorPTD[playerid][1] = CreatePlayerTextDraw(playerid, 95.000000, 39.000000, "Y");
    PlayerTextDrawFont(playerid, ToyEditorPTD[playerid][1], 1);
    PlayerTextDrawLetterSize(playerid, ToyEditorPTD[playerid][1], 1.700001, 6.200004);
    PlayerTextDrawTextSize(playerid, ToyEditorPTD[playerid][1], 50.000000, 55.000000);
    PlayerTextDrawSetOutline(playerid, ToyEditorPTD[playerid][1], 0);
    PlayerTextDrawSetShadow(playerid, ToyEditorPTD[playerid][1], 1);
    PlayerTextDrawAlignment(playerid, ToyEditorPTD[playerid][1], 2);
    PlayerTextDrawColor(playerid, ToyEditorPTD[playerid][1], -1);
    PlayerTextDrawBackgroundColor(playerid, ToyEditorPTD[playerid][1], 255);
    PlayerTextDrawBoxColor(playerid, ToyEditorPTD[playerid][1], 255);
    PlayerTextDrawUseBox(playerid, ToyEditorPTD[playerid][1], 1);
    PlayerTextDrawSetProportional(playerid, ToyEditorPTD[playerid][1], 1);
    PlayerTextDrawSetSelectable(playerid, ToyEditorPTD[playerid][1], 1);

    ToyEditorPTD[playerid][2] = CreatePlayerTextDraw(playerid, 158.000000, 39.000000, "Z");
    PlayerTextDrawFont(playerid, ToyEditorPTD[playerid][2], 1);
    PlayerTextDrawLetterSize(playerid, ToyEditorPTD[playerid][2], 1.700001, 6.200004);
    PlayerTextDrawTextSize(playerid, ToyEditorPTD[playerid][2], 50.000000, 55.000000);
    PlayerTextDrawSetOutline(playerid, ToyEditorPTD[playerid][2], 0);
    PlayerTextDrawSetShadow(playerid, ToyEditorPTD[playerid][2], 1);
    PlayerTextDrawAlignment(playerid, ToyEditorPTD[playerid][2], 2);
    PlayerTextDrawColor(playerid, ToyEditorPTD[playerid][2], -1);
    PlayerTextDrawBackgroundColor(playerid, ToyEditorPTD[playerid][2], 255);
    PlayerTextDrawBoxColor(playerid, ToyEditorPTD[playerid][2], 255);
    PlayerTextDrawUseBox(playerid, ToyEditorPTD[playerid][2], 1);
    PlayerTextDrawSetProportional(playerid, ToyEditorPTD[playerid][2], 1);
    PlayerTextDrawSetSelectable(playerid, ToyEditorPTD[playerid][2], 1);

    ToyEditorPTD[playerid][3] = CreatePlayerTextDraw(playerid, 33.000000, 158.000000, "X");
    PlayerTextDrawFont(playerid, ToyEditorPTD[playerid][3], 1);
    PlayerTextDrawLetterSize(playerid, ToyEditorPTD[playerid][3], 1.700001, 6.200004);
    PlayerTextDrawTextSize(playerid, ToyEditorPTD[playerid][3], 50.000000, 55.000000);
    PlayerTextDrawSetOutline(playerid, ToyEditorPTD[playerid][3], 0);
    PlayerTextDrawSetShadow(playerid, ToyEditorPTD[playerid][3], 1);
    PlayerTextDrawAlignment(playerid, ToyEditorPTD[playerid][3], 2);
    PlayerTextDrawColor(playerid, ToyEditorPTD[playerid][3], -1);
    PlayerTextDrawBackgroundColor(playerid, ToyEditorPTD[playerid][3], 255);
    PlayerTextDrawBoxColor(playerid, ToyEditorPTD[playerid][3], 255);
    PlayerTextDrawUseBox(playerid, ToyEditorPTD[playerid][3], 1);
    PlayerTextDrawSetProportional(playerid, ToyEditorPTD[playerid][3], 1);
    PlayerTextDrawSetSelectable(playerid, ToyEditorPTD[playerid][3], 1);

    ToyEditorPTD[playerid][4] = CreatePlayerTextDraw(playerid, 95.000000, 158.000000, "Y");
    PlayerTextDrawFont(playerid, ToyEditorPTD[playerid][4], 1);
    PlayerTextDrawLetterSize(playerid, ToyEditorPTD[playerid][4], 1.700001, 6.200004);
    PlayerTextDrawTextSize(playerid, ToyEditorPTD[playerid][4], 50.000000, 55.000000);
    PlayerTextDrawSetOutline(playerid, ToyEditorPTD[playerid][4], 0);
    PlayerTextDrawSetShadow(playerid, ToyEditorPTD[playerid][4], 1);
    PlayerTextDrawAlignment(playerid, ToyEditorPTD[playerid][4], 2);
    PlayerTextDrawColor(playerid, ToyEditorPTD[playerid][4], -1);
    PlayerTextDrawBackgroundColor(playerid, ToyEditorPTD[playerid][4], 255);
    PlayerTextDrawBoxColor(playerid, ToyEditorPTD[playerid][4], 255);
    PlayerTextDrawUseBox(playerid, ToyEditorPTD[playerid][4], 1);
    PlayerTextDrawSetProportional(playerid, ToyEditorPTD[playerid][4], 1);
    PlayerTextDrawSetSelectable(playerid, ToyEditorPTD[playerid][4], 1);

    ToyEditorPTD[playerid][5] = CreatePlayerTextDraw(playerid, 158.000000, 158.000000, "Z");
    PlayerTextDrawFont(playerid, ToyEditorPTD[playerid][5], 1);
    PlayerTextDrawLetterSize(playerid, ToyEditorPTD[playerid][5], 1.700001, 6.200004);
    PlayerTextDrawTextSize(playerid, ToyEditorPTD[playerid][5], 50.000000, 55.000000);
    PlayerTextDrawSetOutline(playerid, ToyEditorPTD[playerid][5], 0);
    PlayerTextDrawSetShadow(playerid, ToyEditorPTD[playerid][5], 1);
    PlayerTextDrawAlignment(playerid, ToyEditorPTD[playerid][5], 2);
    PlayerTextDrawColor(playerid, ToyEditorPTD[playerid][5], -1);
    PlayerTextDrawBackgroundColor(playerid, ToyEditorPTD[playerid][5], 255);
    PlayerTextDrawBoxColor(playerid, ToyEditorPTD[playerid][5], 255);
    PlayerTextDrawUseBox(playerid, ToyEditorPTD[playerid][5], 1);
    PlayerTextDrawSetProportional(playerid, ToyEditorPTD[playerid][5], 1);
    PlayerTextDrawSetSelectable(playerid, ToyEditorPTD[playerid][5], 1);

    ToyEditorPTD[playerid][6] = CreatePlayerTextDraw(playerid, 33.000000, 271.000000, "X");
    PlayerTextDrawFont(playerid, ToyEditorPTD[playerid][6], 1);
    PlayerTextDrawLetterSize(playerid, ToyEditorPTD[playerid][6], 1.700001, 6.200004);
    PlayerTextDrawTextSize(playerid, ToyEditorPTD[playerid][6], 50.000000, 55.000000);
    PlayerTextDrawSetOutline(playerid, ToyEditorPTD[playerid][6], 0);
    PlayerTextDrawSetShadow(playerid, ToyEditorPTD[playerid][6], 1);
    PlayerTextDrawAlignment(playerid, ToyEditorPTD[playerid][6], 2);
    PlayerTextDrawColor(playerid, ToyEditorPTD[playerid][6], -1);
    PlayerTextDrawBackgroundColor(playerid, ToyEditorPTD[playerid][6], 255);
    PlayerTextDrawBoxColor(playerid, ToyEditorPTD[playerid][6], 255);
    PlayerTextDrawUseBox(playerid, ToyEditorPTD[playerid][6], 1);
    PlayerTextDrawSetProportional(playerid, ToyEditorPTD[playerid][6], 1);
    PlayerTextDrawSetSelectable(playerid, ToyEditorPTD[playerid][6], 1);

    ToyEditorPTD[playerid][7] = CreatePlayerTextDraw(playerid, 95.000000, 271.000000, "Y");
    PlayerTextDrawFont(playerid, ToyEditorPTD[playerid][7], 1);
    PlayerTextDrawLetterSize(playerid, ToyEditorPTD[playerid][7], 1.700001, 6.200004);
    PlayerTextDrawTextSize(playerid, ToyEditorPTD[playerid][7], 50.000000, 55.000000);
    PlayerTextDrawSetOutline(playerid, ToyEditorPTD[playerid][7], 0);
    PlayerTextDrawSetShadow(playerid, ToyEditorPTD[playerid][7], 1);
    PlayerTextDrawAlignment(playerid, ToyEditorPTD[playerid][7], 2);
    PlayerTextDrawColor(playerid, ToyEditorPTD[playerid][7], -1);
    PlayerTextDrawBackgroundColor(playerid, ToyEditorPTD[playerid][7], 255);
    PlayerTextDrawBoxColor(playerid, ToyEditorPTD[playerid][7], 255);
    PlayerTextDrawUseBox(playerid, ToyEditorPTD[playerid][7], 1);
    PlayerTextDrawSetProportional(playerid, ToyEditorPTD[playerid][7], 1);
    PlayerTextDrawSetSelectable(playerid, ToyEditorPTD[playerid][7], 1);

    ToyEditorPTD[playerid][8] = CreatePlayerTextDraw(playerid, 158.000000, 271.000000, "Z");
    PlayerTextDrawFont(playerid, ToyEditorPTD[playerid][8], 1);
    PlayerTextDrawLetterSize(playerid, ToyEditorPTD[playerid][8], 1.700001, 6.200004);
    PlayerTextDrawTextSize(playerid, ToyEditorPTD[playerid][8], 50.000000, 55.000000);
    PlayerTextDrawSetOutline(playerid, ToyEditorPTD[playerid][8], 0);
    PlayerTextDrawSetShadow(playerid, ToyEditorPTD[playerid][8], 1);
    PlayerTextDrawAlignment(playerid, ToyEditorPTD[playerid][8], 2);
    PlayerTextDrawColor(playerid, ToyEditorPTD[playerid][8], -1);
    PlayerTextDrawBackgroundColor(playerid, ToyEditorPTD[playerid][8], 255);
    PlayerTextDrawBoxColor(playerid, ToyEditorPTD[playerid][8], 255);
    PlayerTextDrawUseBox(playerid, ToyEditorPTD[playerid][8], 1);
    PlayerTextDrawSetProportional(playerid, ToyEditorPTD[playerid][8], 1);
    PlayerTextDrawSetSelectable(playerid, ToyEditorPTD[playerid][8], 1);

    ToyEditorPTD[playerid][9] = CreatePlayerTextDraw(playerid, 10.000000, 385.000000, "ld_beat:left");
    PlayerTextDrawFont(playerid, ToyEditorPTD[playerid][9], 4);
    PlayerTextDrawLetterSize(playerid, ToyEditorPTD[playerid][9], 1.700001, 6.200004);
    PlayerTextDrawTextSize(playerid, ToyEditorPTD[playerid][9], 50.000000, 55.000000);
    PlayerTextDrawSetOutline(playerid, ToyEditorPTD[playerid][9], 0);
    PlayerTextDrawSetShadow(playerid, ToyEditorPTD[playerid][9], 1);
    PlayerTextDrawAlignment(playerid, ToyEditorPTD[playerid][9], 2);
    PlayerTextDrawColor(playerid, ToyEditorPTD[playerid][9], -1);
    PlayerTextDrawBackgroundColor(playerid, ToyEditorPTD[playerid][9], 255);
    PlayerTextDrawBoxColor(playerid, ToyEditorPTD[playerid][9], 255);
    PlayerTextDrawUseBox(playerid, ToyEditorPTD[playerid][9], 1);
    PlayerTextDrawSetProportional(playerid, ToyEditorPTD[playerid][9], 1);
    PlayerTextDrawSetSelectable(playerid, ToyEditorPTD[playerid][9], 1);

    ToyEditorPTD[playerid][10] = CreatePlayerTextDraw(playerid, 135.000000, 385.000000, "ld_beat:right");
    PlayerTextDrawFont(playerid, ToyEditorPTD[playerid][10], 4);
    PlayerTextDrawLetterSize(playerid, ToyEditorPTD[playerid][10], 1.700001, 6.200004);
    PlayerTextDrawTextSize(playerid, ToyEditorPTD[playerid][10], 50.000000, 55.000000);
    PlayerTextDrawSetOutline(playerid, ToyEditorPTD[playerid][10], 0);
    PlayerTextDrawSetShadow(playerid, ToyEditorPTD[playerid][10], 1);
    PlayerTextDrawAlignment(playerid, ToyEditorPTD[playerid][10], 2);
    PlayerTextDrawColor(playerid, ToyEditorPTD[playerid][10], -1);
    PlayerTextDrawBackgroundColor(playerid, ToyEditorPTD[playerid][10], 255);
    PlayerTextDrawBoxColor(playerid, ToyEditorPTD[playerid][10], 255);
    PlayerTextDrawUseBox(playerid, ToyEditorPTD[playerid][10], 1);
    PlayerTextDrawSetProportional(playerid, ToyEditorPTD[playerid][10], 1);
    PlayerTextDrawSetSelectable(playerid, ToyEditorPTD[playerid][10], 1);

    ToyEditorPTD[playerid][11] = CreatePlayerTextDraw(playerid, 96.000000, 405.000000, "0.0");
    PlayerTextDrawFont(playerid, ToyEditorPTD[playerid][11], 2);
    PlayerTextDrawLetterSize(playerid, ToyEditorPTD[playerid][11], 0.600000, 2.000000);
    PlayerTextDrawTextSize(playerid, ToyEditorPTD[playerid][11], 0.000000, 0.000000);
    PlayerTextDrawSetOutline(playerid, ToyEditorPTD[playerid][11], 0);
    PlayerTextDrawSetShadow(playerid, ToyEditorPTD[playerid][11], 1);
    PlayerTextDrawAlignment(playerid, ToyEditorPTD[playerid][11], 2);
    PlayerTextDrawColor(playerid, ToyEditorPTD[playerid][11], -1);
    PlayerTextDrawBackgroundColor(playerid, ToyEditorPTD[playerid][11], 255);
    PlayerTextDrawBoxColor(playerid, ToyEditorPTD[playerid][11], 1687547391);
    PlayerTextDrawUseBox(playerid, ToyEditorPTD[playerid][11], 0);
    PlayerTextDrawSetProportional(playerid, ToyEditorPTD[playerid][11], 1);
    PlayerTextDrawSetSelectable(playerid, ToyEditorPTD[playerid][11], 0);

    ToyEditorPTD[playerid][12] = CreatePlayerTextDraw(playerid, 240.000000, 360.000000, "ld_beat:left");
    PlayerTextDrawFont(playerid, ToyEditorPTD[playerid][12], 4);
    PlayerTextDrawLetterSize(playerid, ToyEditorPTD[playerid][12], 0.600000, 2.000000);
    PlayerTextDrawTextSize(playerid, ToyEditorPTD[playerid][12], 35.000000, 32.000000);
    PlayerTextDrawSetOutline(playerid, ToyEditorPTD[playerid][12], 1);
    PlayerTextDrawSetShadow(playerid, ToyEditorPTD[playerid][12], 0);
    PlayerTextDrawAlignment(playerid, ToyEditorPTD[playerid][12], 2);
    PlayerTextDrawColor(playerid, ToyEditorPTD[playerid][12], -1);
    PlayerTextDrawBackgroundColor(playerid, ToyEditorPTD[playerid][12], 255);
    PlayerTextDrawBoxColor(playerid, ToyEditorPTD[playerid][12], 50);
    PlayerTextDrawUseBox(playerid, ToyEditorPTD[playerid][12], 0);
    PlayerTextDrawSetProportional(playerid, ToyEditorPTD[playerid][12], 1);
    PlayerTextDrawSetSelectable(playerid, ToyEditorPTD[playerid][12], 1);

    ToyEditorPTD[playerid][13] = CreatePlayerTextDraw(playerid, 363.000000, 360.000000, "ld_beat:right");
    PlayerTextDrawFont(playerid, ToyEditorPTD[playerid][13], 4);
    PlayerTextDrawLetterSize(playerid, ToyEditorPTD[playerid][13], 0.600000, 2.000000);
    PlayerTextDrawTextSize(playerid, ToyEditorPTD[playerid][13], 35.000000, 32.000000);
    PlayerTextDrawSetOutline(playerid, ToyEditorPTD[playerid][13], 1);
    PlayerTextDrawSetShadow(playerid, ToyEditorPTD[playerid][13], 0);
    PlayerTextDrawAlignment(playerid, ToyEditorPTD[playerid][13], 2);
    PlayerTextDrawColor(playerid, ToyEditorPTD[playerid][13], -1);
    PlayerTextDrawBackgroundColor(playerid, ToyEditorPTD[playerid][13], 255);
    PlayerTextDrawBoxColor(playerid, ToyEditorPTD[playerid][13], 50);
    PlayerTextDrawUseBox(playerid, ToyEditorPTD[playerid][13], 0);
    PlayerTextDrawSetProportional(playerid, ToyEditorPTD[playerid][13], 1);
    PlayerTextDrawSetSelectable(playerid, ToyEditorPTD[playerid][13], 1);

    ToyEditorPTD[playerid][14] = CreatePlayerTextDraw(playerid, 320.000000, 365.000000, "0");
    PlayerTextDrawFont(playerid, ToyEditorPTD[playerid][14], 2);
    PlayerTextDrawLetterSize(playerid, ToyEditorPTD[playerid][14], 0.600000, 2.000000);
    PlayerTextDrawTextSize(playerid, ToyEditorPTD[playerid][14], 400.000000, 17.000000);
    PlayerTextDrawSetOutline(playerid, ToyEditorPTD[playerid][14], 0);
    PlayerTextDrawSetShadow(playerid, ToyEditorPTD[playerid][14], 1);
    PlayerTextDrawAlignment(playerid, ToyEditorPTD[playerid][14], 2);
    PlayerTextDrawColor(playerid, ToyEditorPTD[playerid][14], -1);
    PlayerTextDrawBackgroundColor(playerid, ToyEditorPTD[playerid][14], 255);
    PlayerTextDrawBoxColor(playerid, ToyEditorPTD[playerid][14], 50);
    PlayerTextDrawUseBox(playerid, ToyEditorPTD[playerid][14], 0);
    PlayerTextDrawSetProportional(playerid, ToyEditorPTD[playerid][14], 1);
    PlayerTextDrawSetSelectable(playerid, ToyEditorPTD[playerid][14], 0);

    ToyEditorPTD[playerid][15] = CreatePlayerTextDraw(playerid, 570.000000, 410.000000, "ID_Modelo");
    PlayerTextDrawFont(playerid, ToyEditorPTD[playerid][15], 1);
    PlayerTextDrawLetterSize(playerid, ToyEditorPTD[playerid][15], 0.449999, 2.000000);
    PlayerTextDrawTextSize(playerid, ToyEditorPTD[playerid][15], 15.000000, 105.000000);
    PlayerTextDrawSetOutline(playerid, ToyEditorPTD[playerid][15], 0);
    PlayerTextDrawSetShadow(playerid, ToyEditorPTD[playerid][15], 1);
    PlayerTextDrawAlignment(playerid, ToyEditorPTD[playerid][15], 2);
    PlayerTextDrawColor(playerid, ToyEditorPTD[playerid][15], -1);
    PlayerTextDrawBackgroundColor(playerid, ToyEditorPTD[playerid][15], 255);
    PlayerTextDrawBoxColor(playerid, ToyEditorPTD[playerid][15], 255);
    PlayerTextDrawUseBox(playerid, ToyEditorPTD[playerid][15], 1);
    PlayerTextDrawSetProportional(playerid, ToyEditorPTD[playerid][15], 1);
    PlayerTextDrawSetSelectable(playerid, ToyEditorPTD[playerid][15], 1);

    ToyEditorPTD[playerid][16] = CreatePlayerTextDraw(playerid, 570.000000, 380.000000, "Bones");
    PlayerTextDrawFont(playerid, ToyEditorPTD[playerid][16], 1);
    PlayerTextDrawLetterSize(playerid, ToyEditorPTD[playerid][16], 0.449999, 2.000000);
    PlayerTextDrawTextSize(playerid, ToyEditorPTD[playerid][16], 15.000000, 105.000000);
    PlayerTextDrawSetOutline(playerid, ToyEditorPTD[playerid][16], 0);
    PlayerTextDrawSetShadow(playerid, ToyEditorPTD[playerid][16], 1);
    PlayerTextDrawAlignment(playerid, ToyEditorPTD[playerid][16], 2);
    PlayerTextDrawColor(playerid, ToyEditorPTD[playerid][16], -1);
    PlayerTextDrawBackgroundColor(playerid, ToyEditorPTD[playerid][16], 255);
    PlayerTextDrawBoxColor(playerid, ToyEditorPTD[playerid][16], 255);
    PlayerTextDrawUseBox(playerid, ToyEditorPTD[playerid][16], 1);
    PlayerTextDrawSetProportional(playerid, ToyEditorPTD[playerid][16], 1);
    PlayerTextDrawSetSelectable(playerid, ToyEditorPTD[playerid][16], 1);

    ToyEditorPTD[playerid][17] = CreatePlayerTextDraw(playerid, 570.000000, 322.000000, "Guardar");
    PlayerTextDrawFont(playerid, ToyEditorPTD[playerid][17], 1);
    PlayerTextDrawLetterSize(playerid, ToyEditorPTD[playerid][17], 0.449999, 2.000000);
    PlayerTextDrawTextSize(playerid, ToyEditorPTD[playerid][17], 15.000000, 105.000000);
    PlayerTextDrawSetOutline(playerid, ToyEditorPTD[playerid][17], 0);
    PlayerTextDrawSetShadow(playerid, ToyEditorPTD[playerid][17], 1);
    PlayerTextDrawAlignment(playerid, ToyEditorPTD[playerid][17], 2);
    PlayerTextDrawColor(playerid, ToyEditorPTD[playerid][17], -1);
    PlayerTextDrawBackgroundColor(playerid, ToyEditorPTD[playerid][17], 255);
    PlayerTextDrawBoxColor(playerid, ToyEditorPTD[playerid][17], 255);
    PlayerTextDrawUseBox(playerid, ToyEditorPTD[playerid][17], 1);
    PlayerTextDrawSetProportional(playerid, ToyEditorPTD[playerid][17], 1);
    PlayerTextDrawSetSelectable(playerid, ToyEditorPTD[playerid][17], 1);

    ToyEditorPTD[playerid][18] = CreatePlayerTextDraw(playerid, 570.000000, 351.000000, "Multiplicador");
    PlayerTextDrawFont(playerid, ToyEditorPTD[playerid][18], 1);
    PlayerTextDrawLetterSize(playerid, ToyEditorPTD[playerid][18], 0.449999, 2.000000);
    PlayerTextDrawTextSize(playerid, ToyEditorPTD[playerid][18], 15.000000, 105.000000);
    PlayerTextDrawSetOutline(playerid, ToyEditorPTD[playerid][18], 0);
    PlayerTextDrawSetShadow(playerid, ToyEditorPTD[playerid][18], 1);
    PlayerTextDrawAlignment(playerid, ToyEditorPTD[playerid][18], 2);
    PlayerTextDrawColor(playerid, ToyEditorPTD[playerid][18], -1);
    PlayerTextDrawBackgroundColor(playerid, ToyEditorPTD[playerid][18], 255);
    PlayerTextDrawBoxColor(playerid, ToyEditorPTD[playerid][18], 255);
    PlayerTextDrawUseBox(playerid, ToyEditorPTD[playerid][18], 1);
    PlayerTextDrawSetProportional(playerid, ToyEditorPTD[playerid][18], 1);
    PlayerTextDrawSetSelectable(playerid, ToyEditorPTD[playerid][18], 1);
    return 1;
}

public OnPlayerRequestClass(playerid, classid)
{
    SetSpawnInfo(playerid, NO_TEAM, 0, 1284.4456, -1652.4658, 13.5469, 270.0, 0, 0, 0, 0, 0, 0);
    SpawnPlayer(playerid);
    return 0;
}

public OnPlayerRequestSpawn(playerid)
{
    SetSpawnInfo(playerid, NO_TEAM, 0, 1284.4456, -1652.4658, 13.5469, 270.0, 0, 0, 0, 0, 0, 0);
    SpawnPlayer(playerid);
    return 1;
}

public OnPlayerSpawn(playerid)
{
    SendPlayerToysInfo(playerid);
}

public OnPlayerText(playerid, text[])
{
    new str_text[1024];
    format(str_text, 1024, "%s (%d) dice: %s", ReturnPlayerName(playerid), playerid, text);
    
    for(new i = 0; i != MAX_PLAYERS; i++)
    {
        if(InToyMaker[i]) continue;

        SendClientMessage(i, -1, str_text);
    }
    return 0;
}

//Callbacks
public OnGameModeInit()
{
    SetGameModeText(SERVER_INFO);
    SendRconCommand("hostname "HOSTNAME"");
    SendRconCommand("language San Andreas");
    SendRconCommand("mapname ToyMaker");

    UsePlayerPedAnims();
    DisableInteriorEnterExits();
    EnableStuntBonusForAll(false);

    ToyEditorTD[0] = TextDrawCreate(0.000000, -256.000000, "Fondo_XYZ");
    TextDrawFont(ToyEditorTD[0], 1);
    TextDrawLetterSize(ToyEditorTD[0], 0.000000, 512.000000);
    TextDrawTextSize(ToyEditorTD[0], 0.000000, 384.000000);
    TextDrawSetOutline(ToyEditorTD[0], 1);
    TextDrawSetShadow(ToyEditorTD[0], 0);
    TextDrawAlignment(ToyEditorTD[0], 2);
    TextDrawColor(ToyEditorTD[0], -1);
    TextDrawBackgroundColor(ToyEditorTD[0], 255);
    TextDrawBoxColor(ToyEditorTD[0], 115);
    TextDrawUseBox(ToyEditorTD[0], 1);
    TextDrawSetProportional(ToyEditorTD[0], 1);
    TextDrawSetSelectable(ToyEditorTD[0], 0);

    ToyEditorTD[1] = TextDrawCreate(90.000000, 7.000000, "Posicion");
    TextDrawFont(ToyEditorTD[1], 2);
    TextDrawLetterSize(ToyEditorTD[1], 0.600000, 2.000000);
    TextDrawTextSize(ToyEditorTD[1], 400.000000, 17.000000);
    TextDrawSetOutline(ToyEditorTD[1], 0);
    TextDrawSetShadow(ToyEditorTD[1], 1);
    TextDrawAlignment(ToyEditorTD[1], 2);
    TextDrawColor(ToyEditorTD[1], -1);
    TextDrawBackgroundColor(ToyEditorTD[1], 255);
    TextDrawBoxColor(ToyEditorTD[1], 50);
    TextDrawUseBox(ToyEditorTD[1], 0);
    TextDrawSetProportional(ToyEditorTD[1], 1);
    TextDrawSetSelectable(ToyEditorTD[1], 0);

    ToyEditorTD[2] = TextDrawCreate(90.000000, 130.000000, "Magnitud");
    TextDrawFont(ToyEditorTD[2], 2);
    TextDrawLetterSize(ToyEditorTD[2], 0.600000, 2.000000);
    TextDrawTextSize(ToyEditorTD[2], 400.000000, 17.000000);
    TextDrawSetOutline(ToyEditorTD[2], 0);
    TextDrawSetShadow(ToyEditorTD[2], 1);
    TextDrawAlignment(ToyEditorTD[2], 2);
    TextDrawColor(ToyEditorTD[2], -1);
    TextDrawBackgroundColor(ToyEditorTD[2], 255);
    TextDrawBoxColor(ToyEditorTD[2], 50);
    TextDrawUseBox(ToyEditorTD[2], 0);
    TextDrawSetProportional(ToyEditorTD[2], 1);
    TextDrawSetSelectable(ToyEditorTD[2], 0);

    ToyEditorTD[3] = TextDrawCreate(90.000000, 242.000000, "Rotacion");
    TextDrawFont(ToyEditorTD[3], 2);
    TextDrawLetterSize(ToyEditorTD[3], 0.600000, 2.000000);
    TextDrawTextSize(ToyEditorTD[3], 400.000000, 17.000000);
    TextDrawSetOutline(ToyEditorTD[3], 0);
    TextDrawSetShadow(ToyEditorTD[3], 1);
    TextDrawAlignment(ToyEditorTD[3], 2);
    TextDrawColor(ToyEditorTD[3], -1);
    TextDrawBackgroundColor(ToyEditorTD[3], 255);
    TextDrawBoxColor(ToyEditorTD[3], 50);
    TextDrawUseBox(ToyEditorTD[3], 0);
    TextDrawSetProportional(ToyEditorTD[3], 1);
    TextDrawSetSelectable(ToyEditorTD[3], 0);

    ToyEditorTD[4] = TextDrawCreate(96.000000, 364.000000, "Valor");
    TextDrawFont(ToyEditorTD[4], 2);
    TextDrawLetterSize(ToyEditorTD[4], 0.600000, 2.000000);
    TextDrawTextSize(ToyEditorTD[4], 400.000000, 17.000000);
    TextDrawSetOutline(ToyEditorTD[4], 0);
    TextDrawSetShadow(ToyEditorTD[4], 1);
    TextDrawAlignment(ToyEditorTD[4], 2);
    TextDrawColor(ToyEditorTD[4], -1);
    TextDrawBackgroundColor(ToyEditorTD[4], 255);
    TextDrawBoxColor(ToyEditorTD[4], 50);
    TextDrawUseBox(ToyEditorTD[4], 0);
    TextDrawSetProportional(ToyEditorTD[4], 1);
    TextDrawSetSelectable(ToyEditorTD[4], 0);
    return 1;
}

CMD:toys(playerid, params[])
{
    for(new i = 0; i != 120; i++)
    {
        SendClientMessage(playerid, -1, "");
    }

    ShowPlayerToyMaker(playerid);
    return 1;
}

CMD:anim(playerid, params[])
{
    //if(InToyMaker[playerid]) return SendClientMessage(playerid, X_ALERT_COLOR, "Debes salir del editor.");
    new animlib[64], animname[64];
    if(sscanf(params, "s[64]s[64]", animlib, animname)) return SendClientMessage(playerid, X_ALERT_COLOR, "Usa /anim [animlib] [animname]");

    ApplyAnimation(playerid, animlib, animname, 4.1, false, false, false, true, false, false);
    return 1;
}

CMD:stop(playerid)
{
    ClearAnimations(playerid, false);
    return 1;
}

CMD:rtoy(playerid, params[])
{
    HidePlayerToyMaker(playerid);

    CurrentSkin[playerid] = -1;
    for(new i = 0; i < 3; i++) ToyPos[playerid][i] = 0.0;
    for(new i = 0; i < 3; i++) ToyRot[playerid][i] = 0.0;
    for(new i = 0; i < 3; i++) ToySize[playerid][i] = 1.0;
    InToyMaker[playerid] = false;
    Multiplier[playerid] = 1.0;

    ToyModelid[playerid] = -1;
    ToyBone[playerid] = 1;

    EditorState[playerid] = EDITOR_STATE_NONE;
    SelectedXYZ[playerid] = EDITOR_SEL_NONE;

    RemovePlayerAttachedObject(playerid, 1);

    SendClientMessage(playerid, X_ALERT_COLOR, "Se han establecido los valores por defecto en el editor.");
    return 1;
}

CMD:skin(playerid, params[])
{
    if(sscanf(params, "d", params[0])) return SendClientMessage(playerid, X_ALERT_COLOR, "Usa /skin [ID]");
    if(params[0] > 311)
    {
        CurrentSkin[playerid] = 311;
        SetPlayerSkin(playerid, CurrentSkin[playerid]);
        SendClientMessage(playerid, X_ALERT_COLOR, "Solo hay 311 skins.");
        return 1;
    }

    CurrentSkin[playerid] = params[0];
    SetPlayerSkin(playerid, CurrentSkin[playerid]);

    SendClientMessage(playerid, -1, "Tu skin se ha cambiado.");
    return 1;
}

CMD:pc(playerid, params[])
{
    if(!InToyMaker[playerid]) return SendClientMessage(playerid, X_ALERT_COLOR, "No estas en el editor de toys.");
    if(ToyModelid[playerid] == -1) return SendClientMessage(playerid, X_ALERT_COLOR, "No has creado un toy.");
    
    HidePlayerToyMaker(playerid);
    EditAttachedObject(playerid, 1);

    SendClientMessage(playerid, X_ALERT_COLOR, "Si no puedes ver el editor significa que estas bug, o no eres de PC.");
    return 1;
}

CMD:actions(playerid, params[])
{
    if(InToyMaker[playerid]) return SendClientMessage(playerid, X_ALERT_COLOR, "Debes salir del editor.");

    new dialog[128 * sizeof SpecialActions], line_str[256];
    for(new i = 0; i != sizeof SpecialActions; i ++)
    {
        format(line_str, sizeof(line_str), "%s\n", SpecialActions[i]);
        strcat(dialog, line_str);
    }

    ShowPlayerDialog(playerid, DIALOG_SPECIAL_ACTION, DIALOG_STYLE_LIST, "SetPlayerSpecialAction", dialog, "Continuar", "Cerrar");
    return 1;
}

main() {}