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
exports.GalleryComponent = void 0;
var vocabulary_1 = require("@iiif/vocabulary");
var base_component_1 = require("@iiif/base-component");
var Utils_1 = require("../../Utils");
var GalleryComponent = /** @class */ (function (_super) {
    __extends(GalleryComponent, _super);
    function GalleryComponent(options) {
        var _this = _super.call(this, options) || this;
        _this._data = _this.data();
        _this._escapeHtml = function (text) {
            return String(text)
                .replace(/&/g, "&amp;") // Escape '&' first to avoid double escaping
                .replace(/</g, "&lt;") // Escape '<'
                .replace(/>/g, "&gt;") // Escape '>'
                .replace(/"/g, "&quot;") // Escape '"'
                .replace(/'/g, "&#039;"); // Escape "'"
        };
        _this._galleryThumbsTemplate = function (thumb) {
            var multiSelectEnabled = thumb.multiSelectEnabled;
            var galleryThumbClassName = _this._escapeHtml(_this._galleryThumbClassName(thumb));
            var label = _this._escapeHtml(thumb.label);
            var uri = _this._escapeHtml(thumb.uri);
            var index = _this._escapeHtml(thumb.index);
            var visible = _this._escapeHtml(thumb.visible);
            var width = _this._escapeHtml(thumb.width);
            var height = _this._escapeHtml(thumb.height);
            var initialWidth = _this._escapeHtml(thumb.initialWidth);
            var initialHeight = _this._escapeHtml(thumb.initialHeight);
            var searchResults = _this._escapeHtml(thumb.data.searchResults || "");
            var searchResultsTitle = _this._escapeHtml(_this._galleryThumbSearchResultsTitle(thumb) || "");
            var htmlTemplate = "\n      <button class=\"".concat(galleryThumbClassName, "\" \n              data-src=\"").concat(uri, "\" \n              data-index=\"").concat(index, "\" \n              data-visible=\"").concat(visible, "\" \n              data-width=\"").concat(width, "\" \n              data-height=\"").concat(height, "\" \n              data-initialwidth=\"").concat(initialWidth, "\" \n              data-initialheight=\"").concat(initialHeight, "\">\n        <div class=\"wrap\" \n             style=\"width:").concat(initialWidth, "px; height:").concat(initialHeight, "px\">\n          ").concat(multiSelectEnabled
                ? "\n          <input id=\"thumb-checkbox-".concat(index, "\" \n                 tabindex=\"-1\" \n                 type=\"checkbox\" \n                 class=\"multiSelect\" />")
                : "", "\n        </div>\n        <div class=\"info\">\n          <span class=\"index\" style=\"width:").concat(initialWidth, "px\">").concat(index, "</span>\n          <span class=\"label\" style=\"width:").concat(initialWidth, "px\" title=\"").concat(label, "\">").concat(label, "</span>\n          <span class=\"searchResults\" \n                title=\"").concat(searchResultsTitle, "\">\n            ").concat(searchResults, "\n          </span>\n        </div>\n      </button>\n    ");
            return htmlTemplate;
        };
        _this._galleryThumbClassName = function (thumb) {
            var className = "thumb preLoad";
            if (thumb.index === 0) {
                className += " first";
            }
            if (!thumb.uri) {
                className += " placeholder";
            }
            return className;
        };
        _this._galleryThumbSearchResultsTitle = function (thumb) {
            var searchResults = Number(thumb.data.searchResults);
            if (searchResults) {
                if (searchResults > 1) {
                    return Utils_1.Strings.format(_this.options.data.content.searchResults, searchResults.toString());
                }
                return Utils_1.Strings.format(_this.options.data.content.searchResults, searchResults.toString());
            }
            return null;
        };
        _this._data = _this.options.data;
        _this._init();
        _this._resize();
        return _this;
    }
    GalleryComponent.prototype._init = function () {
        var _this = this;
        _super.prototype._init.call(this);
        this._$element = $(this.el);
        this._$header = $('<div class="header"></div>');
        this._$element.append(this._$header);
        this._$leftOptions = $('<div class="left"></div>');
        this._$header.append(this._$leftOptions);
        this._$rightOptions = $('<div class="right"></div>');
        this._$header.append(this._$rightOptions);
        this._$sizeDownButton = $('<input class="btn btn-default size-down" type="button" value="-" />');
        this._$leftOptions.append(this._$sizeDownButton);
        this._$sizeRange = $('<input type="range" name="size" min="1" max="10" value="' +
            this.options.data.initialZoom +
            '" />');
        this._$leftOptions.append(this._$sizeRange);
        this._$sizeUpButton = $('<input class="btn btn-default size-up" type="button" value="+" />');
        this._$leftOptions.append(this._$sizeUpButton);
        this._$multiSelectOptions = $('<div class="multiSelectOptions"></div>');
        this._$rightOptions.append(this._$multiSelectOptions);
        this._$selectAllButton = $('<div class="multiSelectAll"><input id="multiSelectAll" type="checkbox" tabindex="0" /><label for="multiSelectAll">' +
            this.options.data.content.selectAll +
            "</label></div>");
        this._$multiSelectOptions.append(this._$selectAllButton);
        this._$selectAllButtonCheckbox = $(this._$selectAllButton.find("input:checkbox"));
        this._$downloadButton = $('<a class="download" href="#">' +
            this.options.data.content.download +
            "</a>");
        this._$multiSelectOptions.append(this._$downloadButton);
        this._$main = $('<div class="main"></div>');
        this._$element.append(this._$main);
        this._$thumbs = $('<div class="thumbs"></div>');
        this._$main.append(this._$thumbs);
        this._$sizeDownButton.on("click", function () {
            var val = Number(_this._$sizeRange.val()) - 1;
            if (val >= Number(_this._$sizeRange.attr("min"))) {
                _this._$sizeRange.val(val.toString());
                _this._$sizeRange.trigger("change");
                _this.fire(Events.DECREASE_SIZE);
            }
        });
        this._$sizeUpButton.on("click", function () {
            var val = Number(_this._$sizeRange.val()) + 1;
            if (val <= Number(_this._$sizeRange.attr("max"))) {
                _this._$sizeRange.val(val.toString());
                _this._$sizeRange.trigger("change");
                _this.fire(Events.INCREASE_SIZE);
            }
        });
        this._$sizeRange.on("change", function () {
            _this._updateThumbs();
            _this._scrollToThumb(_this._getSelectedThumbIndex());
        });
        this._$selectAllButton.checkboxButton(function (checked) {
            var multiSelectState = _this._getMultiSelectState();
            if (multiSelectState) {
                if (checked) {
                    multiSelectState.selectAll(true);
                }
                else {
                    multiSelectState.selectAll(false);
                }
            }
            _this.set(_this.options.data);
        });
        this._$downloadButton.on("click", function () {
            var multiSelectState = _this._getMultiSelectState();
            if (multiSelectState) {
                var ids = multiSelectState
                    .getAllSelectedCanvases()
                    .map(function (canvas) {
                    return canvas.id;
                });
                _this.fire(Events.MULTISELECTION_MADE, ids);
            }
        });
        this._setRange();
        // use unevent to detect scroll stop.
        this._$main.on("scroll", function () {
            _this._updateThumbs();
        }, this.options.data.scrollStopDuration);
        if (!this.options.data.sizingEnabled) {
            this._$sizeRange.hide();
        }
        return true;
    };
    GalleryComponent.prototype.data = function () {
        return {
            chunkedResizingThreshold: 400,
            content: {
                searchResult: "{0} search result",
                searchResults: "{0} search results",
            },
            debug: false,
            helper: null,
            imageFadeInDuration: 300,
            initialZoom: 6,
            minLabelWidth: 20,
            pageModeEnabled: false,
            scrollStopDuration: 100,
            searchResults: [],
            sizingEnabled: true,
            thumbHeight: 320,
            thumbLoadPadding: 3,
            thumbWidth: 200,
            viewingDirection: vocabulary_1.ViewingDirection.LEFT_TO_RIGHT,
        };
    };
    GalleryComponent.prototype.set = function (data) {
        this._data = Object.assign(this._data, data);
        if (this._data.helper &&
            this._data.thumbWidth !== undefined &&
            this._data.thumbHeight !== undefined) {
            this._thumbs = (this._data.helper.getThumbs(this._data.thumbWidth, this._data.thumbHeight));
        }
        if (this._data.viewingDirection) {
            if (this._data.viewingDirection === vocabulary_1.ViewingDirection.BOTTOM_TO_TOP) {
                this._thumbs.reverse();
            }
            this._$thumbs.addClass(this._data.viewingDirection); // defaults to "left-to-right"
        }
        if (this._data.searchResults && this._data.searchResults.length) {
            for (var i = 0; i < this._data.searchResults.length; i++) {
                var searchResult = this._data.searchResults[i];
                // find the thumb with the same canvasIndex and add the searchResult
                var thumb = this._thumbs.filter(function (t) { return t.index === searchResult.canvasIndex; })[0];
                // clone the data so searchResults isn't persisted on the canvas.
                var data_1 = $.extend(true, {}, thumb.data);
                data_1.searchResults = searchResult.rects.length;
                thumb.data = data_1;
            }
        }
        this._thumbsCache = null; // delete cache
        this._createThumbs();
        if (this._data.helper) {
            this.selectIndex(this._data.helper.canvasIndex);
        }
        var multiSelectState = this._getMultiSelectState();
        if (multiSelectState && multiSelectState.isEnabled) {
            this._$multiSelectOptions.show();
            this._$thumbs.addClass("multiSelect");
            for (var i = 0; i < multiSelectState.canvases.length; i++) {
                var canvas = multiSelectState.canvases[i];
                var thumb = this._getThumbByCanvas(canvas);
                this._updateThumbHtmlMultiSelected(thumb.index, canvas.multiSelected);
            }
            // range selections override canvas selections
            for (var i = 0; i < multiSelectState.ranges.length; i++) {
                var range = multiSelectState.ranges[i];
                var thumbs = this._getThumbsByRange(range);
                for (var i_1 = 0; i_1 < thumbs.length; i_1++) {
                    var thumb = thumbs[i_1];
                    this._updateThumbHtmlMultiSelected(thumb.index, range.multiSelected);
                }
            }
        }
        else {
            this._$multiSelectOptions.hide();
            this._$thumbs.removeClass("multiSelect");
        }
        // this._update();
    };
    GalleryComponent.prototype._update = function () {
        var multiSelectState = this._getMultiSelectState();
        if (multiSelectState && multiSelectState.isEnabled) {
            // check/uncheck Select All checkbox
            this._$selectAllButtonCheckbox.prop("checked", multiSelectState.allSelected());
            var anySelected = multiSelectState.getAll().filter(function (t) { return t.multiSelected; }).length > 0;
            if (!anySelected) {
                this._$downloadButton.hide();
            }
            else {
                this._$downloadButton.show();
            }
        }
    };
    GalleryComponent.prototype._getMultiSelectState = function () {
        if (this._data.helper) {
            return this._data.helper.getMultiSelectState();
        }
        return null;
    };
    GalleryComponent.prototype._createThumbs = function () {
        var that = this;
        if (!this._thumbs)
            return;
        this._$thumbs.undelegate(".thumb", "click");
        this._$thumbs.empty();
        var multiSelectState = this._getMultiSelectState();
        // set initial thumb sizes
        var heights = [];
        for (var i_2 = 0; i_2 < this._thumbs.length; i_2++) {
            var thumb = this._thumbs[i_2];
            var initialWidth = thumb.width;
            var initialHeight = thumb.height;
            thumb.initialWidth = initialWidth;
            //thumb.initialHeight = initialHeight;
            heights.push(initialHeight);
            thumb.multiSelectEnabled = multiSelectState
                ? multiSelectState.isEnabled
                : false;
        }
        var medianHeight = Utils_1.Maths.median(heights);
        for (var i_3 = 0; i_3 < this._thumbs.length; i_3++) {
            var thumb = this._thumbs[i_3];
            thumb.initialHeight = medianHeight;
        }
        var renderedHtml = this._thumbs.map(this._galleryThumbsTemplate).join("");
        this._$thumbs.html(renderedHtml);
        if (multiSelectState && !multiSelectState.isEnabled) {
            // add a selection click event to all thumbs
            this._$thumbs.delegate(".thumb", "click", function (e) {
                var thumbIndex = parseInt(this.dataset.index);
                var thumb = that._thumbs[thumbIndex];
                that.fire(Events.THUMB_SELECTED, thumb);
            });
        }
        else {
            // make each thumb a checkboxButton
            var thumbs = this._$thumbs.find(".thumb");
            var _loop_1 = function () {
                var that_1 = this_1;
                var $thumb = $(thumbs[i]);
                $thumb.checkboxButton(function (_checked) {
                    var thumbIndex = parseInt(this.dataset.index);
                    var thumb = that_1._thumbs[thumbIndex];
                    var multiSelected = that_1._getThumbMultiSelected(thumbIndex);
                    that_1._updateThumbHtmlMultiSelected(thumb.index, multiSelected);
                    var range = (that_1.options.data.helper.getCanvasRange(thumb.data));
                    var multiSelectState = that_1._getMultiSelectState();
                    if (multiSelectState) {
                        if (range) {
                            multiSelectState.selectRange(range, multiSelected);
                        }
                        else {
                            multiSelectState.selectCanvas(thumb.data, multiSelected);
                        }
                    }
                    that_1._update();
                    that_1.fire(Events.THUMB_MULTISELECTED, thumb);
                });
            };
            var this_1 = this;
            for (var i = 0; i < thumbs.length; i++) {
                _loop_1();
            }
        }
    };
    GalleryComponent.prototype._getThumbMultiSelected = function (thumbIndex) {
        var $checkbox = this._getThumbByIndex(thumbIndex).find("#thumb-checkbox-".concat(thumbIndex));
        return $checkbox.prop("checked");
    };
    GalleryComponent.prototype._getThumbByCanvas = function (canvas) {
        return this._thumbs.filter(function (c) { return c.data.id === canvas.id; })[0];
    };
    GalleryComponent.prototype._sizeThumb = function ($thumb) {
        var initialWidth = $thumb.data().initialwidth;
        var initialHeight = $thumb.data().initialheight;
        var width = Number(initialWidth);
        var height = Number(initialHeight);
        var newWidth = Math.floor(width * this._range);
        var newHeight = Math.floor(height * this._range);
        var $wrap = $thumb.find(".wrap");
        var $label = $thumb.find(".label");
        var $index = $thumb.find(".index");
        var $searchResults = $thumb.find(".searchResults");
        var newLabelWidth = newWidth;
        // if search results are visible, size index/label to accommodate it.
        // if the resulting size is below options.minLabelWidth, hide search results.
        if (this._data.searchResults && this._data.searchResults.length) {
            $searchResults.show();
            newLabelWidth = newWidth - $searchResults.outerWidth();
            if (this._data.minLabelWidth !== undefined &&
                newLabelWidth < this._data.minLabelWidth) {
                $searchResults.hide();
                newLabelWidth = newWidth;
            }
            else {
                $searchResults.show();
            }
        }
        if (this._data.pageModeEnabled) {
            $index.hide();
            $label.show();
        }
        else {
            $index.show();
            $label.hide();
        }
        $wrap.outerWidth(newWidth);
        $wrap.outerHeight(newHeight);
        $index.outerWidth(newLabelWidth);
        $label.outerWidth(newLabelWidth);
    };
    GalleryComponent.prototype._loadThumb = function ($thumb, cb) {
        var $wrap = $thumb.find(".wrap");
        if ($wrap.hasClass("loading") || $wrap.hasClass("loaded"))
            return;
        $thumb.removeClass("preLoad");
        // if no img has been added yet
        var visible = $thumb.attr("data-visible");
        var fadeDuration = this._data.imageFadeInDuration || 0;
        if (visible !== "false") {
            $wrap.addClass("loading");
            var src = $thumb.attr("data-src");
            var $img = $('<img class="thumbImage" src="' + src + '" />');
            // fade in on load.
            $img.hide();
            $img.on("load", function () {
                $(this).fadeIn(fadeDuration, function () {
                    $(this).parent().switchClass("loading", "loaded");
                });
            });
            $wrap.prepend($img);
            if (cb)
                cb($img);
        }
        else {
            $wrap.addClass("hidden");
        }
    };
    GalleryComponent.prototype._getThumbsByRange = function (range) {
        var thumbs = [];
        if (!this._data.helper) {
            return thumbs;
        }
        for (var i = 0; i < this._thumbs.length; i++) {
            var thumb = this._thumbs[i];
            var canvas = thumb.data;
            var r = (this._data.helper.getCanvasRange(canvas, range.path));
            if (r && r.id === range.id) {
                thumbs.push(thumb);
            }
        }
        return thumbs;
    };
    GalleryComponent.prototype._updateThumbs = function () {
        var debug = !!this._data.debug;
        // cache range size
        this._setRange();
        var scrollTop = this._$main.scrollTop();
        var scrollHeight = this._$main.height();
        var scrollBottom = scrollTop + scrollHeight;
        if (debug) {
            console.log("scrollTop %s, scrollBottom %s", scrollTop, scrollBottom);
        }
        // test which thumbs are scrolled into view
        var thumbs = this._getAllThumbs();
        var numToUpdate = 0;
        for (var i = 0; i < thumbs.length; i++) {
            var $thumb = $(thumbs[i]);
            var thumbTop = $thumb.position().top;
            var thumbHeight = $thumb.outerHeight();
            var thumbBottom = thumbTop + thumbHeight;
            var padding = thumbHeight * this._data.thumbLoadPadding;
            // check all thumbs to see if they are within the scroll area plus padding
            if (thumbTop <= scrollBottom + padding &&
                thumbBottom >= scrollTop - padding) {
                numToUpdate += 1;
                //let $label: JQuery = $thumb.find('span:visible').not('.searchResults');
                // if (debug) {
                //     $thumb.addClass('debug');
                //     $label.empty().append('t: ' + thumbTop + ', b: ' + thumbBottom);
                // } else {
                //     $thumb.removeClass('debug');
                // }
                this._sizeThumb($thumb);
                $thumb.addClass("insideScrollArea");
                // if (debug) {
                //     $label.append(', i: true');
                // }
                this._loadThumb($thumb);
            }
            else {
                $thumb.removeClass("insideScrollArea");
                // if (debug) {
                //     $label.append(', i: false');
                // }
            }
        }
        if (debug) {
            console.log("number of thumbs to update: " + numToUpdate);
        }
    };
    GalleryComponent.prototype._getSelectedThumbIndex = function () {
        return Number(this._$selectedThumb.data("index"));
    };
    GalleryComponent.prototype._getAllThumbs = function () {
        if (!this._thumbsCache) {
            this._thumbsCache = this._$thumbs.find(".thumb");
        }
        return this._thumbsCache;
    };
    GalleryComponent.prototype._getThumbByIndex = function (canvasIndex) {
        return this._$thumbs.find('[data-index="' + canvasIndex + '"]');
    };
    GalleryComponent.prototype._scrollToThumb = function (canvasIndex) {
        var $thumb = this._getThumbByIndex(canvasIndex);
        this._$main.scrollTop($thumb.position().top);
    };
    // these don't work well because thumbs are loaded in chunks
    // public searchPreviewStart(canvasIndex: number): void {
    //     this._scrollToThumb(canvasIndex);
    //     const $thumb: JQuery = this._getThumbByIndex(canvasIndex);
    //     $thumb.addClass('searchpreview');
    // }
    // public searchPreviewFinish(): void {
    //     this._scrollToThumb(this._data.helper.canvasIndex);
    //     this._getAllThumbs().removeClass('searchpreview');
    // }
    GalleryComponent.prototype.selectIndex = function (index) {
        if (!this._thumbs || !this._thumbs.length)
            return;
        this._getAllThumbs().removeClass("selected");
        this._$selectedThumb = this._getThumbByIndex(index);
        this._$selectedThumb.addClass("selected");
        this._scrollToThumb(index);
        // make sure visible images are loaded.
        this._updateThumbs();
    };
    GalleryComponent.prototype._setRange = function () {
        var norm = Utils_1.Maths.normalise(Number(this._$sizeRange.val()), 0, 10);
        this._range = Utils_1.Maths.clamp(norm, 0.05, 1);
    };
    // Update the DOM when the multiSelected state changes
    GalleryComponent.prototype._updateThumbHtmlMultiSelected = function (thumbIndex, multiSelected) {
        var $thumb = this._getThumbByIndex(thumbIndex);
        // Update the "wrap" div class
        var $wrap = $thumb.find(".wrap");
        if (multiSelected) {
            $wrap.addClass("multiSelected");
        }
        else {
            $wrap.removeClass("multiSelected");
        }
        // Update all the checkbox state
        var $checkbox = $thumb.find("#thumb-checkbox-".concat(thumbIndex));
        if ($checkbox.length) {
            $checkbox.prop("checked", multiSelected);
        }
    };
    GalleryComponent.prototype._resize = function () { };
    return GalleryComponent;
}(base_component_1.BaseComponent));
exports.GalleryComponent = GalleryComponent;
var Events = /** @class */ (function () {
    function Events() {
    }
    Events.DECREASE_SIZE = "decreaseSize";
    Events.INCREASE_SIZE = "increaseSize";
    Events.MULTISELECTION_MADE = "multiSelectionMade";
    Events.THUMB_SELECTED = "thumbSelected";
    Events.THUMB_MULTISELECTED = "thumbMultiSelected";
    return Events;
}());
//# sourceMappingURL=GalleryComponent.js.map