import Foundation
import Capacitor

@objc(ZipPlugin)
public class ZipPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "ZipPlugin"
    public let jsName = "Zip"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "compress", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "extract", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "isValidArchive", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "zip", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "unzip", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "isValidZip", returnType: CAPPluginReturnPromise)
    ]
    
    private let implementation = Zip()

    @objc func compress(_ call: CAPPluginCall) {
        guard let source = call.getString("source"),
              let destination = call.getString("destination") else {
            call.reject("Must provide source and destination")
            return
        }
        
        let type = call.getString("type") ?? "zip"
        let password = call.getString("password")
        
        if type != "zip" {
            call.reject("Only ZIP compression supported")
            return
        }

        do {
            let result = try implementation.compress(source: source, destination: destination, password: password)
            call.resolve(result)
        } catch {
            call.reject(error.localizedDescription)
        }
    }

    @objc func extract(_ call: CAPPluginCall) {
        guard let source = call.getString("source"),
              let destination = call.getString("destination") else {
            call.reject("Must provide source and destination")
            return
        }
        
        let password = call.getString("password")
        let overwrite = call.getBool("overwrite") ?? true
        
        let type = call.getString("type") ?? "zip"

        // Allow TAR formats
        if ["zip", "tar", "tgz", "tar.gz", "tbz", "tar.bz2", "txz", "tar.xz", "zst", "tar.zst"].contains(type) == false {
            call.reject("Archive type '\(type)' not supported")
            return
        }

        do {
            let result = try implementation.extract(source: source, destination: destination, password: password, overwrite: overwrite)
            call.resolve(result)
        } catch {
            call.reject(error.localizedDescription)
        }
    }

    @objc func isValidArchive(_ call: CAPPluginCall) {
        guard let source = call.getString("source") else {
            call.reject("Must provide source")
            return
        }

        let type = call.getString("type") ?? "zip"

        // ZIP validation only
        if type != "zip" {
            call.resolve(["valid": false])
            return
        }

        let isValid = implementation.isValidZip(source: source)
        call.resolve(["valid": isValid])
    }

    @objc func zip(_ call: CAPPluginCall) { self.compress(call) }
    @objc func unzip(_ call: CAPPluginCall) { self.extract(call) }
    @objc func isValidZip(_ call: CAPPluginCall) { self.isValidArchive(call) }
}
