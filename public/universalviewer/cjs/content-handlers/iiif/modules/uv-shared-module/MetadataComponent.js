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
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.Events = exports.MetadataComponent = exports.LimitType = void 0;
var manifesto_js_1 = require("manifesto.js");
var base_component_1 = require("@iiif/base-component");
var Utils_1 = require("../../Utils");
var toggleExpandTextByLines_1 = __importDefault(require("./toggleExpandTextByLines"));
var LimitType;
(function (LimitType) {
    LimitType["LINES"] = "lines";
    LimitType["CHARS"] = "chars";
})(LimitType || (exports.LimitType = LimitType = {}));
var MetadataComponent = /** @class */ (function (_super) {
    __extends(MetadataComponent, _super);
    function MetadataComponent(options) {
        var _this = _super.call(this, options) || this;
        _this._data = _this.data();
        _this._data = _this.options.data;
        _this._init();
        _this._resize();
        return _this;
    }
    MetadataComponent.prototype._init = function () {
        _super.prototype._init.call(this);
        this._$element = $(this.el);
        this._$metadataGroupTemplate = $('<div class="group">\
          <div class="header"></div>\
          <div class="items"></div>\
      </div>');
        this._$metadataItemTemplate = $('<div class="item">\
          <div class="label"></div>\
          <div class="values"></div>\
      </div>');
        this._$metadataItemValueTemplate = $('<div class="value"></div>');
        this._$metadataItemURIValueTemplate = $('<a class="value" href="" target="_blank"></a>');
        this._$copyTextTemplate = $('<div class="copyText" alt="' +
            this.options.data.content.copyToClipboard +
            '" title="' +
            this.options.data.content.copyToClipboard +
            '">\
        <div class="copiedText">' +
            this.options.data.content.copiedToClipboard +
            " </div>\
        </div>");
        this._$metadataGroups = $('<div class="groups"></div>');
        this._$element.append(this._$metadataGroups);
        this._$noData = $('<div class="noData">' + this.options.data.content.noData + "</div>");
        this._$element.append(this._$noData);
        return true;
    };
    MetadataComponent.prototype.data = function () {
        return {
            aggregateValues: "",
            canvases: null,
            canvasDisplayOrder: "",
            metadataGroupOrder: "",
            canvasExclude: "",
            canvasLabels: "",
            content: {
                attribution: "Attribution",
                canvasHeader: "About the canvas",
                copiedToClipboard: "Copied to clipboard",
                copyToClipboard: "Copy to clipboard",
                description: "Description",
                imageHeader: "About the image",
                less: "less",
                lessAriaLabelTemplate: "Less information: Hide {0}",
                license: "License",
                rights: "Rights",
                logo: "Logo",
                manifestHeader: "About the item",
                more: "more",
                moreAriaLabelTemplate: "More information: Reveal {0}",
                noData: "No data to display",
                rangeHeader: "About the range",
                sequenceHeader: "About the sequence",
            },
            copiedMessageDuration: 2000,
            copyToClipboardEnabled: false,
            helper: null,
            licenseFormatter: null,
            limit: 4,
            limitType: LimitType.LINES,
            limitToRange: false,
            manifestDisplayOrder: "",
            manifestExclude: "",
            range: null,
            rtlLanguageCodes: "ar, ara, dv, div, he, heb, ur, urd",
            sanitizer: function (html) {
                return html;
            },
            showAllLanguages: false,
        };
    };
    MetadataComponent.prototype._getManifestGroup = function () {
        return this._metadataGroups.filter(function (x) { return x.resource.isManifest(); })[0];
    };
    MetadataComponent.prototype._getCanvasGroups = function () {
        return this._metadataGroups.filter(function (x) { return x.resource.isCanvas(); });
    };
    MetadataComponent.prototype.set = function (data) {
        var _this = this;
        this._data = Object.assign(this._data, data);
        if (!this._data || !this._data.helper) {
            return;
        }
        var options = {
            canvases: this._data.canvases,
            licenseFormatter: this._data.licenseFormatter,
            range: this._data.range,
        };
        this._metadataGroups = this._data.helper.getMetadata(options);
        if (this._data.manifestDisplayOrder) {
            var manifestGroup = this._getManifestGroup();
            manifestGroup.items = this._sortItems(manifestGroup.items, this._readCSV(this._data.manifestDisplayOrder));
        }
        if (this._data.canvasDisplayOrder) {
            var canvasGroups = this._getCanvasGroups();
            canvasGroups.forEach(function (canvasGroup, index) {
                canvasGroup.items = _this._sortItems(canvasGroup.items, _this._readCSV(_this._data.canvasDisplayOrder));
            });
        }
        if (this._data.metadataGroupOrder) {
            this._metadataGroups = this._sortGroups(this._metadataGroups, this._readCSV(this._data.metadataGroupOrder));
        }
        if (this._data.canvasLabels) {
            this._label(this._getCanvasGroups(), this._readCSV(this._data.canvasLabels, false));
        }
        if (this._data.manifestExclude) {
            var manifestGroup = this._getManifestGroup();
            manifestGroup.items = this._exclude(manifestGroup.items, this._readCSV(this._data.manifestExclude));
        }
        if (this._data.canvasExclude) {
            var canvasGroups = this._getCanvasGroups();
            canvasGroups.forEach(function (canvasGroup, _index) {
                canvasGroup.items = _this._exclude(canvasGroup.items, _this._readCSV(_this._data.canvasExclude));
            });
        }
        if (this._data.limitToRange) {
            var newGroups_1 = [];
            this._metadataGroups.forEach(function (group, _index) {
                if (group.resource.isRange()) {
                    newGroups_1.push(group);
                }
            });
            if (newGroups_1.length) {
                this._metadataGroups = newGroups_1;
            }
        }
        this._render();
    };
    MetadataComponent.prototype._sortItems = function (items, displayOrder) {
        var _this = this;
        var sorted = [];
        var unsorted = items.slice(0);
        displayOrder.forEach(function (item, index) {
            var match = unsorted.filter(function (x) { return _this._normalise(x.getLabel()) === item; })[0];
            if (match) {
                sorted.push(match);
                var index_1 = unsorted.indexOf(match);
                if (index_1 > -1) {
                    unsorted.splice(index_1, 1);
                }
            }
        });
        // add remaining items that were not in the displayOrder.
        unsorted.forEach(function (item, index) {
            sorted.push(item);
        });
        return sorted;
    };
    MetadataComponent.prototype._sortGroups = function (groups, metadataGroupOrder) {
        var sorted = [];
        var unsorted = groups.slice(0);
        metadataGroupOrder.forEach(function (group, index) {
            var match = unsorted.filter(function (x) {
                return x.resource.getIIIFResourceType().toLowerCase() == group.toLowerCase();
            })[0];
            if (match) {
                sorted.push(match);
                var index_2 = unsorted.indexOf(match);
                if (index_2 > -1) {
                    unsorted.splice(index_2, 1);
                }
            }
        });
        return sorted;
    };
    MetadataComponent.prototype._label = function (groups, labels) {
        groups.forEach(function (group, index) {
            group.label = labels[index];
        });
    };
    MetadataComponent.prototype._exclude = function (items, excludeConfig) {
        var _this = this;
        excludeConfig.forEach(function (item, index) {
            var match = items.filter(function (x) { return _this._normalise(x.getLabel()) === item; })[0];
            if (match) {
                var index_3 = items.indexOf(match);
                if (index_3 > -1) {
                    items.splice(index_3, 1);
                }
            }
        });
        return items;
    };
    // private _flatten(items: MetadataItem[]): MetadataItem[] {
    //     // flatten metadata into array.
    //     var flattened: MetadataItem[] = [];
    //     items.forEach(item: any, index: number) => {
    //         if (Array.isArray(item.value)){
    //             flattened = flattened.concat(<MetadataItem[]>item.value);
    //         } else {
    //             flattened.push(item);
    //         }
    //     });
    //     return flattened;
    // }
    // merge any duplicate items into canvas metadata
    // todo: needs to be more generic taking a single concatenated array
    // private _aggregate(manifestMetadata: any[], canvasMetadata: any[]) {
    //     if (this._aggregateValues.length) {
    //         canvasMetadata.forEach((canvasItem: any, index: number) => {
    //             this._aggregateValues.forEach((value: string, index: number) => {
    //                 value = this._normalise(value);
    //                 if (this._normalise(canvasItem.label) === value) {
    //                     var manifestItem = manifestMetadata.filter(x => this._normalise(x.label) === value)[0];
    //                     if (manifestItem) {
    //                         canvasItem.value = manifestItem.value + canvasItem.value;
    //                         manifestMetadata.remove(manifestItem);
    //                     }
    //                 }
    //             });
    //         });
    //     }
    // }
    MetadataComponent.prototype._normalise = function (value) {
        if (value) {
            return value.toLowerCase().replace(/ /g, "");
        }
        return null;
    };
    MetadataComponent.prototype._render = function () {
        var _this = this;
        if (!this._metadataGroups.length) {
            this._$noData.show();
            return;
        }
        this._$noData.hide();
        this._$metadataGroups.empty();
        this._metadataGroups.forEach(function (metadataGroup, index) {
            var $metadataGroup = _this._buildMetadataGroup(metadataGroup);
            _this._$metadataGroups.append($metadataGroup);
            var $value = $metadataGroup.find(".value");
            var $items = $metadataGroup.find(".item");
            if (_this._data.limit && _this._data.content) {
                if (_this._data.limitType === LimitType.LINES) {
                    var args_1 = [
                        $items,
                        _this._data.limit,
                        _this._data.content.less,
                        _this._data.content.more,
                        function () { },
                        _this._data.content.lessAriaLabelTemplate,
                        _this._data.content.moreAriaLabelTemplate,
                    ];
                    // allow time for the sidebar to render
                    setTimeout(function () {
                        toggleExpandTextByLines_1.default.apply(_this, args_1);
                    }, 100);
                }
                else if (_this._data.limitType === LimitType.CHARS) {
                    $value.ellipsisHtmlFixed(_this._data.limit, function () { });
                }
            }
        });
    };
    MetadataComponent.prototype._buildMetadataGroup = function (metadataGroup) {
        var $metadataGroup = this._$metadataGroupTemplate.clone();
        var $header = $metadataGroup.find(">.header");
        if (this._data.content) {
            // add group header
            if (metadataGroup.resource.isManifest() &&
                this._data.content.manifestHeader) {
                var text = this._sanitize(this._data.content.manifestHeader);
                if (text) {
                    $header.html(text);
                }
            }
            else if (metadataGroup.resource.isSequence() &&
                this._data.content.sequenceHeader) {
                var text = this._sanitize(this._data.content.sequenceHeader);
                if (text) {
                    $header.html(text);
                }
            }
            else if (metadataGroup.resource.isRange() &&
                this._data.content.rangeHeader) {
                var text = this._sanitize(this._data.content.rangeHeader);
                if (text) {
                    $header.html(text);
                }
            }
            else if (metadataGroup.resource.isCanvas() &&
                (metadataGroup.label || this._data.content.canvasHeader)) {
                var header = metadataGroup.label || this._data.content.canvasHeader;
                $header.html(this._sanitize(header));
            }
            else if (metadataGroup.resource.isAnnotation() &&
                this._data.content.imageHeader) {
                var text = this._sanitize(this._data.content.imageHeader);
                if (text) {
                    $header.html(text);
                }
            }
        }
        if (!$header.text()) {
            $header.hide();
        }
        var $items = $metadataGroup.find(".items");
        for (var i = 0; i < metadataGroup.items.length; i++) {
            var item = metadataGroup.items[i];
            var $metadataItem = this._buildMetadataItem(item);
            $items.append($metadataItem);
        }
        return $metadataGroup;
    };
    MetadataComponent.prototype._buildMetadataItem = function (item) {
        var _a;
        var $metadataItem = this._$metadataItemTemplate.clone();
        var $label = $metadataItem.find(".label");
        var $values = $metadataItem.find(".values");
        var originalLabel = item.getLabel();
        var label = originalLabel;
        var urlPattern = new RegExp("/w+:(/?/?)[^s]+/gm", "i");
        if (this._data.content && label && item.isRootLevel) {
            switch (label.toLowerCase()) {
                case "attribution":
                    label = this._data.content.attribution;
                    break;
                case "description":
                    label = this._data.content.description;
                    break;
                case "license":
                    label = this._data.content.license;
                    break;
                case "logo":
                    label = this._data.content.logo;
                    break;
                case "rights":
                    label = this._data.content.rights;
                    break;
            }
        }
        label = this._sanitize(label);
        $label.html(label);
        // rtl?
        this._addReadingDirection($label, this._getLabelLocale(item));
        $metadataItem.addClass(Utils_1.Strings.toCssClass(label));
        var $value;
        var valueLocale = this._getValueLocale(item);
        var metadataItemValue = (_a = item.value) === null || _a === void 0 ? void 0 : _a.getValue(valueLocale);
        // if the value is a URI
        if (originalLabel &&
            (originalLabel.toLowerCase() === "license" ||
                originalLabel.toLowerCase() === "rights") &&
            urlPattern.exec(metadataItemValue) !== null) {
            $value = this._buildMetadataItemURIValue(metadataItemValue);
            $values.append($value);
        }
        else {
            if (this._data.showAllLanguages && item.value && item.value.length > 1) {
                var localesChecked = [];
                for (var i = 0; i < item.value.length; i++) {
                    var locale = item.value[i]._locale;
                    if (locale && !localesChecked.includes(locale)) {
                        var localizedValue = item.getValue(locale, "<br/>");
                        if (localizedValue) {
                            $value = this._buildMetadataItemValue(localizedValue, locale);
                            localesChecked.push(locale);
                            $values.append($value);
                        }
                    }
                }
            }
            else {
                var valueLocale_1 = this._getValueLocale(item);
                var valueFound = false;
                var values = item.getValues(valueLocale_1);
                for (var _i = 0, values_1 = values; _i < values_1.length; _i++) {
                    var value = values_1[_i];
                    if (value) {
                        valueFound = true;
                        $value = this._buildMetadataItemValue(value, valueLocale_1);
                        $values.append($value);
                    }
                }
                // if no values were found in the current locale, default to the first.
                if (!valueFound) {
                    var value = item.getValue();
                    if (value) {
                        $value = this._buildMetadataItemValue(value, valueLocale_1);
                        $values.append($value);
                    }
                }
            }
        }
        if (this._data.copyToClipboardEnabled &&
            Utils_1.Clipboard.supportsCopy() &&
            $label.text()) {
            this._addCopyButton($metadataItem, $label, $values);
        }
        var that = this;
        if ($metadataItem.find("a.iiif-viewer-link").length > 0) {
            $metadataItem.on("click", "a.iiif-viewer-link", function (e) {
                e.preventDefault();
                var $a = $(e.target);
                var href = $a.attr("data-uv-navigate") || $a.prop("href");
                that.fire(Events.IIIF_VIEWER_LINK_CLICKED, href);
            });
        }
        if ($metadataItem.find("[data-uv-navigate]").length > 0) {
            $metadataItem.on("click", "[data-uv-navigate]", function (e) {
                e.preventDefault();
                var $a = $(e.target);
                var href = $a.attr("data-uv-navigate") || null;
                if (href) {
                    that.fire(Events.IIIF_VIEWER_LINK_CLICKED, href);
                }
            });
        }
        return $metadataItem;
    };
    MetadataComponent.prototype._getLabelLocale = function (item) {
        var _a;
        if (!this._data || !this._data.helper) {
            return "";
        }
        var defaultLocale = this._data.helper.options.locale;
        if ((_a = item.label) === null || _a === void 0 ? void 0 : _a.length) {
            var labelLocale = item.label[0].locale;
            if (labelLocale.toLowerCase() !== defaultLocale.toLowerCase()) {
                return labelLocale;
            }
        }
        return defaultLocale;
    };
    MetadataComponent.prototype._getValueLocale = function (item) {
        if (!this._data || !this._data.helper) {
            return "";
        }
        var defaultLocale = this._data.helper.options.locale;
        // if (item.value.length) {
        //     const valueLocale: string = item.value[0].locale;
        //     if (valueLocale.toLowerCase() !== defaultLocale.toLowerCase()) {
        //         return valueLocale;
        //     }
        // }
        return defaultLocale;
    };
    MetadataComponent.prototype._buildMetadataItemValue = function (value, locale) {
        value = this._sanitize(value);
        value = value.replace("\n", "<br>"); // replace \n with <br>
        var $value = this._$metadataItemValueTemplate.clone();
        $value.html(value);
        // loop through values looking for links with iiif-viewer-link class
        // if found, add click handler
        $value.find("a").each(function () {
            var $a = $(this);
            if (!$a.hasClass("iiif-viewer-link")) {
                $a.prop("target", "_blank");
            }
        });
        // add language attribute and handle rtl
        if (locale) {
            $value.prop("lang", locale);
            this._addReadingDirection($value, locale);
        }
        return $value;
    };
    MetadataComponent.prototype._buildMetadataItemURIValue = function (value) {
        value = this._sanitize(value);
        var $value = this._$metadataItemURIValueTemplate.clone();
        $value.prop("href", value);
        $value.text(value);
        return $value;
    };
    MetadataComponent.prototype._addReadingDirection = function ($elem, locale) {
        locale = manifesto_js_1.Utils.getInexactLocale(locale);
        var rtlLanguages = this._readCSV(this._data.rtlLanguageCodes);
        var match = rtlLanguages.filter(function (x) { return x === locale; }).length > 0;
        if (match) {
            $elem.prop("dir", "rtl");
            $elem.addClass("rtl");
        }
    };
    MetadataComponent.prototype._addCopyButton = function ($elem, $header, $values) {
        var $copyBtn = this._$copyTextTemplate.clone();
        var $copiedText = $copyBtn.children();
        $header.append($copyBtn);
        if (Utils_1.Device.isTouch()) {
            $copyBtn.show();
        }
        else {
            $elem.on("mouseenter", function () {
                $copyBtn.show();
            });
            $elem.on("mouseleave", function () {
                $copyBtn.hide();
            });
            $copyBtn.on("mouseleave", function () {
                $copiedText.hide();
            });
        }
        var that = this;
        var originalValue = $values.text();
        $copyBtn.on("click", function (e) {
            that._copyItemValues($copyBtn, originalValue);
        });
    };
    MetadataComponent.prototype._copyItemValues = function ($copyButton, originalValue) {
        Utils_1.Clipboard.copy(originalValue);
        var $copiedText = $copyButton.find(".copiedText");
        $copiedText.show();
        setTimeout(function () {
            $copiedText.hide();
        }, this._data.copiedMessageDuration);
    };
    MetadataComponent.prototype._readCSV = function (config, normalise) {
        if (normalise === void 0) { normalise = true; }
        var csv = [];
        if (config) {
            csv = config.split(",");
            if (normalise) {
                for (var i = 0; i < csv.length; i++) {
                    csv[i] = this._normalise(csv[i]);
                }
            }
        }
        return csv;
    };
    MetadataComponent.prototype._sanitize = function (html) {
        if (this._data.sanitizer) {
            return this._data.sanitizer(html);
        }
        return null;
    };
    MetadataComponent.prototype._resize = function () { };
    return MetadataComponent;
}(base_component_1.BaseComponent));
exports.MetadataComponent = MetadataComponent;
var Events = /** @class */ (function () {
    function Events() {
    }
    Events.IIIF_VIEWER_LINK_CLICKED = "iiifViewerLinkClicked";
    return Events;
}());
exports.Events = Events;
//# sourceMappingURL=MetadataComponent.js.map