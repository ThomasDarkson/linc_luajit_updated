#include <hxcpp.h>
#include <hx/CFFI.h>

#include "./sscript_lua_hooks.h"
#include "../lib/lua/src/lua.hpp"

namespace linc {

    namespace hooks {

        namespace {

            struct Limits {
                long long instructionLimit;
                long long instructionCount;
                long long memoryLimitKB;
            };

            char kLimitsKey = 0;

            void countHook(lua_State *L, lua_Debug *ar) {

                lua_pushlightuserdata(L, &kLimitsKey);
                lua_rawget(L, LUA_REGISTRYINDEX);
                Limits *lim = (Limits *)lua_touserdata(L, -1);
                lua_pop(L, 1);

                if (lim == NULL)
                    return;

                lim->instructionCount += 1000;

                if (lim->instructionLimit > 0 && lim->instructionCount >= lim->instructionLimit) {
                    luaL_error(L, "instruction limit of %d exceeded (sandboxed script)", (int)lim->instructionLimit);
                    return;
                }

                if (lim->memoryLimitKB > 0) {
                    int kb = lua_gc(L, LUA_GCCOUNT, 0);
                    if (kb >= lim->memoryLimitKB) {
                        luaL_error(L, "memory limit of %dKB exceeded (sandboxed script)", (int)lim->memoryLimitKB);
                        return;
                    }
                }

            }

        } 

        void install_limits(lua_State *L, int instructionLimit, int memoryLimitKB) {

            if (instructionLimit <= 0 && memoryLimitKB <= 0) {
                remove_limits(L);
                return;
            }

            lua_pushlightuserdata(L, &kLimitsKey);
            Limits *lim = (Limits *)lua_newuserdata(L, sizeof(Limits));
            lim->instructionLimit = instructionLimit;
            lim->instructionCount = 0;
            lim->memoryLimitKB = memoryLimitKB;
            lua_rawset(L, LUA_REGISTRYINDEX);

            lua_sethook(L, countHook, LUA_MASKCOUNT, 1000);

        }

        void remove_limits(lua_State *L) {

            lua_pushlightuserdata(L, &kLimitsKey);
            lua_pushnil(L);
            lua_rawset(L, LUA_REGISTRYINDEX);

            lua_sethook(L, NULL, 0, 0);

        }

        int protected_open_jit(lua_State *L) {
            lua_pushcfunction(L, luaopen_jit);
            int status = lua_pcall(L, 0, 1, 0);
            lua_pop(L, 1);
            return status;
        }

        int protected_open_ffi(lua_State *L) {
            lua_pushcfunction(L, luaopen_ffi);
            int status = lua_pcall(L, 0, 1, 0);
            if (status == LUA_OK)
                lua_setglobal(L, "ffi"); 
            else
                lua_pop(L, 1);
            return status;
        }

        int protected_open_package(lua_State *L) {
            lua_pushcfunction(L, luaopen_package);
            int status = lua_pcall(L, 0, 1, 0);
            lua_pop(L, 1);
            return status;
        }

    } // hooks

} // linc
