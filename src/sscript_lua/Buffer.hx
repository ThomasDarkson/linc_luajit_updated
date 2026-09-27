package sscript_lua;

import sscript_lua.State;

@:noCompletion
@:structAccess
@:include('linc_lua.h') @:native("::luaL_Buffer")
extern class LuaL_Buffer
{
	public var p:String; // current position in buffer
	public var lvl:Int; // number of strings in the stack (level)
	public var L:State;
	public var buffer:String;
}

@:include('linc_lua.h') @:native("::cpp::Reference<luaL_Buffer>")
extern class BufferRef extends LuaL_Buffer {}
