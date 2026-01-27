import { CenterPanel } from "../uv-shared-module/CenterPanel";
import { IExternalResource } from "manifesto.js";
import { Config } from "../../extensions/uv-default-extension/config/Config";
export declare class FileLinkCenterPanel extends CenterPanel<Config["modules"]["centerPanel"]> {
    $scroll: JQuery;
    $downloadItems: JQuery;
    $downloadItemTemplate: JQuery;
    constructor($element: JQuery);
    create(): void;
    openMedia(resources: IExternalResource[]): Promise<void>;
    resize(): void;
}
