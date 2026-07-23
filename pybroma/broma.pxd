# cython: language_level = 3
# distutils: language = c++

from libcpp.string cimport string
from libcpp.vector cimport vector
from libcpp.utility cimport pair


ctypedef long long ptrdiff_t

cdef extern from "ast.hpp" namespace "broma" nogil:
    
    enum class Platform:
        pass

    Platform str_to_platform(const string& str)

    struct Attributes:
        string docs # Any docstring pulled from a `[[docs(...)]]` attribute.
        Platform links # All the platforms that link the class or function
        Platform missing # All the platforms that are missing the class or function
        vector[string] depends # List of classes that this class or function depends on
        string since # The Geode SDK version that this class or function was introduced in.

    # offsets for each platform
    struct PlatformNumber:
        ptrdiff_t win
        ptrdiff_t android32
        ptrdiff_t android64
        ptrdiff_t imac
        ptrdiff_t m1
        ptrdiff_t ios

    struct Type:
        string name
        bint is_struct

    cdef cppclass FunctionProto:
        Attributes attributes
        Type ret
        vector[pair[Type, string]] args
        string name

    enum class FunctionType:
        Normal = 0
        Ctor = 1 # A constructor.
        Dtor = 2 # A destructor.

    enum class AccessModifier:
        Private = 0
        Protected = 1
        Public = 2

    cdef cppclass MemberFunctionProto(FunctionProto):
        FunctionType type
        AccessModifier access
        bint is_const
        bint is_virtual
        bint is_callback
        bint is_static

    # @brief A function that is bound to an offset.
    struct FunctionBindField:
        MemberFunctionProto prototype
        PlatformNumber binds # The offsets, separated per platform.

    # @brief A class's member variables.
    struct MemberField:
        Platform platform # For platform-specific members, all platforms this member is defined on 
        string name # The name of the field.
        Type type # The type of the field.

    # @brief Any class padding.
    struct PadField:
        PlatformNumber amount # The amount of padding, separated per platform.

    # @brief A function body that should go in a header file (.hpp).
    struct InlineField:
        string inner # The body of the function as a raw string.

    struct Field:
        size_t field_id # The index of the field. This starts from 0 and counts up across all classes.
        string parent # The name of the parent class.
        # NOTE: I wrote a special function for handling "inner" in helper.cpp since Cython can't handle variants yet
        size_t line

    struct Function:
        FunctionProto prototype # The free function's signature.
        PlatformNumber binds # The offsets of free function, separated per platform.
        size_t line

    struct Header:
        string name
        Platform platform

    struct Class:
        Attributes attributes
        string name # The name of the class.
        vector[string] superclasses # Parent classes that the current class inherits.
        vector[Field] fields # All the fields parsed in the class.
        string source # The Broma file this class was sourced from.
        size_t line

    struct Root:
        vector[Class] classes
        vector[Function] functions
        vector[Header] headers


cdef extern from "helper.hpp" nogil:
    enum class OffsetStatus:
        Unbound = 0
        Bound = 1
        Inlined = 2

    OffsetStatus platform_offset_status(PlatformNumber pn, string plat)
    bint platform_has(Platform p, string plat)
    ptrdiff_t platform_number_for(PlatformNumber pn, string plat)
    vector[string] list_platforms(Platform p)

    InlineField* Field_GetAs_InlineField(Field* f)
    FunctionBindField* Field_GetAs_FunctionBindField(Field* f)
    PadField* Field_GetAs_PadField(Field* f)
    MemberField* Field_GetAs_MemberField(Field* f)
    bint MemberFunctionProtoEquals(MemberFunctionProto a, MemberFunctionProto b)
    bint FunctionProtoEquals(FunctionProto a, FunctionProto b)
    bint TypeEquals(Type a, Type b)
    bint ClassEqualsTo(Class a, Class b)
    bint ClassEqualsToName(Class a, string b)
    MemberFunctionProto* FieldGetFn(Field* field)


cdef extern from "broma.hpp" namespace "broma" nogil:
    Root parse_file(string fname)
