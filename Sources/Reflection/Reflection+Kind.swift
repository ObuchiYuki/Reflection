//
//  File.swift
//  
//
//  Created by yuki on 2021/11/19.
//

extension Reflection {
    public enum Kind {
        case classFromSwift
        case classFromObjectiveC
        case classFromC
        case structure
        case enumeration
        case optional
        case tuple
        case function
        case generic
        case typeForSpecific
        case typeForGeneric
        case opaque
    }
    
    public var kind: Kind {
        let rawKind = Self._getMetadataKind(_of: subject)
        return Kind(rawValue: rawKind) ?? .opaque
    }
    
    @_silgen_name("swift_getMetadataKind")
    private static func _getMetadataKind(_of type: Any.Type) -> UInt
}

extension Reflection.Kind {
    public var isClass: Bool {
        switch self {
        case .classFromSwift, .classFromObjectiveC, .classFromC: return true
        default: return false
        }
    }
    public var isGeneric: Bool {
        switch self {
        case .generic, .typeForGeneric: return true
        default: return false
        }
    }
    public var isType: Bool {
        switch self {
        case .typeForSpecific, .typeForGeneric: return true
        default: return false
        }
    }
    public var isNominal: Bool {
        switch self {
        case .classFromSwift, .classFromObjectiveC, .classFromC, .structure, .enumeration, .optional: return true
        default: return false
        }
    }

    init?(rawValue: UInt) {
        let intrinsic = Intrinsic(rawValue: rawValue)
        switch intrinsic {
            case .classFromSwift:       self = .classFromSwift
            case .classFromObjectiveC:  self = .classFromObjectiveC
            case .classFromC:           self = .classFromC
            case .structure:            self = .structure
            case .enumeration:          self = .enumeration
            case .optional:             self = .optional
            case .tuple:                self = .tuple
            case .function:             self = .function
            case .generic:              self = .generic
            case .typeOnSpecific:       self = .typeForSpecific
            case .typeOnGeneric:        self = .typeForGeneric
            case .opaque:               self = .opaque
            default:                    return nil
        }
    }

    fileprivate struct Intrinsic: OptionSet {
        let rawValue: UInt
        
        static let traitNotPublic: Self = .init(rawValue: 0x100)
        static let traitNotOnHeap: Self = .init(rawValue: 0x200)
        static let traitNotAType: Self = .init(rawValue: 0x400)

        static let classFromSwift: Self = [.init(rawValue: 0)]
        static let structure: Self = [.init(rawValue: 0), traitNotOnHeap]
        static let enumeration: Self = [.init(rawValue: 1), traitNotOnHeap]
        static let optional: Self = [.init(rawValue: 2), traitNotOnHeap]
        static let classFromC: Self = [.init(rawValue: 3), traitNotOnHeap]
        static let opaque: Self = [.init(rawValue: 0), traitNotPublic, traitNotOnHeap]
        static let tuple: Self = [.init(rawValue: 1), traitNotPublic, traitNotOnHeap]
        static let function: Self = [.init(rawValue: 2), traitNotPublic, traitNotOnHeap]
        static let generic: Self = [.init(rawValue: 3), traitNotPublic, traitNotOnHeap]
        static let typeOnSpecific: Self = [.init(rawValue: 4), traitNotPublic, traitNotOnHeap]
        static let classFromObjectiveC: Self = [.init(rawValue: 5), traitNotPublic, traitNotOnHeap]
        static let typeOnGeneric: Self = [.init(rawValue: 6), traitNotPublic, traitNotOnHeap]
        static let specificHeapLocalVariable: Self = [.init(rawValue: 0), traitNotAType]
        static let genericHeapLocalVariable: Self = [.init(rawValue: 0), traitNotPublic, traitNotAType]
        static let errorObject: Self = [.init(rawValue: 1), traitNotPublic, traitNotAType]
        static let task: Self = [.init(rawValue: 2), traitNotPublic, traitNotAType]
        static let job: Self = [.init(rawValue: 3), traitNotPublic, traitNotAType]
    }
}
