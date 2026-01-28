import { BaseConfig } from "../../BaseConfig";
import { FooterPanel as BaseFooterPanel } from "../uv-shared-module/FooterPanel";
export declare class FooterPanel<T extends BaseConfig["modules"]["footerPanel"]> extends BaseFooterPanel<T> {
    constructor($element: JQuery);
    create(): void;
    resize(): void;
}
