import { Config } from "../../extensions/uv-ebook-extension/config/Config";
import { FooterPanel as BaseFooterPanel } from "../uv-shared-module/FooterPanel";
export declare class FooterPanel extends BaseFooterPanel<Config["modules"]["footerPanel"]> {
    $fullScreenBtn: JQuery;
    constructor($element: JQuery);
    create(): void;
    resize(): void;
}
