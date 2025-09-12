const std = @import("std");

// TypeScript enum Type
const Type = enum {
    Unknown = 0,
    Array,
    False,
    Null,
    Number,
    Pair,
    Object,
    String,
    True,
    Value,
};

// TypeScript interface Token
const Token = struct {
    type: Type,
};

const ArrayToken = struct {
    token: Token,
    values: []ValueToken,
};

const FalseToken = struct {
    token: Token,
    value: bool,
};

const NullToken = struct {
    token: Token,
    value: void,
};

const NumberToken = struct {
    token: Token,
    value: ?f64,
};

const ObjectToken = struct {
    token: Token,
    members: []PairToken,
};

const PairToken = struct {
    token: Token,
    key: ?StringToken,
    value: ?ValueToken,
};

const StringToken = struct {
    token: Token,
    value: ?[]const u8,
};

const TrueToken = struct {
    token: Token,
    value: bool,
};

const ValueToken = union(Type) {
    Array: ArrayToken,
    False: FalseToken,
    Null: NullToken,
    Number: NumberToken,
    Object: ObjectToken,
    String: StringToken,
    True: TrueToken,
};
