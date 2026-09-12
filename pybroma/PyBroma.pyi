from enum import IntEnum
from typing import Optional, Union

import os


class BromaParseError(Exception): ...


class FunctionType(IntEnum):
    """A member function's type."""

    Normal = 0
    Ctor = 1
    Dtor = 2


class AccessModifier(IntEnum):
    """A member function's access modifier."""

    Private = 0
    Protected = 1
    Public = 2


class OffsetStatus(IntEnum):
    """The binding status of an offset."""

    Unbound = 0
    Bound = 1
    Inlined = 2


class FieldVariant(IntEnum):
    """The variant of a Field instance."""

    Inline = 0
    FunctionBind = 1
    Pad = 2
    Member = 3


class Attributes:
    """Container class of attributes that apply to a given Broma property."""

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

    @property
    def renamed_from(self) -> list[str]:
        """Prior names for the attributed property."""
        ...

    def __repr__(self) -> str: ...
    def __getitem__(self, key: str): ...


class Type:
    """A C++ type declaration."""

    @property
    def is_struct(self) -> bool: ...

    @property
    def name(self) -> str:
        """The actual type."""
        ...

    def __str__(self) -> str: ...
    def __repr__(self) -> str: ...
    def __bool__(self): ...
    def __eq__(self, other: object) -> bool: ...
    def __hash__(self) -> int: ...


class PlatformNumber:
    """Container class of hexadecimal binding offsets for each platform."""

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
        """The offset for the given platform. None if not found or out-of-line."""
        ...

    def platforms_as_dict(self) -> dict[str, int]:
        """Transforms all platform data into a dictionary as platform name to offsets."""
        ...

    def status_for(self, plat: str) -> OffsetStatus:
        """Gives the offset status of a given platform."""
        ...

    def __repr__(self) -> str: ...
    def __len__(self): ...
    def __iter__(self): ...
    def __contains__(self, item): ...
    def __eq__(self, value: object) -> bool: ...
    def __hash__(self) -> int: ...
    def __getitem__(self, key): ...


class FunctionProto:
    """The signature of a free function."""

    @property
    def attributes(self) -> Attributes:
        """The function's Broma attributes."""
        ...
    @property
    def attrs(self) -> Attributes:
        """The function's Broma attributes."""
        ...

    @property
    def ret(self) -> Type:
        """The return type of the function."""
        ...

    @property
    def args(self) -> list[tuple[str, Type]]:
        """List of the function's arguments as tuples of argument name to argument type `Type`."""
        ...

    @property
    def name(self) -> str:
        """The function's name."""
        ...

    @property
    def is_variadic(self) -> bool:
        """
        Whether this function takes a variable amount of arguments.
        The C++ ellipsis used to indicate this is removed from the args property.
        """
        ...

    def __repr__(self) -> str: ...
    def __eq__(self, value: object) -> bool: ...
    def __hash__(self) -> int: ...


# can't mirror the inheritence in the .pyx but I can mirror it here!
class MemberFunctionProto(FunctionProto):
    """The signature of a member function."""

    @property
    def type(self) -> FunctionType:
        """The C++ type of the function."""
        ...

    @property
    def access(self) -> AccessModifier:
        """The access modifier of the function."""
        ...

    @property
    def is_const(self) -> bool: ...
    @property
    def is_virtual(self) -> bool: ...
    @property
    def is_callback(self) -> bool: ...
    @property
    def is_static(self) -> bool: ...

    @property
    def is_ctor(self) -> bool: ...
    @property
    def is_dtor(self) -> bool: ...

    def __repr__(self) -> str: ...
    def __eq__(self, other: object) -> bool: ...
    def __hash__(self) -> int: ...


class FunctionBindField:
    """Function field instance of a class method."""

    @property
    def prototype(self) -> MemberFunctionProto:
        """The method function's signature."""
        ...
    @property
    def proto(self) -> MemberFunctionProto:
        """The method function's signature."""
        ...

    @property
    def binds(self) -> PlatformNumber:
        """The offsets of this function, separated per platform."""
        ...

    @property
    def inner(self) -> str:
        """The (optional) inline body of the function as a raw string."""
        ...

    def __repr__(self) -> str: ...
    def __eq__(self, value: object) -> bool: ...
    def __hash__(self) -> int: ...


class MemberField:
    """A member inside a class."""

    @property
    def attributes(self) -> Attributes:
        """The member's Broma attributes."""
        ...
    @property
    def attrs(self) -> Attributes:
        """The member's Broma attributes."""
        ...

    @property
    def platform(self) -> list[str]:
        """Platforms this member is present on."""
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
    def count(self) -> int:
        """The number of elements in the field when it's an array."""
        ...

    def __repr__(self) -> str: ...


class PadField:
    @property
    def amount(self) -> PlatformNumber:
        """A `PlatformNumber` instance of padding bytes for all platforms."""
        ...

    def __repr__(self) -> str: ...


class InlineField:
    @property
    def inner(self) -> str:
        """The inline body of the function as a raw string."""
        ...

    def __repr__(self) -> str: ...


class Field:
    """
    Field of a class. Can be any of the following field variants:
    - FunctionBindField
    - MemberField
    - PadField
    - InlineField
    """

    @property
    def field_id(self) -> int:
        """
        The index of the field. This starts from 0 and counts up across all classes.
        Stays persistent across several included Broma files with the include expression.
        """
        ...
    @property
    def id(self) -> int:
        """
        The index of the field. This starts from 0 and counts up across all classes.
        Stays persistent across several included Broma files with the include expression.
        """
        ...

    @property
    def parent(self) -> str:
        """The name of the parent class."""
        ...

    @property
    def line(self) -> int:
        """The line number where this field was defined at inside the class."""
        ...

    def getAsFunctionBindField(self) -> Optional[FunctionBindField]: ...
    def getAsMemberField(self) -> Optional[MemberField]: ...
    def getAsPadField(self) -> Optional[PadField]: ...
    def getAsInlineField(self) -> Optional[InlineField]: ...

    def get_method_proto(self) -> Optional[MemberFunctionProto]:
        """Fetch the method's prototype if this Field is a FunctionBindField, else None."""
        ...

    def for_platform(
        self, plat: str
    ) -> Optional[Union[FunctionBindField, MemberField, PadField, InlineField]]:
        """
        Check if the field is presentable on the given platform
        (e.g. doesn't apply to a missing attribute or
        isn't excluded from a set of platforms),
        then return the relevant field.
        """
        ...

    @property
    def variant(self) -> FieldVariant:
        """Get the variant this field is as a FieldVariant enum."""
        ...

    def __repr__(self) -> str: ...

class Function:
    """A free function instance."""

    @property
    def prototype(self) -> FunctionProto:
        """The free function's signature."""
        ...
    @property
    def proto(self) -> FunctionProto:
        """The free function's signature."""
        ...

    @property
    def binds(self) -> PlatformNumber:
        """The offsets of this free function, separated per platform."""
        ...

    @property
    def inner(self) -> str:
        """The (optional) inline body of the function as a raw string."""
        ...

    @property
    def source(self) -> str:
        """The source file where this free function was defined."""
        ...

    @property
    def line(self) -> int:
        """The line number where this free function was defined at in the file."""
        ...

    def __repr__(self) -> str: ...
    def __eq__(self, value: object) -> bool: ...
    def __hash__(self) -> int: ...


class Header:
    """A header file to be imported."""

    @property
    def name(self) -> str:
        """Name of the header file as written in the import declaration."""
        ...

    @property
    def platform(self) -> list[str]:
        """Platforms this header is present on. All platforms listed if none specified."""
        ...

    @property
    def source(self) -> str:
        """The source file where this header file was imported."""
        ...

    @property
    def line(self) -> int:
        """The line number where this header was imported at in the file."""
        ...

    def __repr__(self) -> str: ...
    def __eq__(self, value: object) -> bool: ...
    def __hash__(self) -> int: ...


class Class:
    """A Broma class instance."""

    @property
    def attributes(self) -> Attributes:
        """The class's Broma attributes."""
        ...
    @property
    def attrs(self) -> Attributes:
        """The class's Broma attributes."""
        ...

    @property
    def name(self) -> str:
        """The name of the class."""
        ...

    @property
    def superclasses(self) -> list[str]:
        """Parent classes that this class inherits from."""
        ...

    @property
    def fields(self) -> list[Field]:
        """All the parsed class fields."""
        ...

    @property
    def source(self) -> str:
        """The source file where this class was defined."""
        ...

    @property
    def line(self) -> int:
        """The line number where this class was defined at in the file."""
        ...

    def __repr__(self) -> str: ...
    def __iter__(self): ...
    def __eq__(self, other: object) -> bool: ...
    def __hash__(self) -> int: ...


class Root:
    """Parsed Broma file instance."""

    def __init__(self, fileName: str | os.PathLike[str]) -> None: ...

    @staticmethod
    def parse_string(source: str, include_base: str | os.PathLike[str] | None = None, source_name: str = "<string>") -> Root:
        """Create a Root instance from a string of Broma declarations."""
        ...

    @property
    def classes(self) -> list[Class]:
        """Parsed top-level classes."""
        ...

    @property
    def functions(self) -> list[Function]:
        """Parsed top-level free functions."""
        ...

    @property
    def headers(self) -> list[Header]:
        """Header files that this Broma file imports."""
        ...

    @property
    def sources(self) -> set[str]:
        """Every distinct source file that contributed content to this Root."""
        ...

    @property
    def by_source(self) -> dict[str, Root]:
        """Dictionary of each distinct source file name to its corresponding filtered Root instance."""
        ...

    def get_field_by_id(self, field_id: int) -> Optional[Field]:
        """Look up a field by its field_id across every class in this Root."""
        ...

    @property
    def all_fields(self) -> list[Field]:
        """All fields across every class in this Root."""
        ...

    def get_class_by_name(self, cls_name: str) -> Optional[Class]:
        """Find a class in this Root by its name."""
        ...

    def __repr__(self) -> str: ...
    def __bool__(self): ...
    def __len__(self): ...
    def __contains__(self, item): ...
    def __iter__(self): ...
    def __getitem__(self, cls_name: str) -> Class: ...
