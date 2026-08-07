import { Panel } from "./Panel";
import { IExtension } from "./IExtension";
import { ModuleConfig } from "../../BaseConfig";
export declare class BaseView<T extends ModuleConfig> extends Panel {
    config: T;
    content: T["content"];
    extension: IExtension;
    modules: string[];
    options: T["options"];
    constructor($element: JQuery, fitToParentWidth?: boolean, fitToParentHeight?: boolean);
    create(): void;
    init(): void;
    setConfig(moduleName: string): void;
    resize(): void;
}
