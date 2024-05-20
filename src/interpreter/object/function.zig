const std = @import("std");
const ArrayList = std.ArrayList;

const Ast = @import("../../ast.zig");
const Statement = Ast.Statement;
const Identifier = Ast.Identifier;
const FunctionLiteral = Ast.FunctionLiteral;

const Environment = @import("../environment.zig").Environment;

pub const Function = struct {
    parameters: ArrayList([]const u8),
    body: *Statement,
    environment: *Environment,

    pub fn init(environment: *Environment, function_literal: FunctionLiteral) !Function {
        var parameters = ArrayList([]const u8).init(environment.allocator);
        for (function_literal.parameters.items) |parameter| {
            const name = try environment.allocator.dupe(u8, parameter.name);
            try parameters.append(name);
        }

        return .{
            .parameters = parameters,
            .body = function_literal.body,
            .environment = environment,
        };
    }

    pub fn deinit(self: Function) void {
        for (self.parameters) |parameter| {
            self.environment.allocator.free(parameter);
        }
        self.parameters.deinit();
    }

    pub fn write(self: Function, writer: anytype) !void {
        _ = try writer.write("fn(");
        var first = true;
        for (self.parameters.items) |parameter| {
            if (first) {
                first = false;
            } else {
                _ = try writer.write(", ");
            }
            try writer.print("{s}", .{parameter});
        }
        _ = try writer.write(")");
    }
};
