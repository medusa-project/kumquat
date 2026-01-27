import { CenterPanel } from "../uv-shared-module/CenterPanel";
import { IExternalResource } from "manifesto.js";
import "@universalviewer/aleph/dist/collection/assets/OrbitControls";
import { Config } from "../../extensions/uv-aleph-extension/config/Config";
export declare class AlephCenterPanel extends CenterPanel<Config["modules"]["centerPanel"]> {
    private _alViewer;
    private _alViewerReady;
    private _state;
    private _prevState;
    constructor($element: JQuery);
    create(): Promise<void>;
    openMedia(resources: IExternalResource[]): Promise<void>;
    private _nextState;
    resize(): void;
}
