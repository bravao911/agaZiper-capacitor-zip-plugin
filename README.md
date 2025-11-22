# agaziper

Capacitor plugin for zipping and unzipping files

## Install

```bash
npm install agaziper
npx cap sync
```

## API

<docgen-index>

* [`compress(...)`](#compress)
* [`extract(...)`](#extract)
* [`isValidArchive(...)`](#isvalidarchive)
* [`zip(...)`](#zip)
* [`unzip(...)`](#unzip)
* [`isValidZip(...)`](#isvalidzip)
* [Interfaces](#interfaces)
* [Enums](#enums)

</docgen-index>

<docgen-api>
<!--Update the source file JSDoc comments and rerun docgen to update the docs below-->

### compress(...)

```typescript
compress(options: CompressOptions) => Promise<CompressResult>
```

Compress files or directories into an archive

| Param         | Type                                                        |
| ------------- | ----------------------------------------------------------- |
| **`options`** | <code><a href="#compressoptions">CompressOptions</a></code> |

**Returns:** <code>Promise&lt;<a href="#compressresult">CompressResult</a>&gt;</code>

--------------------


### extract(...)

```typescript
extract(options: ExtractOptions) => Promise<ExtractResult>
```

Extract files from an archive

| Param         | Type                                                      |
| ------------- | --------------------------------------------------------- |
| **`options`** | <code><a href="#extractoptions">ExtractOptions</a></code> |

**Returns:** <code>Promise&lt;<a href="#extractresult">ExtractResult</a>&gt;</code>

--------------------


### isValidArchive(...)

```typescript
isValidArchive(options: { source: string; type?: ArchiveType; }) => Promise<{ valid: boolean; }>
```

Check if a file is a valid archive

| Param         | Type                                                                            |
| ------------- | ------------------------------------------------------------------------------- |
| **`options`** | <code>{ source: string; type?: <a href="#archivetype">ArchiveType</a>; }</code> |

**Returns:** <code>Promise&lt;{ valid: boolean; }&gt;</code>

--------------------


### zip(...)

```typescript
zip(options: ZipOptions) => Promise<ZipResult>
```

| Param         | Type                                              |
| ------------- | ------------------------------------------------- |
| **`options`** | <code><a href="#zipoptions">ZipOptions</a></code> |

**Returns:** <code>Promise&lt;<a href="#zipresult">ZipResult</a>&gt;</code>

--------------------


### unzip(...)

```typescript
unzip(options: UnzipOptions) => Promise<UnzipResult>
```

| Param         | Type                                                  |
| ------------- | ----------------------------------------------------- |
| **`options`** | <code><a href="#unzipoptions">UnzipOptions</a></code> |

**Returns:** <code>Promise&lt;<a href="#unzipresult">UnzipResult</a>&gt;</code>

--------------------


### isValidZip(...)

```typescript
isValidZip(options: { source: string; }) => Promise<{ valid: boolean; }>
```

| Param         | Type                             |
| ------------- | -------------------------------- |
| **`options`** | <code>{ source: string; }</code> |

**Returns:** <code>Promise&lt;{ valid: boolean; }&gt;</code>

--------------------


### Interfaces


#### CompressResult

| Prop            | Type                                                | Description                               |
| --------------- | --------------------------------------------------- | ----------------------------------------- |
| **`path`**      | <code>string</code>                                 | Path to the created archive file          |
| **`size`**      | <code>number</code>                                 | Size of the created archive file in bytes |
| **`fileCount`** | <code>number</code>                                 | Number of files compressed                |
| **`type`**      | <code><a href="#archivetype">ArchiveType</a></code> | Archive type used                         |


#### CompressOptions

| Prop                   | Type                                                | Description                                      |
| ---------------------- | --------------------------------------------------- | ------------------------------------------------ |
| **`source`**           | <code>string</code>                                 | Source file or directory path to compress        |
| **`destination`**      | <code>string</code>                                 | Destination path for the archive file            |
| **`type`**             | <code><a href="#archivetype">ArchiveType</a></code> | Archive type (zip, tar, tar.gz, tar.bz2, tar.xz) |
| **`password`**         | <code>string</code>                                 | Optional password for zip encryption (ZIP only)  |
| **`compressionLevel`** | <code>number</code>                                 | Compression level (1-9, default: 6)              |


#### ExtractResult

| Prop            | Type                                                | Description                     |
| --------------- | --------------------------------------------------- | ------------------------------- |
| **`path`**      | <code>string</code>                                 | Path where files were extracted |
| **`fileCount`** | <code>number</code>                                 | Number of files extracted       |
| **`files`**     | <code>string[]</code>                               | List of extracted file paths    |
| **`type`**      | <code><a href="#archivetype">ArchiveType</a></code> | Archive type that was extracted |


#### ExtractOptions

| Prop              | Type                                                | Description                                            |
| ----------------- | --------------------------------------------------- | ------------------------------------------------------ |
| **`source`**      | <code>string</code>                                 | Source archive file path                               |
| **`destination`** | <code>string</code>                                 | Destination directory path for extraction              |
| **`type`**        | <code><a href="#archivetype">ArchiveType</a></code> | Archive type - if not specified, will be auto-detected |
| **`password`**    | <code>string</code>                                 | Password for encrypted zip files (ZIP only)            |
| **`overwrite`**   | <code>boolean</code>                                | Overwrite existing files (default: true)               |


#### ZipResult


#### ZipOptions


#### UnzipResult


#### UnzipOptions


### Enums


#### ArchiveType

| Members       | Value                  |
| ------------- | ---------------------- |
| **`ZIP`**     | <code>'zip'</code>     |
| **`TAR`**     | <code>'tar'</code>     |
| **`TAR_GZ`**  | <code>'tar.gz'</code>  |
| **`TAR_BZ2`** | <code>'tar.bz2'</code> |
| **`TAR_XZ`**  | <code>'tar.xz'</code>  |

</docgen-api>
