package sscript_lua.backend;

import sscript_lua.Lua;
import sscript_lua.LuaL;
import sscript_lua.LuaOpen;
import sscript_lua.State;

/**
	Bitmask flags for `SScript_Lua.luaAllowedLibraries`, one bit per Lua standard
	library. Only meaningful when `SScript_Lua.luaSandboxed` is `true` -- an
	unsandboxed script always gets every library via `LuaL.openlibs`.
**/
class LuaLib
{
	public static inline final BASE:Int = 1 << 0;
	public static inline final MATH:Int = 1 << 1;
	public static inline final STRING:Int = 1 << 2;
	public static inline final TABLE:Int = 1 << 3;

	public static inline final IO:Int = 1 << 4;

	public static inline final OS:Int = 1 << 5;

	public static inline final PACKAGE:Int = 1 << 6;

	public static inline final DEBUG:Int = 1 << 7;

	public static inline final BIT:Int = 1 << 8;

	public static inline final JIT:Int = 1 << 9;

	public static inline final FFI:Int = 1 << 10;

	public static inline final ALL:Int = BASE | MATH | STRING | TABLE | IO | OS | PACKAGE | DEBUG | BIT | JIT | FFI;

	/**
		The libraries `SScript_Lua.luaAllowedLibraries` defaults to: `BASE`,
		`MATH`, `STRING`, `TABLE`, `OS` and `BIT`. No filesystem (`IO`), no
		module loading (`PACKAGE`), no `DEBUG`, no `FFI`, no `JIT` control.
	**/
	public static inline final SANDBOX_DEFAULT:Int = BASE | MATH | STRING | TABLE | OS | BIT;
}

/**
	Bitmask flags for `SScript_Lua.luaSandboxOptions`: extra restrictions layered
	on top of whichever libraries `luaAllowedLibraries` opens. These are applied
	as small patches to the globals table after opening, not real Lua library bits.
**/
class LuaSandboxOption
{
	public static inline final NONE:Int = 0;

	/** Removes `os.execute`, `os.exit`, `os.remove`, `os.rename`, `os.tmpname`, `os.getenv` and `os.setlocale` if `os` was opened. `os.time`/`os.clock`/`os.date`/`os.difftime` are left alone. **/
	public static inline final STRIP_OS_DANGEROUS:Int = 1 << 0;

	/** Removes `string.dump` (which can otherwise be used to produce and leak Lua bytecode) if `string` was opened. **/
	public static inline final STRIP_STRING_DUMP:Int = 1 << 1;

	/** Wraps `load`/`loadstring` (if `base` was opened) so a chunk that starts with the Lua bytecode signature is rejected instead of executed. **/
	public static inline final DISABLE_BYTECODE_LOAD:Int = 1 << 2;

	/** Removes the globals `dofile` and `loadfile` (if `base` was opened), so a script can't read arbitrary files off disk even though `IO` itself wasn't opened. **/
	public static inline final BLOCK_DOFILE_LOADFILE:Int = 1 << 3;

	/** Wraps `collectgarbage` (if `base` was opened) so `collectgarbage("stop")` is a no-op, preventing a script from disabling GC to outrun `luaMemoryLimitKB` between checks. **/
	public static inline final RESTRICT_COLLECTGARBAGE:Int = 1 << 4;

	public static inline final DEFAULT:Int = STRIP_OS_DANGEROUS | STRIP_STRING_DUMP | DISABLE_BYTECODE_LOAD | BLOCK_DOFILE_LOADFILE | RESTRICT_COLLECTGARBAGE;
}

/**
	Optional settings accepted by `SScript_Lua.new`'s `luaSandbox` argument.
	Any field left `null` keeps that setting's existing default.
**/
typedef LuaSandboxSettings =
{
	?allowedLibraries:Int,
	?instructionLimit:Int,
	?memoryLimitKB:Int,
	?sandboxOptions:Int
}

/**
	Builds a sandboxed Lua state: opens only the libraries selected by
	`allowedLibraries`, patches out the specific globals selected by
	`sandboxOptions`, and installs the instruction/memory watchdog hook.

	Called once per Lua state, right after `LuaL.newstate()`, from
	`SScript_Lua.ensureLuaState`. Not a hard security boundary -- see
	`SScript_Lua.luaSandboxed`'s doc comment.
**/
class LuaSandbox
{
	public static function apply(l:State, allowedLibraries:Int, instructionLimit:Int, memoryLimitKB:Int, sandboxOptions:Int):Void
	{
		if (l == null)
			return;

		openSelectedLibraries(l, allowedLibraries);

		final patch:StringBuf = new StringBuf();

		if (sandboxOptions & LuaSandboxOption.BLOCK_DOFILE_LOADFILE != 0)
			patch.add(DOFILE_LOADFILE_GUARD);

		if (sandboxOptions & LuaSandboxOption.DISABLE_BYTECODE_LOAD != 0)
			patch.add(BYTECODE_GUARD);

		if (sandboxOptions & LuaSandboxOption.STRIP_OS_DANGEROUS != 0)
			patch.add(OS_GUARD);

		if (sandboxOptions & LuaSandboxOption.STRIP_STRING_DUMP != 0)
			patch.add(STRING_DUMP_GUARD);

		if (sandboxOptions & LuaSandboxOption.RESTRICT_COLLECTGARBAGE != 0)
			patch.add(COLLECTGARBAGE_GUARD);

		if (patch.length > 0)
			runPatch(l, patch.toString());

		if (instructionLimit > 0 || memoryLimitKB > 0)
			Lua.install_limits(l, instructionLimit, memoryLimitKB);
	}

	static function openSelectedLibraries(l:State, mask:Int):Void
	{
		inline function openLib(open:State->Int):Void
		{
			open(l);
			Lua.pop(l, 1);
		}

		if (mask & LuaLib.BASE != 0)
			openLib(LuaOpen.base);
		if (mask & LuaLib.MATH != 0)
			openLib(LuaOpen.math);
		if (mask & LuaLib.STRING != 0)
			openLib(LuaOpen.string);
		if (mask & LuaLib.TABLE != 0)
			openLib(LuaOpen.table);
		if (mask & LuaLib.IO != 0)
			openLib(LuaOpen.io);
		if (mask & LuaLib.OS != 0)
			openLib(LuaOpen.os);
		if (mask & LuaLib.PACKAGE != 0)
			Lua.protected_open_package(l);
		if (mask & LuaLib.DEBUG != 0)
			openLib(LuaOpen.debug);
		if (mask & LuaLib.BIT != 0)
			openLib(LuaOpen.bit);
		if (mask & LuaLib.JIT != 0)
			Lua.protected_open_jit(l);
		if (mask & LuaLib.FFI != 0)
			Lua.protected_open_ffi(l);
	}

	static function runPatch(l:State, code:String):Void
	{
		var status:Int = LuaL.loadbufferx(l, code, code.length, "sscript_sandbox_patch", "t");
		if (status != Lua.LUA_OK)
		{
			Lua.pop(l, 1); 
			return;
		}

		status = Lua.pcall(l, 0, 0, 0);
		if (status != Lua.LUA_OK)
			Lua.pop(l, 1);
	}

	static final DOFILE_LOADFILE_GUARD:String = "dofile = nil\nloadfile = nil\n";

	static final BYTECODE_GUARD:String = "
if load then
	local raw_load = load
	load = function(chunk, chunkname, mode, env)
		if type(chunk) == \"string\" and #chunk > 0 and chunk:byte(1) == 27 then
			return nil, \"bytecode loading is disabled in sandboxed scripts\"
		end
		if mode == nil then mode = \"t\" end
		return raw_load(chunk, chunkname, mode, env)
	end
end
if loadstring then
	local raw_loadstring = loadstring
	loadstring = function(s, chunkname)
		if type(s) == \"string\" and #s > 0 and s:byte(1) == 27 then
			return nil, \"bytecode loading is disabled in sandboxed scripts\"
		end
		return raw_loadstring(s, chunkname)
	end
end
";

	static final OS_GUARD:String = "
if os then
	os.execute = nil
	os.exit = nil
	os.remove = nil
	os.rename = nil
	os.tmpname = nil
	os.getenv = nil
	os.setlocale = nil
end
";

	static final STRING_DUMP_GUARD:String = "if string then string.dump = nil end\n";

	static final COLLECTGARBAGE_GUARD:String = "
if collectgarbage then
	local raw_gc = collectgarbage
	collectgarbage = function(opt, arg)
		if opt == \"stop\" then return 0 end
		return raw_gc(opt, arg)
	end
end
";
}
