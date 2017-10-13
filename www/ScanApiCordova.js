var exec = require('cordova/exec');

exports.useScanApi = function (arg0, success, error) {
    exec(success, error, 'ScanApiCordova', 'useScanApi', [arg0]);
};
