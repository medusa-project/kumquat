import { IUVData } from "./IUVData";
export declare const merge: any;
export declare const sanitize: (html: string) => any;
export declare const isValidUrl: (value: string) => boolean;
export declare const debounce: (callback: (args: any) => void, wait: number) => (...args: any[]) => void;
export declare const propertiesChanged: (newData: IUVData<any>, currentData: IUVData<any>, properties: string[]) => boolean;
export declare const propertyChanged: (newData: IUVData<any>, currentData: IUVData<any>, propertyName: string) => boolean;
export declare const loadScripts: (sources: string[]) => Promise<void>;
export declare const loadCSS: (sources: string[]) => Promise<void>;
export declare const isVisible: (el: JQuery) => boolean;
export declare const defaultLocale: {
    name: string;
};
export declare const getUUID: () => string;
export declare class Storage {
    private static _memoryStorage;
    static clear(storageType?: StorageType): void;
    static clearExpired(storageType?: StorageType): void;
    static get(key: string, storageType?: StorageType): StorageItem | null;
    private static _isExpired;
    static getItems(storageType?: StorageType): StorageItem[];
    static remove(key: string, storageType?: StorageType): void;
    static set(key: string, value: any, expirationSecs: number, storageType?: StorageType): StorageItem;
}
export declare class StorageItem {
    key: string;
    value: any;
    expiresAt: number;
}
export declare enum StorageType {
    MEMORY = "memory",
    SESSION = "session",
    LOCAL = "local"
}
