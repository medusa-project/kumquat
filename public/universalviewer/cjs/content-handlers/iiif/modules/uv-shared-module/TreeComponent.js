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
exports.Events = exports.TreeComponent = void 0;
var manifesto_js_1 = require("manifesto.js");
var manifold_1 = require("@iiif/manifold");
var base_component_1 = require("@iiif/base-component");
var TreeComponent = /** @class */ (function (_super) {
    __extends(TreeComponent, _super);
    function TreeComponent(options) {
        var _this = _super.call(this, options) || this;
        _this._data = _this.data();
        _this._data = _this.options.data;
        _this._init();
        _this._resize();
        return _this;
    }
    TreeComponent.prototype._init = function () {
        _super.prototype._init.call(this);
        this._$element = $(this.el);
        var that = this;
        this._$tree = $('<ul class="tree"></ul>');
        this._$element.append(this._$tree);
        $.templates({
            pageTemplate: "{^{for nodes}}\
					{^{tree/}}\
				{{/for}}",
            treeTemplate: '<li dir={{>dir}}>\
						{^{if nodes && nodes.length}}\
							<div class="toggle" data-link="class{merge:expanded toggle=\'expanded\'}"></div>\
						{{else}}\
						<div class="spacer"></div>\
						{{/if}}\
						{^{if multiSelectEnabled}}\
							<input id="tree-checkbox-{{>id}}" type="checkbox" data-link="checked{:multiSelected ? \'checked\' : \'\'}" class="multiSelect" />\
						{{/if}}\
						{^{if selected}}\
							<a id="tree-link-{{>id}}" href="#" title="{{>label}}" class="selected">{{>label}}</a>\
						{{else}}\
							<a id="tree-link-{{>id}}" href="#" title="{{>label}}">{{>label}}</a>\
						{{/if}}\
				</li>\
				{^{if expanded}}\
					<li>\
							<ul>\
									{^{for nodes}}\
										{^{tree/}}\
									{{/for}}\
							</ul>\
					</li>\
				{{/if}}',
        });
        $.views.tags({
            tree: {
                toggleExpanded: function () {
                    var node = this.data;
                    that._setNodeExpanded(node, !node.expanded);
                },
                toggleMultiSelect: function () {
                    var node = this.data;
                    that._setNodeMultiSelected(node, !!!node.multiSelected);
                    if (node.isRange()) {
                        var multiSelectState = that._getMultiSelectState();
                        if (multiSelectState) {
                            multiSelectState.selectRange(node.data, node.multiSelected);
                        }
                    }
                    that.fire(Events.TREE_NODE_MULTISELECTED, node);
                },
                init: function (tagCtx, _linkCtx, _ctx) {
                    var data = tagCtx.view.data;
                    this.data = data;
                    data.dir = "ltr";
                    if (data.data.__jsonld && data.data.__jsonld.label) {
                        var lang = data.data.__jsonld.label["@language"];
                        if (lang && that._data.rtlLanguageCodes.includes(lang.trim())) {
                            data.dir = "rtl";
                        }
                    }
                },
                onAfterLink: function () {
                    var self = this;
                    self
                        .contents("li")
                        .first()
                        .on("click", ".toggle", function () {
                        self.toggleExpanded();
                    })
                        .on("click", "a", function (e) {
                        e.preventDefault();
                        var node = self.data;
                        if (node.nodes.length && that._data.branchNodesExpandOnClick) {
                            self.toggleExpanded();
                        }
                        if (node.multiSelectEnabled) {
                            self.toggleMultiSelect();
                        }
                        else {
                            if (!node.nodes.length) {
                                that.fire(Events.TREE_NODE_SELECTED, node);
                                that.selectNode(node);
                            }
                            else if (that._data.branchNodesSelectable) {
                                that.fire(Events.TREE_NODE_SELECTED, node);
                                that.selectNode(node);
                            }
                        }
                    })
                        .on("click", "input.multiSelect", function (e) {
                        self.toggleMultiSelect();
                    });
                },
                template: $.templates.treeTemplate,
            },
        });
        return true;
    };
    TreeComponent.prototype.set = function (data) {
        var _this = this;
        this._data = Object.assign(this._data, data);
        if (!this._data.helper) {
            return;
        }
        this._rootNode = this._data.helper.getTree(this._data.topRangeIndex, this._data.treeSortType);
        this._flattenedTree = null; // delete cache
        this._multiSelectableNodes = null; // delete cache
        this._$tree.link($.templates.pageTemplate, this._rootNode);
        var multiSelectState = this._getMultiSelectState();
        if (multiSelectState) {
            var _loop_1 = function (i) {
                var range = multiSelectState.ranges[i];
                var node = this_1._getMultiSelectableNodes().filter(function (n) { return n.data.id === range.id; })[0];
                if (node) {
                    this_1._setNodeMultiSelectEnabled(node, range.multiSelectEnabled);
                    this_1._setNodeMultiSelected(node, range.multiSelected);
                }
            };
            var this_1 = this;
            for (var i = 0; i < multiSelectState.ranges.length; i++) {
                _loop_1(i);
            }
        }
        if (this._data.autoExpand) {
            var allNodes = this.getAllNodes();
            allNodes.forEach(function (node, index) {
                //if (node.nodes && node.nodes.length) {
                _this._setNodeExpanded(node, true);
                //}
            });
        }
    };
    TreeComponent.prototype._getMultiSelectState = function () {
        if (this._data.helper) {
            return this._data.helper.getMultiSelectState();
        }
        return null;
    };
    TreeComponent.prototype.data = function () {
        return {
            autoExpand: false,
            branchNodesExpandOnClick: true,
            branchNodesSelectable: true,
            helper: null,
            topRangeIndex: 0,
            treeSortType: manifold_1.TreeSortType.NONE,
            rtlLanguageCodes: "ar, ara, dv, div, he, heb, ur, urd",
        };
    };
    TreeComponent.prototype.allNodesSelected = function () {
        var applicableNodes = this._getMultiSelectableNodes();
        var multiSelectedNodes = this.getMultiSelectedNodes();
        return applicableNodes.length === multiSelectedNodes.length;
    };
    TreeComponent.prototype._getMultiSelectableNodes = function () {
        var _this = this;
        // if cached
        if (this._multiSelectableNodes) {
            return this._multiSelectableNodes;
        }
        var allNodes = this.getAllNodes();
        if (allNodes) {
            return (this._multiSelectableNodes = allNodes.filter(function (n) {
                return _this._nodeIsMultiSelectable(n);
            }));
        }
        return [];
    };
    TreeComponent.prototype._nodeIsMultiSelectable = function (node) {
        if ((node.data.type === manifesto_js_1.TreeNodeType.MANIFEST &&
            node.nodes &&
            node.nodes.length > 0) ||
            node.data.type === manifesto_js_1.TreeNodeType.RANGE) {
            return true;
        }
        return false;
    };
    TreeComponent.prototype.getAllNodes = function () {
        // if cached
        if (this._flattenedTree) {
            return this._flattenedTree;
        }
        if (this._data.helper) {
            return (this._flattenedTree = this._data.helper.getFlattenedTree(this._rootNode));
        }
        return [];
    };
    TreeComponent.prototype.getMultiSelectedNodes = function () {
        var _this = this;
        return this.getAllNodes().filter(function (n) { return _this._nodeIsMultiSelectable(n) && n.multiSelected; });
    };
    TreeComponent.prototype.getNodeById = function (id) {
        return this.getAllNodes().filter(function (n) { return n.id === id; })[0];
    };
    TreeComponent.prototype.expandParents = function (node, expand) {
        if (!node || !node.parentNode)
            return;
        this._setNodeExpanded(node.parentNode, expand);
        this.expandParents(node.parentNode, expand);
    };
    TreeComponent.prototype._setNodeSelected = function (node, selected) {
        $.observable(node).setProperty("selected", selected);
    };
    TreeComponent.prototype._setNodeExpanded = function (node, expanded) {
        $.observable(node).setProperty("expanded", expanded);
    };
    TreeComponent.prototype._setNodeMultiSelected = function (node, selected) {
        $.observable(node).setProperty("multiSelected", selected);
    };
    TreeComponent.prototype._setNodeMultiSelectEnabled = function (node, enabled) {
        $.observable(node).setProperty("multiSelectEnabled", enabled);
    };
    TreeComponent.prototype.selectPath = function (path) {
        if (!this._rootNode)
            return;
        var pathArr = path.split("/");
        if (pathArr.length >= 1)
            pathArr.shift();
        var node = this.getNodeByPath(this._rootNode, pathArr);
        this.selectNode(node);
    };
    TreeComponent.prototype.deselectCurrentNode = function () {
        if (this.selectedNode)
            this._setNodeSelected(this.selectedNode, false);
    };
    TreeComponent.prototype.selectNode = function (node) {
        if (!this._rootNode)
            return;
        this.deselectCurrentNode();
        this.selectedNode = node;
        this._setNodeSelected(this.selectedNode, true);
    };
    TreeComponent.prototype.expandNode = function (node, expanded) {
        if (!this._rootNode)
            return;
        this._setNodeExpanded(node, expanded);
    };
    // walks down the tree using the specified path e.g. [2,2,0]
    TreeComponent.prototype.getNodeByPath = function (parentNode, path) {
        if (path.length === 0)
            return parentNode;
        var index = Number(path.shift());
        var node = parentNode.nodes[index];
        return this.getNodeByPath(node, path);
    };
    TreeComponent.prototype.show = function () {
        this._$element.show();
    };
    TreeComponent.prototype.hide = function () {
        this._$element.hide();
    };
    TreeComponent.prototype._resize = function () { };
    return TreeComponent;
}(base_component_1.BaseComponent));
exports.TreeComponent = TreeComponent;
var Events = /** @class */ (function () {
    function Events() {
    }
    Events.TREE_NODE_MULTISELECTED = "treeNodeMultiSelected";
    Events.TREE_NODE_SELECTED = "treeNodeSelected";
    return Events;
}());
exports.Events = Events;
//# sourceMappingURL=TreeComponent.js.map