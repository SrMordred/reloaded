# Reloaded

Reloaded is a simple library for live code reloading.

Reloaded is on experimental stage and have been tested only on windows.

### Show And Tell

ReloadeD works with a simple Host application, and a Client Library.

```d
#HOST APPLICATION

struct Data
{
    int value;
}

void main()
{
    import reloaded : Reloaded;
    import std.stdio : writeln;

    Reloaded script;
    Data userdata;
    /*
    Load the library, and pass the data that will be shared between HOST and CLIENT.
    */
    script.load("path/lib.dll", userdata );

    /*
    update() will call the method with same name at the client side and will reload
    the library when changes.
    */

    while(true)
    {
        script.update();
        //see the data change here
        writeln(data);
    }
}
```

The client can be used with 5 functions:
´void init(void*)´ and ´void uninit(void*)´
Will be called on the first lib load and when the host is destroyed.

´void load(void*)´ and ´void unload(void*)´
Will be called once every time the client changes

´void update()´
Can be called at will on the host side (normally around a loop)

Note that you don´t need Reloaded module on the client side
so you can reload dynamic libraries from any language :)

```d
#CLIENT LIBRARY

import core.sys.windows.dll;
import core.stdc.stdio : printf;
mixin SimpleDllMain;

extern(C):
nothrow:

//Same struct declared on Host
struct Data
{
	int x;
	int y;
}

Data* userdata;

void load( void* _userdata )
{
	printf("load\n");
	userdata = cast(UserData*) _userdata;
}
void unload(void* userdata){
	printf("unload\n");
}
void init(void* userdata){
	printf("init\n");
}
void uninit(void* userdata){
	printf("uninit\n");
}

void update()
{
    //change value here, recompile and see the changes on the host side :)
	userdata.value = 10;
}
```

Reloaded was inspired by 

[cr.h](https://github.com/fungos/cr)

### License

The MIT License (MIT)

Copyright (c) 2017 Danny Angelo Carminati Grein

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.