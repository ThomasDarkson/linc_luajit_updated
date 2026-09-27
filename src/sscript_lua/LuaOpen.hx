package sscript_lua;

import sscript_lua.State;

@:include('linc_lua.h')
extern class LuaOpen
{
	@:native('luaopen_base')
	public static function base(l:State):Int;

	@:native('luaopen_math')
	public static function math(l:State):Int;

	@:native('luaopen_string')
	public static function string(l:State):Int;

	@:native('luaopen_table')
	public static function table(l:State):Int;

	@:native('luaopen_io')
	public static function io(l:State):Int;

	@:native('luaopen_os')
	public static function os(l:State):Int;

	@:native('luaopen_package')
	public static function lpackage(l:State):Int; // renamed from "package"

	@:native('luaopen_debug')
	public static function debug(l:State):Int;

	@:native('luaopen_bit')
	public static function bit(l:State):Int;

	@:native('luaopen_jit')
	public static function jit(l:State):Int;

	@:native('luaopen_ffi')
	public static function ffi(l:State):Int;
} // LuaOpen
