from enum import IntEnum
from typing import Optional, Union


FieldVariant = Union[FunctionBindField, MemberField, PadField, InlineField]

class FunctionType(IntEnum):
    Normal = 0
    Ctor = 1
    Dtor = 2

class AccessModifier(IntEnum):
    Private = 0
    Protected = 1
    Public = 2

class OffsetStatus(IntEnum):
    Unbound = 0
    Bound = 1
    Inlined = 2

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
    def win(self) -> int: ...
    @property
    def android32(self) -> int: ...
    @property
    def android64(self) -> int: ...
    @property
    def m1(self) -> int: ...
    @property
    def imac(self) -> int: ...
    @property
    def ios(self) -> int: ...

    def for_platform(self, plat: str) -> Optional[int]:
        """The hex int offset for the given platform. None if not found or out-of-line."""
        ...

    def platforms_as_dict(self) -> dict[str, str]:
        """Transforms all platform data into a dictionary as platform name to hex offsets."""
        ...

    def status_for(self, plat: str) -> OffsetStatus:
        """Gives the offset status of a given platform in the current PlatformNumber instance."""
        ...

class FunctionProto:
    """Prototype of a free function."""
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
    def args(self) -> list[tuple[str, Type]]:
        """List of the function's arguments as tuples of argument name to argument type."""
        ...

    @property
    def name(self) -> str:
        """The function's name."""
        ...

class MemberFunctionProto:
    """Prototype of a class method."""
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
    def args(self) -> list[tuple[str, Type]]:
        """List of the function's arguments as tuples of argument name to argument type."""
        ...

    @property
    def name(self) -> str:
        """The function's name."""
        ...

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
    """Function field instance of a class method."""
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
    """Instance of a member inside a class."""
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

class PadField:
    @property
    def amount(self) -> PlatformNumber:
        """A `PlatformNumber` instance of padding bytes for all platforms."""
        ...

class InlineField:
    @property
    def inner(self) -> str:
        """The inline body of the function as a raw string."""
        ...

class Field:
    """
    Field of a class. Can be any of the following
    field types:
    - FunctionBindField
    - MemberField
    - PadField
    - InlineField
    """
    @property
    def id(self) -> int:
        """The index of the field. This starts from 0 and counts up across all classes."""
        ...

    @property
    def parent(self) -> str:
        """The name of the parent class."""
        ...

    def getAsFunctionBindField(self) -> Optional[FunctionBindField]: ...
    def getAsMemberField(self) -> Optional[MemberField]: ...
    def getAsPadField(self) -> Optional[PadField]: ...
    def getAsInlineField(self) -> Optional[InlineField]: ...

    def for_platform(self, plat: str) -> Optional[FieldVariant]:
        """
        Check if the field is presentable on the given platform
        (e.g. doesn't apply to a missing attribute or
        isn't excluded from a set of platforms),
        then return the relevant field.
        """
        ...

class Function:
    """A free function instance."""
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

class Header:
    @property
    def name(self) -> str:
        """Name of the header file as written in the import declaration."""
        ...

    @property
    def platform(self) -> list[str]:
        """Platforms this header is present on. All platforms listed if none specified."""
        ...

class Class:
    """A Broma class instance."""
    @property
    def attributes(self) -> Attributes:
        """The class's Broma attributes."""
        ...

    @property
    def attrs(self) -> Attributes:
        """Shorthand equivalent for `attributes`."""
        ...

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
    def source(self) -> str:
        """The Broma file this class originates from."""
        ...

    def __eq__(self, other: object) -> bool: ...
    def __hash__(self) -> int: ...

class Root:
    """Parsed Broma file instance."""

    def __init__(self, fileName: str) -> None: ...

    @property
    def classes(self) -> list[Class]:
        """Classes as class name to `Class` instance."""
        ...

    @property
    def functions(self) -> list[Function]:
        """Free functions."""
        ...

    @property
    def headers(self) -> list[Header]:
        """
        Header files that this Broma file imports.
        These are automatically resolved and loaded by Broma if they exist.
        """
        ...

    def __getitem__(self, _class_name_: str) -> Optional[Class]:
        """
        Searches for a `Class` object by name, similar to
        the vector operator[] in the original Broma implementation.
        """
