import { LeftPanel } from "../uv-shared-module/LeftPanel";
import { Config } from "../../extensions/uv-aleph-extension/config/Config";
export declare class AlephLeftPanel extends LeftPanel<Config["modules"]["alephLeftPanel"]> {
    private _alControlPanel;
    constructor($element: JQuery);
    create(): Promise<void>;
    expandFullStart(): void;
    expandFullFinish(): void;
    collapseFullStart(): void;
    collapseFullFinish(): void;
    resize(): void;
}
