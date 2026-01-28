import { LeftPanel } from "../uv-shared-module/LeftPanel";
import { ThumbsView } from "./ThumbsView";
import { ResourcesLeftPanel as ResourcesLeftPanelConfig } from "../../extensions/config/ResourcesLeftPanel";
export declare class ResourcesLeftPanel extends LeftPanel<ResourcesLeftPanelConfig> {
    $resources: JQuery;
    $resourcesButton: JQuery;
    $resourcesView: JQuery;
    $tabs: JQuery;
    $tabsContent: JQuery;
    $thumbsButton: JQuery;
    $thumbsView: JQuery;
    $views: JQuery;
    thumbsView: ThumbsView;
    constructor($element: JQuery);
    create(): void;
    dataBind(): void;
    dataBindThumbsView(): void;
    expandFullStart(): void;
    expandFullFinish(): void;
    collapseFullStart(): void;
    collapseFullFinish(): void;
    resize(): void;
}
