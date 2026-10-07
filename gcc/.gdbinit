set disassembly-flavor intel
# Don't automatically show the next machine instruction after stepping
set disassemble-next-line off

# Normal source-level stepping; don't force stepping into functions without debug info
set step-mode off

# Skip stepping into C++ standard library functions
skip -rfunction ^std::
skip -rfunction ^__gnu_cxx::
skip -rfunction ^__cxa_
skip -rfunction ^_Unwind_
# Skip functions whose source files are inside the C++ standard library headers
skip -gfi /usr/include/c++/*
skip -gfi /usr/include/c++/*/*
skip -gfi /usr/include/c++/*/*/*

# Pretty-print structs/classes using a more readable multi-line format
set print pretty on
# Print the actual dynamic/derived C++ object type when possible
set print object on
# Print symbolic names for addresses when available
set print symbol on
# Demangle C++ symbol names when printing them
set print demangle on
# Demangle C++ symbol names in disassembly output
set print asm-demangle on
# Disable paged output ("Type <return> to continue")
set pagination off

# Save command history between GDB sessions
set history save on
set history size 10000
set history remove-duplicates unlimited

# Show the full Python traceback when a GDB Python script fails
set python print-stack full
