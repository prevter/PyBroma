# cython: language_level = 3
# distutils: language = c++
# cython: c_string_type=str, c_string_encoding=utf8

from enum import IntEnum
from functools import cached_property

from libcpp.string cimport string
from libcpp.vector cimport vector
from libcpp.utility cimport pair
from libcpp cimport nullptr
cimport pybroma.broma as broma


cdef extern from *:
    """
#define DEPACK(x) *x
    """
    broma.PadField DEPACK(broma.PadField* x)
    broma.MemberField DEPACK(broma.MemberField* x)
    broma.InlineField DEPACK(broma.InlineField* x)
    broma.FunctionBindField DEPACK(broma.FunctionBindField* x)


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
        return [<str>s for s in broma.list_platforms(self.attributes.links)]

    @property
    def missing(self):
        return [<str>s for s in broma.list_platforms(self.attributes.missing)]

    @property
    def depends(self):
        if not self._depends:
            self._depends = [<str>d for d in self.attributes.depends]
        return self._depends

    @property
    def since(self): return <str>self.attributes.since

    @staticmethod
    cdef Attributes init(broma.Attributes attrs):
        cdef Attributes _attr = Attributes()
        _attr.attributes = attrs
        return _attr


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
        cdef Type _type = Type()
        _type.type = t
        return _type


cdef class PlatformNumber:
    cdef:
        broma.PlatformNumber binds

    def __cinit__(self):
        pass

    @property
    def win(self): return self.binds.win
    @property
    def android32(self): return self.binds.android32
    @property
    def android64(self): return self.binds.android64
    @property
    def imac(self): return self.binds.imac
    @property
    def m1(self): return self.binds.m1
    @property
    def ios(self): return self.binds.ios

    def for_platform(self, str plat):
        cdef ptrdiff_t b = broma.platform_number_for(self.binds, plat)
        return b if b >= 0 else None

    def platforms_as_dict(self):
        cdef list plats = [
            "win", "android32", "android64",
            "imac", "m1", "ios"
        ]
        cdef dict d = {}

        for plat in plats:
            bind = self.for_platform(plat)
            if bind is not None:
                d[plat] = hex(bind)

        return d

    def status_for(self, str plat):
        return OffsetStatus(<int>broma.platform_offset_status(self.binds, plat))

    @staticmethod
    cdef PlatformNumber init(broma.PlatformNumber pnum) noexcept:
        cdef PlatformNumber _pn = PlatformNumber()
        _pn.binds = pnum
        return _pn


cdef class FunctionProto:
    cdef:
        broma.FunctionProto fproto
        dict _args

    def __cinit__(self):
        self._args = dict()
        pass

    cdef void _init(self, broma.FunctionProto proto) noexcept:
        self.fproto = proto
        self._args = [(a.second, Type.init(a.first)) for a in proto.args]

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
        self._args = [(a.second, Type.init(a.first)) for a in proto.args]

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
        cdef MemberFunctionProto _mfp = MemberFunctionProto()
        _mfp._init(proto)
        return _mfp


cdef class FunctionBindField:
    cdef broma.FunctionBindField fbfield

    def __cinit__(self):
        pass

    @property
    def prototype(self):
        return MemberFunctionProto.init(self.fbfield.prototype)
    @property
    def proto(self): return self.prototype

    @property
    def binds(self):
        return PlatformNumber.init(self.fbfield.binds)

    @staticmethod
    cdef FunctionBindField init(broma.FunctionBindField fbf) noexcept:
        cdef FunctionBindField _fbf = FunctionBindField()
        _fbf.fbfield = fbf
        return _fbf


cdef class MemberField:
    cdef:
        broma.MemberField mfield

    def __cinit__(self):
        pass

    @property
    def platform(self):
        return [<str>s for s in broma.list_platforms(self.mfield.platform)]

    @property
    def name(self): return <str>self.mfield.name

    @property
    def type(self): return Type.init(self.mfield.type)

    @staticmethod
    cdef MemberField init(broma.MemberField mfld) noexcept:
        cdef MemberField _mf = MemberField()
        _mf.mfield = mfld
        return _mf


cdef class PadField:
    cdef:
        broma.PadField pfield

    def __cinit__(self):
        pass

    @property
    def amount(self):
        return PlatformNumber.init(self.pfield.amount)

    @staticmethod
    cdef PadField init(broma.PadField pfld):
        cdef PadField _pf = PadField()
        _pf.pfield = pfld
        return _pf


cdef class InlineField:
    cdef broma.InlineField ifield
    def __cinit__(self):
        pass

    @property
    def inner(self): return <str>self.ifield.inner

    @staticmethod
    cdef InlineField init(broma.InlineField ifld):
        cdef InlineField _if = InlineField()
        _if.ifield = ifld
        return _if


cdef class Field:
    cdef:
        broma.Field field

    def __cinit__(self):
        pass

    @property
    def id(self): return self.field.field_id
    @property
    def parent(self): return <str>self.field.parent
    @property
    def line(self): return self.field.line

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

    def for_platform(self, str plat):
        fb = self.getAsFunctionBindField()
        if fb is not None:
            return fb if plat not in fb.proto.attrs.missing else None

        mf = self.getAsMemberField()
        if mf is not None:
            return mf if plat in mf.platform else None

        pf = self.getAsPadField()
        if pf is not None:
            return pf if pf.amount.for_platform(plat) is not None else None

        inf = self.getAsInlineField()
        if inf is not None:
            # inline bodies are platform-agnostic by construction
            return inf

        return None

    @staticmethod
    cdef Field init(broma.Field fld) noexcept:
        cdef Field _f = Field()
        _f.field = fld
        return _f


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

    @property
    def line(self): return self.func.line

    @staticmethod
    cdef Function init(broma.Function fnc) noexcept:
        cdef Function _fn = Function()
        _fn.func = fnc
        return _fn


cdef class Header:
    cdef:
        broma.Header header

    def __cinit__(self):
        pass

    @property
    def name(self): return <str>self.header.name

    @property
    def platform(self):
        return [<str>s for s in broma.list_platforms(self.header.platform)]

    @staticmethod
    cdef Header init(broma.Header hdr) noexcept:
        cdef Header _h = Header()
        _h.header = hdr
        return _h


cdef class Class:
    cdef:
        broma.Class bclass
        list _superclasses
        bint _superclasses_ran
        list _fields

    def __cinit__(self):
        self._superclasses = []
        self._superclasses_ran = False
        self._fields = []

    @property
    def attributes(self):
        return Attributes.init(self.bclass.attributes)
    @property
    def attrs(self): return self.attributes

    @property
    def name(self): return <str>self.bclass.name

    @property
    def superclasses(self):
        cdef size_t i
        cdef string sclass

        # Have we made these into a list?
        # The class itself might not have any superclasses
        # so checking if the list is empty wouldn't really work
        if not self._superclasses_ran:
            for i in range(self.bclass.superclasses.size()):
                sclass = self.bclass.superclasses[i]
                self._superclasses.append(<str>sclass)
            self._superclasses_ran = True
        return self._superclasses

    @property
    def fields(self):
        if not self._fields:
            self._fields = [Field.init(f) for f in self.bclass.fields]
        return self._fields

    @property
    def source(self): return self.bclass.source
    @property
    def line(self): return self.bclass.line

    @staticmethod
    cdef Class init(broma.Class cls):
        cdef Class _cls = Class()
        _cls.bclass = cls
        return _cls

    def __eq__(self, object other):
        if isinstance(other, Class):
            return broma.ClassEqualsTo(self.bclass, other.bclass)
        elif isinstance(other, str):
            return broma.ClassEqualsTo(self.bclass, other)

        return NotImplemented

    def __hash__(self):
        return hash(self.bclass.name)


cdef class Root:
    cdef:
        broma.Root root
        list _functions
        list _classes
        list _headers
        dict _optimized_class_dict

    def __init__(self, str fileName):
        self.root = broma.parse_file(fileName)
        self._functions = []
        # this is better than forwarding to the
        # Root::operator[] as it's more optimized
        self._optimized_class_dict = {
            <str>cls.name: Class.init(cls) for cls in self.root.classes
        }

        self._classes = list(self._optimized_class_dict.values())

    @property
    def classes(self): return self._classes

    @property
    def functions(self):
        if not self._functions:
            self._functions = [Function.init(x) for x in self.root.functions]
        return self._functions

    @property
    def headers(self):
        if not self._headers:
            self._headers = [Header.init(x) for x in self.root.headers]
        return self._headers

    def __getitem__(self, str _class_name_):
        return self._optimized_class_dict[_class_name_]
