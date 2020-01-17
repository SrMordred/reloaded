module reloaded.setjmp;

version( Windows )
{
    version( X86_64 )
    {
        alias ubyte[256] jmp_buf;
    }
    else version( X86 )
    {
        alias ubyte[128] jmp_buf;
    }
    extern(C): nothrow: @nogc:

    int  _setjmp(ref jmp_buf, void*);
    void longjmp(ref jmp_buf, int);

    alias setjmp = _setjmp;
}
else
{
    public import core.sys.posix.setjmp : setjmp, longjmp, jmp_buf;
}

