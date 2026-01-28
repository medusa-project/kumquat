import { Dialogue } from "../uv-shared-module/Dialogue";
import { BaseConfig } from "../../BaseConfig";
export declare class MoreInfoDialogue extends Dialogue<BaseConfig["modules"]["moreInfoRightPanel"]> {
    $title: JQuery;
    metadataComponent: any;
    $metadata: JQuery;
    constructor($element: JQuery);
    create(): void;
    open(triggerButton?: HTMLElement): void;
    private _getData;
    close(): void;
    resize(): void;
}
