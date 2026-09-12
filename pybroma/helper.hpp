#ifndef __HELPER_HPP__
#define __HELPER_HPP__

#include <broma.hpp>
#include <ast.hpp>
#include <vector>
#include <string>

namespace pybroma {
    enum class OffsetStatus {
        Unbound,
        Bound,
        Inlined
    };

    enum class FieldVariant {
        Inline = 0,
        FunctionBind = 1,
        Pad = 2,
        Member = 3,
    };

    // helpers to sidestep taking geode::Result directly through the by-reference Root 'out' parameter
    inline bool parse_file_to_root(std::filesystem::path const& fname, broma::Root& out, broma::ParseError& err) {
        auto result = broma::parse_file(fname);

        if (result.isErr()) {
            err = std::move(result.unwrapErr());
            return false;
        }

        out = std::move(result.unwrap());
        return true;
    }

    inline bool parse_string_to_root(
        std::string_view source,
        std::filesystem::path const& include_base,
        std::string const& source_name,
        broma::Root& out,
        broma::ParseError& err
    ) {
        auto result = broma::parse_string(source, include_base, source_name);

        if (result.isErr()) {
            err = std::move(result.unwrapErr());
            return false;
        }

        out = std::move(result.unwrap());
        return true;
    }

    inline bool platform_has(broma::Platform p, std::string const& plat)
    {
        return (p & broma::str_to_platform(plat)) != broma::Platform::None;
    }

    inline ptrdiff_t platform_number_for(broma::PlatformNumber const& pn, std::string const& plat)
    {
        if (plat == "win")       return pn.win;
        if (plat == "android32") return pn.android32;
        if (plat == "android64") return pn.android64;
        if (plat == "imac")      return pn.imac;
        if (plat == "m1")        return pn.m1;
        if (plat == "ios")       return pn.ios;
        return -1;
    }

    inline OffsetStatus platform_offset_status(broma::PlatformNumber const& pn, std::string const& plat) {
        ptrdiff_t v = platform_number_for(pn, plat);
        if (v == -2) return OffsetStatus::Inlined;
        if (v == -1) return OffsetStatus::Unbound;
        return OffsetStatus::Bound;
    }

    inline std::vector<std::string> list_platforms(broma::Platform p) {
        using broma::Platform;
        std::vector<std::string> out;

        if ((p & Platform::Android) == Platform::Android)   out.push_back("android");
        if ((p & Platform::Android32) != Platform::None)    out.push_back("android32");
        if ((p & Platform::Android64) != Platform::None)    out.push_back("android64");

        if ((p & Platform::Mac) == Platform::Mac)       out.push_back("mac");
        if ((p & Platform::MacIntel) != Platform::None) out.push_back("imac");
        if ((p & Platform::MacArm) != Platform::None)   out.push_back("m1");

        if ((p & Platform::Windows) != Platform::None)  out.push_back("win");
        if ((p & Platform::iOS) != Platform::None)      out.push_back("ios");

        return out;
    }

    // stole from https://github.com/geode-sdk/geode/blob/main/loader/include/Geode/utils/general.hpp
    template<class... Ts> struct makeVisitor : Ts... { using Ts::operator()...; };
    template<class... Ts> makeVisitor(Ts...) -> makeVisitor<Ts...>;

    inline FieldVariant Field_GetVariant(broma::Field const* f) {
        // based on ast.hpp's Field.inner
        return std::visit(makeVisitor {
            [](broma::InlineField const&)       { return FieldVariant::Inline; },
            [](broma::FunctionBindField const&) { return FieldVariant::FunctionBind; },
            [](broma::PadField const&)          { return FieldVariant::Pad; },
            [](broma::MemberField const&)       { return FieldVariant::Member; },
        }, f->inner);
    }

    /* Used as primary helpers around Field's variant and other Types since variants
    are not supported by cython yet as far as I am aware... */

    /* These help to provide compatibility to python */

    inline broma::InlineField *Field_GetAs_InlineField(broma::Field *f)
    {
        broma::InlineField *x;
        if ((x = std::get_if<broma::InlineField>(&f->inner)))
        {
            return x;
        };
        return nullptr;
    }

    inline broma::FunctionBindField *Field_GetAs_FunctionBindField(broma::Field *f)
    {
        broma::FunctionBindField *x;
        if ((x = std::get_if<broma::FunctionBindField>(&f->inner)))
        {
            return x;
        };
        return nullptr;
    }

    inline broma::PadField *Field_GetAs_PadField(broma::Field *f)
    {
        broma::PadField *x;
        if ((x = std::get_if<broma::PadField>(&f->inner)))
        {
            return x;
        };
        return nullptr;
    }

    inline broma::MemberField *Field_GetAs_MemberField(broma::Field *f)
    {
        broma::MemberField *x;
        if ((x = std::get_if<broma::MemberField>(&f->inner)))
        {
            return x;
        };
        return nullptr;
    }

    inline bool MemberFunctionProtoEquals(broma::MemberFunctionProto const &a, broma::MemberFunctionProto const &b)
    {
        return a == b;
    }

    inline bool FunctionProtoEquals(broma::FunctionProto const &a, broma::FunctionProto const &b)
    {
        return a == b;
    }

    inline bool TypeEquals(broma::Type const &a, broma::Type const &b)
    {
        return a == b;
    }

    inline bool ClassEqualsTo(broma::Class const &a, broma::Class const &b)
    {
        return a.name == b.name;
    }

    inline bool ClassEqualsToName(broma::Class const &a, std::string const &b)
    {
        return a.name == b;
    }

    inline broma::MemberFunctionProto *FieldGetFn(broma::Field *field)
    {
        return field->get_fn();
    }
}

#endif // __HELPER_HPP__
