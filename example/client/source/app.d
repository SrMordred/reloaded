//COMPILE AS LIBRARY
import core.sys.windows.dll;
import core.stdc.stdio : printf;
mixin SimpleDllMain;

extern(C):
nothrow:
struct UserData
{
	int x;
	int y;
}
UserData* userdata;

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
	userdata.x = 10;
	userdata.y = 20;
}
