import { BaseConfig } from "../../BaseConfig";
import { Dialogue } from "../uv-shared-module/Dialogue";
import { Shell } from "../uv-shared-module/Shell";
export declare class AdjustImageDialogue extends Dialogue<BaseConfig["modules"]["adjustImageDialogue"]> {
    $message: JQuery;
    $scroll: JQuery;
    $title: JQuery;
    $brightnessLabel: JQuery;
    $brightnessInput: JQuery;
    $contrastLabel: JQuery;
    $contrastInput: JQuery;
    $saturationLabel: JQuery;
    $saturationInput: JQuery;
    $rememberContainer: JQuery;
    $rememberCheckbox: JQuery;
    $rememberLabel: JQuery;
    $resetButton: JQuery;
    contrastPercent: number;
    brightnessPercent: number;
    saturationPercent: number;
    rememberSettings: boolean;
    shell: Shell;
    constructor($element: JQuery, shell: Shell);
    create(): void;
    filter(): void;
    open(): void;
    close(): void;
    resize(): void;
}
