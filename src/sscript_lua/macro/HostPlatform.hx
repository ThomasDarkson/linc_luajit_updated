package sscript_lua.macro;

#if macro
import haxe.macro.Compiler;
import haxe.macro.Context;

using StringTools;

class HostPlatform
{
	public static macro function use()
	{
		if (!Context.defined("cpp")) {
			Context.fatalError("[ERROR] linc_luajit_updated only supports C++ target (hxcpp)", (macro null).pos);
		}

		defineOS();
		defineArch();

		return macro null;
	}

	static function hostOS():String
	{
		return Sys.systemName();
	}

	static function defineOS():Void
	{
		if (Context.defined("windows") || Context.defined("mac") || Context.defined("linux") || Context.defined("ios") || Context.defined("iphoneios")
			|| Context.defined("android"))
			return;

		switch (hostOS())
		{
			case "Windows":
				Compiler.define("windows");
			case "Mac":
				Compiler.define("mac");
				Compiler.define("macos");
			case "Linux":
				Compiler.define("linux");
			default:
		}
	}
	static function hostArch():String
	{
		#if windows
		var arch = Sys.getEnv("PROCESSOR_ARCHITEW6432");
		if (arch == null || arch == "")
			arch = Sys.getEnv("PROCESSOR_ARCHITECTURE");
		return arch == null ? "" : arch;
		#else
		try
		{
			var p = new sys.io.Process("uname", ["-m"]);
			var out = p.stdout.readLine();
			p.close();
			return out;
		}
		catch (e:Dynamic)
		{
			return "";
		}
		#end
	}

	static function defineArch():Void
	{
		if (Context.defined("HXCPP_M32") || Context.defined("HXCPP_M64") || Context.defined("HXCPP_ARM64")
			|| Context.defined("HXCPP_ARMV7") || Context.defined("HXCPP_X86") || Context.defined("HXCPP_X86_64"))
			return;
		if (Context.defined("ios") || Context.defined("iphoneos"))
			return;

		var androidTarget = Context.defined("android");

		switch (hostArch().trim().toLowerCase())
		{
			case "amd64", "x86_64":
				if (androidTarget)
					Compiler.define("HXCPP_X86_64")
				else
					Compiler.define("HXCPP_M64");
			case "x86", "i386", "i486", "i586", "i686":
				if (androidTarget)
					Compiler.define("HXCPP_X86")
				else
					Compiler.define("HXCPP_M32");
			case "arm64", "aarch64":
				Compiler.define("HXCPP_ARM64");
			case "armv7l", "armv7", "arm":
				Compiler.define("HXCPP_ARMV7");
			default:
		}
	}
}
#end
