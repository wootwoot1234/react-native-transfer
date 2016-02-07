'use strict';

var React, {NativeModules} = require('react-native');
var NativeTransfer = NativeModules.Transfer;

var Transfer = {
    Upload: function(obj, successCallback, errorCallback) {
        NativeTransfer.Upload(obj, successCallback, errorCallback);
    },
};

module.exports = Transfer;