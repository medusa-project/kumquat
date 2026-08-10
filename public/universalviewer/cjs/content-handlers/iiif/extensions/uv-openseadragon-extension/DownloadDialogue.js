"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
var react_1 = __importStar(require("react"));
var classnames_1 = __importDefault(require("classnames"));
var Utils_1 = require("../../Utils");
var manifesto_js_1 = require("manifesto.js");
var DownloadOption_1 = require("../../modules/uv-shared-module/DownloadOption");
var DownloadDialogue = function (_a) {
    var canvases = _a.canvases, confinedImageSize = _a.confinedImageSize, content = _a.content, downloadCurrentViewEnabled = _a.downloadCurrentViewEnabled, downloadWholeImageHighResEnabled = _a.downloadWholeImageHighResEnabled, downloadWholeImageLowResEnabled = _a.downloadWholeImageLowResEnabled, getConfinedImageDimensions = _a.getConfinedImageDimensions, getConfinedImageUri = _a.getConfinedImageUri, getCroppedImageDimensions = _a.getCroppedImageDimensions, locale = _a.locale, manifest = _a.manifest, maxImageWidth = _a.maxImageWidth, minImageWidth = _a.minImageWidth, mediaDownloadEnabled = _a.mediaDownloadEnabled, onClose = _a.onClose, onDownload = _a.onDownload, onDownloadCurrentView = _a.onDownloadCurrentView, onDownloadSelection = _a.onDownloadSelection, onShowTermsOfUse = _a.onShowTermsOfUse, open = _a.open, paged = _a.paged, parent = _a.parent, resources = _a.resources, requiredStatement = _a.requiredStatement, rotation = _a.rotation, selectionEnabled = _a.selectionEnabled, sequence = _a.sequence, termsOfUseEnabled = _a.termsOfUseEnabled, triggerButton = _a.triggerButton;
    var ref = (0, react_1.useRef)(null);
    var _b = (0, react_1.useState)({ top: "0px", left: "0px" }), position = _b[0], setPosition = _b[1];
    var _c = (0, react_1.useState)("0px 0px"), arrowPosition = _c[0], setArrowPosition = _c[1];
    var _d = (0, react_1.useState)("left"), selectedPage = _d[0], setSelectedPage = _d[1];
    var hasNormalDimensions = rotation % 180 == 0;
    (0, react_1.useEffect)(function () {
        var _a;
        if (open) {
            var top_1 = parent.clientHeight -
                ref.current.clientHeight -
                triggerButton.clientHeight;
            var left = triggerButton.getBoundingClientRect().left -
                parent.getBoundingClientRect().left;
            var normalisedPos = Utils_1.Maths.normalise(left, 0, parent.clientWidth);
            left =
                parent.clientWidth * normalisedPos -
                    ref.current.clientWidth * normalisedPos;
            var arrowLeft = ref.current.clientWidth * normalisedPos;
            setPosition({ top: "".concat(top_1, "px"), left: "".concat(left, "px") });
            setArrowPosition("".concat(arrowLeft, "px 0px"));
            // Focus on the first element when opened
            var focusableElements = getFocusableElements();
            if (focusableElements && focusableElements.length > 0) {
                (_a = focusableElements[0]) === null || _a === void 0 ? void 0 : _a.focus();
            }
        }
    }, [open]);
    // Method to get focusable elements inside the component
    var getFocusableElements = function () {
        var _a;
        return (_a = ref.current) === null || _a === void 0 ? void 0 : _a.querySelectorAll('button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])');
    };
    // Focus trapping logic
    var handleTabKey = function (e) {
        if (e.key === "Tab") {
            var focusableElements = getFocusableElements();
            if (!focusableElements)
                return;
            var firstFocusableElement = focusableElements[0];
            var lastFocusableElement = focusableElements[focusableElements.length - 1];
            if (e.shiftKey) {
                // If Shift + Tab is pressed and the focus is on the first element, go to the last
                if (document.activeElement === firstFocusableElement) {
                    e.preventDefault();
                    lastFocusableElement.focus();
                }
            }
            else {
                // If Tab is pressed and the focus is on the last element, go to the first
                if (document.activeElement === lastFocusableElement) {
                    e.preventDefault();
                    firstFocusableElement.focus();
                }
            }
        }
    };
    (0, react_1.useEffect)(function () {
        if (open) {
            document.addEventListener("keydown", handleTabKey);
        }
        return function () {
            document.removeEventListener("keydown", handleTabKey);
        };
    }, [open]);
    if (!open)
        return null;
    function getCanvasDimensions(canvas) {
        // externalResource may not have loaded yet
        if (canvas.externalResource.data) {
            var width = canvas.externalResource.data.width;
            var height = canvas.externalResource.data.height;
            if (width && height) {
                return new manifesto_js_1.Size(width, height);
            }
        }
        return null;
    }
    function getCanvasComputedDimensions(canvas) {
        var imageSize = getCanvasDimensions(canvas);
        var requiredSize = canvas.getMaxDimensions();
        if (!imageSize) {
            return null;
        }
        if (!requiredSize) {
            return imageSize;
        }
        if (imageSize.width <= requiredSize.width &&
            imageSize.height <= requiredSize.height) {
            return imageSize;
        }
        var scaleW = requiredSize.width / imageSize.width;
        var scaleH = requiredSize.height / imageSize.height;
        var scale = Math.min(scaleW, scaleH);
        return new manifesto_js_1.Size(Math.floor(imageSize.width * scale), Math.floor(imageSize.height * scale));
    }
    function isLevel0(profile) {
        if (!profile || !profile.length)
            return false;
        return manifesto_js_1.Utils.isLevel0ImageProfile(profile[0]);
    }
    function getSelectedCanvas() {
        return canvases[selectedPage === "left" ? 0 : 1];
    }
    function getSelectedResource() {
        if (resources && resources.length) {
            if (resources.length > 1) {
                return resources[selectedPage === "left" ? 0 : 1];
            }
            else {
                return resources[0];
            }
        }
        return null;
    }
    function isDownloadOptionAvailable(option) {
        var selectedResource = getSelectedResource();
        if (!selectedResource) {
            return false;
        }
        var canvas = getSelectedCanvas();
        if (!canvas.externalResource) {
            return false;
        }
        // if the external resource doesn't have a service descriptor or is level 0
        // only allow wholeImageHighRes
        if (!canvas.externalResource.hasServiceDescriptor() ||
            isLevel0(canvas.externalResource.data.profile)) {
            if (option === DownloadOption_1.DownloadOption.WHOLE_IMAGE_HIGH_RES &&
                downloadWholeImageHighResEnabled) {
                // if in one-up mode, or in two-up mode with a single page being shown
                if (!(paged || (paged && selectedResource))) {
                    return true;
                }
            }
            return false;
        }
        var maxDimensions = canvas.getMaxDimensions();
        switch (option) {
            case DownloadOption_1.DownloadOption.CURRENT_VIEW:
                if (!downloadCurrentViewEnabled) {
                    return false;
                }
                if (maxDimensions && maxDimensions.width < minImageWidth)
                    return false;
                return !paged;
            case DownloadOption_1.DownloadOption.WHOLE_IMAGE_HIGH_RES:
                // If high-res download is disabled, bail out now; otherwise drop into cases below.
                if (!downloadWholeImageHighResEnabled) {
                    return false;
                }
            case DownloadOption_1.DownloadOption.CANVAS_RENDERINGS:
            case DownloadOption_1.DownloadOption.IMAGE_RENDERINGS:
                if (maxDimensions) {
                    if (maxDimensions.width <= maxImageWidth &&
                        maxDimensions.width >= minImageWidth) {
                        return true;
                    }
                    else {
                        return false;
                    }
                }
                return true;
            case DownloadOption_1.DownloadOption.WHOLE_IMAGE_LOW_RES:
                if (!downloadWholeImageLowResEnabled) {
                    return false;
                }
                // hide low-res option if hi-res width is smaller than constraint
                var size = getCanvasComputedDimensions(canvas);
                if (!size) {
                    return false;
                }
                return Math.max(size.width, size.height) > confinedImageSize;
            case DownloadOption_1.DownloadOption.SELECTION:
                return selectionEnabled;
            case DownloadOption_1.DownloadOption.RANGE_RENDERINGS:
                if (canvas.ranges && canvas.ranges.length) {
                    var range = canvas.ranges[0];
                    return range.getRenderings().length > 0;
                }
                return false;
            case DownloadOption_1.DownloadOption.ENTIRE_FILE_AS_ORIGINAL:
                return mediaDownloadEnabled;
            default:
                return true;
        }
    }
    function getCanvasImageResource(canvas) {
        var images = canvas.getImages();
        if (images[0]) {
            return images[0].getResource();
        }
        return null;
    }
    function getCanvasImageAnnotationBody(canvas) {
        var images = canvas.getContent();
        if (images.length == 0) {
            return null;
        }
        var bodies = images[0].getBody();
        if (bodies.length == 0) {
            return null;
        }
        return bodies[0];
    }
    function getCanvasMimeType(canvas) {
        // presentation api version 2
        var resource = getCanvasImageResource(canvas);
        if (resource) {
            var format = resource.getFormat();
            if (format) {
                return format.toString();
            }
        }
        // presentation api version 3
        var annotationBody = getCanvasImageAnnotationBody(canvas);
        if (annotationBody) {
            var format = annotationBody.getFormat();
            if (format) {
                return format.toString();
            }
        }
        return null;
    }
    function getCanvasHighResImageUri(canvas) {
        var size = getCanvasComputedDimensions(canvas);
        if (size) {
            var width = size.width;
            var uri = canvas.getCanonicalImageUri(width);
            if (canvas.externalResource &&
                canvas.externalResource.hasServiceDescriptor()) {
                var uriParts = uri.split("/");
                uriParts[uriParts.length - 2] = String(rotation);
                uri = uriParts.join("/");
            }
            return uri;
        }
        else if (canvas.externalResource &&
            !canvas.externalResource.hasServiceDescriptor()) {
            // if there is no image service, return the dataUri.
            return canvas.externalResource.dataUri;
        }
        return "";
    }
    function getWholeImageHighResLabel() {
        var label = "";
        var canvas = getSelectedCanvas();
        var mime = getCanvasMimeType(canvas);
        if (mime) {
            mime = Utils_1.Files.simplifyMimeType(mime);
        }
        else {
            mime = "?";
        }
        // dimensions
        var size = getCanvasComputedDimensions(canvas);
        if (!size) {
            // if there is no image service, allow the image to be downloaded directly.
            if (canvas.externalResource &&
                !canvas.externalResource.hasServiceDescriptor()) {
                label = Utils_1.Strings.format(content.wholeImageHighRes, "?", "?", mime);
            }
        }
        else {
            label = hasNormalDimensions
                ? Utils_1.Strings.format(content.wholeImageHighRes, size.width.toString(), size.height.toString(), mime)
                : Utils_1.Strings.format(content.wholeImageHighRes, size.height.toString(), size.width.toString(), mime);
        }
        return label;
    }
    function getWholeImageLowResLabel() {
        var canvas = getSelectedCanvas();
        var size = getConfinedImageDimensions(canvas);
        var label = "";
        if (size) {
            label = hasNormalDimensions
                ? Utils_1.Strings.format(content.wholeImageLowResAsJpg, size.width.toString(), size.height.toString())
                : Utils_1.Strings.format(content.wholeImageLowResAsJpg, size.height.toString(), size.width.toString());
        }
        return label;
    }
    function getCurrentViewLabel() {
        var label = content.currentViewAsJpg;
        var dimensions = getCroppedImageDimensions(getSelectedCanvas());
        // dimensions
        if (dimensions) {
            label = hasNormalDimensions
                ? Utils_1.Strings.format(label, dimensions.size.width.toString(), dimensions.size.height.toString())
                : Utils_1.Strings.format(label, dimensions.size.height.toString(), dimensions.size.width.toString());
        }
        return label;
    }
    function Renderings(_a) {
        var resource = _a.resource, defaultLabel = _a.defaultLabel, type = _a.type;
        var renderings = resource.getRenderings();
        return (react_1.default.createElement(react_1.default.Fragment, null, renderings.map(function (rendering, index) {
            var label = manifesto_js_1.LanguageMap.getValue(rendering.getLabel(), locale);
            if (label) {
                label += " ({0})";
            }
            else {
                label = defaultLabel;
            }
            var mime = Utils_1.Files.simplifyMimeType(rendering.getFormat().toString());
            label = Utils_1.Strings.format(label, mime);
            return (react_1.default.createElement("li", { key: index },
                react_1.default.createElement("button", { onClick: function () {
                        onDownload(type, label);
                        window.open(rendering.id, "_blank");
                    } }, label)));
        })));
    }
    // function getRangeRenderings(): boolean {
    //   return resource.getRenderings().length > 0;
    // }
    function hasRangeRenderings() {
        var _a;
        var canvas = getSelectedCanvas();
        return ((_a = canvas.ranges) !== null && _a !== void 0 ? _a : []).some(function (range) { return range.getRenderings().length > 0; });
    }
    function RangeRenderings() {
        var _a;
        var canvas = getSelectedCanvas();
        return (react_1.default.createElement(react_1.default.Fragment, null, (_a = canvas.ranges) === null || _a === void 0 ? void 0 : _a.map(function (range, index) { return (react_1.default.createElement(Renderings, { resource: range, defaultLabel: content.entireFileAsOriginal, key: "range-rendering-".concat(String(index)), type: DownloadOption_1.DownloadOption.RANGE_RENDERINGS })); })));
    }
    function hasImageRenderings() {
        var canvas = getSelectedCanvas();
        var images = canvas.getImages();
        return images.some(function (image) { return image.getResource().getRenderings().length > 0; });
    }
    function ImageRenderings() {
        var canvas = getSelectedCanvas();
        var images = canvas.getImages();
        return (react_1.default.createElement(react_1.default.Fragment, null, images.map(function (image, index) { return (react_1.default.createElement(Renderings, { resource: image.getResource(), defaultLabel: content.entireFileAsOriginal, key: "image-rendering-".concat(String(index)), type: DownloadOption_1.DownloadOption.IMAGE_RENDERINGS })); })));
    }
    function hasCanvasRenderings() {
        var canvas = getSelectedCanvas();
        return canvas.getRenderings().length > 0;
    }
    function CanvasRenderings() {
        var canvas = getSelectedCanvas();
        return (react_1.default.createElement(Renderings, { resource: canvas, defaultLabel: content.entireFileAsOriginal, type: DownloadOption_1.DownloadOption.CANVAS_RENDERINGS }));
    }
    function hasManifestRenderings() {
        return (sequence.getRenderings().length > 0 || manifest.getRenderings().length > 0);
    }
    function ManifestRenderings() {
        return (react_1.default.createElement(react_1.default.Fragment, null,
            react_1.default.createElement(Renderings, { resource: sequence, defaultLabel: content.entireFileAsOriginal, type: DownloadOption_1.DownloadOption.MANIFEST_RENDERINGS }),
            react_1.default.createElement(Renderings, { resource: manifest, defaultLabel: content.entireFileAsOriginal, type: DownloadOption_1.DownloadOption.MANIFEST_RENDERINGS })));
    }
    function TermsOfUse() {
        return termsOfUseEnabled && requiredStatement ? (react_1.default.createElement("button", { onClick: function () {
                onShowTermsOfUse();
            } }, content.termsOfUse)) : null;
    }
    var individualPageOptions = [];
    if (isDownloadOptionAvailable(DownloadOption_1.DownloadOption.CURRENT_VIEW)) {
        individualPageOptions.push(react_1.default.createElement("li", { key: "current-view", className: "option single" },
            react_1.default.createElement("button", { onClick: function () {
                    onDownload(DownloadOption_1.DownloadOption.CURRENT_VIEW, getCurrentViewLabel());
                    onDownloadCurrentView(getSelectedCanvas());
                } }, getCurrentViewLabel())));
    }
    if (isDownloadOptionAvailable(DownloadOption_1.DownloadOption.WHOLE_IMAGE_HIGH_RES)) {
        individualPageOptions.push(react_1.default.createElement("li", { key: "high-res", className: "option single" },
            react_1.default.createElement("button", { onClick: function () {
                    onDownload(DownloadOption_1.DownloadOption.WHOLE_IMAGES_HIGH_RES, getWholeImageHighResLabel());
                    window.open(getCanvasHighResImageUri(getSelectedCanvas()));
                } }, getWholeImageHighResLabel())));
    }
    if (isDownloadOptionAvailable(DownloadOption_1.DownloadOption.WHOLE_IMAGE_LOW_RES)) {
        individualPageOptions.push(react_1.default.createElement("li", { key: "low-res", className: "option single" },
            react_1.default.createElement("button", { onClick: function () {
                    onDownload(DownloadOption_1.DownloadOption.WHOLE_IMAGE_LOW_RES, getWholeImageLowResLabel());
                    var imageUri = getConfinedImageUri(getSelectedCanvas());
                    if (imageUri) {
                        window.open(imageUri);
                    }
                } }, getWholeImageLowResLabel())));
    }
    if (isDownloadOptionAvailable(DownloadOption_1.DownloadOption.RANGE_RENDERINGS) &&
        hasRangeRenderings()) {
        individualPageOptions.push(react_1.default.createElement(RangeRenderings, { key: "range-renderings" }));
    }
    if (isDownloadOptionAvailable(DownloadOption_1.DownloadOption.IMAGE_RENDERINGS) &&
        hasImageRenderings()) {
        individualPageOptions.push(react_1.default.createElement(ImageRenderings, { key: "image-renderings" }));
    }
    if (isDownloadOptionAvailable(DownloadOption_1.DownloadOption.CANVAS_RENDERINGS) &&
        hasCanvasRenderings()) {
        individualPageOptions.push(react_1.default.createElement(CanvasRenderings, { key: "canvas-renderings" }));
    }
    var allPageOptions = [];
    if (isDownloadOptionAvailable(DownloadOption_1.DownloadOption.MANIFEST_RENDERINGS) &&
        hasManifestRenderings()) {
        allPageOptions.push(react_1.default.createElement(ManifestRenderings, { key: "manifest-renderings" }));
    }
    if (isDownloadOptionAvailable(DownloadOption_1.DownloadOption.SELECTION)) {
        allPageOptions.push(react_1.default.createElement("li", { key: "selection", className: "option single" },
            react_1.default.createElement("button", { onClick: function () {
                    onDownload(DownloadOption_1.DownloadOption.SELECTION, content.selection);
                    onDownloadSelection();
                } }, content.selection)));
    }
    return (react_1.default.createElement("div", { ref: ref, className: (0, classnames_1.default)("overlay download"), style: position },
        react_1.default.createElement("div", { className: "top" }),
        react_1.default.createElement("div", { className: "middle" },
            react_1.default.createElement("div", { className: "content" },
                react_1.default.createElement("div", { role: "heading", className: "heading" }, content.download),
                !individualPageOptions.length && !allPageOptions.length && (react_1.default.createElement("p", null, content.noneAvailable)),
                individualPageOptions.length > 0 && (react_1.default.createElement("h2", null, content.individualPages)),
                canvases.length === 2 && (react_1.default.createElement("div", { className: "pages" },
                    react_1.default.createElement("div", { onClick: function () {
                            setSelectedPage("left");
                        }, className: (0, classnames_1.default)("page left", {
                            selected: selectedPage === "left",
                        }) },
                        react_1.default.createElement("span", { className: "label" }, canvases[0].getLabel().getValue())),
                    react_1.default.createElement("div", { onClick: function () {
                            setSelectedPage("right");
                        }, className: (0, classnames_1.default)("page right", {
                            selected: selectedPage === "right",
                        }) },
                        react_1.default.createElement("span", { className: "label" }, canvases[1].getLabel().getValue())))),
                react_1.default.createElement("ol", { className: "options" }, individualPageOptions),
                allPageOptions.length > 0 && react_1.default.createElement("h2", null, content.allPages),
                react_1.default.createElement("ol", { className: "options" }, allPageOptions),
                react_1.default.createElement("div", { className: "footer" },
                    react_1.default.createElement(TermsOfUse, null))),
            react_1.default.createElement("div", { className: "buttons" },
                react_1.default.createElement("button", { type: "button", className: "btn btn-default close", tabIndex: 0, onClick: function () {
                        onClose();
                    } }, content.close))),
        react_1.default.createElement("div", { className: (0, classnames_1.default)("bottom"), style: {
                backgroundPosition: arrowPosition,
            } })));
};
exports.default = DownloadDialogue;
//# sourceMappingURL=DownloadDialogue.js.map