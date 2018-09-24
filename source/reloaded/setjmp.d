module reloaded.setjmp;

alias ubyte[256] jmp_buf;

extern(C): nothrow: @nogc:

int  _setjmp(ref jmp_buf, void*);
void longjmp(ref jmp_buf, int);

alias setjmp = _setjmp;