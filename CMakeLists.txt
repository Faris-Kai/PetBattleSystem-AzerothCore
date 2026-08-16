# Copyright (C) 2016+ AzerothCore <www.azerothcore.org>
# Licensed under GNU AGPL v3 license: https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
#
# CMakeLists.txt del modulo mod-pet-battle
#
# Este modulo se registra agregando cada archivo .cpp directamente a la
# lista de scripts del core mediante la macro AC_ADD_SCRIPT, que es el
# mecanismo que usa AzerothCore (y este fork npcbots) para compilar los
# modulos dentro del target "worldserver" (no existe un target separado
# llamado "modules" en esta version del core).

file(GLOB_RECURSE sources_mod_pet_battle "${CMAKE_CURRENT_LIST_DIR}/src/*.cpp")

foreach(source ${sources_mod_pet_battle})
    AC_ADD_SCRIPT(${source})
endforeach()
