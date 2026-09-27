package sscript_lua;

import sscript_lua.State;
import sscript_lua.Convert;

@:keep
@:include('linc_lua.h')
@:include('sscript_lua_hooks.h')
#if !display
@:build(linc.Linc.touch())
@:build(linc.Linc.xml('lua'))
#end
extern class Lua
{
	@:native('lua_upvalueindex')
	public static function upvalueindex(i:Int):Int;

	/* option for multiple returns in `lua_pcall' and `lua_call' */
	public static inline var LUA_MULTRET:Int = (-1);

	/* pseudo-indices */

	public static inline var LUA_REGISTRYINDEX:Int = (-10000);
	public static inline var LUA_ENVIRONINDEX:Int = (-10001);
	public static inline var LUA_GLOBALSINDEX:Int = (-10002);

	/* thread status */

	public static inline var LUA_OK:Int = 0;
	public static inline var LUA_YIELD:Int = 1;
	public static inline var LUA_ERRRUN:Int = 2;
	public static inline var LUA_ERRSYNTAX:Int = 3;
	public static inline var LUA_ERRMEM:Int = 4;
	public static inline var LUA_ERRERR:Int = 5;

	/* basic types */

	public static inline var LUA_TNONE:Int = (-1);

	public static inline var LUA_TNIL:Int = 0;
	public static inline var LUA_TBOOLEAN:Int = 1;
	public static inline var LUA_TLIGHTUSERDATA:Int = 2;
	public static inline var LUA_TNUMBER:Int = 3;
	public static inline var LUA_TSTRING:Int = 4;
	public static inline var LUA_TTABLE:Int = 5;
	public static inline var LUA_TFUNCTION:Int = 6;
	public static inline var LUA_TUSERDATA:Int = 7;
	public static inline var LUA_TTHREAD:Int = 8;

	/* minimum Lua stack available to a C function */

	public static inline var LUA_MINSTACK:Int = 20;

	/* state manipulation */

	@:native('lua_close')
	public static function close(l:State):Void;

	@:native('lua_newthread')
	public static function newthread(l:State):State;

	/* basic stack manipulation */

	@:native('lua_gettop')
	public static function gettop(l:State):Int;

	@:native('lua_settop')
	public static function settop(l:State, idx:Int):Void;

	@:native('lua_pushvalue')
	public static function pushvalue(l:State, idx:Int):Void;

	@:native('lua_remove')
	public static function remove(l:State, idx:Int):Void;

	@:native('lua_insert')
	public static function insert(l:State, idx:Int):Void;

	@:native('lua_replace')
	public static function replace(l:State, idx:Int):Void;

	@:native('lua_checkstack')
	public static function checkstack(l:State, sz:Int):Int;

	@:native('lua_xmove')
	public static function xmove(from:State, to:State, n:Int):Void;

	/* access functions (stack -> C) */

	@:noCompletion
	@:native('lua_isnumber')
	static function _isnumber(l:State, idx:Int):Int;

	public static inline function isnumber(l:State, idx:Int):Bool
	{
		return _isnumber(l, idx) != 0;
	}

	@:noCompletion
	@:native('lua_isstring')
	static function _isstring(l:State, idx:Int):Int;

	public static inline function isstring(l:State, idx:Int):Bool
	{
		return _isstring(l, idx) != 0;
	}

	@:noCompletion
	@:native('lua_iscfunction')
	static function _iscfunction(l:State, idx:Int):Int;

	public static inline function iscfunction(l:State, idx:Int):Bool
	{
		return _iscfunction(l, idx) != 0;
	}

	@:noCompletion
	@:native('lua_isuserdata')
	static function _isuserdata(l:State, idx:Int):Int;

	public static inline function isuserdata(l:State, idx:Int):Bool
	{
		return _isuserdata(l, idx) != 0;
	}

	@:native('lua_type')
	public static function type(l:State, idx:Int):Int;

	@:native('linc::lua::_typename')
	public static function typename(l:State, tp:Int):String;

	@:native('lua_equal')
	public static function equal(l:State, idx1:Int, idx2:Int):Int;

	@:native('lua_rawequal')
	public static function rawequal(l:State, idx1:Int, idx2:Int):Int;

	@:native('lua_lessthan')
	public static function lessthan(l:State, idx1:Int, idx2:Int):Int;

	@:native('lua_tonumber')
	public static function tonumber(l:State, idx:Int):Float;

	@:native('lua_tointeger')
	public static function tointeger(l:State, idx:Int):Int;

	@:noCompletion
	@:native('lua_toboolean')
	static function _toboolean(l:State, idx:Int):Int;

	public static inline function toboolean(l:State, idx:Int):Bool
	{
		return _toboolean(l, idx) != 0;
	}

	@:native('linc::lua::tolstring')
	public static function tolstring(l:State, idx:Int, len:UInt):String;

	@:native('lua_objlen')
	public static function objlen(l:State, idx:Int):Int;

	@:native('lua_touserdata')
	public static function touserdata(l:State, idx:Int):Void;

	@:native('lua_tothread')
	public static function tothread(l:State, idx:Int):State;

	@:native('lua_topointer')
	public static function topointer(l:State, idx:Int):Void;

	/* push functions (C -> stack) */

	@:native('lua_pushnil')
	public static function pushnil(l:State):Void;

	@:native('lua_pushnumber')
	public static function pushnumber(l:State, n:Float):Void;

	@:native('lua_pushinteger')
	public static function pushinteger(l:State, n:Int):Void;

	@:native('lua_pushlstring')
	public static function pushlstring(l:State, s:String, len:Int):Void;

	@:native('lua_pushstring')
	public static function pushstring(l:State, s:String):Void;

	@:noCompletion
	@:native('lua_pushboolean')
	static function _pushboolean(l:State, b:Int):Void;

	public static inline function pushboolean(l:State, b:Bool):Void
	{
		_pushboolean(l, b == true ? 1 : 0);
	}

	@:native('lua_pushthread')
	public static function pushthread(l:State):Int;

	/* get functions (Lua -> stack) */

	@:native('lua_gettable')
	public static function gettable(l:State, idx:Int):Void;

	@:native('lua_getfield')
	public static function getfield(l:State, idx:Int, k:String):Void;

	@:native('lua_rawget')
	public static function rawget(l:State, idx:Int):Void;

	@:native('lua_rawgeti')
	public static function rawgeti(l:State, idx:Int, n:Int):Void;

	@:native('lua_createtable')
	public static function createtable(l:State, narr:Int, nrec:Int):Void;

	@:native('lua_newuserdata')
	public static function newuserdata(l:State, size:Int):Void;

	@:native('lua_getmetatable')
	public static function getmetatable(l:State, objindex:Int):Int;

	@:native('lua_getfenv')
	public static function getfenv(l:State, int:Int):Void;

	/* set functions (stack -> Lua) */

	@:native('lua_settable')
	public static function settable(l:State, idx:Int):Void;

	@:native('lua_setfield')
	public static function setfield(l:State, idx:Int, s:String):Void;

	@:native('lua_rawset')
	public static function rawset(l:State, idx:Int):Void;

	@:native('lua_rawseti')
	public static function rawseti(l:State, idx:Int, n:Int):Void;

	@:native('lua_setmetatable')
	public static function setmetatable(l:State, objindex:Int):Int;

	@:native('lua_setfenv')
	public static function lua_setfenv(l:State, idx:Int):Int;

	/* `load' and `call' functions (load and run Lua code) */

	@:native('lua_call')
	public static function call(l:State, nargs:Int, nresults:Int):Void;

	@:native('lua_pcall')
	public static function pcall(l:State, nargs:Int, nresults:Int, errfunc:Int):Int;

	/* coroutine functions */

	@:native('lua_yield')
	public static function yield(l:State, n:Int):Int;

	@:native('lua_resume')
	public static function resume(l:State, narg:Int):Int;

	@:native('lua_status')
	public static function status(l:State):Int;

	/* garbage-collection function and options */

	public static inline var LUA_GCSTOP:Int = 0;
	public static inline var LUA_GCRESTART:Int = 1;
	public static inline var LUA_GCCOLLECT:Int = 2;
	public static inline var LUA_GCCOUNT:Int = 3;
	public static inline var LUA_GCCOUNTB:Int = 4;
	public static inline var LUA_GCSTEP:Int = 5;
	public static inline var LUA_GCSETPAUSE:Int = 6;
	public static inline var LUA_GCSETSTEPMUL:Int = 7;

	@:native('lua_gc')
	public static function gc(l:State, what:Int, data:Int):Int;

	/* miscellaneous functions */

	@:native('lua_error')
	public static function error(l:State):Int;

	@:native('lua_next')
	public static function next(l:State, idx:Int):Int;

	@:native('lua_concat')
	public static function concat(l:State, n:Int):Void;

	/* some useful macros */

	@:native('lua_pop')
	public static function pop(l:State, n:Int):Void;

	@:native('lua_newtable')
	public static function newtable(l:State):Void;

	public static inline function register(l:State, name:String, f:Dynamic):Void
	{
		if (Type.typeof(f) == Type.ValueType.TFunction && !Lua_helper.callbacks.exists(name))
		{
			Lua_helper.add_callback(l, name, f);
		}
	}

	@:native('lua_strlen')
	public static function strlen(l:State, idx:Int):Int;

	@:native('lua_isfunction')
	public static function isfunction(l:State, idx:Int):Int;

	@:native('lua_istable')
	public static function istable(l:State, idx:Int):Int;

	@:native('lua_islightuserdata')
	public static function islightuserdata(l:State, idx:Int):Int;

	@:native('lua_isnil')
	public static function isnil(l:State, idx:Int):Int;

	@:native('lua_isboolean')
	public static function isboolean(l:State, idx:Int):Int;

	@:native('lua_isthread')
	public static function isthread(l:State, idx:Int):Int;

	@:native('lua_isnone')
	public static function isnone(l:State, idx:Int):Int;

	@:native('lua_isnoneornil')
	public static function isnoneornil(l:State, idx:Int):Int;

	@:native('lua_pushliteral')
	public static function pushliteral(l:State, s:String):Void;

	@:native('lua_setglobal')
	public static function setglobal(l:State, name:String):Void;

	@:noCompletion
	@:native('lua_getglobal')
	static function _getglobal(l:State, name:String):Void;

	/**
		Pushes the global `name` onto the stack, like Lua 5.1's `lua_getglobal`,
		but -- like Lua 5.3+'s `lua_getglobal` -- returns the Lua type of the
		pushed value (one of the `Lua.LUA_T*` constants), so callers don't need a
		separate `Lua.type(l, -1)` call to know what they got.
	**/
	public static inline function getglobal(l:State, name:String):Int
	{
		_getglobal(l, name);
		return Lua.type(l, -1);
	}

	@:native('linc::lua::tostring')
	public static function tostring(l:State, idx:Int):String;

	/* hack */
	@:native('lua_setlevel')
	public static function setlevel(from:State, to:State):Void;

	/*
	** {======================================================================
	** Debug API
	** =======================================================================
	*/

	/* Event codes */

	public static inline var LUA_HOOKCALL:Int = 0;
	public static inline var LUA_HOOKRET:Int = 1;
	public static inline var LUA_HOOKLINE:Int = 2;
	public static inline var LUA_HOOKCOUNT:Int = 3;
	public static inline var LUA_HOOKTAILRET:Int = 4;

	/* Event masks */

	public static inline var LUA_MASKCALL:Int = (1 << LUA_HOOKCALL);
	public static inline var LUA_MASKRET:Int = (1 << LUA_HOOKRET);
	public static inline var LUA_MASKLINE:Int = (1 << LUA_HOOKLINE);
	public static inline var LUA_MASKCOUNT:Int = (1 << LUA_HOOKCOUNT);

	/* Functions to be called by the debugger in specific events */

	@:native('linc::lua::getstack')
	public static function getstack(l:State, level:Int, ar:Lua_Debug):Int;

	@:native('linc::lua::getinfo')
	public static function getinfo(l:State, what:String, ar:Lua_Debug):Int;

	@:native('lua_getupvalue')
	public static function getupvalue(l:State, funcindex:Int, n:Int):String;

	@:native('lua_setupvalue')
	public static function setupvalue(l:State, funcindex:Int, n:Int):String;

	@:native('lua_gethookmask')
	public static function gethookmask(l:State):Int;

	@:native('lua_gethookcount')
	public static function gethookcount(l:State):Int;

	/* From Lua 5.2. */

	@:native('lua_upvalueid')
	public static function upvalueid(l:State, idx:Int, n:Int):Void;

	@:native('lua_upvaluejoin')
	public static function upvaluejoin(l:State, idx1:Int, n1:Int, idx2:Int, n2:Int):Void;

	/* compatibility with ref system */

	@:native('lua_ref')
	public static function ref(l:State, lock:Bool):Int;

	@:native('lua_unref')
	public static function unref(l:State, ref:Int):Void;

	@:native('lua_getref')
	public static function getref(l:State, ref:Int):Void;

	/* unofficial API helpers */

	@:native('linc::lua::version')
	public static function version():String;

	@:native('linc::lua::versionJIT')
	public static function versionJIT():String;

	public static inline function init_callbacks(?handler:State->String->Int):Void
	{
		Lua.set_callbacks_function(cpp.Callable.fromStaticFunction(Lua_helper.callback_handler));
	}

	@:native('linc::callbacks::set_callbacks_function')
	static function set_callbacks_function(f:cpp.Callable<State->String->Int>):Void;

	@:native('linc::callbacks::add_callback_function')
	public static function add_callback_function(l:State, name:String):Void;

	@:native('linc::callbacks::remove_callback_function')
	public static function remove_callback_function(l:State, name:String):Void;

	@:native('linc::helpers::register_hxtrace_lib')
	public static function register_hxtrace_lib(l:State):Void;

	@:native('linc::helpers::register_hxtrace_func')
	public static function register_hxtrace_func(f:cpp.Callable<String->Int>):Void;

	@:native('linc::hooks::install_limits')
	public static function install_limits(l:State, instructionLimit:Int, memoryLimitKB:Int):Void;

	@:native('linc::hooks::remove_limits')
	public static function remove_limits(l:State):Void;

	@:native('linc::hooks::protected_open_jit')
	public static function protected_open_jit(l:State):Int;

	@:native('linc::hooks::protected_open_ffi')
	public static function protected_open_ffi(l:State):Int;

	@:native('linc::hooks::protected_open_package')
	public static function protected_open_package(l:State):Int;
} // Lua

class Lua_helper
{
	static inline function print_function(s:String):Int
	{
		Lua_helper.trace(s);
		return 0;
	}

	public static inline function register_hxtrace(l:State):Void
	{
		Lua.register_hxtrace_func(cpp.Callable.fromStaticFunction(print_function));
		Lua.register_hxtrace_lib(l);
	}

	public static dynamic function trace(s:String, ?inf:haxe.PosInfos):Void
	{
		trace(s);
	}

	public static var callbacks:Map<String, Dynamic> = new Map();

	public static inline function add_callback(l:State, fname:String, f:Dynamic):Bool
	{
		callbacks.set(fname, f);
		Lua.add_callback_function(l, fname);
		return true;
	}

	public static inline function remove_callback(l:State, fname:String):Bool
	{
		callbacks.remove(fname);
		Lua.remove_callback_function(l, fname);
		return true;
	}

	public static var sendErrorsToLua:Bool = true;

	public static inline function callback_handler(l:State, fname:String):Int
	{
		try
		{
			var cbf = callbacks.get(fname);

			if (cbf == null)
				return 0;

			var args:Array<Dynamic> = [];

			for (i in 0...Lua.gettop(l))
				args[i] = Convert.fromLua(l, i + 1);

			var ret:Dynamic = Reflect.callMethod(null, cbf, args);

			if (ret != null)
			{
				Convert.toLua(l, ret);
				return 1;
			}
		}
		catch (e:Dynamic)
		{
			if (sendErrorsToLua)
			{
				LuaL.error(l, 'CALLBACK ERROR! ${if (e.message != null) e.message else e}');
				return 0;
			}
			trace(e);
			throw (e);
		}
		return 0;
	} // callback_handler
}

typedef Lua_Debug =
{
	@:optional var event:Int;
	@:optional var name:String; // (n)
	@:optional var namewhat:String; // (n) `global', `local', `field', `method'
	@:optional var what:String; // (S) `Lua', `C', `main', `tail'
	@:optional var source:String; // (S)
	@:optional var currentline:Int; // (l)
	@:optional var nups:Int; // (u) number of upvalues
	@:optional var linedefined:Int; // (S)
	@:optional var lastlinedefined:Int; // (S)
	@:optional var short_src:Array<String>; // (S)

	@:optional var i_ci:Int; // private
}
