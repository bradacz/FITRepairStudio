import Foundation

enum FitScalar: Equatable {
    case signed(Int64)
    case unsigned(UInt64)
    case floating(Double)
    case string(String)
    case bytes(Data)
    case invalid

    var integerValue: Int64? {
        switch self {
        case .signed(let value):
            return value
        case .unsigned(let value):
            return value <= UInt64(Int64.max) ? Int64(value) : nil
        default:
            return nil
        }
    }

    var displayString: String {
        switch self {
        case .signed(let value):
            return String(value)
        case .unsigned(let value):
            return String(value)
        case .floating(let value):
            return FitFormatter.number(value)
        case .string(let value):
            return value
        case .bytes(let value):
            return value.map { String(format: "%02x", $0) }.joined()
        case .invalid:
            return ""
        }
    }
}

struct FitHeader {
    var headerSize: Int
    var protocolVersion: UInt8
    var profileVersion: UInt16
    var dataSize: UInt32
    var headerCRC: UInt16?
    var fileCRC: UInt16?
    var expectedSize: Int
    var actualSize: Int
}

struct FitFieldDef {
    var number: UInt8
    var size: Int
    var baseType: UInt8
}

struct FitDefinition {
    var localType: UInt8
    var endian: FitEndian
    var globalNumber: UInt16
    var fields: [FitFieldDef]
    var developerFieldSizes: [Int]
}

struct FitFieldLocation {
    var name: String
    var number: UInt8
    var offset: Int
    var size: Int
    var baseType: UInt8
    var endian: FitEndian

    var canEdit: Bool {
        guard let base = FitBaseType(rawType: baseType) else { return false }
        return size == base.size && base.kind != .bytes
    }
}

struct FitFieldRow: Identifiable, Equatable {
    var id: String { name }
    var name: String
    var raw: FitScalar
    var value: String
    var isEditable: Bool
}

struct FitMessage: Identifiable {
    var id: Int { index }
    var index: Int
    var offset: Int
    var localType: UInt8
    var compressed: Bool
    var globalNumber: UInt16
    var typeName: String
    var rawValues: [String: FitScalar]
    var decodedValues: [String: String]
    var fieldLocations: [String: FitFieldLocation]

    var fields: [FitFieldRow] {
        rawValues.keys.sorted(by: fieldSort).map { name in
            FitFieldRow(
                name: name,
                raw: rawValues[name] ?? .invalid,
                value: decodedValues[name] ?? rawValues[name]?.displayString ?? "",
                isEditable: fieldLocations[name]?.canEdit ?? false
            )
        }
    }

    func value(_ name: String) -> String {
        decodedValues[name] ?? rawValues[name]?.displayString ?? ""
    }

    private func fieldSort(_ lhs: String, _ rhs: String) -> Bool {
        if lhs == "timestamp" { return true }
        if rhs == "timestamp" { return false }
        return lhs.localizedStandardCompare(rhs) == .orderedAscending
    }
}

struct FitRecordRow: Identifiable {
    var id: Int { recordIndex }
    var recordIndex: Int
    var message: FitMessage

    var timestamp: String { message.value("timestamp") }
    var latitude: String { message.value("position_lat") }
    var longitude: String { message.value("position_long") }
    var distance: String { message.value("distance") }
    var speed: String { message.value("speed") }
    var altitude: String {
        let enhanced = message.value("enhanced_altitude")
        return enhanced.isEmpty ? message.value("altitude") : enhanced
    }
    var heartRate: String { message.value("heart_rate") }
    var cadence: String { message.value("cadence") }
    var power: String { message.value("power") }
    var temperature: String { message.value("temperature") }
}

struct FitSummary {
    var fileName: String
    var actualSize: Int
    var expectedSize: Int
    var protocolVersion: UInt8
    var profileVersion: UInt16
    var headerCRCOk: Bool
    var fileCRCOk: Bool
    var parseErrors: [String]
    var messageCounts: [(String, Int)]
    var recordCount: Int
    var sessionCount: Int
    var lapCount: Int
    var activityCount: Int
    var firstRecordTime: String
    var lastRecordTime: String
    var durationSeconds: Int?
    var timestampBackwardsCount: Int
    var badCoordinateCount: Int
    var latitudeRange: String
    var longitudeRange: String

    var warnings: [String] {
        var values: [String] = []
        if actualSize != expectedSize {
            values.append(L10n.tr("warning.size.mismatch"))
        }
        if !fileCRCOk {
            values.append(L10n.tr("warning.file.crc.invalid"))
        }
        if !parseErrors.isEmpty {
            values.append(L10n.tr("warning.parse.errors"))
        }
        if timestampBackwardsCount > 0 {
            values.append(L10n.tr("warning.time.backwards"))
        }
        if badCoordinateCount > 0 {
            values.append(L10n.tr("warning.bad.coordinates"))
        }
        return values
    }
}

struct FitParseResult {
    var header: FitHeader
    var messages: [FitMessage]
    var messageCounts: [String: Int]
    var errors: [String]
}

enum FitEndian {
    case little
    case big
}

enum FitBaseKind {
    case signed
    case unsigned
    case floating
    case string
    case bytes
}

struct FitBaseType {
    var rawType: UInt8
    var name: String
    var size: Int
    var kind: FitBaseKind
    var invalidSigned: Int64?
    var invalidUnsigned: UInt64?

    init(rawType: UInt8, name: String, size: Int, kind: FitBaseKind, invalidSigned: Int64?, invalidUnsigned: UInt64?) {
        self.rawType = rawType
        self.name = name
        self.size = size
        self.kind = kind
        self.invalidSigned = invalidSigned
        self.invalidUnsigned = invalidUnsigned
    }

    static func raw(_ rawType: UInt8) -> UInt8 {
        rawType & 0xFF
    }

    init?(rawType: UInt8) {
        switch rawType {
        case 0x00:
            self.init(rawType: rawType, name: "enum", size: 1, kind: .unsigned, invalidSigned: nil, invalidUnsigned: 0xFF)
        case 0x01:
            self.init(rawType: rawType, name: "sint8", size: 1, kind: .signed, invalidSigned: 0x7F, invalidUnsigned: nil)
        case 0x02:
            self.init(rawType: rawType, name: "uint8", size: 1, kind: .unsigned, invalidSigned: nil, invalidUnsigned: 0xFF)
        case 0x07:
            self.init(rawType: rawType, name: "string", size: 1, kind: .string, invalidSigned: nil, invalidUnsigned: nil)
        case 0x0A:
            self.init(rawType: rawType, name: "uint8z", size: 1, kind: .unsigned, invalidSigned: nil, invalidUnsigned: 0x00)
        case 0x0D:
            self.init(rawType: rawType, name: "byte", size: 1, kind: .bytes, invalidSigned: nil, invalidUnsigned: nil)
        case 0x83:
            self.init(rawType: rawType, name: "sint16", size: 2, kind: .signed, invalidSigned: 0x7FFF, invalidUnsigned: nil)
        case 0x84:
            self.init(rawType: rawType, name: "uint16", size: 2, kind: .unsigned, invalidSigned: nil, invalidUnsigned: 0xFFFF)
        case 0x85:
            self.init(rawType: rawType, name: "sint32", size: 4, kind: .signed, invalidSigned: 0x7FFFFFFF, invalidUnsigned: nil)
        case 0x86:
            self.init(rawType: rawType, name: "uint32", size: 4, kind: .unsigned, invalidSigned: nil, invalidUnsigned: 0xFFFFFFFF)
        case 0x88:
            self.init(rawType: rawType, name: "float32", size: 4, kind: .floating, invalidSigned: nil, invalidUnsigned: nil)
        case 0x89:
            self.init(rawType: rawType, name: "float64", size: 8, kind: .floating, invalidSigned: nil, invalidUnsigned: nil)
        case 0x8B:
            self.init(rawType: rawType, name: "uint16z", size: 2, kind: .unsigned, invalidSigned: nil, invalidUnsigned: 0x0000)
        case 0x8C:
            self.init(rawType: rawType, name: "uint32z", size: 4, kind: .unsigned, invalidSigned: nil, invalidUnsigned: 0x00000000)
        case 0x8E:
            self.init(rawType: rawType, name: "sint64", size: 8, kind: .signed, invalidSigned: 0x7FFFFFFFFFFFFFFF, invalidUnsigned: nil)
        case 0x8F:
            self.init(rawType: rawType, name: "uint64", size: 8, kind: .unsigned, invalidSigned: nil, invalidUnsigned: 0xFFFFFFFFFFFFFFFF)
        case 0x90:
            self.init(rawType: rawType, name: "uint64z", size: 8, kind: .unsigned, invalidSigned: nil, invalidUnsigned: 0x0000000000000000)
        default:
            return nil
        }
    }
}
