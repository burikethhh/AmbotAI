import { Readable } from 'stream';
import { File } from 'undici';

interface BlobCommandOptions {
    /**
     * Define your blob API token.
     * When supplied, this takes priority over process.env.VERCEL_OIDC_TOKEN and process.env.BLOB_READ_WRITE_TOKEN.
     * @defaultvalue process.env.BLOB_READ_WRITE_TOKEN
     */
    token?: string;
    /**
     * Define your Vercel OIDC token for store-scoped blob operations.
     * Use this together with `storeId` (or `BLOB_STORE_ID`) when you want to pass OIDC credentials explicitly.
     * @defaultvalue process.env.VERCEL_OIDC_TOKEN
     */
    oidcToken?: string;
    /**
     * Blob store id. Used to override process.env.BLOB_STORE_ID when Vercel OIDC token is available.
     * @defaultvalue process.env.BLOB_STORE_ID
     */
    storeId?: string;
    /**
     * `AbortSignal` to cancel the running request. See https://developer.mozilla.org/en-US/docs/Web/API/AbortSignal
     */
    abortSignal?: AbortSignal;
}
interface PresignedUrlPayload {
    delegationToken: string;
    signature: string;
    params: Record<string, string>;
}
/**
 * The access level of a blob.
 * - 'public': The blob is publicly accessible via its URL.
 * - 'private': The blob requires authentication to access.
 */
type BlobAccessType = 'public' | 'private';
interface CommonCreateBlobOptions extends BlobCommandOptions {
    /**
     * Whether the blob should be publicly accessible.
     * - 'public': The blob will be publicly accessible via its URL.
     * - 'private': The blob will require authentication to access.
     */
    access: BlobAccessType;
    /**
     * Adds a random suffix to the filename.
     * @defaultvalue false
     */
    addRandomSuffix?: boolean;
    /**
     * Allow overwriting an existing blob. By default this is set to false and will throw an error if the blob already exists.
     * @defaultvalue false
     */
    allowOverwrite?: boolean;
    /**
     * Defines the content type of the blob. By default, this value is inferred from the pathname. Sent as the 'content-type' header when downloading a blob.
     */
    contentType?: string;
    /**
     * Number in seconds to configure the edge and browser cache. The minimum is 1 minute. There's no maximum but keep in mind that browser and edge caches will do a best effort to respect this value.
     * Detailed documentation can be found here: https://vercel.com/docs/storage/vercel-blob#caching
     * @defaultvalue 30 * 24 * 60 * 60 (1 Month)
     */
    cacheControlMaxAge?: number;
    /**
     * Only perform the operation if the blob's current ETag matches this value.
     * Use this for optimistic concurrency control to prevent overwriting changes made by others.
     * If the ETag doesn't match, a `BlobPreconditionFailedError` will be thrown.
     */
    ifMatch?: string;
    /**
     * Maximum size in bytes allowed for this upload. Currently only enforced
     * client-side for multipart uploads (`put(..., { multipart: true })`).
     * For bodies with a known size (Blob, File, Buffer, etc.) the check is
     * performed before the upload starts. Streams cannot be checked upfront.
     * The maximum allowed value is 5TB.
     */
    maximumSizeInBytes?: number;
}
/**
 * Event object passed to the onUploadProgress callback.
 */
interface UploadProgressEvent {
    /**
     * The number of bytes uploaded.
     */
    loaded: number;
    /**
     * The total number of bytes to upload.
     */
    total: number;
    /**
     * The percentage of the upload that has been completed.
     */
    percentage: number;
}
/**
 * Callback type for tracking upload progress.
 */
type OnUploadProgressCallback = (progressEvent: UploadProgressEvent) => void;
/**
 * Interface for including upload progress tracking capabilities.
 */
interface WithUploadProgress {
    /**
     * Callback to track the upload progress. You will receive an object with the following properties:
     * - `loaded`: The number of bytes uploaded
     * - `total`: The total number of bytes to upload
     * - `percentage`: The percentage of the upload that has been completed
     */
    onUploadProgress?: OnUploadProgressCallback;
}
/**
 * Reads `storeId` from the delegation JWT embedded in a presigned blob URL’s
 * `vercel-blob-delegation` query parameter (same payload shape as `issueSignedToken` delegations).
 */
/**
 * Reads `storeId` from a delegation JWT’s payload segment (same format as
 * embedded in a presigned URL’s `vercel-blob-delegation` query parameter).
 */
declare function parseStoreIdFromDelegationToken(delegationToken: string): string;
declare function parseStoreIdFromPresignedUrl(presignedUrlPayload: PresignedUrlPayload): string;
declare class BlobError extends Error {
    constructor(message: string);
}
/**
 * Generates a download URL for a blob.
 * The download URL includes a ?download=1 parameter which causes browsers to download
 * the file instead of displaying it inline.
 *
 * @param blobUrl - The URL of the blob to generate a download URL for
 * @returns A string containing the download URL with the download parameter appended
 */
declare function getDownloadUrl(blobUrl: string): string;

/**
 * Result of a successful put or copy operation.
 */
interface PutBlobResult {
    /**
     * The URL of the blob.
     */
    url: string;
    /**
     * A URL that will cause browsers to download the file instead of displaying it inline.
     */
    downloadUrl: string;
    /**
     * The pathname of the blob within the store.
     */
    pathname: string;
    /**
     * The content-type of the blob.
     */
    contentType: string;
    /**
     * The content disposition header value.
     */
    contentDisposition: string;
    /**
     * The ETag of the blob. Can be used with `ifMatch` for conditional writes.
     */
    etag: string;
}
/**
 * Represents the body content for a put operation.
 * Can be one of several supported types.
 */
type PutBody = string | Readable | Buffer | Blob | ArrayBuffer | ReadableStream | File;

/**
 * Input format for a multipart upload part.
 * Used internally for processing multipart uploads.
 */
interface PartInput {
    /**
     * The part number (1-based index).
     */
    partNumber: number;
    /**
     * The content of the part.
     */
    blob: PutBody;
}
/**
 * Represents a single part of a multipart upload.
 * This structure is used when completing a multipart upload to specify the
 * uploaded parts and their order.
 */
interface Part {
    /**
     * The ETag value returned when the part was uploaded.
     * This value is used to verify the integrity of the uploaded part.
     */
    etag: string;
    /**
     * The part number of this part (1-based).
     * This number is used to order the parts when completing the multipart upload.
     */
    partNumber: number;
}

/**
 * Upload / blob constraints shared between `generateClientTokenFromReadWriteToken` and
 * `issueSignedToken` (serialized in the JSON body to the control API where supported).
 */
interface BlobClientTokenConstraintOptions {
    /**
     * A number specifying the maximum size in bytes that can be uploaded. The maximum is 5TB.
     */
    maximumSizeInBytes?: number;
    /**
     * An array of strings specifying the media types that are allowed to be uploaded.
     * By default, it's all content types. Wildcards are supported (text/*).
     */
    allowedContentTypes?: string[];
    /**
     * A number specifying the timestamp in ms when the token will expire.
     * For client tokens, defaults to now + 1 hour when omitted.
     */
    validUntil?: number;
    /**
     * Adds a random suffix to the filename.
     * @defaultvalue false
     */
    addRandomSuffix?: boolean;
    /**
     * Allow overwriting an existing blob. By default this is set to false and will throw an error if the blob already exists.
     * @defaultvalue false
     */
    allowOverwrite?: boolean;
    /**
     * Number in seconds to configure how long Blobs are cached. Defaults to one month. Cannot be set to a value lower than 1 minute.
     * @defaultvalue 30 * 24 * 60 * 60 (1 Month)
     */
    cacheControlMaxAge?: number;
    /**
     * Only write if the ETag matches (optimistic concurrency control).
     * Use this for conditional writes to prevent overwriting changes made by others.
     * If the ETag doesn't match, a `BlobPreconditionFailedError` will be thrown.
     */
    ifMatch?: string;
    /**
     * Configuration for upload completion callback.
     */
    onUploadCompleted?: {
        callbackUrl: string;
        tokenPayload?: string | null;
    };
}

/**
 * Options for completing a multipart upload.
 * Used with the completeMultipartUpload method.
 */
interface CommonCompleteMultipartUploadOptions {
    /**
     * Unique upload identifier for the multipart upload, received from createMultipartUpload.
     * This ID is used to identify which multipart upload is being completed.
     */
    uploadId: string;
    /**
     * Unique key identifying the blob object, received from createMultipartUpload.
     * This key is used to identify which blob object the parts belong to.
     */
    key: string;
}
type CompleteMultipartUploadCommandOptions = CommonCompleteMultipartUploadOptions & CommonCreateBlobOptions;

/**
 * Options for uploading a part in a multipart upload process.
 * Used with the uploadPart method.
 */
interface CommonMultipartUploadOptions {
    /**
     * Unique upload identifier for the multipart upload, received from createMultipartUpload.
     * This ID is used to associate all uploaded parts with the same multipart upload.
     */
    uploadId: string;
    /**
     * Unique key identifying the blob object, received from createMultipartUpload.
     * This key is used to identify which blob object the parts belong to.
     */
    key: string;
    /**
     * A number identifying which part is being uploaded (1-based).
     * This number is used to order the parts when completing the multipart upload.
     * Parts must be uploaded with consecutive part numbers starting from 1.
     */
    partNumber: number;
}
type UploadPartCommandOptions = CommonMultipartUploadOptions & CommonCreateBlobOptions;

/**
 * Operations that may be encoded in a delegation token (e.g. read: `get` /
 * `head` for blob object reads, write: `put` for presigned control-plane writes
 * — both single-object `PUT`, destructive: `delete` for presigned control-plane
 * `DELETE /?pathname=…`). `head` shares the GET URL shape (blob object host)
 * and is distinguished only by the HTTP method and `operation=head` in the
 * canonical signing string.
 */
type DelegationOperation = 'get' | 'head' | 'put' | 'delete';
/**
 * Result of `issueSignedToken` — the same values returned from `POST /signed-token` on
 * the Blob API. Use with {@link presignUrl} to obtain `{ presignedUrl }` for GET/HEAD,
 * presigned `PUT`, presigned multipart `POST`
 * without a bearer token when verified by the CDN.
 */
interface IssuedSignedToken {
    /**
     * Encodes delegation scope (pathname, allowed operations, expiry) and a store-level
     * HMAC, as issued by the API.
     */
    delegationToken: string;
    /**
     * Per-issuance HMAC key: `HMAC-SHA256(blobSigningSecret, delegationToken)` in base64url
     * form. The SDK uses this as the HMAC key when signing a concrete blob URL
     * (the CDN re-derives the same value from the delegation token and store secret).
     */
    clientSigningToken: string;
    /** Time after which the delegation (and any presigned URLs) must be rejected, in ms since epoch. */
    validUntil: number;
}
/**
 * Options for {@link issueSignedToken}.
 */
type IssueSignedTokenOptions = BlobCommandOptions & {
    /**
     * Blob object pathname to scope the token to, e.g. `media/photo.png`.
     * Use `"*"` to allow any pathname in the store. When omitted, the API defaults
     * to a whole-store `"*"` wildcard.
     */
    pathname?: string;
    /**
     * Allowed operations (e.g. `get` / `head` for reads to `*.blob.vercel-storage.com`,
     * `put` for presigned control-plane `PUT` and multipart `POST /mpu`,
     * When omitted, the API defaults to read (`get`) only.
     */
    operations?: DelegationOperation[];
    /**
     * Absolute delegation expiry (ms since epoch). Must be after `now`. When omitted, the API uses `now + 1 hour`.
     */
    validUntil?: number;
    allowedContentTypes?: string[];
    maximumSizeInBytes?: number;
};
/**
 * Requests short-lived signed-token material from the Blob control API
 * (`POST /signed-token`). Use OIDC (`VERCEL_OIDC_TOKEN` + `storeId` / `BLOB_STORE_ID`)
 * or a read–write token like other SDK control-plane calls. Client (browser) tokens
 * are not allowed by the server for this operation.
 */
declare function issueSignedToken(options: IssueSignedTokenOptions): Promise<IssuedSignedToken>;
/**
 * Presign URL options for {@link presignUrl} when `operation` is `get`.
 * Only `validUntil` is honored for these operations; upload-only fields are rejected at the type level.
 */
type PresignGetUrlOptions = {
    operation: 'get';
    pathname: string;
    /**
     * Absolute URL expiry (ms since epoch), capped to the delegation `validUntil`.
     * Omitted on the wire when equal to the delegation ceiling (server defaults to delegation).
     */
    validUntil?: number;
};
/**
 * Presign URL options for {@link presignUrl} when `operation` is `head`.
 * Mirrors {@link PresignGetUrlOptions}; the CDN URL is identical, the HTTP
 * method differentiates, and the canonical signing string carries
 * `operation=head` so a GET-signed URL cannot be replayed for HEAD.
 */
type PresignHeadUrlOptions = {
    operation: 'head';
    pathname: string;
    validUntil?: number;
};
/**
 * Presign URL options for {@link presignUrl} when `operation` is `put` (single `PUT` or multipart `POST`).
 * Serialized as individual `vercel-blob-*` query params (see {@link PRESIGN_CANONICAL_QUERY_KEYS}).
 */
type PresignPutUrlOptions = {
    operation: 'put';
    pathname: string;
    validUntil?: number;
    allowedContentTypes?: string[];
    maximumSizeInBytes?: number;
    onUploadCompleted?: {
        callbackUrl: string;
        tokenPayload?: string;
    };
    allowOverwrite?: boolean;
    addRandomSuffix?: boolean;
    cacheControlMaxAge?: number;
    ifMatch?: string;
};
/**
 * Presign URL options for {@link presignUrl} when `operation` is `delete`.
 * Targets the control-plane `DELETE /?pathname=…` route — mirrors the PUT
 * presign URL shape, signed with `operation=delete` so the HTTP method
 * differentiates without changing the URL path. Only `validUntil` and
 * `ifMatch` are honored; upload-only fields are rejected at the type level.
 */
type PresignDeleteUrlOptions = {
    operation: 'delete';
    pathname: string;
    validUntil?: number;
    ifMatch?: string;
};
type PresignUrlOptions = PresignGetUrlOptions | PresignHeadUrlOptions | PresignPutUrlOptions | PresignDeleteUrlOptions;
/** Result of {@link presignUrl}: a ready-to-fetch blob object URL or control-plane upload URL. */
type PresignUrlResult = {
    presignedUrl: string;
};
/**
 * Builds a presigned URL for `GET` / `HEAD` (blob object host), `PUT` / multipart (control API),
 * or `DELETE` (`DELETE /?pathname=…` on the control API — mirrors the PUT URL shape; the
 * HTTP method discriminates, and the canonical signing string includes `operation=delete`).
 * `HEAD` reuses the GET URL shape against the blob object host; `operation=head` in the
 * canonical string prevents a GET-signed URL from being replayed as a HEAD.
 */
declare function presignUrl(signedToken: Pick<IssuedSignedToken, 'clientSigningToken' | 'delegationToken'>, options: PresignUrlOptions & {
    access: 'public' | 'private';
}): Promise<PresignUrlResult>;

type CreateFolderCommandOptions = Pick<CommonCreateBlobOptions, 'token' | 'abortSignal'> & {
    /** @defaultValue 'public' — kept for backward compatibility */
    access?: BlobAccessType;
};
interface CreateFolderResult {
    pathname: string;
    url: string;
}
/**
 * Creates a folder in your store. Vercel Blob has no real concept of folders, our file browser on Vercel.com displays folders based on the presence of trailing slashes in the pathname. Unless you are building a file browser system, you probably don't need to use this method.
 *
 * Use the resulting `url` to delete the folder, just like you would delete a blob.
 * @param pathname - Can be user1/ or user1/avatars/
 * @param options - Additional options including required `access` ('public' or 'private') and optional `token`
 */
declare function createFolder(pathname: string, options?: CreateFolderCommandOptions): Promise<CreateFolderResult>;

export { type BlobAccessType as B, type CommonCompleteMultipartUploadOptions as C, type DelegationOperation as D, type IssuedSignedToken as I, type OnUploadProgressCallback as O, type PutBlobResult as P, type UploadPartCommandOptions as U, type WithUploadProgress as W, type BlobCommandOptions as a, type BlobClientTokenConstraintOptions as b, type PresignPutUrlOptions as c, type IssueSignedTokenOptions as d, type Part as e, type PutBody as f, type PresignedUrlPayload as g, type CommonMultipartUploadOptions as h, createFolder as i, type CommonCreateBlobOptions as j, BlobError as k, type CompleteMultipartUploadCommandOptions as l, type CreateFolderCommandOptions as m, type CreateFolderResult as n, type PartInput as o, type PresignDeleteUrlOptions as p, type PresignGetUrlOptions as q, type PresignHeadUrlOptions as r, type PresignUrlOptions as s, type PresignUrlResult as t, type UploadProgressEvent as u, getDownloadUrl as v, issueSignedToken as w, parseStoreIdFromDelegationToken as x, parseStoreIdFromPresignedUrl as y, presignUrl as z };
