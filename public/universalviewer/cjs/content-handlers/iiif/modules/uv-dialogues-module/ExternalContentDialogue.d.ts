import { Config } from "../../extensions/uv-openseadragon-extension/config/Config";
import { Dialogue } from "../uv-shared-module/Dialogue";
export declare class ExternalContentDialogue extends Dialogue<Config["modules"]["externalContentDialogue"]> {
    $iframe: JQuery;
    constructor($element: JQuery);
    create(): void;
    resize(): void;
}
