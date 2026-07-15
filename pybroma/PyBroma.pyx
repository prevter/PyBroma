# cython: language_level = 3
# distutils: language = c++
# cython: c_string_type=str, c_string_encoding=utf8

from enum import IntFlag, IntEnum
from functools import cached_property

from .platforms import list_platforms, Platform

from libcpp.string cimport string
from libcpp.vector cimport vector
from libcpp.utility cimport pair
from libcpp cimport nullptr
from libc.stdlib cimport free
cimport pybroma.broma as broma
cimport cython


cdef extern from *:
    """
#define DEPACK(x) *x
    """
    broma.PadField DEPACK(broma.PadField* x)
    broma.MemberField DEPACK(broma.MemberField* x)
    broma.InlineField DEPACK(broma.InlineField* x)
    broma.FunctionBindField DEPACK(broma.FunctionBindField* x)
    broma.Class DEPACK(broma.Class* x)


class _PlatformFlags(IntFlag):
    NONE = 0
    Windows = 2
    iOS = 4
    Android32 = 8
    Android64 = 16
    Android = 8 | 16
    MacIntel = 32
    MacArm = 64
    Mac = 32 | 64

cdef list _list_platforms_internal(int links):
    cdef list link_list = []

    if links & _PlatformFlags.Android:   link_list.append("android")
    if links & _PlatformFlags.Android32: link_list.append("android32")
    if links & _PlatformFlags.Android64: link_list.append("android64")
    if links & _PlatformFlags.Mac:       link_list.append("mac")
    if links & _PlatformFlags.MacArm:    link_list.append("m1")
    if links & _PlatformFlags.MacIntel:  link_list.append("imac")
    if links & _PlatformFlags.Windows:   link_list.append("win")
    if links & _PlatformFlags.iOS:       link_list.append("ios")

    return link_list


class FunctionType(IntEnum):
    Normal = 0
    Ctor = 1
    Dtor = 2

class AccessModifier(IntEnum):
    Private = 0
    Protected = 1
    Public = 2


cdef class Attributes:
    cdef:
        broma.Attributes attributes
        list _depends

    def __cinit__(self):
        self._depends = []

    @property
    def docs(self): return <str>self.attributes.docs

    @property
    def links(self):
        return list_platforms(<int>self.attributes.links)

    @property
    def missing(self):
        return list_platforms(<int>self.attributes.missing)

    @property
    def depends(self):
        if not self._depends:
            self._depends = [<str>d for d in self.attributes.depends]
        return self._depends

    @property
    def since(self): return <str>self.attributes.since

    @staticmethod
    cdef Attributes init(broma.Attributes attrs):
        cdef Attributes cls = Attributes()
        cls.attributes = attrs
        return cls


cdef class Type:
    cdef:
        broma.Type type
    
    def __cinit__(self):
        pass

    @property
    def is_struct(self): return self.type.is_struct
    @property
    def name(self): return self.type.name

    def __eq__(self, Type t):
        return broma.TypeEquals(self.type, t)

    @staticmethod
    cdef Type init(broma.Type t) noexcept:
        cdef Type cls = Type()
        cls.type = t
        return cls


cdef class PlatformNumber:
    cdef:
        broma.PlatformNumber binds

    def __cinit__(self):
        pass

    @property
    def imac(self): return self.binds.imac
    @property
    def m1(self): return self.binds.m1
    @property
    def ios(self): return self.binds.ios
    @property
    def win(self): return self.binds.win
    @property
    def android32(self): return self.binds.android32
    @property
    def android64(self): return self.binds.android64

    def platforms_as_dict(self):
        cdef dict d = {}

        if self.binds.imac > 0:
            d["imac"] = hex(self.binds.imac)
        if self.binds.m1 > 0:
            d["m1"] = hex(self.binds.m1)
        if self.binds.ios > 0:
            d["ios"] = hex(self.binds.ios)
        if self.binds.win > 0:
            d["win"] = hex(self.binds.win)
        if self.binds.android32 > 0:
            d["android32"] = hex(self.binds.android32)
        if self.binds.android64 > 0:
            d["android64"] = hex(self.binds.android64)

        return d

    @staticmethod
    cdef PlatformNumber init(broma.PlatformNumber pn) noexcept:
        number = PlatformNumber()
        number.binds = pn
        return number


cdef class FunctionProto:
    cdef:
        broma.FunctionProto fproto
        dict _args

    def __cinit__(self):
        self._args = dict()
        pass

    cdef void _init(self, broma.FunctionProto proto) noexcept:
        cdef vector[pair[broma.Type, string]] args = proto.args
        cdef size_t i
        self.fproto = proto
        self._args = {args[i].second : Type.init(args[i].first) for i in range(args.size())}

    @property
    def attributes(self):
        return Attributes.init(self.fproto.attributes)

    # Alias for attributes
    @property
    def attrs(self): return self.attributes

    @property
    def ret(self): return Type.init(self.fproto.ret)
    @property
    def args(self): return self._args
    @property
    def name(self): return <str>self.fproto.name

    @staticmethod
    cdef FunctionProto init(broma.FunctionProto fp) noexcept:
        cdef FunctionProto _fp = FunctionProto()
        _fp._init(fp)
        return _fp


# we don't need to mirror the C++ inheritence here...
cdef class MemberFunctionProto:
    cdef:
        broma.MemberFunctionProto mfproto
        dict _args

    def __cinit__(self):
        self._args = dict()
        pass

    cdef void _init(self, broma.MemberFunctionProto proto):
        self.mfproto = proto
        self._args = {<str>a.second : Type.init(a.first) for a in proto.args}

    # inherited from FunctionProto
    @property
    def attributes(self):
        return Attributes.init(self.mfproto.attributes)
    @property
    def attrs(self): return self.attributes

    @property
    def ret(self): return Type.init(self.mfproto.ret)
    @property
    def args(self): return self._args
    @property
    def name(self): return <str>self.mfproto.name

    # MemberFunctionProto members
    @property
    def type(self):
        return FunctionType(<int>self.mfproto.type)
    @property
    def access(self):
        return AccessModifier(<int>self.mfproto.access)

    @property
    def is_const(self): return self.mfproto.is_const
    @property
    def is_virtual(self): return self.mfproto.is_virtual
    @property
    def is_callback(self): return self.mfproto.is_callback
    @property
    def is_static(self): return self.mfproto.is_static

    def __eq__(self, MemberFunctionProto mfp):
        return broma.MemberFunctionProtoEquals(self.mfproto, mfp.mfproto)

    @staticmethod
    cdef MemberFunctionProto init(broma.MemberFunctionProto proto) noexcept:
        cdef MemberFunctionProto mfp = MemberFunctionProto()
        mfp._init(proto)
        return mfp


cdef class FunctionBindField:
    cdef broma.FunctionBindField fbf

    def __cinit__(self):
        pass

    @property
    def prototype(self):
        return MemberFunctionProto.init(self.fbf.prototype)
    @property
    def proto(self): return self.prototype

    @property
    def binds(self):
        return PlatformNumber.init(self.fbf.binds)

    @staticmethod
    cdef FunctionBindField init(broma.FunctionBindField fbf) noexcept:
        cdef FunctionBindField cls = FunctionBindField()
        cls.fbf = fbf
        return cls


cdef class MemberField:
    cdef:
        broma.MemberField field

    def __cinit__(self):
        pass

    @property
    def platform(self):
        return list_platforms(<int>self.field.platform)

    @property
    def name(self): return <str>self.field.name

    @property
    def type(self): return Type.init(self.field.type)

    @staticmethod
    cdef MemberField init(broma.MemberField field) noexcept:
        cdef MemberField f = MemberField()
        f.field = field
        return f


cdef class PadField:
    cdef:
        broma.PadField pf

    def __cinit__(self):
        pass

    @property
    def amount(self):
        return PlatformNumber.init(self.pf.amount)

    @staticmethod
    cdef PadField init(broma.PadField pf):
        cdef PadField _pf = PadField()
        _pf.pf = pf
        return _pf


cdef class InlineField:
    cdef broma.InlineField _if
    def __cinit__(self):
        pass

    @property
    def inner(self): return <str>self._if.inner

    @staticmethod
    cdef InlineField init(broma.InlineField _if):
        cdef InlineField cls = InlineField()
        cls._if = _if
        return cls


cdef class Field:
    cdef:
        broma.Field field

    def __cinit__(self):
        pass

    @property
    def id(self): return self.field.field_id
    @property
    def parent(self): return <str>self.field.parent

    def getAsFunctionBindField(self):
        cdef broma.FunctionBindField* x = broma.Field_GetAs_FunctionBindField(&self.field)
        return FunctionBindField.init(DEPACK(x)) if x != nullptr else None

    def getAsMemberField(self):
        cdef broma.MemberField* x = broma.Field_GetAs_MemberField(&self.field)
        return MemberField.init(DEPACK(x)) if x != nullptr else None

    def getAsPadField(self):
        cdef broma.PadField* x = broma.Field_GetAs_PadField(&self.field)
        return PadField.init(DEPACK(x)) if x != nullptr else None

    def getAsInlineField(self):
        cdef broma.InlineField* x = broma.Field_GetAs_InlineField(&self.field)
        return InlineField.init(DEPACK(x)) if x != nullptr else None

    @staticmethod
    cdef Field init(broma.Field field) noexcept:
        cdef Field f = Field()
        f.field = field
        return f


cdef class Function:
    cdef:
        broma.Function func

    def __cinit__(self):
        pass

    @property
    def prototype(self):
        return FunctionProto.init(self.func.prototype)
    @property
    def proto(self): return self.prototype

    @property
    def binds(self):
        return PlatformNumber.init(self.func.binds)

    @staticmethod
    cdef Function init(broma.Function func) noexcept:
        cdef Function fn = Function()
        fn.func = func
        return fn


cdef class Class:
    cdef:
        broma.Class _cls
        list _superclasses
        bint _superclasses_ran

    def __cinit__(self):
        self._superclasses = []
        self._superclasses_ran = False

    @property
    def attributes(self):
        return Attributes.init(self._cls.attributes)
    @property
    def attrs(self): return self.attributes

    @property
    def name(self): return <str>self._cls.name

    @property
    def superclasses(self):
        cdef size_t i
        # Have we made these into a list?
        # The class itself might not have any superclasses
        # so checking if the list is empty wouldn't really work
        if not self._superclasses_ran:
            self._superclasses = [self._cls.superclasses[i] for i in range(self._cls.superclasses.size())]
            self._superclasses_ran = True
        return self._superclasses

    @property
    def fields(self):
        return [Field.init(f) for f in self._cls.fields]

    @property
    def source(self): return self._cls.source

    @staticmethod
    cdef Class init(broma.Class cls):
        cdef Class _cls = Class()
        _cls._cls = cls
        return _cls

    def __eq__(self, object other):
        if isinstance(other, Class):
            return (<str>self._cls.name) == (<str>other._cls.name)
        elif isinstance(other, str):
            return (<str>self._cls.name) == other

        return NotImplemented

    def __hash__(self):
        return hash(self._cls.name)


cdef class Root:
    cdef:
        broma.Root root
        list _functions
        dict _classes

    def __init__(self, str fileName):
        self.root = broma.parse_file(fileName)
        self._functions = []
        self._classes = {}

    @property
    def functions(self):
        if not self._functions:
            self._functions = [Function.init(x) for x in self.root.functions]
        return self._functions

    @property
    def classes(self):
        if not self._classes:
            self._classes = {
                <str>cls.name: Class.init(cls) for cls in self.root.classes
            }
        return self._classes
