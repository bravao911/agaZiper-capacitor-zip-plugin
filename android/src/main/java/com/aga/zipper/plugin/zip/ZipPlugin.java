package com.aga.zipper.plugin.zip;

import android.net.Uri;
import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;
import com.getcapacitor.annotation.Permission;

import java.io.*;
import java.util.ArrayList;
import java.util.List;
import java.util.zip.*;

import net.lingala.zip4j.ZipFile;
import net.lingala.zip4j.model.ZipParameters;
import net.lingala.zip4j.model.enums.CompressionLevel;
import net.lingala.zip4j.model.enums.EncryptionMethod;

import org.apache.commons.compress.archivers.tar.TarArchiveEntry;
import org.apache.commons.compress.archivers.tar.TarArchiveInputStream;
import org.apache.commons.compress.archivers.tar.TarArchiveOutputStream;
import org.apache.commons.compress.compressors.gzip.GzipCompressorInputStream;
import org.apache.commons.compress.compressors.gzip.GzipCompressorOutputStream;
import org.apache.commons.compress.compressors.bzip2.BZip2CompressorInputStream;
import org.apache.commons.compress.compressors.bzip2.BZip2CompressorOutputStream;
import org.apache.commons.compress.compressors.xz.XZCompressorInputStream;
import org.apache.commons.compress.compressors.xz.XZCompressorOutputStream;

@CapacitorPlugin(
    name = "Zip",
    permissions = {
        @Permission(
            alias = "storage",
            strings = {
                android.Manifest.permission.READ_EXTERNAL_STORAGE,
                android.Manifest.permission.WRITE_EXTERNAL_STORAGE
            }
        )
    }
)
public class ZipPlugin extends Plugin {

    @PluginMethod
    public void compress(PluginCall call) {
        String source = call.getString("source");
        String destination = call.getString("destination");
        String type = call.getString("type");
        String password = call.getString("password");
        int compressionLevel = call.getInt("compressionLevel", 6);

        if (source == null || destination == null || type == null) {
            call.reject("Source, destination, and type are required");
            return;
        }

        try {
            String sourcePath = getAbsolutePath(source);
            String destPath = getAbsolutePath(destination);

            File sourceFile = new File(sourcePath);
            if (!sourceFile.exists()) {
                call.reject("Source file/directory does not exist: " + sourcePath);
                return;
            }

            // Create parent directories if they don't exist
            File destFile = new File(destPath);
            File parentDir = destFile.getParentFile();
            if (parentDir != null && !parentDir.exists()) {
                parentDir.mkdirs();
            }

            int fileCount = 0;
            long fileSize = 0;

            switch (type.toLowerCase()) {
                case "zip":
                    fileCount = compressZip(sourceFile, destPath, password, compressionLevel);
                    break;
                case "tar":
                    fileCount = compressTar(sourceFile, destPath, null);
                    break;
                case "tar.gz":
                    fileCount = compressTar(sourceFile, destPath, "gzip");
                    break;
                case "tar.bz2":
                    fileCount = compressTar(sourceFile, destPath, "bzip2");
                    break;
                case "tar.xz":
                    fileCount = compressTar(sourceFile, destPath, "xz");
                    break;
                default:
                    call.reject("Unsupported archive type: " + type);
                    return;
            }

            fileSize = new File(destPath).length();

            JSObject result = new JSObject();
            result.put("path", destPath);
            result.put("size", fileSize);
            result.put("fileCount", fileCount);
            result.put("type", type);

            call.resolve(result);

        } catch (Exception e) {
            call.reject("Failed to create archive: " + e.getMessage());
        }
    }

    @PluginMethod
    public void extract(PluginCall call) {
        String source = call.getString("source");
        String destination = call.getString("destination");
        String type = call.getString("type");
        String password = call.getString("password");

        if (source == null || destination == null) {
            call.reject("Source and destination paths are required");
            return;
        }

        try {
            String sourcePath = getAbsolutePath(source);
            String destPath = getAbsolutePath(destination);

            File sourceFile = new File(sourcePath);
            if (!sourceFile.exists()) {
                call.reject("Source archive file does not exist: " + sourcePath);
                return;
            }

            // Auto-detect type if not provided
            if (type == null) {
                type = detectArchiveType(sourcePath);
            }

            // Create destination directory
            File destDir = new File(destPath);
            if (!destDir.exists()) {
                destDir.mkdirs();
            }

            List<String> extractedFiles = new ArrayList<>();
            int fileCount = 0;

            switch (type.toLowerCase()) {
                case "zip":
                    fileCount = extractZip(sourcePath, destPath, password, extractedFiles);
                    break;
                case "tar":
                    fileCount = extractTar(sourcePath, destPath, null, extractedFiles);
                    break;
                case "tar.gz":
                    fileCount = extractTar(sourcePath, destPath, "gzip", extractedFiles);
                    break;
                case "tar.bz2":
                    fileCount = extractTar(sourcePath, destPath, "bzip2", extractedFiles);
                    break;
                case "tar.xz":
                    fileCount = extractTar(sourcePath, destPath, "xz", extractedFiles);
                    break;
                default:
                    call.reject("Unsupported archive type: " + type);
                    return;
            }

            JSObject result = new JSObject();
            result.put("path", destPath);
            result.put("fileCount", fileCount);
            result.put("files", extractedFiles);
            result.put("type", type);

            call.resolve(result);

        } catch (Exception e) {
            call.reject("Failed to extract archive: " + e.getMessage());
        }
    }

    @PluginMethod
    public void isValidArchive(PluginCall call) {
        String source = call.getString("source");
        String type = call.getString("type");
        
        if (source == null) {
            call.reject("Source path is required");
            return;
        }

        try {
            String sourcePath = getAbsolutePath(source);
            
            if (type == null) {
                type = detectArchiveType(sourcePath);
            }

            boolean isValid = false;
            
            switch (type.toLowerCase()) {
                case "zip":
                    ZipFile zipFile = new ZipFile(sourcePath);
                    isValid = zipFile.isValidZipFile();
                    break;
                case "tar":
                case "tar.gz":
                case "tar.bz2":
                case "tar.xz":
                    isValid = isValidTarFile(sourcePath, type);
                    break;
            }

            JSObject result = new JSObject();
            result.put("valid", isValid);
            call.resolve(result);

        } catch (Exception e) {
            JSObject result = new JSObject();
            result.put("valid", false);
            call.resolve(result);
        }
    }

    // Legacy methods for backward compatibility
    @PluginMethod
    public void zip(PluginCall call) {
        call.getData().put("type", "zip");
        compress(call);
    }

    @PluginMethod
    public void unzip(PluginCall call) {
        call.getData().put("type", "zip");
        extract(call);
    }

    @PluginMethod
    public void isValidZip(PluginCall call) {
        call.getData().put("type", "zip");
        isValidArchive(call);
    }

    // Helper methods
    private int compressZip(File sourceFile, String destPath, String password, int compressionLevel) throws Exception {
        ZipFile zipFile = new ZipFile(destPath);
        ZipParameters zipParameters = new ZipParameters();
        
        switch (compressionLevel) {
            case 1:
                zipParameters.setCompressionLevel(CompressionLevel.FASTEST);
                break;
            case 9:
                zipParameters.setCompressionLevel(CompressionLevel.MAXIMUM);
                break;
            default:
                zipParameters.setCompressionLevel(CompressionLevel.NORMAL);
        }

        if (password != null && !password.isEmpty()) {
            zipParameters.setEncryptFiles(true);
            zipParameters.setEncryptionMethod(EncryptionMethod.ZIP_STANDARD);
            zipFile.setPassword(password.toCharArray());
        }

        if (sourceFile.isDirectory()) {
            zipFile.addFolder(sourceFile, zipParameters);
            return countFilesInDirectory(sourceFile);
        } else {
            zipFile.addFile(sourceFile, zipParameters);
            return 1;
        }
    }

    private int compressTar(File sourceFile, String destPath, String compression) throws Exception {
        FileOutputStream fos = new FileOutputStream(destPath);
        OutputStream compressedOut = fos;

        // Add compression layer if specified
        if ("gzip".equals(compression)) {
            compressedOut = new GzipCompressorOutputStream(fos);
        } else if ("bzip2".equals(compression)) {
            compressedOut = new BZip2CompressorOutputStream(fos);
        } else if ("xz".equals(compression)) {
            compressedOut = new XZCompressorOutputStream(fos);
        }

        TarArchiveOutputStream tarOut = new TarArchiveOutputStream(compressedOut);
        
        try {
            int fileCount = addToTarArchive(tarOut, sourceFile, "");
            return fileCount;
        } finally {
            tarOut.close();
        }
    }

    private int addToTarArchive(TarArchiveOutputStream tarOut, File file, String basePath) throws IOException {
        String entryName = basePath + file.getName();
        int count = 0;

        if (file.isFile()) {
            TarArchiveEntry entry = new TarArchiveEntry(file, entryName);
            tarOut.putArchiveEntry(entry);

            FileInputStream fis = new FileInputStream(file);
            byte[] buffer = new byte[1024];
            int bytesRead;
            while ((bytesRead = fis.read(buffer)) != -1) {
                tarOut.write(buffer, 0, bytesRead);
            }
            fis.close();
            tarOut.closeArchiveEntry();
            count = 1;
        } else if (file.isDirectory()) {
            File[] children = file.listFiles();
            if (children != null) {
                for (File child : children) {
                    count += addToTarArchive(tarOut, child, entryName + "/");
                }
            }
        }

        return count;
    }

    private int extractZip(String sourcePath, String destPath, String password, List<String> extractedFiles) throws Exception {
        ZipFile zipFile = new ZipFile(sourcePath);
        
        if (password != null && !password.isEmpty()) {
            zipFile.setPassword(password.toCharArray());
        }

        zipFile.extractAll(destPath);
        
        File destDir = new File(destPath);
        listFiles(destDir, extractedFiles);
        return extractedFiles.size();
    }

    private int extractTar(String sourcePath, String destPath, String compression, List<String> extractedFiles) throws Exception {
        FileInputStream fis = new FileInputStream(sourcePath);
        InputStream compressedIn = fis;

        // Add decompression layer if specified
        if ("gzip".equals(compression)) {
            compressedIn = new GzipCompressorInputStream(fis);
        } else if ("bzip2".equals(compression)) {
            compressedIn = new BZip2CompressorInputStream(fis);
        } else if ("xz".equals(compression)) {
            compressedIn = new XZCompressorInputStream(fis);
        }

        TarArchiveInputStream tarIn = new TarArchiveInputStream(compressedIn);
        
        try {
            TarArchiveEntry entry;
            int count = 0;

            while ((entry = tarIn.getNextTarEntry()) != null) {
                File outputFile = new File(destPath, entry.getName());
                
                if (entry.isDirectory()) {
                    outputFile.mkdirs();
                } else {
                    outputFile.getParentFile().mkdirs();
                    
                    FileOutputStream fos = new FileOutputStream(outputFile);
                    byte[] buffer = new byte[1024];
                    int bytesRead;
                    while ((bytesRead = tarIn.read(buffer)) != -1) {
                        fos.write(buffer, 0, bytesRead);
                    }
                    fos.close();
                    
                    extractedFiles.add(outputFile.getAbsolutePath());
                    count++;
                }
            }
            
            return count;
        } finally {
            tarIn.close();
        }
    }

    private String detectArchiveType(String filePath) {
        String fileName = new File(filePath).getName().toLowerCase();
        
        if (fileName.endsWith(".tar.gz") || fileName.endsWith(".tgz")) {
            return "tar.gz";
        } else if (fileName.endsWith(".tar.bz2") || fileName.endsWith(".tbz2")) {
            return "tar.bz2";
        } else if (fileName.endsWith(".tar.xz") || fileName.endsWith(".txz")) {
            return "tar.xz";
        } else if (fileName.endsWith(".tar")) {
            return "tar";
        } else if (fileName.endsWith(".zip")) {
            return "zip";
        }
        
        return "zip"; // default
    }

    private boolean isValidTarFile(String filePath, String type) {
        try {
            FileInputStream fis = new FileInputStream(filePath);
            InputStream compressedIn = fis;

            if (type.equals("tar.gz")) {
                compressedIn = new GzipCompressorInputStream(fis);
            } else if (type.equals("tar.bz2")) {
                compressedIn = new BZip2CompressorInputStream(fis);
            } else if (type.equals("tar.xz")) {
                compressedIn = new XZCompressorInputStream(fis);
            }

            TarArchiveInputStream tarIn = new TarArchiveInputStream(compressedIn);
            TarArchiveEntry entry = tarIn.getNextTarEntry();
            tarIn.close();
            
            return entry != null;
        } catch (Exception e) {
            return false;
        }
    }

    // ... (keep existing helper methods: getAbsolutePath, countFilesInDirectory, listFiles)
    
    private String getAbsolutePath(String path) {
        if (path.startsWith("file://")) {
            return Uri.parse(path).getPath();
        } else if (!path.startsWith("/")) {
            return new File(getContext().getFilesDir(), path).getAbsolutePath();
        }
        return path;
    }

    private int countFilesInDirectory(File directory) {
        int count = 0;
        File[] files = directory.listFiles();
        if (files != null) {
            for (File file : files) {
                if (file.isFile()) {
                    count++;
                } else if (file.isDirectory()) {
                    count += countFilesInDirectory(file);
                }
            }
        }
        return count;
    }

    private void listFiles(File directory, List<String> fileList) {
        File[] files = directory.listFiles();
        if (files != null) {
            for (File file : files) {
                if (file.isFile()) {
                    fileList.add(file.getAbsolutePath());
                } else if (file.isDirectory()) {
                    listFiles(file, fileList);
                }
            }
        }
    }
}