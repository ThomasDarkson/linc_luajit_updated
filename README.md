# linc/LuaJIT (updated)

Haxe/hxcpp `@:native` bindings for [LuaJIT](http://luajit.org/).

This is a [linc](http://snowkit.github.io/linc/) library. Updates regularly to rolling releases of LuaJIT.

> [!NOTE]
> This library works with the Haxe **cpp** target only (hxcpp).

> [!NOTE]
> Compatible with Psych Engine!

## New Features
- Automatic host detection, no need to define OS and architecture (e.g, `-D windows`, `-D HXCPP_M64`) (except for iOS (`-D iphoneos`) and Android (`-D android`))
- Newer LuaJIT (updates regularly)
- Sandboxing
- New helper, SScript_Lua
---

## Installation
`haxelib git linc_luajit https://github.com/ThomasDarkson/linc_luajit_updated`

After installing, add it to your Haxe project.

### Haxe Projects
Add this to `build.hxml`:
```hxml
-lib linc_luajit
```

### OpenFL projects
Add this to `Project.xml`:
```xml
<haxelib name="linc_luajit"/>
```

---

## Two ways to use it

- **`sscript_lua.SScript_Lua`** — a script execution helper (run strings or files, call functions, get/set globals, optional sandboxing). Recommended for most use cases.
- **`llua` / `sscript_lua.Lua`, `LuaL`, `State`, ...** — the raw `@:native` bindings to the LuaJIT C API, for when you need direct control over the stack. `SScript_Lua` is built entirely on top of these, so they're always available alongside it.

---

## Quick start with `SScript_Lua`

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
        trace(call.returnValue, call.exception); // 2, null
    }
}
```

You can also load from a file — if `scriptPath` exists on disk it's read as a file, otherwise it's treated as raw source:

```haxe
import sscript_lua.SScript_Lua;

class Main {
    static function main() {
        var script = new SScript_Lua("script.lua");
        var call = script.call('method');
        trace(call.returnValue, call.exception);
    }
}
```

### Globals: `set`, `get`, `remove`, `exists`

```haxe
import sscript_lua.SScript_Lua;

class Main {
    static function main() {
        var script = new SScript_Lua();
        script.set('greeting', 'hello');
        script.set('add', function(a:Int, b:Int) return a + b); // Haxe functions become Lua callbacks

        script.doString('
            function useGlobals()
                return greeting .. " " .. add(1, 2)
            end
        ');

        trace(script.call('useGlobals').returnValue); // "hello 3"
        trace(script.exists('greeting'));              // true

        script.remove('greeting');
        trace(script.exists('greeting'));              // false
    }
}
```

### Calling a function and reading `FunctionCall`

`call()` always returns a `FunctionCall`, whether it succeeded or not:

```haxe
var call = script.call('method');
if (call.succeeded) {
    trace(call.returnValue);
} 
else {
    trace(call.exception); // e.g. "Function method does not exist in [SScript_Lua #1]"
}
```

### Default entry function

Set a function to be called automatically right after a script runs, either per-instance or as a static default for every instance:

```haxe
import sscript_lua.SScript_Lua;

class Main {
    static function main() {
        SScript_Lua.defaultFun = {functionName: "main"};

        var script = new SScript_Lua();
        script.doString('
            function main()
                trace("ran automatically")
            end
        ');
    }
}
```

### Global variables shared across every script

```haxe
import sscript_lua.SScript_Lua;

class Main {
    static function main() {
        SScript_Lua.globalVariables.set('variable2', 2);

        var script = new SScript_Lua();
        script.set('variable', 1);
        script.doString('
            function returnVar()
                return variable + variable2
            end
        ');

        trace(script.call('returnVar').returnValue); // 3
    }
}
```

### Finding and running scripts in a directory

```haxe
var scripts = SScript_Lua.listScripts("scripts/"); // defaults to *.lua
for (s in scripts)
    trace(s.toString());
```

### Cleaning up

```haxe
script.clear();   // tears down and rebuilds the Lua state, wiping globals
script.destroy(); // makes the instance permanently unusable
```

---

## Lua Sandboxing

Set `luaSandboxed = true` (or pass a `LuaSandboxSettings` to the constructor) to restrict what a Lua script can reach and how much it can run.

```haxe
import sscript_lua.SScript_Lua;
import sscript_lua.backend.LuaSandbox.LuaLib;

class Main {
    static function main() {
        var script = new SScript_Lua("", true, false); // don't auto-execute yet
        script.luaSandboxed = true; // Blocked libraries default to LuaLib.SANDBOX_DEFAULT
        script.doString("os.execute('rm -rf /')"); // fails: os.execute is stripped by default
        script.execute();
        trace(script.parsingException);
    }
}
```

Or configure it up front through the constructor's `luaSandbox` argument:

```haxe
import sscript_lua.SScript_Lua;
import sscript_lua.backend.LuaSandbox.LuaLib;

var script = new SScript_Lua("script.lua", true, true, {
    allowedLibraries: LuaLib.BASE | LuaLib.MATH | LuaLib.STRING,
    instructionLimit: 1000000,
    memoryLimitKB: 65536
});
```

> [!NOTE]
> Sandboxing is **not** a hard security boundary. It restricts what the Lua standard library exposes, not what native functions you `set()` into the script yourself — anything you expose that way is reachable from a sandboxed script exactly as it would be from a normal one.

A sandboxed script only gets the standard libraries you allow, can't load precompiled Lua bytecode through `load()`/`loadstring()` by default, and is bounded by an instruction count and a memory budget so a `while true do end` or a runaway table can't hang or crash the host.

### `luaAllowedLibraries` — which standard libraries get opened

Bitmask of `sscript_lua.backend.LuaSandbox.LuaLib`, one bit per Lua/LuaJIT standard library. Ignored unless `luaSandboxed` is `true` — an unsandboxed script always gets every library via `LuaL.openlibs`.

| `LuaLib` flag | Opens |
|---|---|
| `BASE` | Base library (`print`, `pairs`, `pcall`, `load`, ...) |
| `MATH` | `math.*` |
| `STRING` | `string.*` |
| `TABLE` | `table.*` |
| `IO` | `io.*` (filesystem access) |
| `OS` | `os.*` (clock, time, and by default also `execute`/`exit`/etc. unless stripped, see below) |
| `PACKAGE` | `package`, `require` |
| `DEBUG` | `debug.*` |
| `BIT` | `bit.*` (LuaJIT bit operations) |
| `JIT` | `jit.*` (JIT control) |
| `FFI` | `ffi.*` (native memory / C calls — effectively unrestricted native access) |
| `ALL` | Every flag above |
| `SANDBOX_DEFAULT` | `BASE \| MATH \| STRING \| TABLE \| OS \| BIT` — default when `luaAllowedLibraries` is left unset. No `IO`, no `PACKAGE`, no `DEBUG`, no `FFI`, no `JIT` control. |

### `luaSandboxOptions` — extra patches on top of the opened libraries

Bitmask of `sscript_lua.backend.LuaSandbox.LuaSandboxOption`. These aren't real Lua library bits — they're applied as small patches to the globals table right after the selected libraries are opened. Ignored unless `luaSandboxed` is `true`.

| `LuaSandboxOption` flag | Removes / restricts |
|---|---|
| `STRIP_OS_DANGEROUS` | `os.execute`, `os.exit`, `os.remove`, `os.rename`, `os.tmpname`, `os.getenv`, `os.setlocale` (if `os` was opened). `os.time`/`os.clock`/`os.date`/`os.difftime` are left alone. |
| `STRIP_STRING_DUMP` | `string.dump` (if `string` was opened) — otherwise it can be used to produce and leak Lua bytecode. |
| `DISABLE_BYTECODE_LOAD` | Wraps `load`/`loadstring` (if `base` was opened) so a chunk starting with the Lua bytecode signature is rejected instead of executed. |
| `BLOCK_DOFILE_LOADFILE` | Removes `dofile` and `loadfile` (if `base` was opened), so a script can't read arbitrary files off disk even without `IO` opened. |
| `RESTRICT_COLLECTGARBAGE` | Wraps `collectgarbage` (if `base` was opened) so `collectgarbage("stop")` is a no-op, preventing a script from disabling GC to outrun `luaMemoryLimitKB` between checks. |
| `NONE` | No extra patches. |
| `DEFAULT` | All five options above combined — this is what `luaSandboxOptions` uses if left unset. |

### Instruction and memory limits

* **`luaInstructionLimit`** — rough VM-instruction budget. Once exceeded, the running script or function call is aborted with an error. `<= 0` disables the check. Defaults to `0` (disabled). Ignored unless `luaSandboxed` is `true`.
* **`luaMemoryLimitKB`** — rough memory budget in kilobytes, re-evaluated every 1000 VM instructions. It catches runaway accumulation (e.g. an unbounded table build-up in a loop), not a single huge allocation. `<= 0` disables the check. Defaults to `262144` KB (256 MB). Ignored unless `luaSandboxed` is `true`.

Both must be set before the script's first execution — `SScript_Lua`'s constructor lets you pass them straight in via `LuaSandboxSettings`.

---

## Low-level usage (raw Lua C API bindings)

For direct stack manipulation, use `sscript_lua.Lua`, `LuaL` and `State` (the legacy `llua` package still works as a set of type aliases onto these, for backwards compatibility with original linc_luajit).

Be sure to read the Lua documentation:
www.lua.org/manual/5.1/manual.html

```haxe
import sscript_lua.Lua;
import sscript_lua.LuaL;
import sscript_lua.State;

class Test {

    static function main() {

        var lua:State = LuaL.newstate();
        LuaL.openlibs(lua);
        trace("Lua version: " + Lua.version());
        trace("LuaJIT version: " + Lua.versionJIT());

        LuaL.dofile(lua, "script.lua");

        Lua.getglobal(lua, "foo");

        Lua.pushinteger(lua, 1);
        Lua.pushnumber(lua, 2.0);
        Lua.pushstring(lua, "three");

        Lua.pcall(lua, 3, 0, 1);

        Lua.close(lua);

    }

}
```

---

## Version info & platform

```haxe
trace(SScript_Lua.luaVersion);     // e.g. "Lua 5.1.4"
trace(SScript_Lua.luaJITVersion);  // e.g. "LuaJIT 2.1.1788856981"
trace(SScript_Lua.luaLibVariant);  // which prebuilt lib got linked, e.g. "Linux/x86_64", "Android/arm64-v8a", "iPhone"
```

Prebuilt LuaJIT libraries are bundled for Windows (x86/x86_64), Linux (x86_64/aarch64), Mac (x86_64/arm64), Android (armeabi-v7a/arm64-v8a/x86/x86_64) and iOS.