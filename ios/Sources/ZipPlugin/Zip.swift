import Foundation
import SSZipArchive

@objc public class Zip: NSObject {

    // --------------------------------------------------
    // MARK: - ZIP COMPRESSION
    // --------------------------------------------------
    public func compress(source: String, destination: String, password: String?) throws -> [String: Any] {
        let sourceURL = getURL(path: source)
        let destURL = getURL(path: destination)
        
        let fm = FileManager.default
        var isDir: ObjCBool = false
        
        if !fm.fileExists(atPath: sourceURL.path, isDirectory: &isDir) {
            throw NSError(domain: "ZipPlugin", code: 404,
                          userInfo: [NSLocalizedDescriptionKey: "Source not found at: \(sourceURL.path)"])
        }

        let destDir = destURL.deletingLastPathComponent()
        if !fm.fileExists(atPath: destDir.path) {
            try fm.createDirectory(at: destDir, withIntermediateDirectories: true)
        }

        let success: Bool
        if isDir.boolValue {
            success = SSZipArchive.createZipFile(atPath: destURL.path,
                                                 withContentsOfDirectory: sourceURL.path,
                                                 keepParentDirectory: false,
                                                 withPassword: password)
        } else {
            success = SSZipArchive.createZipFile(atPath: destURL.path,
                                                 withFilesAtPaths: [sourceURL.path],
                                                 withPassword: password)
        }

        if !success {
            throw NSError(domain: "ZipPlugin", code: 500,
                          userInfo: [NSLocalizedDescriptionKey: "Failed creating ZIP"])
        }

        let attr = try fm.attributesOfItem(atPath: destURL.path)
        let size = attr[.size] as? Int64 ?? 0

        return [
            "path": destURL.path,
            "size": size,
            "fileCount": countFiles(at: sourceURL),
            "type": "zip"
        ]
    }

    // --------------------------------------------------
    // MARK: - ZIP / TAR EXTRACTION
    // --------------------------------------------------
    public func extract(source: String, destination: String, password: String?, overwrite: Bool) throws -> [String: Any] {

        let sourceURL = getURL(path: source)
        let destURL = getURL(path: destination)
        let fm = FileManager.default

        if !fm.fileExists(atPath: sourceURL.path) {
            throw NSError(domain: "ZipPlugin", code: 404,
                          userInfo: [NSLocalizedDescriptionKey: "Source file does not exist at: \(sourceURL.path)"])
        }

        if !fm.fileExists(atPath: destURL.path) {
            try fm.createDirectory(at: destURL, withIntermediateDirectories: true)
        }

        let ext = sourceURL.pathExtension.lowercased()
        let filename = sourceURL.lastPathComponent.lowercased()

        // TAR / TGZ / TBZ2 / TXZ / ZSTD
        if ext == "tar" ||
           filename.hasSuffix(".tgz") ||
           filename.hasSuffix(".tar.gz") ||
           filename.hasSuffix(".tbz") ||
           filename.hasSuffix(".tar.bz2") ||
           filename.hasSuffix(".txz") ||
           filename.hasSuffix(".tar.xz") ||
           filename.hasSuffix(".zst") ||
           filename.hasSuffix(".tar.zst") {
            return try untar(sourceURL: sourceURL, destURL: destURL)
        }

        // Otherwise ZIP
        var zipError: NSError?
        let ok = SSZipArchive.unzipFile(atPath: sourceURL.path,
                                        toDestination: destURL.path,
                                        preserveAttributes: true,
                                        overwrite: overwrite,
                                        password: password,
                                        error: &zipError,
                                        delegate: nil)

        if !ok {
            throw NSError(domain: "ZipPlugin", code: 500,
                          userInfo: [NSLocalizedDescriptionKey:
                                        "ZIP extraction failed: \(zipError?.localizedDescription ?? "Unknown error")"])
        }

        let extracted = listFiles(at: destURL)
        return [
            "path": destURL.path,
            "fileCount": extracted.count,
            "files": extracted,
            "type": "zip"
        ]
    }

    // --------------------------------------------------
    // MARK: - TAR EXTRACTOR (Pure Swift)
    // --------------------------------------------------
    private func untar(sourceURL: URL, destURL: URL) throws -> [String: Any] {
        let fm = FileManager.default
        guard let fileHandle = FileHandle(forReadingAtPath: sourceURL.path) else {
            throw NSError(domain: "ZipPlugin", code: 500, userInfo: [NSLocalizedDescriptionKey: "Cannot open source file"])
        }
        defer { fileHandle.closeFile() }

        var extractedCount = 0
        let blockSize = 512

        while true {
            let headerData = fileHandle.readData(ofLength: blockSize)
            if headerData.count < blockSize { break } // End of file

            // Check for empty block (end of archive marker is 2 empty blocks)
            if headerData.allSatisfy({ $0 == 0 }) {
                // Read next block to confirm end, or just stop
                let nextBlock = fileHandle.readData(ofLength: blockSize)
                if nextBlock.allSatisfy({ $0 == 0 }) { break }
                // If not empty, we might have just hit one empty block (padding?), but standard is 2.
                // However, if we consumed it, we need to process it if it wasn't empty.
                // For simplicity, if we hit an empty block, we assume end or padding.
                // But wait, we already read it. If it WASN'T empty, we need to process `nextBlock` as header?
                // No, standard tar ends with 2 zero blocks.
                // Let's just break if we hit a zero block.
                break
            }

            // Parse Header
            // Name: offset 0, length 100
            let nameData = headerData.subdata(in: 0..<100)
            guard let name = String(data: nameData.prefix(while: { $0 != 0 }), encoding: .ascii) else { continue }
            if name.isEmpty { continue }

            // Size: offset 124, length 12 (octal ASCII)
            let sizeData = headerData.subdata(in: 124..<136)
            let sizeString = String(data: sizeData.prefix(while: { $0 != 0 }), encoding: .ascii)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "0"
            let fileSize = Int(sizeString, radix: 8) ?? 0

            // Type: offset 156, length 1
            let typeFlag = headerData[156]
            
            let fullPath = destURL.appendingPathComponent(name).path
            
            // '5' is directory
            if typeFlag == 0x35 { // '5'
                try? fm.createDirectory(atPath: fullPath, withIntermediateDirectories: true, attributes: nil)
            } else {
                // Regular file ('0' or null) or other types we treat as file for extraction
                // Ensure parent dir exists
                let parentDir = (fullPath as NSString).deletingLastPathComponent
                if !fm.fileExists(atPath: parentDir) {
                    try? fm.createDirectory(atPath: parentDir, withIntermediateDirectories: true, attributes: nil)
                }
                
                if fileSize > 0 {
                    let fileData = fileHandle.readData(ofLength: fileSize)
                    if fm.createFile(atPath: fullPath, contents: fileData, attributes: nil) {
                        extractedCount += 1
                    }
                    
                    // Read padding to align to 512 bytes
                    let padding = (blockSize - (fileSize % blockSize)) % blockSize
                    if padding > 0 {
                        _ = fileHandle.readData(ofLength: padding)
                    }
                } else {
                    // Empty file
                    fm.createFile(atPath: fullPath, contents: Data(), attributes: nil)
                    extractedCount += 1
                }
            }
        }

        let files = listFiles(at: destURL)
        return [
            "path": destURL.path,
            "fileCount": files.count,
            "files": files,
            "type": "tar"
        ]
    }

    // --------------------------------------------------
    // MARK: - VALID ZIP CHECK
    // --------------------------------------------------
    public func isValidZip(source: String) -> Bool {
        let url = getURL(path: source)

        guard let data = try? Data(contentsOf: url), data.count >= 4 else { return false }

        return data[0] == 0x50 &&
               data[1] == 0x4B &&
               data[2] == 0x03 &&
               data[3] == 0x04
    }

    // --------------------------------------------------
    // MARK: - Helpers
    // --------------------------------------------------
    private func getURL(path: String) -> URL {
        let clean = path.replacingOccurrences(of: "file://", with: "")
        return URL(fileURLWithPath: clean)
    }

    private func countFiles(at url: URL) -> Int {
        var c = 0
        if let e = FileManager.default.enumerator(at: url, includingPropertiesForKeys: nil) {
            for _ in e { c += 1 }
        }
        return c
    }

    private func listFiles(at url: URL) -> [String] {
        var arr: [String] = []
        if let e = FileManager.default.enumerator(at: url, includingPropertiesForKeys: nil) {
            for case let u as URL in e { arr.append(u.path) }
        }
        return arr
    }
}
