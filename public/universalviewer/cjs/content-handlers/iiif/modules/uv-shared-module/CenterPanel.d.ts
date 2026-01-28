import { BaseView } from "./BaseView";
import { Position } from "./Position";
import { BaseConfig } from "../../BaseConfig";
export declare class CenterPanel<T extends BaseConfig["modules"]["centerPanel"]> extends BaseView<T> {
    title: string | null;
    subtitle: string | null;
    subtitleExpanded: boolean;
    $attribution: JQuery;
    $closeAttributionButton: JQuery;
    $content: JQuery;
    $title: JQuery;
    $subtitle: JQuery;
    $subtitleWrapper: JQuery;
    $subtitleExpand: JQuery;
    $subtitleText: JQuery;
    isAttributionOpen: boolean;
    attributionPosition: Position;
    isAttributionLoaded: boolean;
    constructor($element: JQuery);
    create(): void;
    openAttribution(): void;
    closeAttribution(): void;
    updateRequiredStatement(): void;
    resize(): void;
}
