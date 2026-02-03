import { BaseView } from "./BaseView";
import { Thumb } from "manifesto.js";
import { ExtendedLeftPanel } from "../../extensions/config/ExtendedLeftPanel";
export declare class ThumbsView<T extends ExtendedLeftPanel> extends BaseView<T> {
    private _$thumbsCache;
    $selectedThumb: JQuery;
    $thumbs: JQuery;
    isCreated: boolean;
    isOpen: boolean;
    lastThumbClickedIndex: number;
    thumbs: Thumb[];
    constructor($element: JQuery);
    create(): void;
    databind(): void;
    createThumbs(): void;
    scrollStop(): void;
    loadThumbs(index?: number): void;
    show(): void;
    hide(): void;
    isPDF(): boolean;
    setLabel(): void;
    addSelectedClassToThumbs(index: number): void;
    selectIndex(index: number): void;
    getAllThumbs(): JQuery;
    getThumbByIndex(canvasIndex: number): JQuery;
    scrollToThumb(canvasIndex: number): void;
    resize(): void;
}
