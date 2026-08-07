import { ContentLeftPanel } from "../../extensions/config/ContentLeftPanel";
import { BaseView } from "../uv-shared-module/BaseView";
export declare class GalleryView extends BaseView<ContentLeftPanel> {
    isOpen: boolean;
    galleryComponent: any;
    galleryData: any;
    $gallery: JQuery;
    constructor($element: JQuery, fitToParentWidth?: boolean, fitToParentHeight?: boolean);
    create(): void;
    setup(): void;
    databind(): void;
    show(): void;
    hide(): void;
    resize(): void;
    applyExtendedLabelsStyles(): void;
}
