'use strict';

var React, {NativeModules} = require('react-native');

var Transfer = {
    Upload: function(files) {
        NativeModules.Transfer.Upload(files, successCallback, errorCallback);
    },
};

module.exports = {Transfer};