//
//  File.swift
//  
//
//  Created by yuki on 2021/11/19.
//

extension Reflection {
    public struct Properties {
        public typealias Index = Int
        
        let reflection: Reflection
        
        public var startIndex: Index { 0 }
        public var endIndex: Index { count }
        
        public var count: Int { Self._rawPropertyCount(_in: reflection.subject) }

        public func index(after anotherIndex: Index) -> Index { anotherIndex + 1 }
        
        public func index(_ anotherIndex: Index, offsetBy distance: Int) -> Index { anotherIndex + distance }

        public func index(_ anotherIndex: Index, offsetBy distance: Int, limitedBy limit: Index) -> Index? {
            let resultingIndex = index(anotherIndex, offsetBy: distance)
            return resultingIndex < limit ? resultingIndex : nil
        }

        public subscript(_ index: Index) -> Property {
            Property(Property.Identifier(reflection: self.reflection, index: index))
        }
        
        @_silgen_name("swift_reflectionMirror_recursiveCount")
        private static func _rawPropertyCount(_in type: Any.Type) -> Int
    }
    
    public var properties: Properties { Properties(reflection: self) }
}

extension Reflection {
    public struct Property {
        public struct Identifier {
            let reflection: Reflection
            let index: Int
        }
        
        public let name: String
        public let offset: Int
        public let isStrong: Bool
        public let isMutable: Bool
        public let reflection: Reflection
        public let id: Identifier

        public init(_ id: Identifier) {
            self.id = id
            var configuration: Configuration = (name: nil, nameRelease: nil, isStrong: false, isMutable: false)
            
            let opaqueType = Self.recursiveChildMetadata(id.reflection.subject, id.index, &configuration)
            guard let type = opaqueType else {
                preconditionFailure("execution has reached a routine that is not supposed to be reachable")
            }
            self.reflection = Reflection(type)
            
            let opaqueName = configuration.name.map(String.init(cString:))
            defer { configuration.nameRelease?(configuration.name) }
            guard let name = opaqueName else {
                preconditionFailure("execution has reached a routine that is not supposed to be reachable")
            }
            self.name = name
            self.offset = Self.recursiveChildOffset(id.reflection.subject, id.index)
            self.isStrong = configuration.isStrong
            self.isMutable = configuration.isMutable
        }
        
        private typealias Name = UnsafePointer<CChar>
        private typealias NameRelease = @convention(c) (Name?) -> Void
        private typealias Configuration = (name: Name?, nameRelease: NameRelease?, isStrong: Bool, isMutable: Bool)

        @_silgen_name("swift_reflectionMirror_recursiveChildMetadata")
        private static func recursiveChildMetadata(_: Any.Type, _: Int, _: UnsafeMutablePointer<Configuration>) -> Any.Type?

        @_silgen_name("swift_reflectionMirror_recursiveChildOffset")
        private static func recursiveChildOffset(_: Any.Type, _: Int) -> Int
    }
}

extension Reflection.Property {
    public enum AccessError: Error {
        case wrongInstanceType
        case wrongValueType
        case isNotMutable
    }

    public func getValue<Instance>(in instance: Instance) throws -> Any {
        guard type(of: instance) == id.reflection.subject else {
            throw AccessError.wrongInstanceType
        }
        return try Self.withRawPointer(to: instance) { instanceInteriorPointer in
            func withProperValueType<ProperValue>(_: ProperValue.Type) throws -> ProperValue {
                let valuePointer = (instanceInteriorPointer + offset).bindMemory(to: ProperValue.self, capacity: 1)
                return valuePointer.pointee
            }
            return try _openExistential(reflection.subject, do: withProperValueType)
        }
    }

    public func setValue<Instance, Value>(to value: Value, in instance: inout Instance) throws {
        guard type(of: instance) == id.reflection.subject else {
            throw AccessError.wrongInstanceType
        }
        guard isMutable else {
            throw AccessError.isNotMutable
        }
        return try Self.withRawMutablePointer(to: &instance) { instanceInteriorPointer in
            func withProperValueType<ProperValue>(_: ProperValue.Type) throws {
                guard let value = value as? ProperValue else {
                    throw AccessError.wrongValueType
                }
                let valuePointer = (instanceInteriorPointer + offset).bindMemory(to: ProperValue.self, capacity: 1)
                valuePointer.pointee = value
            }
            return try _openExistential(reflection.subject, do: withProperValueType)
        }
    }

    private static func withRawPointer<Instance, Success>(to instance: Instance, routine: (UnsafeRawPointer) throws -> Success) rethrows -> Success {
        let instanceType = type(of: instance)
        let isIndirectInstance = instanceType is AnyClass
        return try withUnsafePointer(to: instance) { instancePointer in
            let instanceInteriorPointer: UnsafeRawPointer
            if isIndirectInstance {
                return try instancePointer.withMemoryRebound(to: UnsafeRawPointer.self, capacity: 1) { instancePointer in
                    let instanceInteriorPointer = instancePointer.pointee
                    return try routine(instanceInteriorPointer)
                }
            } else {
                instanceInteriorPointer = UnsafeRawPointer(instancePointer)
                return try routine(instanceInteriorPointer)
            }
        }
    }

    private static func withRawMutablePointer<Instance, Success>(to instance: inout Instance, routine: (UnsafeMutableRawPointer) throws -> Success) rethrows -> Success {
        let instanceType = type(of: instance)
        let isIndirectInstance = instanceType is AnyClass
        return try withUnsafeMutablePointer(to: &instance) { instancePointer in
            let instanceInteriorPointer: UnsafeMutableRawPointer
            if isIndirectInstance {
                return try instancePointer.withMemoryRebound(to: UnsafeMutableRawPointer.self, capacity: 1) { instancePointer in
                    let instanceInteriorPointer = instancePointer.pointee
                    return try routine(instanceInteriorPointer)
                }
            } else {
                instanceInteriorPointer = UnsafeMutableRawPointer(instancePointer)
                return try routine(instanceInteriorPointer)
            }
        }
    }
}
