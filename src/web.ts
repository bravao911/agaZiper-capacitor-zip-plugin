import { WebPlugin } from '@capacitor/core';
import type { 
  ZipPlugin, 
  ZipOptions, 
  UnzipOptions, 
  ZipResult, 
  UnzipResult,
  CompressOptions,
  ExtractOptions,
  CompressResult,
  ExtractResult,
  ArchiveType
} from './definitions';

export class ZipWeb extends WebPlugin implements ZipPlugin {

  async compress(options: CompressOptions): Promise<CompressResult> {
    console.log('Compress operation not supported on web', options);
    throw this.unimplemented('Compress operations are not supported on web platform');
  }

  async extract(options: ExtractOptions): Promise<ExtractResult> {
    console.log('Extract operation not supported on web', options);
    throw this.unimplemented('Extract operations are not supported on web platform');
  }

  async isValidArchive(options: { source: string; type?: ArchiveType }): Promise<{ valid: boolean }> {
    console.log('Archive validation not supported on web', options);
    throw this.unimplemented('Archive validation is not supported on web platform');
  }

  // Legacy methods for backward compatibility
  async zip(options: ZipOptions): Promise<ZipResult> {
    console.log('Zip operation not supported on web', options);
    throw this.unimplemented('Zip operations are not supported on web platform');
  }

  async unzip(options: UnzipOptions): Promise<UnzipResult> {
    console.log('Unzip operation not supported on web', options);
    throw this.unimplemented('Unzip operations are not supported on web platform');
  }

  async isValidZip(options: { source: string }): Promise<{ valid: boolean }> {
    console.log('Zip validation not supported on web', options);
    throw this.unimplemented('Zip validation is not supported on web platform');
  }
}