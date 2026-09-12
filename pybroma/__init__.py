try:
    # Read the auto-generated file if installed from wheel
    from ._version import __version__
except ImportError:
    try:
        # Fallback for local dev environments
        import importlib.metadata
        __version__ = importlib.metadata.version("pybroma")
    except Exception:
        __version__ = "0.4.0"


from .PyBroma import (
    # enums
    AccessModifier,
    FieldVariant,
    FunctionType,
    OffsetStatus,
    # exceptions
    BromaParseError,
    # core
    Attributes,
    Class,
    Field,
    Function,
    FunctionBindField,
    FunctionProto,
    Header,
    InlineField,
    MemberField,
    MemberFunctionProto,
    PadField,
    PlatformNumber,
    Root,
    Type,
)
from .visitor import BromaTreeVisitor

# Defines the explicit public interface for Pylance and users
__all__ = [
    "__version__",
    # enums
    "AccessModifier",
    "FieldVariant",
    "FunctionType",
    "OffsetStatus",
    # exceptions
    "BromaParseError",
    # core
    "Attributes",
    "Class",
    "Field",
    "Function",
    "FunctionBindField",
    "FunctionProto",
    "Header",
    "InlineField",
    "MemberField",
    "MemberFunctionProto",
    "PadField",
    "PlatformNumber",
    "Root",
    "Type",
    # visitor
    "BromaTreeVisitor",
]
