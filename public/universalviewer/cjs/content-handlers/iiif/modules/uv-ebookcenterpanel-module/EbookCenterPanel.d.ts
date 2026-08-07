import { CenterPanel } from "../uv-shared-module/CenterPanel";
import { IExternalResource } from "manifesto.js";
import { Config } from "../../extensions/uv-ebook-extension/config/Config";
export declare class EbookCenterPanel extends CenterPanel<Config["modules"]["ebookCenterPanel"]> {
    private _cfi;
    private _ebookReader;
    private _ebookReaderReady;
    private _state;
    private _prevState;
    constructor($element: JQuery);
    create(): Promise<void>;
    openMedia(resources: IExternalResource[]): void;
    private _nextState;
    resize(): void;
}
