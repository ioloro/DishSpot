//
//  DishSpot+SIMD.swift
//  DishSpot
//
//  Created by John Marc on 11/16/25.
//

import simd

extension simd_float4 {
    var xyz: simd_float3 {
        return simd_float3(x, y, z)
    }
}
