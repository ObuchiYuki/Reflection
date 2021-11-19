//
//  Reflection.swift
//  
//
//  Created by yuki on 2021/11/19.
//

public struct Reflection {
    public let subject: Any.Type
    
    @inlinable public init(_ subject: Any.Type) {
        self.subject = subject
    }

    @inlinable public var name: String {
        let (base, count) = Self._getTypeName(subject, false)
        let name = UnsafeBufferPointer(start: base, count: count)
        return String(decoding: name, as: Unicode.UTF8.self)
    }
    
    @_silgen_name("swift_getTypeName")
    @inlinable static func _getTypeName(_: Any.Type, _: Bool) -> (UnsafePointer<UInt8>, Int)
}
