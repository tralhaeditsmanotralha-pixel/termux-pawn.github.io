// Filterscript: FreeBikeFS.pwn
#include <a_samp>

#define PICKUP_ICON        1318   // Ícone azul
#define VEHICLE_BIKE       481    // BMX
#define VEHICLE_MOTO       462    // Faggio
#define DIALOG_FREEBIKE    12345  // ID único

// Cores
#define COR_AZULCLARO 0x00BFFFFF
#define COR_VERDE     0x00FF00FF
#define COR_VERMELHO  0xFF0000FF
#define COR_BRANCO    0xFFFFFFFF

// Variáveis globais
new freeBikePickup;
new Float:pickupX, Float:pickupY, Float:pickupZ;
new bool:pickupAtivo = false;
new playerVehicle[MAX_PLAYERS];

// Função auxiliar: cria posição à frente do player
stock GetXYInFrontOfPlayer(playerid, &Float:x, &Float:y, Float:dist)
{
    new Float:a, Float:rad;
    GetPlayerFacingAngle(playerid, a);             // ângulo do player em graus
    rad = a * (3.14159265 / 180.0);                // converte para radianos
    x += dist * floatsin(-rad);                    // desloca X
    y += dist * floatcos(-rad);                    // desloca Y
    return 1;
}

// FS inicia
public OnFilterScriptInit()
{
    for (new i = 0; i < MAX_PLAYERS; i++) playerVehicle[i] = INVALID_VEHICLE_ID;

    print("\n--------------------------------------");
    print(" FreeBike Filterscript carregado com sucesso!");
    print("--------------------------------------\n");
    return 1;
}

public OnFilterScriptExit()
{
    if (pickupAtivo)
    {
        DestroyPickup(freeBikePickup);
        pickupAtivo = false; // garante reset
    }
    print("\n--------------------------------------");
    print(" FreeBike Filterscript descarregado.");
    print("--------------------------------------\n");
    return 1;
}

// Comandos
public OnPlayerCommandText(playerid, cmdtext[])
{
    if (!strcmp("/criarponto", cmdtext, true))
    {
        if (pickupAtivo)
        {
            SendClientMessage(playerid, COR_VERMELHO, "Já existe um ponto criado! Use /removerponto antes.");
            return 1;
        }

        GetPlayerPos(playerid, pickupX, pickupY, pickupZ);
        freeBikePickup = CreatePickup(PICKUP_ICON, 1, pickupX, pickupY, pickupZ, -1);
        pickupAtivo = true;

        SendClientMessage(playerid, COR_AZULCLARO, "Você criou um ponto de moto/bicicleta grátis!");
        return 1;
    }

    if (!strcmp("/removerponto", cmdtext, true))
    {
        if (!pickupAtivo)
        {
            SendClientMessage(playerid, COR_VERMELHO, "Nenhum ponto ativo para remover!");
            return 1;
        }

        DestroyPickup(freeBikePickup);
        pickupAtivo = false;
        SendClientMessage(playerid, COR_VERMELHO, "Você removeu o ponto de moto/bicicleta grátis!");
        return 1;
    }

    if (!strcmp("/destruirveiculo", cmdtext, true))
    {
        if (playerVehicle[playerid] == INVALID_VEHICLE_ID)
        {
            SendClientMessage(playerid, COR_VERMELHO, "Você não tem veículo ativo para destruir!");
            return 1;
        }

        DestroyVehicle(playerVehicle[playerid]);
        playerVehicle[playerid] = INVALID_VEHICLE_ID;
        SendClientMessage(playerid, COR_VERMELHO, "Seu veículo grátis foi destruído!");
        return 1;
    }

    return 0;
}

// Pickup
public OnPlayerPickUpPickup(playerid, pickupid)
{
    if (!pickupAtivo) return 0; // proteção extra

    if (pickupid == freeBikePickup)
    {
        if (playerVehicle[playerid] != INVALID_VEHICLE_ID)
        {
            SendClientMessage(playerid, COR_VERMELHO, "Você já tem um veículo ativo! Use /destruirveiculo antes.");
            return 1;
        }

        ShowPlayerDialog(playerid, DIALOG_FREEBIKE, DIALOG_STYLE_LIST,
            "Escolha um veículo",
            "Bicicleta (BMX)\nMoto (Faggio)",
            "Selecionar", "Cancelar");
    }
    return 1;
}

// Resposta do menu
public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    if (dialogid == DIALOG_FREEBIKE && response)
    {
        new Float:x, Float:y, Float:z, Float:a;
        GetPlayerPos(playerid, x, y, z);
        GetPlayerFacingAngle(playerid, a);
        GetXYInFrontOfPlayer(playerid, x, y, 3.0); // 3 metros à frente

        if (listitem == 0) // Bicicleta
        {
            playerVehicle[playerid] = CreateVehicle(VEHICLE_BIKE, x, y, z, a, 0, 0, -1);
            if (playerVehicle[playerid] == INVALID_VEHICLE_ID)
            {
                SendClientMessage(playerid, COR_VERMELHO, "Erro ao criar a bicicleta!");
                return 1;
            }
            SendClientMessage(playerid, COR_VERDE, "Bicicleta grátis criada!");
            GameTextForPlayer(playerid, "~p~AGRADEÇA AO MICA", 4000, 3);
        }
        else if (listitem == 1) // Moto
        {
            playerVehicle[playerid] = CreateVehicle(VEHICLE_MOTO, x, y, z, a, 0, 0, -1);
            if (playerVehicle[playerid] == INVALID_VEHICLE_ID)
            {
                SendClientMessage(playerid, COR_VERMELHO, "Erro ao criar a moto!");
                return 1;
            }
            ChangeVehicleColor(playerVehicle[playerid], 0, 0); // Preto
            SendClientMessage(playerid, COR_VERDE, "Moto grátis criada!");
            GameTextForPlayer(playerid, "~p~AGRADEÇA AO MICA", 4000, 3);
        }
    }
    return 1;
}

// Reset ao sair
public OnPlayerDisconnect(playerid, reason)
{
    if (playerVehicle[playerid] != INVALID_VEHICLE_ID)
    {
        DestroyVehicle(playerVehicle[playerid]);
        playerVehicle[playerid] = INVALID_VEHICLE_ID;
    }
    return 1;
}

// Reset ao explodir veículo
public OnVehicleDeath(vehicleid, killerid)
{
    for (new i = 0; i < MAX_PLAYERS; i++)
    {
        if (playerVehicle[i] == vehicleid)
        {
            playerVehicle[i] = INVALID_VEHICLE_ID;
            SendClientMessage(i, COR_VERMELHO, "Seu veículo grátis foi destruído!");
            break;
        }
    }
    return 1;
}
