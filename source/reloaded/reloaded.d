module reloaded.reloaded;

import reloaded.setjmp;

public:

mixin template ReloadedCrashReturn()
{
    import core.stdc.signal;
    import reloaded.setjmp : setjmp, jmp_buf;

    static jmp_buf __crash_return_buffer;

    extern(C) @nogc nothrow
    static void __crash_return_handler(int code)
    {
        import core.stdc.stdio;
    	import core.stdc.signal;
        import reloaded.setjmp : longjmp;

        enum ERROR_MSG = 
        [
            SIGABRT : "Signal Abort",
            SIGFPE : "Signal Floating-Point Exception",
            SIGILL : "Signal Illegal Instruction",
            SIGINT : "Signal Interrupt",
            SIGSEGV : "Signal Segmentation Violation",
            SIGTERM : "Signal Terminate",
        ];

        printf("ReloadeD Client crashed with signal :");

        switch(code)
        {
            case SIGABRT: printf("Abort"); break;
            case SIGFPE: printf("Floating-Point Exception"); break;
            case SIGILL: printf("Illegal Instruction"); break;
            case SIGINT: printf("Interrupt"); break;
            case SIGSEGV: printf("Segmentation Violation"); break;
            case SIGTERM: printf("Terminate"); break;
            default:
                printf("Unknown (%d) ", code);
            break;
        }

    	printf("\n",);
    	longjmp(__crash_return_buffer, 1);
    }
    version(Windows)
    {
        auto __crash_return_code = setjmp(__crash_return_buffer, null);
    }
    else
    {
        auto __crash_return_code = setjmp(__crash_return_buffer);
    }
    auto __crash_return_noop = {signal(SIGSEGV, &__crash_return_handler ); return false; }();
}

struct Reloaded
{
	import derelict.util.sharedlib : SharedLib;
	import fswatch : FileWatch, FileChangeEventType;
    import std.typecons : Flag, Yes, No;

    static void noop(){}

    alias extern_init   = void function(void*);
    alias extern_uninit = void function(void*);
    alias extern_load   = void function(void*);
    alias extern_unload = void function(void*);
    alias extern_update = void function();

	SharedLib       lib;
	extern_update   update_fun;
	void*           userdata;
	FileWatch       fw;

    string          lib_path;
    string[2]       lib_swaps;
	bool            lib_swaps_v = 0;

    

	this(T)(string lib_path, auto ref T userdata)
	{
		fw = FileWatch(lib_path);
        	load( lib_path, userdata );
	}

    void load(T)(string lib_path, auto ref T userdata)
    {
        import std.path : stripExtension, extension;

        this.lib_path = lib_path;
        this.userdata = cast(void*)&userdata;

        auto base = lib_path.stripExtension;
        auto ext  = lib_path.extension;

        lib_swaps[0] = base ~ "0" ~ ext;
        lib_swaps[1] = base ~ "1" ~ ext;

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
        {
			lib.unload;
            //DTOR unload;
        }

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
    }
}
