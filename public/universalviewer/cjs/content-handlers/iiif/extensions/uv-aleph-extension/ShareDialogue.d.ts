import { ShareDialogue as BaseShareDialogue } from "../../modules/uv-dialogues-module/ShareDialogue";
import { Config } from "../uv-aleph-extension/config/Config";
export declare class ShareDialogue extends BaseShareDialogue<Config["modules"]["shareDialogue"]> {
    constructor($element: JQuery);
    create(): void;
    update(): void;
    resize(): void;
}
