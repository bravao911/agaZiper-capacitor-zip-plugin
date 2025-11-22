import Foundation
import SSZipArchive

@objc public class Zip: NSObject {
    
    public func compress(source: String, destination: String, password: String?) throws -> [String: Any] {
        let sourceURL = getURL(path: source)
        let destURL = getURL(path: destination)
        
        // Ensure destination directory exists
        let fileManager = FileManager.default
        let destDir = destURL.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: destDir.path) {
            try fileManager.createDirectory(at: destDir, withIntermediateDirectories: true, attributes: nil)
        }

        let success: Bool
        
        // Check if source is Directory or File
        var isDir: ObjCBool = false
        if fileManager.fileExists(atPath: sourceURL.path, isDirectory: &isDir) {
            if isDir.boolValue {
                // Zip Directory
                success = SSZipArchive.createZipFile(atPath: destURL.path, 
                                                   withContentsOfDirectory: sourceURL.path, 
                                                   keepParentDirectory: false, 
                                                   withPassword: password)
            } else {
                // Zip Single File
                success = SSZipArchive.createZipFile(atPath: destURL.path, 
                                                   withFilesAtPaths: [sourceURL.path], 
                                                   withPassword: password)
            }
        } else {
            throw NSError(domain: "ZipPlugin", code: 404, userInfo: [NSLocalizedDescriptionKey: "Source file or directory does not exist"])
        }

        if !success {
            throw NSError(domain: "ZipPlugin", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to create zip archive"])
        }
        
        // Calculate result stats
        let attr = try? fileManager.attributesOfItem(atPath: destURL.path)
        let size = attr?[.size] as? Int64 ?? 0
        let fileCount = countFiles(at: sourceURL) // Count files in source

        return [
            "path": destURL.path, // Return absolute path
            "size": size,
            "fileCount": fileCount,
            "type": "zip"
        ]
    }

    public func extract(source: String, destination: String, password: String?, overwrite: Bool) throws -> [String: Any] {
        let sourceURL = getURL(path: source)
        let destURL = getURL(path: destination)
        
        let success = SSZipArchive.unzipFile(atPath: sourceURL.path, 
                                             toDestination: destURL.path, 
                                             overwrite: overwrite, 
                                             password: password, 
                                             error: nil)

        if !success {
             throw NSError(domain: "ZipPlugin", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to extract archive"])
        }
        
        // Gather extracted files info
        let extractedFiles = listFiles(at: destURL)
        
        return [
            "path": destURL.path,
            "fileCount": extractedFiles.count,
            "files": extractedFiles, // List of file paths
            "type": "zip"
        ]
    }

    public func isValidZip(source: String) -> Bool {
        let sourceURL = getURL(path: source)
        return SSZipArchive.isFileZipped(atPath: sourceURL.path)
    }
    
    // MARK: - Helpers

    private func getURL(path: String) -> URL {
        if path.hasPrefix("file://") {
            return URL(string: path) ?? URL(fileURLWithPath: path)
        }
        return URL(fileURLWithPath: path)
    }
    
    private func countFiles(at url: URL) -> Int {
        let fileManager = FileManager.default
        var count = 0
        var isDir: ObjCBool = false
        
        if fileManager.fileExists(atPath: url.path, isDirectory: &isDir) {
            if isDir.boolValue {
                if let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: nil) {
                    for _ in enumerator {
                        count += 1
                    }
                }
            } else {
                return 1
            }
        }
        return count
    }
    
    private func listFiles(at url: URL) -> [String] {
        let fileManager = FileManager.default
        var files: [String] = []
        
        if let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: nil) {
            for case let fileURL as URL in enumerator {
                files.append(fileURL.path)
            }
        }
        return files
    }
}