import { Canvas, Range } from "manifesto.js";
import { Helper, UriLabeller } from "@iiif/manifold";
import { BaseComponent, IBaseComponentOptions } from "@iiif/base-component";
export interface IMetadataComponentContent {
    attribution: string;
    canvasHeader: string;
    copiedToClipboard: string;
    copyToClipboard: string;
    description: string;
    imageHeader: string;
    less: string;
    lessAriaLabelTemplate: string;
    license: string;
    rights: string;
    logo: string;
    manifestHeader: string;
    more: string;
    moreAriaLabelTemplate: string;
    noData: string;
    rangeHeader: string;
    sequenceHeader: string;
}
export interface IMetadataComponentData {
    canvasDisplayOrder?: string;
    metadataGroupOrder?: string;
    canvases?: Canvas[] | null;
    canvasExclude?: string;
    canvasLabels?: string;
    content?: IMetadataComponentContent;
    copiedMessageDuration?: number;
    copyToClipboardEnabled?: boolean;
    helper?: Helper | null;
    licenseFormatter?: UriLabeller | null;
    limit?: number;
    limitType?: LimitType;
    limitToRange?: boolean;
    manifestDisplayOrder?: string;
    manifestExclude?: string;
    range?: Range | null;
    rtlLanguageCodes?: string;
    sanitizer?: (html: string) => string;
    showAllLanguages?: boolean;
}
export declare enum LimitType {
    LINES = "lines",
    CHARS = "chars"
}
export declare class MetadataComponent extends BaseComponent {
    options: IBaseComponentOptions;
    private _$element;
    private _$copyTextTemplate;
    private _$metadataGroups;
    private _$metadataGroupTemplate;
    private _$metadataItemTemplate;
    private _$metadataItemURIValueTemplate;
    private _$metadataItemValueTemplate;
    private _$noData;
    private _data;
    private _metadataGroups;
    constructor(options: IBaseComponentOptions);
    protected _init(): boolean;
    data(): IMetadataComponentData;
    private _getManifestGroup;
    private _getCanvasGroups;
    set(data: IMetadataComponentData): void;
    private _sortItems;
    private _sortGroups;
    private _label;
    private _exclude;
    private _normalise;
    private _render;
    private _buildMetadataGroup;
    private _buildMetadataItem;
    private _getLabelLocale;
    private _getValueLocale;
    private _buildMetadataItemValue;
    private _buildMetadataItemURIValue;
    private _addReadingDirection;
    private _addCopyButton;
    private _copyItemValues;
    private _readCSV;
    private _sanitize;
    protected _resize(): void;
}
export declare class Events {
    static IIIF_VIEWER_LINK_CLICKED: string;
}
