/* Naberius: the bridge sets a thread-local C numeric locale during parsing.
   Do not enable upstream HAVE_SETLOCALE: it changes process-global state. */
#define SYNCTEX_INLINE inline
