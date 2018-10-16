//COMPILE AS A NORMAL APP
import std.stdio;

struct UserData
{
	int x;
	int y;
}
//Receive as first argument the lib path
//eg: app.exe client/client.dll


void main( string[] args )
{	

	if(args.length >= 2)
	{
		import reloaded : Reloaded, ReloadedCrashReturn;
		import core.stdc.stdlib : system;
		import core.thread;

		UserData userdata;

		auto lib_path = args[1];

		auto script = Reloaded();
		script.load( lib_path, userdata );

		mixin ReloadedCrashReturn;
		while(true)
		{
			script.update;
			auto result = userdata.x + userdata.y;
			writeln("x + y = ", result);
			if(result < 0)
			{
				writeln("Negative result skip loop :)");
				break;
			}
			Thread.sleep(1.seconds);
		}
	}
}
