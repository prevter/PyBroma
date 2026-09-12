# PyBroma

> [!CAUTION]
> This library is currently highly experimental and features, APIs, or bindings may break without prior notice at any time. Use at your own risk in production-critical software!

A Python wrapper for [Broma](https://github.com/geode-sdk/broma), designed to parse `.bro` files from the [Geometry Dash Geode bindings](https://github.com/geode-sdk/bindings).

## Features

- **Fast Prototyping:** Avoid slow C++ compile times with a scriptable Python environment.
- **Python Compatibility:** Provides many Python-specific extras and functionalities to feel native to the language.
- **Mod Automation:** Generate code and automate reverse-engineering workflows for Geometry Dash and Geode mods.
- **Data Analysis:** Useful for using in simple apps to analyze Broma ASTs seamlessly.
- **Tooling Support:** Ideal for creating tool-specific headers (e.g. Ghidra/IDA header files like in [BromaIDA](https://github.com/Stazzical/BromaIDA)).

## How To Use

```python
from pybroma import Root

# parses 'test.bro' in current working directory
root = Root("test.bro")

for cls in root.classes:
    print(f"class {cls.name}")
    for field in cls.fields:
        # a Field instance can be of different variants
        if fn := field.getAsFunctionBindField():
            # fn.proto is a MemberFunctionProto instance
            args = ", ".join(f"{t} {n}" for n, t in fn.proto.args)
            print(f"  {fn.proto.ret} {fn.proto.name}({args})")

            for plat in fn.binds:
                print(f"    {plat}: {fn.binds[plat]:#x}")
```

## Installation

### Option 1: Install via Prebuilt Wheels

Download the compatible wheel for your OS, architecture, and Python version from the [GitHub Releases](https://github.com/prevter/PyBroma/releases) page.

Wheel filenames encode the Python version (`cp312`) and platform (`win_amd64`, `linux_x86_64`, `macosx_26_0_arm64`, etc.). Pick the one matching your interpreter and OS.

Install the wheel file with `pip`:

```bash
pip install path/to/pybroma-0.3.1-cp312-cp312-win_amd64.whl
```

If there's no prebuilt wheel for your platform, download and install the source distribution instead from the releases page:

```bash
pip install path/to/pybroma-0.3.1.tar.gz
```

Building from source requires a C++20 compiler suite like Visual Studio, GCC or Xcode Command Line Tools.

### Option 2: Install directly from Git

Run the following command in your terminal:

```bash
pip install git+https://github.com/prevter/PyBroma
```

## Frequently Asked Questions

### Will this be released on PyPI?

Due to licensing and redistribution limitations regarding the original codebase, an official PyPI release is unlikely. This repository serves as a maintained fork and functions as the primary backend for [BromaIDA](https://github.com/Stazzical/BromaIDA).

### Will Geode officially adopt this library?

There are no current plans for official adoption. If you find the tool useful for Geode development, feel free to recommend it to others in the community.

## TODOs

- [ ] Broma Writer/Formatter
- [ ] Class member injector (For helping with pull requests to the bindings)
- [ ] Ability to create an AST by hand from scratch and export it
