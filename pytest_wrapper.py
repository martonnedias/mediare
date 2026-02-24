import sys
import os
import pytest

# Manual path setup
root = r"c:\Users\tonne\SITES\mediare_mgcf"
backend = os.path.join(root, "backend")
sys.path.insert(0, root)
sys.path.insert(0, backend)

if __name__ == "__main__":
    # Run pytest on the requested arguments
    args = sys.argv[1:]
    if not args:
        args = [os.path.join(backend, "tests")]
    
    sys.exit(pytest.main(args))
