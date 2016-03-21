# react-native-transfer  [![NPM version](https://img.shields.io/npm/v/react-native-transfer.svg?style=flat-square)](https://www.npmjs.com/package/react-native-transfer)

A module for React Native for uploading multiple files

* Supports uploading multiple files at a time (currently downloading is not supported)
* Supports files and fields
* Supports the following file paths: `file://path/to.file`, `data://path/to.file`, `/path/to.file` and `assets-library:` (untested)
* Reports progress of file transfer percentage.

## File uploading is built in to React Native

https://github.com/facebook/react-native/blob/master/Libraries/Network/FormData.js#L29

Polyfill for XMLHttpRequest2 FormData API, allowing multipart POST requests with mixed data (string, native files) to be submitted via XMLHttpRequest.

Example:

```javascript
var photo = {
    uri: uriFromCameraRoll,
    type: 'image/jpeg',
    name: 'photo.jpg',
};

var body = new FormData();
body.append('authToken', 'secret');
body.append('photo', photo);
body.append('title', 'A beautiful photo!');

xhr.open('POST', serverURL);
xhr.send(body);
```

## Road Map, Feature Requests & Bug Fixes

* To Do: Download file with progress

I will add to this module as I need more features and I hope you will too, pull requests are always welcome.  I will not add features on request because I'm busy with other projects.  I want this to be a community written module so if there is a feature that's missing or bug, add it or fix it and send me a pull request.  If you don't know Objective C you can learn it.  We all were where you are now at some point.  [StackOverflow.com](http://stackoverflow.com/) is your friend.  :)

## Getting started

1. `npm install react-native-transfer --save`
2. In XCode, in the project navigator, right click `your project` ➜ `Add Files to [your project's name]`
3. Go to `node_modules` ➜ `react-native-transfer` and add `Transfer.m` & `Transfer.h`
4. Run your project (`Cmd+R`)

## Testing

I suggest you go to [requestb.in](http://requestb.in/) and create a unique link for testing.  It's free, super easy to use and there is no sign up required.  Do it!

## Usage

```javascript
'use strict';

var React = require('react-native');
var Transfer = require('react-native-transfer');

var {
  AppRegistry,
  StyleSheet,
  Text,
  View,
} = React;

var FileUploadDemo = React.createClass({
  componentDidMount: function() {
    var obj = {
        uploadUrl: 'http://requestb.in/XXXXXXX',  // Go to http://requestb.in/ and create your own link for testing
        method: 'POST', // default 'POST',support 'POST' and 'PUT'
        headers: {
          'Accept': 'application/json',
        },
        fields: {
            'hello': 'world',
        },
        files: [
          {
            name: 'one', // optional, if none then `filename` is used instead
            filename: 'one.w4a', // require, file name
            filepath: '/xxx/one.w4a', // require, file absolute path
            filetype: 'audio/x-m4a', // options, if none, will get mimetype from `filepath` extension
          },
        ]
    };

    // Add a listener to get progress
    var subscription = NativeAppEventEmitter.addListener(
        'transferring',
        (response) => {
            console.log("Transferring: percentage: ", response.progress * 100);
        }
    );
    Transfer.Upload(
        obj,
        function(response) {
            console.log('response: ', response);
            subscription.remove();
        },
        function(error) {
            console.log('error: ', error);
            subscription.remove();
        }
    );
  },
  render: function() {
    return (
      <View style={styles.container}>
        <Text style={styles.welcome}>
          Welcome to React Native!
        </Text>
      </View>
    );
  }
});

var styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#F5FCFF',
  },
  welcome: {
    fontSize: 20,
    textAlign: 'center',
    margin: 10,
  },
});

AppRegistry.registerComponent('FileUploadDemo', () => FileUploadDemo);
```

## Credits

This was originally created by [booxood](https://github.com/booxood) called [react-native-file-upload](https://github.com/booxood/react-native-file-upload).

Heavily modified by [wootwoot1234](https://github.com/wootwoot1234)

## License

The MIT License (MIT)

Copyright (c) 2015 Tom Krones

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
