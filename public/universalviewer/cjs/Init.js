"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.init = void 0;
var Events_1 = require("./Events");
var UniversalViewer_1 = require("./UniversalViewer");
var init = function (el, data) {
    var uv;
    var isFullScreen = false;
    var overrideFullScreen = false;
    var container = typeof el === "string" ? document.getElementById(el) : el;
    if (!container) {
        throw new Error("UV target element not found");
    }
    container.innerHTML = "";
    var parent = document.createElement("div");
    container.appendChild(parent);
    // extra div is needed for safari full screen
    var uvDiv = document.createElement("div");
    parent.appendChild(uvDiv);
    var resize = function () {
        if (uv) {
            if (isFullScreen && !overrideFullScreen) {
                // is full screen and not overridden.
                parent.style.width = window.innerWidth + "px";
                parent.style.height = window.innerHeight + "px";
            }
            else {
                // either we're not full screen or scaling to the window size is overridden
                parent.style.width = container.offsetWidth + "px";
                parent.style.height = container.offsetHeight + "px";
            }
            uv.resize();
        }
    };
    window.addEventListener("resize", function () {
        resize();
    });
    window.addEventListener("orientationchange", function () {
        setTimeout(function () {
            resize();
        }, 100);
    });
    uv = new UniversalViewer_1.UniversalViewer({
        target: uvDiv,
        data: data,
    });
    // todo: can we remove the following two event listeners
    // by using css to scale the parent div?
    uv.on(Events_1.Events.CREATED, function (_obj) {
        resize();
    }, false);
    uv.on(Events_1.Events.EXTERNAL_RESOURCE_OPENED, function (_obj) {
        setTimeout(function () {
            resize();
        }, 100);
    }, false);
    uv.on(Events_1.Events.TOGGLE_FULLSCREEN, function (data) {
        console.log("[UV] TOGGLE_FULLSCREEN received:", data);
        isFullScreen = data.isFullScreen;
        overrideFullScreen = data.overrideFullScreen;
        if (!data.overrideFullScreen) {
            if (isFullScreen) {
                if (parent.requestFullscreen) {
                    parent.requestFullscreen();
                } else if (parent.webkitRequestFullscreen) {
                    parent.webkitRequestFullscreen();
                } else if (parent.msRequestFullscreen) {
                    parent.msRequestFullscreen();
                }
            }
            else {
                if (document.webkitExitFullscreen) {
                    document.webkitExitFullscreen();
                } else if (document.exitFullscreen) {
                    document.exitFullscreen();
                } else if (document.msExitFullscreen) {
                    document.msExitFullscreen();
                }
            }
        }
        setTimeout(function () {
            resize();
        }, 100);
    }, false);
    uv.on(Events_1.Events.ERROR, function (message) {
        console.error(message);
    }, false);
    function fullScreenChange(e) {
        console.log("[UV] fullScreenChange fired:", e.type,
            "webkitFullscreenElement:", document.webkitFullscreenElement,
            "fullscreenElement:", document.fullscreenElement);
        if ((e.type === "webkitfullscreenchange" && !document.webkitFullscreenElement) ||
            (e.type === "fullscreenchange" && !document.fullscreenElement) ||
            (e.type === "MSFullscreenChange" && document.msFullscreenElement === null)) {
            if (isFullScreen) {
                console.log("[UV] calling uv.exitFullScreen()");
                isFullScreen = false;
                uv.exitFullScreen();
                setTimeout(function () {
                    resize();
                }, 100);
            }
        }
    }
    document.addEventListener("fullscreenchange", fullScreenChange, false);
    document.addEventListener("webkitfullscreenchange", fullScreenChange, false);
    document.addEventListener("MSFullscreenChange", fullScreenChange, false);
    return uv;
};
exports.init = init;
function getRequestFullScreen(elem) {
    if (elem.requestFullscreen) {
        return elem.requestFullscreen;
    }
    if (elem.webkitRequestFullscreen) {
        return elem.webkitRequestFullscreen;
    }
    if (elem.msRequestFullscreen) {
        return elem.msRequestFullscreen;
    }
    return false;
}
function getExitFullScreen() {
    if (document.exitFullscreen) {
        return document.exitFullscreen;
    }
    if (document.webkitExitFullscreen) {
        return document.webkitExitFullscreen;
    }
    if (document.msExitFullscreen) {
        return document.msExitFullscreen;
    }
    return false;
}
//# sourceMappingURL=Init.js.map