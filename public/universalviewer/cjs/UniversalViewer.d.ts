import { IUVData } from "./IUVData";
import { IContentHandler } from "./IContentHandler";
import BaseContentHandler from "./BaseContentHandler";
export interface IUVOptions {
    target: HTMLElement;
    data: IUVData<any>;
}
export declare class UniversalViewer extends BaseContentHandler<IUVData<any>> {
    options: IUVOptions;
    private _contentType;
    private _assignedContentHandler;
    private _externalEventListeners;
    constructor(options: IUVOptions);
    get(): IContentHandler<IUVData<any>>;
    on(name: string, cb: Function, ctx?: any): void;
    private _assignContentHandler;
    set(data: IUVData<any>, initial?: boolean): void;
    exitFullScreen(): void;
    resize(): void;
    dispose(): void;
}
