#pragma once

#include <hxcpp.h>
#include <hx/CFFI.h>

#include "../lib/lua/src/lua.hpp"

namespace linc {

    namespace hooks {
        extern void install_limits(lua_State *L, int instructionLimit, int memoryLimitKB);
        extern void remove_limits(lua_State *L);
        extern int protected_open_jit(lua_State *L);
        extern int protected_open_ffi(lua_State *L);
        extern int protected_open_package(lua_State *L);
    } // hooks

} // linc
