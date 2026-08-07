import { IUVData } from "./IUVData";
import { IContentHandler } from "./IContentHandler";
import BaseContentHandler from "./BaseContentHandler";
import { ContentType } from "./ContentType";
export interface IUVOptions {
    target: HTMLElement;
    data: IUVData<any>;
}
export declare class UniversalViewer extends BaseContentHandler<IUVData<any>> {
    options: IUVOptions;
    contentType: ContentType;
    assignedContentHandler: IContentHandler<IUVData<any>>;
    _contentType: ContentType;
    _assignedContentHandler: any;
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
