try:
    # Read the auto-generated file if installed from wheel
    from ._version import __version__
except ImportError:
    try:
        # Fallback for local dev environments
        import importlib.metadata
        __version__ = importlib.metadata.version("pybroma")
    except Exception:
        __version__ = "0.3.1"

from .PyBroma import (
    AccessModifier,
    Attributes,
    Class,
    Field,
    Header,
    Function,
    FunctionBindField,
    FunctionProto,
    FunctionType,
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
    "AccessModifier",
    "Attributes",
    "Class",
    "Header",
    "Field",
    "Function",
    "FunctionBindField",
    "FunctionProto",
    "FunctionType",
    "InlineField",
    "MemberField",
    "MemberFunctionProto",
    "PadField",
    "PlatformNumber",
    "Root",
    "Type",
    "BromaTreeVisitor",
]
