module reloaded.reloaded;

// void __error_handler( int code )
// {
// {
// 	import core.stdc.stdio;
// 	import core.stdc.signal;

//     enum ERROR_MSG = 
//     [
//         SIGABRT = "Signal Abort",
//         SIGFPE = "Signal Floating-Point Exception",
//         SIGILL = "Signal Illegal Instruction",
//         SIGINT = "Signal Interrupt",
//         SIGSEGV = "Signal Segmentation Violation",
//         SIGTERM = "Signal Terminate",
//     ];

// 	printf("Program crash with signal :'%s'(%d)\n",ERROR_MSG[code], code);
// 	longjmp(env, 1);
// }
public:

struct Reloaded
{
	import derelict.util.sharedlib : SharedLib;
	import fswatch : FileWatch, FileChangeEventType;
    import std.typecons : Flag, Yes, No;

    static nothrow void noop(){}

    alias extern_init   = nothrow void function(void*);
    alias extern_uninit = nothrow void function(void*);
    alias extern_load   = nothrow void function(void*);
    alias extern_unload = nothrow void function(void*);
    alias extern_update = nothrow void function();

	SharedLib       lib;
	extern_update   update_fun;
	void*           userdata;
	FileWatch       fw;

    string          lib_path;
    string[2]       lib_swaps;
	bool            lib_swaps_v = 0;

	this(T)(string lib_path, auto ref T userdata)
	{
        load( lib_path, userdata );
	}

    void load(T)(string lib_path, auto ref T userdata)
    {
        import std.path : baseName, extension;
        this.lib_path = lib_path;
        this.userdata = cast(void*)&userdata;
		fw = FileWatch(lib_path);

        auto base = lib_path.baseName;
        auto ext  = lib_path.extension;

        lib_swaps[0] = base ~ "0." ~ ext;
        lib_swaps[1] = base ~ "1." ~ ext;

        loadLib!(Yes.FirstTime);
    }

    void update()
    {
        foreach (event; fw.getEvents())
		{
			if (event.type == FileChangeEventType.create || event.type == FileChangeEventType.modify  )
			{
				loadLib!(No.FirstTime);
				break;
			}
		}
        update_fun();
    }

    ~this()
    {
        auto unload = getLibFun!"unload";
        if(unload)
            unload(userdata);

        auto uninit = getLibFun!"uninit";
        if(uninit)
            uninit(userdata);
    }

    private:

    auto getLibFun(string fun, Args... )(auto ref Args args)
    {
        mixin("return cast(extern_" ~ fun ~ " )lib.loadSymbol(fun, false);");
    }

    void waitFileUnlock()
    {
		import core.stdc.stdio : FILE, fopen, fclose;

        FILE* fp;
		while( (fp = fopen(lib_path.ptr, "r" )) == null ){}
		fclose(fp);
    }


    void loadLib(Flag!"FirstTime" first_time = No.FirstTime)()
    {
        import std.file : copy, exists, remove;
        import std.stdio : printf = writefln;

        if( !lib_path.exists )
        {
            printf("Lib not found :'%s'", lib_path );
            return;
        }

        waitFileUnlock;

        auto lib_tmp = lib_swaps[cast(size_t)lib_swaps_v];
		copy(lib_path, lib_tmp);

        if( lib.isLoaded )
			lib.unload;
		lib.load( [lib_tmp] );

        //TEST ALL FUNCTIONS

        static foreach(fun ; ["init", "uninit", "load", "unload", "update"])
        {
            if( getLibFun!fun() == null )
            {
                printf("Lib failed to load extern function: %s -> '%s'", fun,  mixin( "extern_"~fun~".stringof" ));
            }
        }

        lib_swaps_v = !lib_swaps_v;

        update_fun = getLibFun!"update";
        if( !update_fun )
            update_fun = &noop;

        static if(first_time)
        {
            auto init = getLibFun!"init";
            if(init)
                init(userdata);
            
            auto load = getLibFun!"load";
            if(load)
                load(userdata);
        }
        else
        {
            auto unload = getLibFun!"unload";
            if(unload)
                unload( userdata );

            auto load = getLibFun!"load";
            if(load)
                load( userdata );

        }

        auto remove_lib_tmp = lib_swaps[cast(size_t)lib_swaps_v];
		if( remove_lib_tmp.exists )
			remove_lib_tmp.remove;
    }
}
