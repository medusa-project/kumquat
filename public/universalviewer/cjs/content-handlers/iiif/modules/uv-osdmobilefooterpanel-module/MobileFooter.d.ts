import { FooterPanel as BaseFooterPanel } from "../uv-shared-module/FooterPanel";
import { Config } from "../../extensions/uv-openseadragon-extension/config/Config";
export declare class FooterPanel extends BaseFooterPanel<Config["modules"]["mobileFooterPanel"]> {
    $rotateButton: JQuery;
    $zoomInButton: JQuery;
    $zoomOutButton: JQuery;
    constructor($element: JQuery);
    create(): void;
    resize(): void;
}
