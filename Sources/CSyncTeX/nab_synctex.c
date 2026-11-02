#include "CSyncTeX.h"
#include <xlocale.h>

synctex_scanner_p nab_synctex_scanner_new(const char *output) {
    locale_t numeric = newlocale(LC_NUMERIC_MASK, "C", NULL);
    if (!numeric) return NULL;
    locale_t previous = uselocale(numeric);
    synctex_scanner_p scanner = synctex_scanner_new_with_output_file(output, NULL, 1);
    uselocale(previous);
    freelocale(numeric);
    return scanner;
}
