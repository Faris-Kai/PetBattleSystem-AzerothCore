/*
 * Este archivo es el punto de entrada que AzerothCore detecta
 * automaticamente al escanear la carpeta modules/ durante la
 * configuracion de CMake. SIN este archivo, las clases definidas
 * en mod_pet_battle.cpp (comando /dp y hooks de gossip) nunca se
 * registran en el servidor, aunque el modulo compile sin errores.
 *
 * La funcion debe llamarse "Add" + <nombre_de_la_carpeta_del_modulo
 * con guiones reemplazados por guiones bajos> + "Scripts".
 * Carpeta: mod-pet-battle  ->  Addmod_pet_battleScripts
 */

void AddSC_mod_pet_battle();

void Addmod_pet_battleScripts()
{
    AddSC_mod_pet_battle();
}
