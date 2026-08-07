"use strict";
var __extends = (this && this.__extends) || (function () {
    var extendStatics = function (d, b) {
        extendStatics = Object.setPrototypeOf ||
            ({ __proto__: [] } instanceof Array && function (d, b) { d.__proto__ = b; }) ||
            function (d, b) { for (var p in b) if (Object.prototype.hasOwnProperty.call(b, p)) d[p] = b[p]; };
        return extendStatics(d, b);
    };
    return function (d, b) {
        if (typeof b !== "function" && b !== null)
            throw new TypeError("Class extends value " + String(b) + " is not a constructor or null");
        extendStatics(d, b);
        function __() { this.constructor = d; }
        d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.TreeView = void 0;
var $ = require("jquery");
var IIIFEvents_1 = require("../../IIIFEvents");
var BaseView_1 = require("../uv-shared-module/BaseView");
var TreeComponent_1 = require("../uv-shared-module/TreeComponent");
var TreeView = /** @class */ (function (_super) {
    __extends(TreeView, _super);
    function TreeView($element, fitToParentWidth, fitToParentHeight) {
        if (fitToParentWidth === void 0) { fitToParentWidth = true; }
        if (fitToParentHeight === void 0) { fitToParentHeight = true; }
        var _this = _super.call(this, $element, fitToParentWidth, fitToParentHeight) || this;
        _this.isOpen = false;
        _this.expandedNodeIds = new Set();
        return _this;
    }
    TreeView.prototype.create = function () {
        this.setConfig("contentLeftPanel");
        _super.prototype.create.call(this);
        this.$tree = $('<div class="iiif-tree-component"></div>');
        this.$element.append(this.$tree);
    };
    TreeView.prototype.setup = function () {
        var _this = this;
        this.treeComponent = new TreeComponent_1.TreeComponent({
            target: this.$tree[0],
            data: this.treeData,
        });
        this.treeComponent.on("treeNodeSelected", function (node) {
            _this.extensionHost.publish(IIIFEvents_1.IIIFEvents.TREE_NODE_SELECTED, node);
        }, false);
        this.treeComponent.on("treeNodeMultiSelected", function (node) {
            _this.extensionHost.publish(IIIFEvents_1.IIIFEvents.TREE_NODE_MULTISELECTED, node);
        }, false);
    };
    TreeView.prototype.saveState = function () {
        var _this = this;
        var allNodes = this.treeComponent.getAllNodes();
        this.expandedNodeIds.clear();
        allNodes.forEach(function (node) {
            if (node.expanded) {
                _this.expandedNodeIds.add(node.id);
            }
        });
    };
    TreeView.prototype.restoreState = function () {
        var _this = this;
        var allNodes = this.treeComponent.getAllNodes();
        allNodes.forEach(function (node) {
            if (_this.expandedNodeIds.has(node.id)) {
                _this.treeComponent.expandNode(node, true);
            }
        });
    };
    TreeView.prototype.databind = function () {
        this.saveState();
        this.treeComponent.set(this.treeData);
        this.restoreState();
        this.resize();
    };
    TreeView.prototype.show = function () {
        this.isOpen = true;
        this.$element.show();
    };
    TreeView.prototype.hide = function () {
        this.isOpen = false;
        this.$element.hide();
    };
    TreeView.prototype.selectNode = function (node) {
        var _this = this;
        this.treeComponent.expandParents(node, true); // Expand node parents
        var link = this.$tree.find("#tree-link-" + node.id)[0];
        if (link) {
            //commented out as bug where scrolls to wrong node eg in Villanova collection
            // link.scrollIntoViewIfNeeded();
        }
        Promise.resolve().then(function () {
            _this.treeComponent.selectNode(node);
        });
    };
    TreeView.prototype.expandNode = function (node, expanded) {
        this.treeComponent.expandNode(node, expanded);
    };
    TreeView.prototype.getAllNodes = function () {
        return this.treeComponent.getAllNodes();
    };
    TreeView.prototype.deselectCurrentNode = function () {
        this.treeComponent.deselectCurrentNode();
    };
    TreeView.prototype.getNodeById = function (id) {
        return this.treeComponent.getNodeById(id);
    };
    TreeView.prototype.resize = function () {
        _super.prototype.resize.call(this);
    };
    return TreeView;
}(BaseView_1.BaseView));
exports.TreeView = TreeView;
//# sourceMappingURL=TreeView.js.map