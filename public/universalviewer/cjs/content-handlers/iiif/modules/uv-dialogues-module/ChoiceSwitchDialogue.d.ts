import { BaseConfig } from "../../BaseConfig";
import { Dialogue } from "../uv-shared-module/Dialogue";
import { Shell } from "../uv-shared-module/Shell";
export declare class ChoiceSwitchDialogue extends Dialogue<BaseConfig["modules"]["choiceSwitchDialogue"]> {
    $choiceList: JQuery;
    shell: Shell;
    $anchor: JQuery;
    constructor($element: JQuery, shell: Shell);
    create(): void;
    open(): void;
    close(): void;
    resize(): void;
}
