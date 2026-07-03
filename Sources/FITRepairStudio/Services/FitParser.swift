import Foundation

enum FitParserError: LocalizedError {
    case tooShort
    case unsupportedHeaderSize(UInt8)
    case missingMagic
    case declaredDataBeyondFile
    case messageIndexNotFound(Int)
    case fieldNotEditable(String)
    case unsupportedBaseType(UInt8)
    case invalidValue(String)

    var errorDescription: String? {
        switch self {
        case .tooShort:
            return L10n.tr("fit.error.too.short")
        case .unsupportedHeaderSize(let size):
            return L10n.tr("fit.error.unsupported.header.size", Int(size))
        case .missingMagic:
            return L10n.tr("fit.error.missing.magic")
        case .declaredDataBeyondFile:
            return L10n.tr("fit.error.declared.data.beyond.file")
        case .messageIndexNotFound(let index):
            return L10n.tr("fit.error.message.index.not.found", index)
        case .fieldNotEditable(let field):
            return L10n.tr("fit.error.field.not.editable", field)
        case .unsupportedBaseType(let baseType):
            return L10n.tr("fit.error.unsupported.base.type", Int(baseType))
        case .invalidValue(let value):
            return L10n.tr("fit.error.invalid.value", value)
        }
    }
}

enum FitParser {
    static let fitEpoch = Date(timeIntervalSince1970: 631_065_600)
    static let semicircleScale = 180.0 / Double(Int64(1) << 31)

    private static let crcTable: [UInt16] = [
        0x0000, 0xCC01, 0xD801, 0x1400,
        0xF001, 0x3C00, 0x2800, 0xE401,
        0xA001, 0x6C00, 0x7800, 0xB401,
        0x5000, 0x9C01, 0x8801, 0x4400
    ]

    private static let globalNames: [UInt16: String] = [
        0: "file_id",
        12: "sport",
        18: "session",
        19: "lap",
        20: "record",
        21: "event",
        22: "device_info",
        23: "workout",
        34: "activity",
        49: "file_creator",
        78: "hrv",
        104: "developer_data_id",
        105: "field_description",
        127: "connectivity",
        132: "software",
        142: "segment_lap",
        206: "field_capabilities",
        207: "file_capabilities",
        208: "mesg_capabilities"
    ]

    private static let fieldNames: [UInt16: [UInt8: String]] = [
        0: [
            0: "type", 1: "manufacturer", 2: "product", 3: "serial_number",
            4: "time_created", 5: "number", 8: "product_name"
        ],
        18: [
            0: "event", 1: "event_type", 2: "start_time",
            3: "start_position_lat", 4: "start_position_long",
            5: "sport", 6: "sub_sport", 7: "total_elapsed_time",
            8: "total_timer_time", 9: "total_distance", 10: "total_cycles",
            11: "total_calories", 13: "avg_speed", 14: "max_speed",
            15: "avg_heart_rate", 16: "max_heart_rate", 20: "first_lap_index",
            21: "num_laps", 253: "timestamp"
        ],
        19: [
            0: "event", 1: "event_type", 2: "start_time",
            3: "start_position_lat", 4: "start_position_long",
            5: "end_position_lat", 6: "end_position_long",
            7: "total_elapsed_time", 8: "total_timer_time",
            9: "total_distance", 10: "total_cycles", 11: "total_calories",
            12: "total_fat_calories", 13: "avg_speed", 14: "max_speed",
            15: "avg_heart_rate", 16: "max_heart_rate", 24: "intensity",
            25: "lap_trigger", 32: "sport", 33: "event_group", 253: "timestamp"
        ],
        20: [
            0: "position_lat", 1: "position_long", 2: "altitude",
            3: "heart_rate", 4: "cadence", 5: "distance",
            6: "speed", 7: "power", 13: "temperature",
            30: "enhanced_speed", 31: "enhanced_altitude", 253: "timestamp"
        ],
        21: [
            0: "event", 1: "event_type", 2: "data16",
            3: "data", 4: "event_group", 253: "timestamp"
        ],
        22: [
            0: "device_index", 1: "device_type", 2: "manufacturer",
            3: "serial_number", 4: "product", 5: "software_version",
            6: "hardware_version", 10: "battery_voltage", 11: "battery_status",
            18: "sensor_position", 19: "descriptor", 20: "ant_transmission_type",
            21: "ant_device_number", 22: "ant_network", 25: "source_type",
            253: "timestamp"
        ],
        34: [
            0: "total_timer_time", 1: "num_sessions", 2: "type",
            3: "event", 4: "event_type", 5: "local_timestamp", 253: "timestamp"
        ],
        49: [
            0: "software_version", 1: "hardware_version"
        ]
    ]

    static func parse(_ data: Data) throws -> FitParseResult {
        let bytes = [UInt8](data)
        let header = try readHeader(bytes)
        let dataStart = header.headerSize
        let dataEnd = dataStart + Int(header.dataSize)
        guard dataEnd <= bytes.count else { throw FitParserError.declaredDataBeyondFile }

        var definitions: [UInt8: FitDefinition] = [:]
        var messages: [FitMessage] = []
        var counts: [String: Int] = [:]
        var errors: [String] = []
        var pos = dataStart
        var index = 0
        var lastTimestamp: Int64?

        while pos < dataEnd {
            let recordOffset = pos
            let headerByte = bytes[pos]
            pos += 1

            let compressed = (headerByte & 0x80) != 0
            let definitionFlag: Bool
            let localType: UInt8
            let timeOffset: UInt8?

            if compressed {
                localType = (headerByte >> 5) & 0x03
                definitionFlag = false
                timeOffset = headerByte & 0x1F
            } else {
                localType = headerByte & 0x0F
                definitionFlag = (headerByte & 0x40) != 0
                timeOffset = nil
            }

            if definitionFlag {
                let hasDeveloperFields = (headerByte & 0x20) != 0
                guard pos + 5 <= dataEnd else {
                    errors.append("\(recordOffset): truncated definition header")
                    break
                }

                let arch = bytes[pos + 1]
                let endian: FitEndian = arch == 1 ? .big : .little
                let globalNumber = readUInt16(bytes, pos + 2, endian)
                let fieldCount = Int(bytes[pos + 4])
                pos += 5

                guard pos + fieldCount * 3 <= dataEnd else {
                    errors.append("\(recordOffset): truncated field definitions")
                    break
                }

                var fields: [FitFieldDef] = []
                for _ in 0..<fieldCount {
                    fields.append(FitFieldDef(number: bytes[pos], size: Int(bytes[pos + 1]), baseType: bytes[pos + 2]))
                    pos += 3
                }

                var developerFieldSizes: [Int] = []
                if hasDeveloperFields {
                    guard pos < dataEnd else {
                        errors.append("\(recordOffset): missing developer field count")
                        break
                    }
                    let developerCount = Int(bytes[pos])
                    pos += 1
                    guard pos + developerCount * 3 <= dataEnd else {
                        errors.append("\(recordOffset): truncated developer fields")
                        break
                    }
                    for _ in 0..<developerCount {
                        developerFieldSizes.append(Int(bytes[pos + 1]))
                        pos += 3
                    }
                }

                definitions[localType] = FitDefinition(
                    localType: localType,
                    endian: endian,
                    globalNumber: globalNumber,
                    fields: fields,
                    developerFieldSizes: developerFieldSizes
                )
                bump("def:\(messageName(globalNumber))", in: &counts)
                index += 1
                continue
            }

            guard let definition = definitions[localType] else {
                errors.append("\(recordOffset): data message without definition local \(localType)")
                break
            }

            let totalSize = definition.fields.reduce(0) { $0 + $1.size } +
                definition.developerFieldSizes.reduce(0, +)
            guard pos + totalSize <= dataEnd else {
                errors.append("\(recordOffset): truncated data message \(messageName(definition.globalNumber))")
                break
            }

            var rawValues: [String: FitScalar] = [:]
            var decodedValues: [String: String] = [:]
            var locations: [String: FitFieldLocation] = [:]

            for field in definition.fields {
                let fieldOffset = pos
                let raw = Array(bytes[pos..<pos + field.size])
                pos += field.size
                let name = fieldName(globalNumber: definition.globalNumber, fieldNumber: field.number)
                let scalar = unpack(raw, field.baseType, definition.endian)
                rawValues[name] = scalar
                decodedValues[name] = decode(globalNumber: definition.globalNumber, fieldNumber: field.number, scalar: scalar)
                locations[name] = FitFieldLocation(
                    name: name,
                    number: field.number,
                    offset: fieldOffset,
                    size: field.size,
                    baseType: field.baseType,
                    endian: definition.endian
                )
            }

            for developerFieldSize in definition.developerFieldSizes {
                pos += developerFieldSize
            }

            if compressed, let previousTimestamp = lastTimestamp, let timeOffset {
                var timestamp = (previousTimestamp & ~0x1F) + Int64(timeOffset)
                if timestamp < previousTimestamp {
                    timestamp += 0x20
                }
                rawValues["timestamp"] = .signed(timestamp)
                decodedValues["timestamp"] = decodeTime(timestamp)
                lastTimestamp = timestamp
            } else if let timestamp = rawValues["timestamp"]?.integerValue {
                lastTimestamp = timestamp
            }

            let typeName = messageName(definition.globalNumber)
            bump(typeName, in: &counts)
            messages.append(FitMessage(
                index: index,
                offset: recordOffset,
                localType: localType,
                compressed: compressed,
                globalNumber: definition.globalNumber,
                typeName: typeName,
                rawValues: rawValues,
                decodedValues: decodedValues,
                fieldLocations: locations
            ))
            index += 1
        }

        return FitParseResult(header: header, messages: messages, messageCounts: counts, errors: errors)
    }

    static func summary(for fileName: String, data: Data, parseResult: FitParseResult) -> FitSummary {
        let header = parseResult.header
        let bytes = [UInt8](data)
        let headerCRCCalc = header.headerSize == 14 ? crc16(Array(bytes[0..<12])) : nil
        let fileCRCCalc = header.expectedSize <= bytes.count ? crc16(Array(bytes[0..<header.expectedSize - 2])) : nil
        let records = parseResult.messages.filter { $0.globalNumber == 20 }
        let sessions = parseResult.messages.filter { $0.globalNumber == 18 }
        let laps = parseResult.messages.filter { $0.globalNumber == 19 }
        let activities = parseResult.messages.filter { $0.globalNumber == 34 }

        let timestamps = records.compactMap { $0.rawValues["timestamp"]?.integerValue }
        var backwards = 0
        var previous: Int64?
        for timestamp in timestamps {
            if let previous, timestamp < previous {
                backwards += 1
            }
            previous = timestamp
        }

        let coordinates: [(Double, Double)] = records.compactMap { message in
            guard
                let lat = message.rawValues["position_lat"]?.integerValue,
                let lon = message.rawValues["position_long"]?.integerValue
            else { return nil }
            return (Double(lat) * semicircleScale, Double(lon) * semicircleScale)
        }
        let badCoordinates = coordinates.filter { lat, lon in
            !(-90...90).contains(lat) || !(-180...180).contains(lon)
        }.count

        let countPairs = parseResult.messageCounts
            .map { ($0.key, $0.value) }
            .sorted { lhs, rhs in
                if lhs.1 == rhs.1 { return lhs.0 < rhs.0 }
                return lhs.1 > rhs.1
            }

        return FitSummary(
            fileName: fileName,
            actualSize: header.actualSize,
            expectedSize: header.expectedSize,
            protocolVersion: header.protocolVersion,
            profileVersion: header.profileVersion,
            headerCRCOk: header.headerCRC == nil || header.headerCRC == headerCRCCalc,
            fileCRCOk: header.fileCRC == fileCRCCalc,
            parseErrors: parseResult.errors,
            messageCounts: countPairs,
            recordCount: records.count,
            sessionCount: sessions.count,
            lapCount: laps.count,
            activityCount: activities.count,
            firstRecordTime: timestamps.first.map(decodeTime) ?? "",
            lastRecordTime: timestamps.last.map(decodeTime) ?? "",
            durationSeconds: timestamps.count >= 2 ? Int(timestamps[timestamps.count - 1] - timestamps[0]) : nil,
            timestampBackwardsCount: backwards,
            badCoordinateCount: badCoordinates,
            latitudeRange: rangeString(coordinates.map(\.0)),
            longitudeRange: rangeString(coordinates.map(\.1))
        )
    }

    static func repairCRC(_ data: Data) throws -> Data {
        var bytes = [UInt8](data)
        let header = try readHeader(bytes)
        guard bytes.count >= header.expectedSize else { throw FitParserError.declaredDataBeyondFile }
        if bytes.count > header.expectedSize {
            bytes = Array(bytes[0..<header.expectedSize])
        }
        if header.headerSize == 14 {
            let crc = crc16(Array(bytes[0..<12]))
            writeUInt16(crc, into: &bytes, at: 12, endian: .little)
        }
        let fileCRC = crc16(Array(bytes[0..<header.expectedSize - 2]))
        writeUInt16(fileCRC, into: &bytes, at: header.expectedSize - 2, endian: .little)
        return Data(bytes)
    }

    static func editField(data: Data, messageIndex: Int, fieldName: String, value: String) throws -> Data {
        var bytes = [UInt8](data)
        let result = try parse(data)
        guard let message = result.messages.first(where: { $0.index == messageIndex }) else {
            throw FitParserError.messageIndexNotFound(messageIndex)
        }
        guard let location = message.fieldLocations[fieldName], location.canEdit else {
            throw FitParserError.fieldNotEditable(fieldName)
        }
        let rawValue = try encode(globalNumber: message.globalNumber, fieldNumber: location.number, value: value)
        let packed = try pack(rawValue, baseType: location.baseType, size: location.size, endian: location.endian)
        bytes.replaceSubrange(location.offset..<location.offset + location.size, with: packed)
        return try repairCRC(Data(bytes))
    }

    static func messageName(_ globalNumber: UInt16) -> String {
        globalNames[globalNumber] ?? "global_\(globalNumber)"
    }

    static func fieldName(globalNumber: UInt16, fieldNumber: UInt8) -> String {
        fieldNames[globalNumber]?[fieldNumber] ?? String(fieldNumber)
    }

    private static func readHeader(_ bytes: [UInt8]) throws -> FitHeader {
        guard bytes.count >= 14 else { throw FitParserError.tooShort }
        let headerSize = Int(bytes[0])
        guard headerSize == 12 || headerSize == 14 else {
            throw FitParserError.unsupportedHeaderSize(bytes[0])
        }
        guard bytes.count >= headerSize + 2 else { throw FitParserError.tooShort }
        guard String(bytes: bytes[8..<12], encoding: .ascii) == ".FIT" else {
            throw FitParserError.missingMagic
        }
        let dataSize = readUInt32(bytes, 4, .little)
        let expectedSize = headerSize + Int(dataSize) + 2
        let headerCRC = headerSize == 14 ? readUInt16(bytes, 12, .little) : nil
        let fileCRC = bytes.count >= expectedSize ? readUInt16(bytes, headerSize + Int(dataSize), .little) : nil
        return FitHeader(
            headerSize: headerSize,
            protocolVersion: bytes[1],
            profileVersion: readUInt16(bytes, 2, .little),
            dataSize: dataSize,
            headerCRC: headerCRC,
            fileCRC: fileCRC,
            expectedSize: expectedSize,
            actualSize: bytes.count
        )
    }

    private static func unpack(_ raw: [UInt8], _ baseType: UInt8, _ endian: FitEndian) -> FitScalar {
        guard let base = FitBaseType(rawType: baseType) else {
            return .bytes(Data(raw))
        }
        if base.kind == .string {
            let prefix = raw.prefix { $0 != 0 }
            return .string(String(bytes: prefix, encoding: .utf8) ?? "")
        }
        if base.kind == .bytes || raw.count != base.size {
            return .bytes(Data(raw))
        }
        switch base.kind {
        case .signed:
            let value = readSigned(raw, endian)
            if base.invalidSigned == value { return .invalid }
            return .signed(value)
        case .unsigned:
            let value = readUnsigned(raw, endian)
            if base.invalidUnsigned == value { return .invalid }
            return .unsigned(value)
        case .floating:
            if base.size == 4 {
                let bits = UInt32(readUnsigned(raw, endian))
                return .floating(Double(Float(bitPattern: bits)))
            }
            let bits = readUnsigned(raw, endian)
            return .floating(Double(bitPattern: bits))
        case .string:
            return .string("")
        case .bytes:
            return .bytes(Data(raw))
        }
    }

    private static func pack(_ scalar: FitScalar, baseType: UInt8, size: Int, endian: FitEndian) throws -> [UInt8] {
        guard let base = FitBaseType(rawType: baseType) else {
            throw FitParserError.unsupportedBaseType(baseType)
        }
        guard size == base.size else {
            throw FitParserError.fieldNotEditable(base.name)
        }
        switch base.kind {
        case .signed:
            let value = scalar.integerValue ?? 0
            return writeSigned(value, size: base.size, endian: endian)
        case .unsigned:
            let value: UInt64
            switch scalar {
            case .unsigned(let unsigned):
                value = unsigned
            case .signed(let signed):
                value = UInt64(max(0, signed))
            case .floating(let double):
                value = UInt64(max(0, double.rounded()))
            case .invalid:
                value = base.invalidUnsigned ?? 0
            default:
                value = 0
            }
            return writeUnsigned(value, size: base.size, endian: endian)
        case .floating:
            let double: Double
            switch scalar {
            case .floating(let value):
                double = value
            case .signed(let value):
                double = Double(value)
            case .unsigned(let value):
                double = Double(value)
            default:
                double = 0
            }
            if base.size == 4 {
                return writeUnsigned(UInt64(Float(double).bitPattern), size: 4, endian: endian)
            }
            return writeUnsigned(double.bitPattern, size: 8, endian: endian)
        case .string, .bytes:
            throw FitParserError.fieldNotEditable(base.name)
        }
    }

    private static func decode(globalNumber: UInt16, fieldNumber: UInt8, scalar: FitScalar) -> String {
        guard case .invalid = scalar else {
            let name = fieldName(globalNumber: globalNumber, fieldNumber: fieldNumber)
            switch name {
            case "timestamp", "start_time", "time_created", "local_timestamp":
                if let value = scalar.integerValue { return decodeTime(value) }
            case "position_lat", "position_long", "start_position_lat", "start_position_long", "end_position_lat", "end_position_long":
                if let value = scalar.integerValue { return FitFormatter.number(Double(value) * semicircleScale) }
            case "altitude", "enhanced_altitude":
                if let value = scalar.integerValue { return FitFormatter.number(Double(value) / 5.0 - 500.0) }
            case "distance", "total_distance":
                if let value = scalar.integerValue { return FitFormatter.number(Double(value) / 100.0) }
            case "speed", "avg_speed", "max_speed", "enhanced_speed":
                if let value = scalar.integerValue { return FitFormatter.number(Double(value) / 1000.0) }
            case "total_elapsed_time", "total_timer_time":
                if let value = scalar.integerValue { return FitFormatter.number(Double(value) / 1000.0) }
            case "software_version":
                if let value = scalar.integerValue { return FitFormatter.number(Double(value) / 100.0) }
            default:
                break
            }
            return scalar.displayString
        }
        return ""
    }

    private static func encode(globalNumber: UInt16, fieldNumber: UInt8, value: String) throws -> FitScalar {
        let text = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = fieldName(globalNumber: globalNumber, fieldNumber: fieldNumber)
        if text.isEmpty {
            return .invalid
        }
        switch name {
        case "timestamp", "start_time", "time_created", "local_timestamp":
            return .signed(try encodeTime(text))
        case "position_lat", "position_long", "start_position_lat", "start_position_long", "end_position_lat", "end_position_long":
            guard let double = Double(text.replacingOccurrences(of: ",", with: ".")) else { throw FitParserError.invalidValue(value) }
            let raw = Int64((double / semicircleScale).rounded())
            return .signed(min(max(raw, Int64(Int32.min)), Int64(Int32.max)))
        case "altitude", "enhanced_altitude":
            return .signed(try scaledInt(text, scale: 5.0, offset: 500.0))
        case "distance", "total_distance":
            return .signed(try scaledInt(text, scale: 100.0, offset: 0.0))
        case "speed", "avg_speed", "max_speed", "enhanced_speed":
            return .signed(try scaledInt(text, scale: 1000.0, offset: 0.0))
        case "total_elapsed_time", "total_timer_time":
            return .signed(try scaledInt(text, scale: 1000.0, offset: 0.0))
        case "software_version":
            return .signed(try scaledInt(text, scale: 100.0, offset: 0.0))
        default:
            if let intValue = Int64(text) {
                return .signed(intValue)
            }
            if let double = Double(text.replacingOccurrences(of: ",", with: ".")) {
                return .floating(double)
            }
            throw FitParserError.invalidValue(value)
        }
    }

    private static func scaledInt(_ text: String, scale: Double, offset: Double) throws -> Int64 {
        guard let double = Double(text.replacingOccurrences(of: ",", with: ".")) else {
            throw FitParserError.invalidValue(text)
        }
        return Int64(((double + offset) * scale).rounded())
    }

    private static func encodeTime(_ text: String) throws -> Int64 {
        if let intValue = Int64(text) {
            return intValue
        }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var date = formatter.date(from: text)
        if date == nil {
            let fallback = ISO8601DateFormatter()
            fallback.formatOptions = [.withInternetDateTime]
            date = fallback.date(from: text)
        }
        guard let date else { throw FitParserError.invalidValue(text) }
        return Int64(date.timeIntervalSince(fitEpoch).rounded())
    }

    private static func decodeTime(_ fitSeconds: Int64) -> String {
        FitFormatter.iso.string(from: fitEpoch.addingTimeInterval(TimeInterval(fitSeconds)))
    }

    private static func rangeString(_ values: [Double]) -> String {
        guard let min = values.min(), let max = values.max() else { return "" }
        return "\(FitFormatter.number(min)) .. \(FitFormatter.number(max))"
    }

    private static func crc16(_ bytes: [UInt8]) -> UInt16 {
        var crc: UInt16 = 0
        for byte in bytes {
            var tmp = crcTable[Int(crc & 0xF)]
            crc = ((crc >> 4) & 0x0FFF) ^ tmp ^ crcTable[Int(byte & 0xF)]
            tmp = crcTable[Int(crc & 0xF)]
            crc = ((crc >> 4) & 0x0FFF) ^ tmp ^ crcTable[Int((byte >> 4) & 0xF)]
        }
        return crc
    }

    private static func bump(_ key: String, in counts: inout [String: Int]) {
        counts[key, default: 0] += 1
    }

    private static func readUInt16(_ bytes: [UInt8], _ offset: Int, _ endian: FitEndian) -> UInt16 {
        let value = UInt16(bytes[offset]) | (UInt16(bytes[offset + 1]) << 8)
        return endian == .little ? value : value.byteSwapped
    }

    private static func readUInt32(_ bytes: [UInt8], _ offset: Int, _ endian: FitEndian) -> UInt32 {
        let value = UInt32(bytes[offset]) |
            (UInt32(bytes[offset + 1]) << 8) |
            (UInt32(bytes[offset + 2]) << 16) |
            (UInt32(bytes[offset + 3]) << 24)
        return endian == .little ? value : value.byteSwapped
    }

    private static func readUnsigned(_ bytes: [UInt8], _ endian: FitEndian) -> UInt64 {
        let ordered = endian == .little ? bytes : bytes.reversed()
        return ordered.enumerated().reduce(UInt64(0)) { result, item in
            result | (UInt64(item.element) << UInt64(item.offset * 8))
        }
    }

    private static func readSigned(_ bytes: [UInt8], _ endian: FitEndian) -> Int64 {
        let unsigned = readUnsigned(bytes, endian)
        let bits = UInt64(bytes.count * 8)
        let signBit = UInt64(1) << (bits - 1)
        if unsigned & signBit == 0 {
            return Int64(unsigned)
        }
        if bits == 64 {
            return Int64(bitPattern: unsigned)
        }
        let mask = UInt64.max << bits
        return Int64(bitPattern: unsigned | mask)
    }

    private static func writeUInt16(_ value: UInt16, into bytes: inout [UInt8], at offset: Int, endian: FitEndian) {
        let raw = endian == .little ? value : value.byteSwapped
        bytes[offset] = UInt8(raw & 0xFF)
        bytes[offset + 1] = UInt8((raw >> 8) & 0xFF)
    }

    private static func writeUnsigned(_ value: UInt64, size: Int, endian: FitEndian) -> [UInt8] {
        var bytes = (0..<size).map { UInt8((value >> UInt64($0 * 8)) & 0xFF) }
        if endian == .big {
            bytes.reverse()
        }
        return bytes
    }

    private static func writeSigned(_ value: Int64, size: Int, endian: FitEndian) -> [UInt8] {
        writeUnsigned(UInt64(bitPattern: value), size: size, endian: endian)
    }
}
