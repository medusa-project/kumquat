import { BaseConfig } from "../../BaseConfig";
import { Dialogue } from "./Dialogue";
export declare class GenericDialogue extends Dialogue<BaseConfig["modules"]["genericDialogue"]> {
    acceptCallback: any;
    $acceptButton: JQuery;
    $message: JQuery;
    constructor($element: JQuery);
    create(): void;
    accept(): void;
    showMessage(params: any): void;
    resize(): void;
}
