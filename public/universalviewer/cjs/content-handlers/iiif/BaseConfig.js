"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.Metric = exports.StorageType = void 0;
var Utils_1 = require("../iiif/Utils");
Object.defineProperty(exports, "StorageType", { enumerable: true, get: function () { return Utils_1.StorageType; } });
var Metric = /** @class */ (function () {
    function Metric(type, minWidth) {
        this.type = type;
        this.minWidth = minWidth;
    }
    return Metric;
}());
exports.Metric = Metric;
//# sourceMappingURL=BaseConfig.js.map