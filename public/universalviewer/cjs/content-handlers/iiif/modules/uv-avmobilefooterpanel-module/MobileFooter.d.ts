import { Config } from "../../extensions/uv-av-extension/config/Config";
import { FooterPanel as BaseFooterPanel } from "../uv-shared-module/FooterPanel";
export declare class FooterPanel extends BaseFooterPanel<Config["modules"]["mobileFooterPanel"]> {
    $fullScreenBtn: JQuery;
    constructor($element: JQuery);
    create(): void;
    resize(): void;
}
