"""Test if FreeCAD toolcahin is used"""
import sys

def main():
    print("Hello from FreeCAD's python!")
    print(f"Python executable: {sys.executable}")
    print(f"Python version: {sys.version}")

if __name__ == "__main__":
    main()
else:
    raise ValueError(__name__)

import FreeCAD as App
print("you are using Freecad")
