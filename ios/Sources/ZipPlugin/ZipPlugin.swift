content:
import Foundation
import Capacitor

/**
 * Please read the Capacitor iOS Plugin Development Guide
 * here: https://capacitorjs.com/docs/plugins/ios
 */
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
        
        // Currently only ZIP is supported on iOS via SSZipArchive
        if type != "zip" {
            call.reject("Archive type '\(type)' is not currently supported on iOS")
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
        
        // Auto-detect type or default to zip (Only ZIP supported currently)
        let type = call.getString("type") ?? "zip"
        if type != "zip" {
             call.reject("Archive type '\(type)' is not currently supported on iOS")
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
        // Using "zip" as default as it's the only one implemented
        let type = call.getString("type") ?? "zip"
        
        if type != "zip" {
             call.resolve(["valid": false])
             return
        }
        
        let isValid = implementation.isValidZip(source: source)
        call.resolve(["valid": isValid])
    }

    // MARK: - Legacy Methods
    
    @objc func zip(_ call: CAPPluginCall) {
        self.compress(call)
    }
    
    @objc func unzip(_ call: CAPPluginCall) {
        self.extract(call)
    }
    
    @objc func isValidZip(_ call: CAPPluginCall) {
        self.isValidArchive(call)
    }
}