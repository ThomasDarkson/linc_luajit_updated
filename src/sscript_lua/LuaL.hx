package sscript_lua;

import sscript_lua.State;
import sscript_lua.Buffer;

@:include('linc_lua.h')
extern class LuaL
{
	@:native('luaL_getmetafield')
	public static function getmetafield(l:State, obj:Int, e:String):Int;

	@:native('luaL_callmeta')
	public static function callmeta(l:State, obj:Int, e:String):Int;

	@:native('luaL_typerror')
	public static function typerror(l:State, narg:Int, tname:String):Int;

	@:native('luaL_argerror')
	public static function argerror(l:State, narg:Int, extramsg:String):Int;

	@:native('linc::lual::checklstring')
	public static function checklstring(l:State, narg:Int, l:UInt):String;

	@:native('linc::lual::optlstring')
	public static function optlstring(l:State, narg:Int, d:String, l:UInt):String;

	@:native('luaL_checknumber')
	public static function checknumber(l:State, narg:Int):Float;

	@:native('luaL_optnumber')
	public static function optnumber(l:State, narg:Int, d:Float):Float;

	@:native('luaL_checkinteger')
	public static function checkinteger(l:State, narg:Int):Int;

	@:native('luaL_optinteger')
	public static function optinteger(l:State, narg:Int, d:Int):Int;

	@:native('luaL_checkstack')
	public static function checkstack(l:State, sz:Int, msg:String):Void;

	@:native('luaL_checktype')
	public static function checktype(l:State, narg:Int, t:Int):Void;

	@:native('luaL_checkany')
	public static function checkany(l:State, narg:Int):Void;

	@:native('luaL_newmetatable')
	public static function newmetatable(l:State, tname:String):Int;

	@:native('luaL_checkudata')
	public static function checkudata(l:State, narg:Int, tname:String):Void;

	@:native('luaL_where')
	public static function where(l:State, lvl:Int):Void;

	@:native('luaL_checkoption')
	public static function checkoption(l:State, narg:Int, def:String, const:Array<String>):Int;

	@:native('luaL_ref')
	public static function ref(l:State, t:Int):Int;

	@:native('luaL_unref')
	public static function unref(l:State, t:Int, ref:Int):Void;

	@:native('luaL_loadfile')
	public static function loadfile(l:State, filename:String):Int;

	@:native('luaL_loadbuffer')
	public static function loadbuffer(l:State, buff:String, sz:Int, name:String):Int;

	@:native('luaL_loadstring')
	public static function loadstring(l:State, s:String):Int;

	@:native('luaL_newstate')
	public static function newstate():State;

	@:native('linc::lual::gsub')
	public static function gsub(l:State, s:String, p:String, r:String):String;

	@:native('linc::lual::findtable')
	public static function findtable(l:State, idx:Int, fname:String, szhint:Int):String;

	/* From Lua 5.2. */

	@:native('luaL_fileresult')
	public static function fileresult(l:State, stat:Int, tname:String):Int;

	@:native('luaL_execresult')
	public static function execresult(l:State, stat:Int):Int;

	@:native('luaL_loadfilex')
	public static function loadfilex(l:State, filename:String, mode:String):Int;

	@:native('luaL_loadbufferx')
	public static function loadbufferx(l:State, buff:String, sz:Int, name:String, mode:String):Int;

	@:native('luaL_traceback')
	public static function traceback(l:State, l2:State, msg:String, level:Int):Void;

	/*
	** ===============================================================
	** some useful macros
	** ===============================================================
	*/

	@:native('luaL_argcheck')
	public static function argcheck(l:State, cond:Int, narg:Int, extramsg:String):Void;

	@:native('linc::lual::checkstring')
	public static function checkstring(l:State, narg:Int):String;

	@:native('linc::lual::optstring')
	public static function optstring(l:State, narg:Int, d:String):String;

	@:native('luaL_checkint')
	public static function checkint(l:State, narg:Int):Int;

	@:native('luaL_optint')
	public static function optint(l:State, narg:Int, d:Int):Int;

	@:native('luaL_checklong')
	public static function checklong(l:State, narg:Int):Float;

	@:native('luaL_optlong')
	public static function optlong(l:State, narg:Int, d:Float):Float;

	@:native('linc::lual::ltypename')
	public static function typename(l:State, index:Int):String;

	@:native('luaL_dofile')
	public static function dofile(l:State, filename:String):Int;

	@:native('luaL_dostring')
	public static function dostring(l:State, str:String):Int;

	@:native('luaL_getmetatable')
	public static function getmetatable(l:State, tname:String):Void;

	/*
	** {======================================================
	** Generic Buffer manipulation
	** =======================================================
	*/

	@:native('luaL_addchar')
	public static function addchar(b:BufferRef, c:String):Void;

	/* compatibility only */
	@:native('luaL_putchar')
	public static function putchar(b:BufferRef, c:String):Void;

	@:native('luaL_addsize')
	public static function addsize(b:BufferRef, n:Int):Void;

	@:native('luaL_buffinit')
	public static function buffinit(l:State, b:BufferRef):Void;

	@:native('linc::lual::prepbuffer')
	public static function prepbuffer(b:BufferRef):String;

	@:native('luaL_addlstring')
	public static function addlstring(b:BufferRef, s:String, l:Int):Void;

	@:native('luaL_addstring')
	public static function addstring(b:BufferRef, s:String):Void;

	@:native('luaL_addvalue')
	public static function addvalue(b:BufferRef):Void;

	@:native('luaL_pushresult')
	public static function pushresult(b:BufferRef):Void;

	/* }====================================================== */

	/* compatibility with ref system */

	/* predefined references */
	public static inline var LUA_NOREF:Int = (-2);
	public static inline var LUA_REFNIL:Int = (-1);

	@:native('luaL_openlibs')
	public static function openlibs(l:State):Void;

	@:native('linc::lual::error')
	public static function error(l:State, fmt:String):Int;
} // LuaL
