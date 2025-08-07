#!/usr/bin/python3

from pathlib import Path
import sys
import os

from posh import sh

root = os.environ.get("MOUNT_ROOT")
if not root:
    print("can't find root")
    print(os.environ)
    sys.exit(1)

for arg in sys.argv[1:]:
    if not Path(arg).is_absolute():
        print(f"{arg} is not an absolute path")

    elif Path(root) in Path(arg).parents:
        path = Path(arg).relative_to(Path(root))
        path = Path('/home/vim/mount', path)
        print(f"Opening {path}")
        sh.null().nvim('--server', '/tmp/nvimsocket', '--remote', path)

    else:
        print(f'I cant open {arg}')

