package sscript_lua;

import haxe.Exception;
import haxe.Timer;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

import sscript_lua.Lua;
import sscript_lua.Lua.Lua_helper;
import sscript_lua.LuaL;
import sscript_lua.Convert;
import sscript_lua.State;

import sscript_lua.backend.LuaSandbox;
import sscript_lua.backend.LuaSandbox.LuaLib;
import sscript_lua.backend.LuaSandbox.LuaSandboxOption;
import sscript_lua.backend.LuaSandbox.LuaSandboxSettings;

import SysInfo;
import SysInfo.Converter;
#if (lime && openfl)
import SysInfo.OpenFLSysInfo;
#end

using StringTools;

@:allow(sscript_lua.SScript_Lua)
/**
	Class containing several useful pieces of information about function calls.
**/
final class FunctionCall
{
	/**
		If the call was successful or not.
	**/
	public var succeeded(default, null):Bool;
	/**
		Name of the function that was called.
	**/
	public var calledFunction(default, null):String;
	/**
		Function's return value. Will be null if there is no value.
	**/
	public var returnValue(default, null):Null<Dynamic>;
	/**
		Errors that occurred during this call. Will be empty if none occurred.
	**/
	public var exception(default, null):Exception;

	function new() {
	}

	private function set_succeeded(s:Bool):FunctionCall
	{
		this.succeeded = s;
		return this;
	}

	private function set_calledFunction(s:String):FunctionCall
	{
		this.calledFunction = s;
		return this;
	}
	
	private function set_returnValue(s:Null<Dynamic>):FunctionCall
	{
		this.returnValue = s;
		return this;
	}
	private function set_exception(s:Exception):FunctionCall
	{
		this.exception = s;
		return this;
	}
}

/**
	A Lua execution helper with functions for running, executing, and interacting with Lua scripts.

	To get started, create an SScript_Lua instance:

	```haxe
	import sscript_lua.SScript_Lua;
	class Main {
		static function main() {
			var script = new SScript_Lua();
			script.doString('
				function method()
					return 1 + 1
				end
			');

			var call = script.call('method');
			trace(call.returnValue, call.exceptions[0]); // 2, null
		}
	}
	```

	You can also use files!

	```haxe
	import sscript_lua.SScript_Lua;
	class Main {
		static function main() {
			var script = new SScript_Lua("script.lua");
			var call = script.call('method');
			trace(call.returnValue, call.exceptions[0]);
		}
	}
	```

	@see `doString`
	@see `set`
	@see `call`
**/
@:structInit
@:keepSub
class SScript_Lua
{
	/**
		If not null, enables error traces for all of the methods.

		@see `traces`
	**/
	public static var defaultTraces:Null<Bool> = null;

	/**
		If not null, when a script is created, the function with this name
		will automatically be called.

		Default is `"main"`.
	**/
	public static var defaultFun:{functionName:String, ?arguments:Array<Dynamic>} = null;

	/**
		Every created SScript_Lua instance is stored in this map, keyed by its `ID`.
	**/
	public static var global(default, null):Map<Int, SScript_Lua> = [];

	/**
		Variables in this map will get set to all created SScript_Lua instance.
	**/
	public static var globalVariables(default, null):Map<String, Dynamic> = [];

	/**
		Lua version SScript_Lua is bundled with.

		Lua version, as of 09/26, is **Lua 5.1.4**.
	**/
	public static var luaVersion(get, never):String;

	/**
		LuaJIT version SScript_Lua is bundled with.

		LuaJIT version, as of 09/26, is **LuaJIT 2.1.1788856981**.
	**/
	public static var luaJITVersion(get, never):String;

	/**
		Which Lua library got linked into this build, as `"<Platform>/<Architecture>"`, e.g. `"Linux/x86_64"`,
		`"Android/arm64-v8a"`, `"Mac/arm64"`. `"iPhone"` on iOS.
	**/
	public static var luaLibVariant(default, never):String =
		#if windows
			#if HXCPP_M64
				"Windows/x86_64"
			#elseif HXCPP_M32
				"Windows/x86"
			#else
				"Windows/unknown"
			#end
		#elseif linux
			#if HXCPP_M64
				"Linux/x86_64"
			#elseif HXCPP_ARM64
				"Linux/aarch64"
			#else
				"Linux/unknown"
			#end
		#elseif mac
			#if HXCPP_ARM64
				"Mac/arm64"
			#elseif HXCPP_M64
				"Mac/x86_64"
			#else
				"Mac/unknown"
			#end
		#elseif android
			#if HXCPP_ARM64
				"Android/arm64-v8a"
			#elseif HXCPP_ARMV7
				"Android/armeabi-v7a"
			#elseif HXCPP_X86_64
				"Android/x86_64"
			#elseif HXCPP_X86
				"Android/x86"
			#else
				"Android/unknown"
			#end
		#elseif ios
			"iPhone"
		#else
			"unknown"
		#end;

	public static var shouldInitializeCallbacks = true;

	static var initialized_callbacks = false;

	static var IDCount(default, null):Int = 0;

	/**
		Script-specific default function name.

		If not null, this function will be called automatically after execution.
	**/
	public var defaultFunc:{functionName:String, ?arguments:Array<Dynamic>} = null;

	/**
		The script's own return value.

		This is separate from individual function return values.
	**/
	public var returnValue(default, null):Null<Dynamic>;

	/**
		Unique ID for this script instance, used when no script file is provided.
	**/
	public var ID(default, null):Null<Int> = null;

	/**
		The Lua state used to run this script.

		This is `null` until this Lua script has actually been executed at least once.

		You can use this to interact with the Lua library (`sscript_lua.Lua`,
		`sscript_lua.LuaL`, ...) directly.
	**/
	public var luaState(default, null):State;

	/**
		Whether Lua scripts run by this instance are sandboxed.

		A sandboxed script only gets the standard libraries listed in
		`luaAllowedLibraries` (by default: no `os` process/filesystem access
		beyond the clock, no `io`, no `package`, `require`, `debug`), can't
		load precompiled Lua bytecode through `load()`, and is bounded by
		`luaInstructionLimit` and `luaMemoryLimitKB` so a `while true do end` (or
		a runaway allocation) can't hang or crash the host.

		This is **not** a hard security boundary. It restricts what the Lua standard library
		exposes, not what native functions you `set()` into the script
		yourself. Anything you expose with  `set()` is reachable
		from a sandboxed script exactly as it would be from a normal one.

		Must be set before the first Lua script actually executes.

		Passing anything other than `null` to `luaSandbox` in the constructor turns this on.

		Defaults to `false`.

		@see `sscript_lua.backend.LuaSandbox.LuaLib`
	**/
	public var luaSandboxed:Bool = false;

	/**
		Bitmask of `sscript_lua.backend.LuaSandbox.LuaLib` flags controlling which
		Lua standard libraries are available when `luaSandboxed` is `true`.

		Ignored when `luaSandboxed` is `false`.

		Defaults to `LuaLib.SANDBOX_DEFAULT`.
	**/
	public var luaAllowedLibraries:Int = LuaLib.SANDBOX_DEFAULT;

	/**
		Bitmask of `sscript_lua.backend.LuaSandbox.LuaSandboxOption` flags for
		extra restrictions layered on top of `luaAllowedLibraries` (e.g.
		trimming `os` further, stripping `string.dump`). These don't
		correspond to real Lua library bits -- they're applied as patches
		after the selected libraries are opened.

		Ignored when `luaSandboxed` is `false`.

		Defaults to `LuaSandboxOption.DEFAULT`.

		@see `sscript_lua.backend.LuaSandbox.LuaSandboxOption`
	**/
	public var luaSandboxOptions:Int = LuaSandboxOption.DEFAULT;

	/**
		Rough VM-instruction budget for a sandboxed Lua script.
		Once exceeded, the running script or function call is aborted with an error.

		`<= 0` disables the check. 
		
		Ignored unless `luaSandboxed` is `true`.

		Defaults to 0.
	**/
	public var luaInstructionLimit:Int = 0;

	/**
		Rough memory budget in kilobytes for a sandboxed Lua script.

		Re-evaluated every 1000 VM instructions, so a script can still spike
		memory well past this number between checks. It catches runaway
		accumulation (e.g. an unbounded table build-up in a loop), not a
		single huge allocation.

		`<= 0` disables the check. 
		
		Ignored unless `luaSandboxed` is `true`.

		Defaults to 262,144 KB (256 MB).
	**/
	public var luaMemoryLimitKB:Int = 262144;

	/**
		The script source code to execute.
	**/
	public var script(default, null):String = "";

	/**
		Whether this script is active.

		Set to false to prevent execution.
	**/
	public var active:Bool = true;

	/**
		Read-only path of the script file, if loaded from disk.
	**/
	public var scriptFile(default, null):String = "";

	/**
		If true, enables error traces from script functions.
	**/
	public var traces:Bool = false;

	/**
		Most recent loading or runtime error, if any.
	**/
	public var parsingException(default, null):Exception;

	var shouldWarn:Bool = true;

	@:noPrivateAccess var _destroyed(default, null):Bool;

	/**
		Creates a new SScript_Lua instance.

		@param scriptPath Script file path or raw Lua code.
		@param startExecute Whether to execute the script immediately. (Recommended)
		@param luaSandbox If not null, sandboxes this script per `luaSandboxed`'s docs. Equivalent to setting `luaSandboxed = true` plus whichever of `LuaSandboxSettings`'s fields you pass. Has no effect if `startExecute` is false; set the properties directly before calling `execute()` in that case.
	**/
	public function new(?scriptPath:String = "", ?startExecute:Bool = true, ?luaSandbox:LuaSandboxSettings)
	{
		if (luaSandbox != null) {
			luaSandboxed = true;
			if (luaSandbox.allowedLibraries != null)
				luaAllowedLibraries = luaSandbox.allowedLibraries;
			if (luaSandbox.instructionLimit != null)
				luaInstructionLimit = luaSandbox.instructionLimit;
			if (luaSandbox.memoryLimitKB != null)
				luaMemoryLimitKB = luaSandbox.memoryLimitKB;
			if (luaSandbox.sandboxOptions != null)
				luaSandboxOptions = luaSandbox.sandboxOptions;
		}

		if (!initialized_callbacks && shouldInitializeCallbacks) {
			Lua.init_callbacks(Lua_helper.callback_handler);
			initialized_callbacks = true;
		}

		if (defaultFun != null)
			defaultFunc = defaultFun;
		if (defaultTraces != null)
			traces = defaultTraces;
		
		doFile(scriptPath);
		if (startExecute)
			execute();
	}

	/**
		Executes this script once.

		This must be called at least once before calling script-defined functions.

		Don't call this if the script was already executed when creating its instance with the `startExecute` argument set to true.
	**/
	public function execute():Void
	{
		if (_destroyed || !active)
			return;

		parsingException = null;
		if (script != null && script.length > 0)
		{
			var origin:String = toString();
			runLua(script, origin);

			if (defaultFunc != null)
			{
				shouldWarn = false;
				call(defaultFunc.functionName, defaultFunc.arguments);
				shouldWarn = true;
			}
		}
	}

	/**
		Sets a global in this script.

		If the key already exists, it will be replaced.
		@param key Global name.
		@param obj The object to set. Can be left blank.
		@return Returns this instance for chaining.
	**/
	public function set(key:String, ?obj:Dynamic, ?setAsFinal:Bool = null):SScript_Lua
	{
		if (_destroyed)
			return null;
		if (!active)
			return this;

		if (key == null || key.length == 0)
		{
			traceError('$key is not a valid variable name', "set", [key, obj]);
			return this;
		}

		ensureLuaState();
		if (luaState != null)
		{
			if (Type.typeof(obj) == TFunction)
			{
				if (!Lua_helper.callbacks.exists(key))
					Lua_helper.add_callback(luaState, key, obj);
			}
			else
			{
				Convert.toLua(luaState, obj);
				Lua.setglobal(luaState, key);
			}
		}
		return this;
	}

	/**
		Removes a global from this script.

		If a global named `key` does not exist, this function won't do anything.
		@param key Global name to remove.
		@return Returns this instance for chaining.
	**/
	public function remove(key:String):SScript_Lua
	{
		if (_destroyed)
			return this;
		if (key == null || key.length == 0)
			return this;
		if (!active)
			return this;

		ensureLuaState();
		if (luaState != null)
		{
			Lua.pushnil(luaState);
			Lua.setglobal(luaState, key);
		}
		return this;
	}

	@:deprecated('Use remove instead')
	public function unset(key:String):SScript_Lua
	{
		return remove(key);
	}

	/**
		Gets a global by name.

		If a global named `key` does not exist, `null` is returned.
		@param key Global name.
		@return The object got by name.
	**/
	public function get(key:String):Dynamic
	{
		if (_destroyed)
			return null;
		if (key == null || key.length == 0)
			return null;

		if (!active)
		{
			if (traces)
				traceError("This script is not active!", "get");

			return null;
		}

		ensureLuaState();
		if (luaState == null)
			return null;

		var t:Int = Lua.getglobal(luaState, key);
		if (t == Lua.LUA_TNIL)
		{
			Lua.pop(luaState, 1);
			return null;
		}

		var value:Dynamic = Convert.fromLua(luaState, -1);
		Lua.pop(luaState, 1);
		return value;
	}

	/**
		Calls a function from this script.

		**WARNING**:
		The script must be executed at least once before calling functions.

		@param func Function name in script.
		@param args Arguments for `func`. If the function does not require arguments, leave this as `null`.
		@return Returns a `FunctionCall` object.
	**/
	public function call(func:String, ?args:Array<Dynamic> = null):FunctionCall
	{
		var call:FunctionCall = new FunctionCall();
		call.set_calledFunction(func);
		if (_destroyed)
			return call.set_exception(new Exception(toString() + " is destroyed.")).set_succeeded(false);

		if (!active)
			return call.set_exception(new Exception(toString() + " is not active.")).set_succeeded(false);

		if (args == null)
			args = [];

		if (func == null || func.length == 0)
		{
			if (traces)
				traceError('Function name cannot be invalid', 'call', [func, args]);

			var scriptFile:String = if (scriptFile != null && scriptFile.length > 0) scriptFile else "";
			return call.set_exception(new Exception('Function name cannot be invalid for ' + toString())).set_succeeded(false);
		}

		return callLua(func, args, call);
	}

	/**
		Clears all globals assigned to this script by tearing down and
		rebuilding its Lua state.

		@return Returns this instance for chaining.
	**/
	public function clear():SScript_Lua
	{
		if (_destroyed)
			return null;
		if (!active)
			return this;

		closeLuaState();
		ensureLuaState();
		return this;
	}

	/**
		Checks whether `key` exists in this script's Lua globals.
		@param key The global name to look for.
		@return Returns true if `key` is found.
	**/
	public function exists(key:String):Bool
	{
		if (_destroyed)
			return false;
		if (!active)
			return false;
		if (key == null || key.length == 0)
			return false;

		ensureLuaState();
		if (luaState == null)
			return false;

		var t:Int = Lua.getglobal(luaState, key);
		Lua.pop(luaState, 1);
		return t != Lua.LUA_TNIL;
	}

	function useIDForGlobal()
	{
		if (ID != null)
			return;

		ID = IDCount + 1;
		IDCount++;
		global[ID] = this;
	}

	function ensureLuaState():Void
	{
		if (_destroyed || luaState != null)
			return;

		luaState = LuaL.newstate();
		if (luaState == null)
			return;

		if (luaSandboxed)
			LuaSandbox.apply(luaState, luaAllowedLibraries, luaInstructionLimit, luaMemoryLimitKB, luaSandboxOptions);
		else
			LuaL.openlibs(luaState);

		Lua_helper.register_hxtrace(luaState);

		for (i => k in globalVariables)
		{
			var name:String = i;
			if (name == null)
				continue;

			if (name.endsWith("-final") && name.length > 6)
				name = name.substring(0, name.length - 6);

			Convert.toLua(luaState, k);
			Lua.setglobal(luaState, name);
		}
	}

	function closeLuaState():Void
	{
		if (luaState == null)
			return;

		Lua.close(luaState);
		luaState = null;
	}

	function runLua(source:String, origin:String):Void
	{
		ensureLuaState();
		if (luaState == null)
			return;

		if (origin == null || origin.length < 1)
			origin = toString();

		var base:Int = Lua.gettop(luaState);
		var loadStatus:Int = LuaL.loadbufferx(luaState, source, source.length, origin, luaSandboxed ? "t" : "bt");
		if (loadStatus != Lua.LUA_OK)
		{
			var msg:String = Lua.tostring(luaState, -1);
			Lua.pop(luaState, 1);
			parsingException = new Exception(msg);
			returnValue = null;
			return;
		}

		var callStatus:Int = Lua.pcall(luaState, 0, Lua.LUA_MULTRET, 0);
		if (callStatus != Lua.LUA_OK)
		{
			var msg:String = Lua.tostring(luaState, -1);
			Lua.pop(luaState, 1);
			parsingException = new Exception(msg);
			returnValue = null;
			return;
		}

		var top:Int = Lua.gettop(luaState);
		if (top > base)
		{
			returnValue = Convert.fromLua(luaState, base + 1);
			Lua.settop(luaState, base);
		}
		else
			returnValue = null;
	}

	function callLua(func:String, args:Array<Dynamic>, call:FunctionCall):FunctionCall
	{
		ensureLuaState();
		if (luaState == null)
		{
			return call.set_exception(new Exception('Lua state could not be created for ${toString()}')).set_succeeded(false);
		}

		var base:Int = Lua.gettop(luaState);
		var t:Int = Lua.getglobal(luaState, func);
		if (t != Lua.LUA_TFUNCTION)
		{
			Lua.settop(luaState, base);

			if (traces)
				traceError('Function $func does not exist', "call", [func, args]);
			return call.set_exception(new Exception('Function $func does not exist in ${toString()}')).set_succeeded(false); 
		}

		if (Lua.checkstack(luaState, args.length + 2) == 0)
		{
			Lua.settop(luaState, base);
			return call.set_exception(new Exception('Too many arguments for $func in ${toString()}')).set_succeeded(false);
		}

		for (a in args)
			if (!Convert.toLua(luaState, a))
				Lua.pushnil(luaState);

		var status:Int = Lua.pcall(luaState, args.length, Lua.LUA_MULTRET, 0);
		if (status != Lua.LUA_OK)
		{
			var msg:String = Lua.tostring(luaState, -1);
			Lua.settop(luaState, base);

			if (traces)
				traceError(msg, "call", [func, args]);

			return call.set_exception(new Exception(msg)).set_succeeded(false);
		}

		var top:Int = Lua.gettop(luaState);
		var ret:Dynamic = top > base ? Convert.fromLua(luaState, base + 1) : null;
		Lua.settop(luaState, base);

		return call.set_returnValue(ret).set_exception(null).set_succeeded(true);
	}

	function luaGlobalsToMap():Map<String, Dynamic>
	{
		var map:Map<String, Dynamic> = new Map();
		if (luaState == null)
			return map;

		Lua.getglobal(luaState, "_G");
		var tableIndex:Int = Lua.gettop(luaState);

		Lua.pushnil(luaState);
		while (Lua.next(luaState, tableIndex) != 0)
		{
			var key:Dynamic = Convert.fromLua(luaState, -2);
			if ((key is String))
				map.set(key, Convert.fromLua(luaState, -1));

			Lua.pop(luaState, 1);
		}

		Lua.pop(luaState, 1);
		return map;
	}

	function doFile(scriptPath:String):Void
	{
		if (_destroyed)
			return;

		if (scriptPath == null || scriptPath.length < 1 || StringTools.trim(scriptPath).length == 0)
		{
			useIDForGlobal();
			return;
		}

		#if sys
		if (FileSystem.exists(scriptPath))
		{
			scriptFile = scriptPath;
			script = File.getContent(scriptPath);
		}
		else
		{
			scriptFile = "";
			script = scriptPath;
		}
		#else
		scriptFile = "";
		script = scriptPath;
		#end

		useIDForGlobal();
	}

	/**
		Executes a string once instead of a script file.

		This does not change `scriptFile`, but it does change `script`.

		Even though this function is faster,
		it should be avoided whenever possible.
		Always try to use a script file.

		This function does NOT check for files, `string` is always treated as
		raw Lua source.
		@param string The Lua source to execute.
		@param origin Optional origin to use for this script, it will appear on traces.
		@return Returns this instance for chaining. Returns `null` if it fails.
	**/
	public function doString(string:String, ?origin:String):SScript_Lua
	{
		if (_destroyed)
			return null;
		if (!active)
			return this;
		if (string == null || string.length < 1)
			return this;

		parsingException = null;

		var og:String = origin;
		if (og == null)
			og = toString();

		script = string;

		useIDForGlobal();

		runLua(script, og);
		if (defaultFunc != null)
		{
			shouldWarn = false;
			call(defaultFunc.functionName, defaultFunc.arguments);
			shouldWarn = true;
		}

		return this;
	}

	/**
		Converts this instance of SScript_Lua to a String and returns it.

		For scripts without a file, it will use its `ID`. (e.g, "[SScript_Lua #618]")

		For scripts with a file, it will use the file name. (e.g, "[SScript_Lua (script.lua)]")

		@return This SScript_Lua instance as a string.
	**/
	public function toString():String
	{
		if (_destroyed)
			return "null";

		if (_str == null || _strFile != scriptFile || _strID != ID || _strSandboxed != luaSandboxed)
		{
			_strFile = scriptFile;
			_strID = ID;
			_strSandboxed = luaSandboxed;
			_str = (scriptFile != null && scriptFile.length > 0)
				? "[SScript_Lua (" + scriptFile + ")" + (luaSandboxed ? " (Sandboxed)]" : "]")
				: "[SScript_Lua" + (ID != null ? (" #" + ID) : "") + (luaSandboxed ? " (Sandboxed)]" : "]");
		}
		return _str;
	}

	var _str:String = null;
	var _strFile:String = null;
	var _strID:Null<Int> = null;
	var _strSandboxed:Bool = false;

	#if sys
	/**
		Finds scripts in the provided path and returns them in an array.

		Make sure `path` is a directory!

		If `extensions` is not `null`, file extensions will be checked.
		Otherwise, only files with the `.lua` extensions will be checked and listed.

		@param path The directory to check. Non-directory paths will be ignored.
		@param extensions Optional extension to check in file names.
		@return An array of found scripts.
	**/
	#else
	/**
		Finds scripts in the provided path and returns them in an array.

		This function will always return an empty array, because you are targeting an unsupported target.
		@return An empty array.
	**/
	#end
	public static function listScripts(path:String, ?extensions:Array<String>):Array<SScript_Lua>
	{
		if (!path.endsWith('/'))
			path += '/';

		if (extensions == null || extensions.length < 1)
			extensions = ['lua'];

		var list:Array<SScript_Lua> = [];
		#if sys
		if (FileSystem.exists(path) && FileSystem.isDirectory(path))
		{
			var files:Array<String> = FileSystem.readDirectory(path);
			for (i in files)
			{
				var hasExtension:Bool = false;
				for (l in extensions)
				{
					if (i.endsWith(l))
					{
						hasExtension = true;
						break;
					}
				}
				if (hasExtension && FileSystem.exists(path + i))
					list.push(new SScript_Lua(path + i));
			}
		}
		#end

		return list;
	}

	/**
		This function makes this script instance completely unusable and impossible to restore.

		If you don't want to destroy your script just yet, just set `active` to false!

		Override this function if you set up other variables to destroy them.
	**/
	public function destroy():Void
	{
		if (_destroyed)
			return;

		global.remove(ID);
		closeLuaState();

		parsingException = null;
		script = null;
		scriptFile = null;
		active = false;
		ID = null;
		returnValue = null;
		_destroyed = true;
	}

	public dynamic function traceError(error:String, funcCalled:String, ?args:Array<Dynamic>)
	{
		if (!shouldWarn)
			return;

		var buf = new StringBuf();
		buf.add(this.toString());
		buf.add(" ");
		buf.add(error);
		buf.add(", error message from function '");
		buf.add(funcCalled);
		buf.add("'");

		if (args != null && args.length > 0)
		{
			buf.add(", passed arguments are: ");
			buf.add(args.join(", "));
		}

		trace(buf.toString());
	}

	static function get_luaVersion():String {
		return Lua.version();
	}

	static function get_luaJITVersion():String {
		return Lua.versionJIT();
	}
}