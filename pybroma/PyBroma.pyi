from enum import IntEnum
from typing import Optional


class FunctionType(IntEnum):
    Normal = 0
    Ctor = 1
    Dtor = 2

class AccessModifier(IntEnum):
    Private = 0
    Protected = 1
    Public = 2

class Attributes:
    @property
    def docs(self) -> str:
        """Any docstring pulled from a `[[docs(...)]]` attribute."""
        ...
    @property
    def links(self) -> list[str]:
        """Platforms this function or class links to its symbol(s) on."""
        ...
    @property
    def missing(self) -> list[str]:
        """Platforms this function or class is missing from. Empty if universally present."""
        ...
    @property
    def depends(self) -> list[str]:
        """Classes this function or class depends on. Includes the superclasses."""
        ...
    @property
    def since(self) -> str:
        """The Geode SDK version that this class or function was introduced in."""
        ...

class Type:
    @property
    def is_struct(self) -> bool: ...
    @property
    def name(self) -> str:
        """The actual type."""
        ...

    def __eq__(self, other: object) -> bool: ...

class PlatformNumber:
    @property
    def m1(self) -> int: ...
    @property
    def imac(self) -> int: ...
    @property
    def ios(self) -> int: ...
    @property
    def win(self) -> int: ...
    @property
    def android32(self) -> int: ...
    @property
    def android64(self) -> int: ...

    def platforms_as_dict(self) -> dict[str, str]:
        """Transforms all platform data into a dictionary as platform name to hex offsets."""

class FunctionProto:
    @property
    def attributes(self) -> Attributes:
        """The function's Broma attributes."""
        ...
    @property
    def attrs(self) -> Attributes:
        """Shorthand equivalent for `attributes`."""
        ...
    @property
    def ret(self) -> Type:
        """The return type of the function."""
        ...
    @property
    def args(self) -> dict[str, Type]:
        """Dictionary of the function's arguments as argument name to argument type."""
        ...
    @property
    def name(self) -> str:
        """The function's name."""
        ...

class MemberFunctionProto:
    @property
    def attributes(self) -> Attributes:
        """The function's Broma attributes."""
        ...
    @property
    def attrs(self) -> Attributes:
        """Shorthand equivalent for `attributes`."""
        ...
    @property
    def ret(self) -> Type:
        """The return type of the function."""
        ...
    @property
    def args(self) -> dict[str, Type]:
        """Dictionary of the function's arguments as argument name to argument type."""
        ...
    @property
    def name(self) -> str: ...

    @property
    def type(self) -> FunctionType:
        """The C++ type of the function. Gives a `FunctionType` `IntEnum`."""
        ...
    @property
    def access(self) -> AccessModifier:
        """The access modifier of the function. Gives an `AccessModifier` `IntEnum`."""
        ...

    @property
    def is_const(self) -> bool: ...
    @property
    def is_virtual(self) -> bool: ...
    @property
    def is_callback(self) -> bool: ...
    @property
    def is_static(self) -> bool: ...

    def __eq__(self, other: object) -> bool: ...

class FunctionBindField:
    @property
    def prototype(self) -> MemberFunctionProto: ...
    @property
    def proto(self) -> MemberFunctionProto:
        """Shorthand equivalent for `prototype`."""
        ...
    @property
    def binds(self) -> PlatformNumber:
        """A `PlatformNumber` instance of binding addresses for all platforms."""
        ...

class MemberField:
    @property
    def platform(self) -> list[str]:
        """Platforms this member is present on. Empty if present on all platforms."""
        ...
    @property
    def name(self) -> str:
        """The member's name."""
        ...
    @property
    def type(self) -> Type:
        """The member's C++ type."""
        ...
    @property
    def count(self) -> int: ...

class PadField:
    @property
    def amount(self) -> PlatformNumber:
        """A `PlatformNumber` instance of padding bytes for all platforms."""
        ...

class InlineField:
    @property
    def inner(self) -> str: ...

class Field:
    @property
    def id(self) -> int: ...
    @property
    def parent(self) -> str: ...

    def getAsFunctionBindField(self) -> Optional[FunctionBindField]: ...
    def getAsMemberField(self) -> Optional[MemberField]: ...
    def getAsPadField(self) -> Optional[PadField]: ...
    def getAsInlineField(self) -> Optional[InlineField]: ...

class Function:
    @property
    def prototype(self) -> FunctionProto: ...
    @property
    def proto(self) -> FunctionProto:
        """Shorthand equivalent for `prototype`."""
        ...
    @property
    def binds(self) -> PlatformNumber:
        """A `PlatformNumber` instance of binding addresses for all platforms."""
        ...

class Class:
    @property
    def name(self) -> str:
        """The class name."""
        ...
    @property
    def superclasses(self) -> list[str]:
        """Classes that this class inherits from."""
        ...
    @property
    def fields(self) -> list[Field]:
        """All class fields as `Field` instances."""
        ...
    @property
    def attributes(self) -> Attributes:
        """The class's Broma attributes."""
        ...
    @property
    def attrs(self) -> Attributes:
        """Shorthand equivalent for `attributes`."""
        ...
    @property
    def source(self) -> str:
        """The Broma file this class originates from."""
        ...

class Root:
    """Parsed Broma file instance."""

    def __init__(self, fileName: str) -> None: ...

    @property
    def classes(self) -> dict[str, Class]:
        """Classes as class name to `Class` instance."""
        ...
    @property
    def functions(self) -> list[Function]:
        """Free functions."""
        ...
