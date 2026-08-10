import { AdjustImageDialogue as BaseAdjustImageDialogue } from "../../modules/uv-dialogues-module/AdjustImageDialogue";
import { Shell } from "../../modules/uv-shared-module/Shell";
export declare class AdjustImageDialogue extends BaseAdjustImageDialogue {
    constructor($element: JQuery, shell: Shell);
    create(): void;
    resize(): void;
}
