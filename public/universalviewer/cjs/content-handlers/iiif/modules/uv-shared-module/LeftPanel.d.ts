import { BaseConfig } from "../../BaseConfig";
import { BaseExpandPanel } from "./BaseExpandPanel";
export declare class LeftPanel<T extends BaseConfig["modules"]["leftPanel"]> extends BaseExpandPanel<T> {
    constructor($element: JQuery);
    create(): void;
    init(): void;
    getTargetWidth(): number;
    getFullTargetWidth(): number;
    toggleFinish(): void;
    resize(): void;
}
