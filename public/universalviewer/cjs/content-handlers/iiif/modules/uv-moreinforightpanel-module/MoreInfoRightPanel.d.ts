import { RightPanel } from "../uv-shared-module/RightPanel";
import { MoreInfoRightPanel as MoreInfoRightPanelConfig } from "../../BaseConfig";
export declare class MoreInfoRightPanel extends RightPanel<MoreInfoRightPanelConfig> {
    metadataComponent: any;
    $metadata: JQuery;
    limitType: any;
    limit: number;
    constructor($element: JQuery);
    create(): void;
    toggleFinish(): void;
    databind(): void;
    private _getCurrentRange;
    private _getData;
    resize(): void;
}
