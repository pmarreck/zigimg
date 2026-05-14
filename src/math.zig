const std = @import("std");

// Using HLSL nomenclature for the vector and matrix types
pub const float2 = @Vector(2, f32);
pub const float3 = @Vector(3, f32);
pub const float4 = @Vector(4, f32);

pub const float2x2 = Matrix([2]float2);
pub const float3x3 = Matrix([3]float3);
pub const float4x4 = Matrix([4]float4);

pub fn Matrix(comptime T: type) type {
    return struct {
        matrix: T,

        const ComponentSize = @typeInfo(T).array.len;
        const VectorType = @Vector(ComponentSize, f32);
        const ArrayType = [ComponentSize]f32;
        const Self = @This();

        // 0.16: runtime indexing into @Vector is not allowed — coerce to array first.
        inline fn vget(v: VectorType, idx: usize) f32 {
            const arr: ArrayType = v;
            return arr[idx];
        }

        inline fn vset(v: *VectorType, idx: usize, value: f32) void {
            var arr: ArrayType = v.*;
            arr[idx] = value;
            v.* = arr;
        }

        pub fn determinant(self: Self) f32 {
            if (ComponentSize == 2) {
                return self.matrix[0][0] * self.matrix[1][1] - self.matrix[0][1] * self.matrix[1][0];
            } else {
                var temp = self;

                // To find the determinant, use a Gaussian elimination to transform the temp matrix into the row echelon form
                for (0..(ComponentSize - 1)) |row| {
                    for ((row + 1)..ComponentSize) |next_row| {
                        const factor = vget(temp.matrix[next_row], row) / vget(temp.matrix[row], row);

                        for (0..ComponentSize) |column| {
                            const new_val = vget(temp.matrix[next_row], column) - factor * vget(temp.matrix[row], column);
                            vset(&temp.matrix[next_row], column, new_val);
                        }
                    }
                }

                // Once the temp matrix is in row echelon form, multiply the diagonal to find the determinant
                var result: f32 = temp.matrix[0][0];

                for (1..ComponentSize) |diagonal| {
                    result *= vget(temp.matrix[diagonal], diagonal);
                }

                return result;
            }
        }

        pub fn fromArray(array: [ComponentSize * ComponentSize]f32) Self {
            var result: Self = undefined;

            for (0..ComponentSize) |row| {
                const stride = row * ComponentSize;
                for (0..ComponentSize) |column| {
                    vset(&result.matrix[row], column, array[stride + column]);
                }
            }

            return result;
        }

        pub fn identity() Self {
            var result: Self = std.mem.zeroes(Self);

            inline for (0..ComponentSize) |diagonal| {
                result.matrix[diagonal][diagonal] = 1;
            }

            return result;
        }

        pub fn inverse(self: Self) Self {
            var temp = self;
            var result: Self = identity();

            for (0..ComponentSize) |row| {
                // Transform the pivot to 1 by multiplying the row by its inverse
                const inverse_pivot = 1.0 / vget(temp.matrix[row], row);

                for (0..ComponentSize) |column| {
                    vset(&temp.matrix[row], column, vget(temp.matrix[row], column) * inverse_pivot);
                    vset(&result.matrix[row], column, vget(result.matrix[row], column) * inverse_pivot);
                }

                // Then do Gaussian elimination from current row to bottom
                for ((row + 1)..ComponentSize) |next_row| {
                    const factor = vget(temp.matrix[next_row], row) / vget(temp.matrix[row], row);

                    for (0..ComponentSize) |column| {
                        const new_temp = vget(temp.matrix[next_row], column) - factor * vget(temp.matrix[row], column);
                        vset(&temp.matrix[next_row], column, new_temp);
                        const new_result = vget(result.matrix[next_row], column) - factor * vget(result.matrix[row], column);
                        vset(&result.matrix[next_row], column, new_result);
                    }
                }
            }

            // Then do a Gaussian elimination bottom-up to transform the temp matrix into an identity matrix.
            // The result will be the inverse of the matrix
            var row: usize = ComponentSize -% 1;
            while (row >= 1 and row < ComponentSize) : (row -%= 1) {
                var previous_row = row -% 1;

                while (previous_row >= 0 and previous_row < ComponentSize) : (previous_row -%= 1) {
                    const factor = vget(temp.matrix[previous_row], row) / vget(temp.matrix[row], row);

                    for (0..ComponentSize) |column| {
                        const new_temp = vget(temp.matrix[previous_row], column) - factor * vget(temp.matrix[row], column);
                        vset(&temp.matrix[previous_row], column, new_temp);
                        const new_result = vget(result.matrix[previous_row], column) - factor * vget(result.matrix[row], column);
                        vset(&result.matrix[previous_row], column, new_result);
                    }
                }
            }

            return result;
        }

        pub fn mulVector(self: Self, vector: VectorType) VectorType {
            var result: VectorType = std.mem.zeroes(VectorType);

            inline for (0..ComponentSize) |row| {
                result[row] = @reduce(.Add, self.matrix[row] * vector);
            }

            return result;
        }

        pub fn mul(self: Self, right: Self) Self {
            var result = std.mem.zeroes(Self);

            const transposed_right = right.transpose();

            for (0..ComponentSize) |row| {
                for (0..ComponentSize) |column| {
                    vset(&result.matrix[row], column, @reduce(.Add, self.matrix[row] * transposed_right.matrix[column]));
                }
            }

            return result;
        }

        pub fn transpose(self: Self) Self {
            var result = std.mem.zeroes(Self);

            for (0..ComponentSize) |row| {
                for (0..ComponentSize) |column| {
                    vset(&result.matrix[row], column, vget(self.matrix[column], row));
                }
            }

            return result;
        }
    };
}

pub fn clamp2(value: float2, min: f32, max: f32) float2 {
    const all_min: float2 = @splat(min);
    const all_max: float2 = @splat(max);

    return @min(@max(value, all_min), all_max);
}

pub fn clamp3(value: float3, min: f32, max: f32) float3 {
    const all_min: float3 = @splat(min);
    const all_max: float3 = @splat(max);

    return @min(@max(value, all_min), all_max);
}

pub fn clamp4(value: float4, min: f32, max: f32) float4 {
    const all_min: float4 = @splat(min);
    const all_max: float4 = @splat(max);

    return @min(@max(value, all_min), all_max);
}
