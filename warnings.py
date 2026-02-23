# Collects warnings from the output of a FreeBSD build. By default ignores
# warnings from third-party code. Will instead collect only warnings from
# third-party code if the 'contrib' option is supplied.

# Usage: warnings.py <file> [|contrib]

import re, sys

show_contrib = len(sys.argv) > 2 and sys.argv[2] == 'contrib'

warn_re = re.compile(r"\[-W.+\]")
file_re = re.compile(r"^\/.+?:")
contrib_re = re.compile(r"\/contrib\/")
crypto_re = re.compile(r"\/crypto\/")

warnings = {}
with open(sys.argv[1], 'r') as f:
    for s in f.readlines():
        maybe_match = warn_re.search(s)
        is_contrib = (contrib_re.search(s) != None) or (crypto_re.search(s) != None)
        if not maybe_match or (show_contrib != is_contrib):
            continue
        warn = maybe_match.group()[1:-1]
        file = file_re.search(s).group()[9:]
        if warn in warnings:
            warnings[warn][file] = warnings[warn].get(file, 0) + 1
        else:
            warnings[warn] = {file: 1}

for warn in reversed(sorted(warnings.items(), key=lambda w: sum(w[1].values()))):
    print(f'{warn[0]}')
    for file in reversed(sorted(warn[1].items(), key=lambda x: x[1])):
        print(f'    {file[0]:50} {file[1]}')
