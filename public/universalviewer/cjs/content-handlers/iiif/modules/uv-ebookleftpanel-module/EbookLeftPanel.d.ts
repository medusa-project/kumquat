import { LeftPanel } from "../uv-shared-module/LeftPanel";
import { Config } from "../../extensions/uv-ebook-extension/config/Config";
export declare class EbookLeftPanel extends LeftPanel<Config["modules"]["leftPanel"]> {
    private _ebookTOC;
    private _$container;
    private _$ebookTOC;
    constructor($element: JQuery);
    create(): Promise<void>;
    expandFullStart(): void;
    expandFullFinish(): void;
    collapseFullStart(): void;
    collapseFullFinish(): void;
    resize(): void;
}
