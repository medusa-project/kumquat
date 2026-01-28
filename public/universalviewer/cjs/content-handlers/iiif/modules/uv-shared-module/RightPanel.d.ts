import { ExpandPanel } from "../../extensions/config/ExpandPanel";
import { BaseExpandPanel } from "./BaseExpandPanel";
export declare class RightPanel<T extends ExpandPanel> extends BaseExpandPanel<T> {
    constructor($element: JQuery);
    create(): void;
    init(): void;
    getTargetWidth(): number;
    getTargetLeft(): number;
    toggleFinish(): void;
    resize(): void;
}
