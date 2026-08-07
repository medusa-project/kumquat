import { TreeNode } from "manifesto.js";
import { Helper, MultiSelectableTreeNode, TreeSortType } from "@iiif/manifold";
import { BaseComponent, IBaseComponentOptions } from "@iiif/base-component";
export interface ITreeComponentData {
    [key: string]: any;
    autoExpand?: boolean;
    branchNodesSelectable?: boolean;
    branchNodesExpandOnClick?: boolean;
    helper?: Helper | null;
    topRangeIndex?: number;
    treeSortType?: TreeSortType;
}
export declare class TreeComponent extends BaseComponent {
    options: IBaseComponentOptions;
    private _$element;
    private _$tree;
    private _flattenedTree;
    private _data;
    private _multiSelectableNodes;
    private _rootNode;
    selectedNode: MultiSelectableTreeNode;
    constructor(options: IBaseComponentOptions);
    protected _init(): boolean;
    set(data: ITreeComponentData): void;
    private _getMultiSelectState;
    data(): ITreeComponentData;
    allNodesSelected(): boolean;
    private _getMultiSelectableNodes;
    private _nodeIsMultiSelectable;
    private getAllNodes;
    getMultiSelectedNodes(): MultiSelectableTreeNode[];
    getNodeById(id: string): MultiSelectableTreeNode;
    expandParents(node: TreeNode, expand: boolean): void;
    private _setNodeSelected;
    private _setNodeExpanded;
    private _setNodeMultiSelected;
    private _setNodeMultiSelectEnabled;
    selectPath(path: string): void;
    deselectCurrentNode(): void;
    selectNode(node: MultiSelectableTreeNode): void;
    expandNode(node: TreeNode, expanded: boolean): void;
    getNodeByPath(parentNode: MultiSelectableTreeNode, path: string[]): MultiSelectableTreeNode;
    show(): void;
    hide(): void;
    protected _resize(): void;
}
export declare class Events {
    static TREE_NODE_MULTISELECTED: string;
    static TREE_NODE_SELECTED: string;
}
