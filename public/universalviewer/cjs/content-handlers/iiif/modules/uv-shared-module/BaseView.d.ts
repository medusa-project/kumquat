import { Panel } from "./Panel";
import { IExtension } from "./IExtension";
import { BaseConfig, ModuleConfig } from "../../BaseConfig";
export declare class BaseView<T extends ModuleConfig> extends Panel {
    config: T;
    content: T["content"];
    extension: IExtension;
    modules: string[];
    options: T["options"];
    constructor($element: JQuery, fitToParentWidth?: boolean, fitToParentHeight?: boolean);
    create(): void;
    init(): void;
    setConfig<T extends BaseConfig>(moduleName: keyof T["modules"]): void;
    resize(): void;
}
