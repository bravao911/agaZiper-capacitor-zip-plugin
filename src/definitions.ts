export interface ZipPlugin {
  /**
   * Compress files or directories into an archive
   */
  compress(options: CompressOptions): Promise<CompressResult>;

  /**
   * Extract files from an archive
   */
  extract(options: ExtractOptions): Promise<ExtractResult>;

  /**
   * Check if a file is a valid archive
   */
  isValidArchive(options: { source: string; type?: ArchiveType }): Promise<{ valid: boolean }>;

  // Legacy methods for backward compatibility
  zip(options: ZipOptions): Promise<ZipResult>;
  unzip(options: UnzipOptions): Promise<UnzipResult>;
  isValidZip(options: { source: string }): Promise<{ valid: boolean }>;
}

export enum ArchiveType {
  ZIP = 'zip',
  TAR = 'tar',
  TAR_GZ = 'tar.gz',
  TAR_BZ2 = 'tar.bz2',
  TAR_XZ = 'tar.xz'
}

export interface CompressOptions {
  /**
   * Source file or directory path to compress
   */
  source: string;
  
  /**
   * Destination path for the archive file
   */
  destination: string;
  
  /**
   * Archive type (zip, tar, tar.gz, tar.bz2, tar.xz)
   */
  type: ArchiveType;
  
  /**
   * Optional password for zip encryption (ZIP only)
   */
  password?: string;
  
  /**
   * Compression level (1-9, default: 6)
   */
  compressionLevel?: number;
}

export interface ExtractOptions {
  /**
   * Source archive file path
   */
  source: string;
  
  /**
   * Destination directory path for extraction
   */
  destination: string;
  
  /**
   * Archive type - if not specified, will be auto-detected
   */
  type?: ArchiveType;
  
  /**
   * Password for encrypted zip files (ZIP only)
   */
  password?: string;
  
  /**
   * Overwrite existing files (default: true)
   */
  overwrite?: boolean;
}

export interface CompressResult {
  /**
   * Path to the created archive file
   */
  path: string;
  
  /**
   * Size of the created archive file in bytes
   */
  size: number;
  
  /**
   * Number of files compressed
   */
  fileCount: number;
  
  /**
   * Archive type used
   */
  type: ArchiveType;
}

export interface ExtractResult {
  /**
   * Path where files were extracted
   */
  path: string;
  
  /**
   * Number of files extracted
   */
  fileCount: number;
  
  /**
   * List of extracted file paths
   */
  files: string[];
  
  /**
   * Archive type that was extracted
   */
  type: ArchiveType;
}

// Legacy interfaces for backward compatibility
export interface ZipOptions extends Omit<CompressOptions, 'type'> {}
export interface UnzipOptions extends Omit<ExtractOptions, 'type'> {}
export interface ZipResult extends CompressResult {}
export interface UnzipResult extends ExtractResult {}