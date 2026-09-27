package sscript_lua;

import sscript_lua.State;


class Convert
{
	public static inline var MAX_DEPTH:Int = 64;

	public static function toLua(l:State, val:Any):Bool
	{
		return toLuaD(l, val, 0);
	}

	static function toLuaD(l:State, val:Any, depth:Int):Bool
	{
		switch (Type.typeof(val))
		{
			case Type.ValueType.TNull:
				Lua.pushnil(l);
			case Type.ValueType.TBool:
				Lua.pushboolean(l, val);
			case Type.ValueType.TInt:
				Lua.pushinteger(l, cast(val, Int));
			case Type.ValueType.TFloat:
				Lua.pushnumber(l, val);
			case Type.ValueType.TClass(String):
				Lua.pushstring(l, cast(val, String));
			case Type.ValueType.TClass(Array):
				if (!canNest(l, depth)) return false;
				arrayToLuaD(l, val, depth);
			case Type.ValueType.TObject:
				if (!canNest(l, depth)) return false;
				objectToLua(l, val, depth);
			case Type.ValueType.TClass(haxe.ds.StringMap):
				if (!canNest(l, depth)) return false;
				mapToLua(l, val, depth);
			default:
				#if debug
				trace('sscript_lua.Convert: Haxe value of type ${Type.typeof(val)} is not supported');
				#end
				return false;
		}

		return true;
	}

	static inline function canNest(l:State, depth:Int):Bool
		return depth < MAX_DEPTH && Lua.checkstack(l, 4) != 0;

	public static inline function arrayToLua(l:State, arr:Array<Any>):Void
		arrayToLuaD(l, arr, 0);

	static function arrayToLuaD(l:State, arr:Array<Any>, depth:Int):Void
	{
		var size:Int = arr.length;
		Lua.createtable(l, size, 0);

		for (i in 0...size)
		{
			if (!toLuaD(l, arr[i], depth + 1))
				Lua.pushnil(l);
			Lua.rawseti(l, -2, i + 1);
		}
	}

	static function objectToLua(l:State, res:Any, depth:Int):Void
	{
		Lua.createtable(l, 0, 0);
		for (n in Reflect.fields(res))
		{
			Lua.pushstring(l, n);
			if (toLuaD(l, Reflect.field(res, n), depth + 1))
				Lua.settable(l, -3);
			else
				Lua.pop(l, 1);
		}
	}

	static function mapToLua(l:State, mapValue:Any, depth:Int):Void
	{
		var map:haxe.ds.StringMap<Dynamic> = cast(mapValue, haxe.ds.StringMap<Dynamic>);

		Lua.createtable(l, 0, 0);
		for (key => value in map)
		{
			Lua.pushstring(l, key);
			if (toLuaD(l, value, depth + 1))
				Lua.settable(l, -3);
			else
				Lua.pop(l, 1);
		}
	}

	public static function fromLua(l:State, v:Int):Any
	{
		return fromLuaD(l, v, 0);
	}

	static function fromLuaD(l:State, v:Int, depth:Int):Any
	{
		switch (Lua.type(l, v))
		{
			case Lua.LUA_TNIL:
				return null;
			case Lua.LUA_TBOOLEAN:
				return Lua.toboolean(l, v);
			case Lua.LUA_TNUMBER:
				return Lua.tonumber(l, v);
			case Lua.LUA_TSTRING:
				return Lua.tostring(l, v);
			case Lua.LUA_TTABLE:
				if (!canNest(l, depth))
					return null;
				var t:Int = v < 0 ? Lua.gettop(l) + v + 1 : v;
				return fromLuaTable(l, t, depth);
			default:
				#if debug
				trace('sscript_lua.Convert: Lua value of type ${Lua.typename(l, Lua.type(l, v))} is not supported');
				#end
				return null;
		}
	}

	static function fromLuaTable(l:State, t:Int, depth:Int):Any
	{
		var count:Int = 0;
		var maxKey:Int = 0;
		var array:Bool = true;

		Lua.pushnil(l);
		while (Lua.next(l, t) != 0)
		{
			Lua.pop(l, 1);
			count++;
			if (array)
			{
				if (Lua.type(l, -1) != Lua.LUA_TNUMBER)
					array = false;
				else
				{
					var n:Float = Lua.tonumber(l, -1);
					if (n < 1 || n != Math.ffloor(n) || n > 1e9)
						array = false;
					else if (n > maxKey)
						maxKey = Std.int(n);
				}
			}
		}
		
		if (array && maxKey <= count * 2 + 8)
		{
			var arr:Array<Any> = [];
			if (maxKey > 0)
				arr.resize(maxKey);
			for (i in 1...maxKey + 1)
			{
				Lua.rawgeti(l, t, i);
				arr[i - 1] = fromLuaD(l, -1, depth + 1);
				Lua.pop(l, 1);
			}
			return arr;
		}

		var obj:Anon = Anon.create();
		Lua.pushnil(l);
		while (Lua.next(l, t) != 0)
		{
			obj.add(Std.string(fromLuaD(l, -2, depth + 1)), fromLuaD(l, -1, depth + 1));
			Lua.pop(l, 1);
		}
		return obj;
	}
}

// Anon_obj from hxcpp
@:native('hx::Anon')
extern class Anon
{
	@:native('hx::Anon_obj::Create')
	public static function create():Anon;

	@:native('hx::Anon_obj::Add')
	public function add(k:String, v:Any):Void;
}
