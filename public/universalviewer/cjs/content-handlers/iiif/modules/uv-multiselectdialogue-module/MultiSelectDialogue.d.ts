import { Dialogue } from "../uv-shared-module/Dialogue";
import { Config } from "../../extensions/uv-openseadragon-extension/config/Config";
export declare class MultiSelectDialogue extends Dialogue<Config["modules"]["multiSelectDialogue"]> {
    $title: JQuery;
    $gallery: JQuery;
    galleryComponent: any;
    data: any;
    constructor($element: JQuery);
    create(): void;
    isPageModeEnabled(): boolean;
    open(): void;
    close(): void;
    resize(): void;
}
