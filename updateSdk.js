/**
  updateSdk.js

  This script updates the ScanAPI SDK files required
  by this plugin in order to use the ScanAPI SDK
*/
const fs = require('fs');

function copyFile(source, target, cb) {
  var cbCalled = false;
console.log(`copy ${source} ${target}`);
  var rd = fs.createReadStream(source);
  rd.on("error", function(err) {
    done(err);
  });
  var wr = fs.createWriteStream(target);
  wr.on("error", function(err) {
    done(err);
  });
  wr.on("close", function(ex) {
    done();
  });
  rd.pipe(wr);

  function done(err) {
    if (!cbCalled) {
      cb(err);
      cbCalled = true;
    }
  }
}

function copyFiles(files,source, target, done) {
  let count = 0;
  const cb = (err) => {
    if (err) {
      return done(err);
    }
    count += 1;
    if (count === files.length) {
      done();
    }
  };
  files.map((file) => {
    copyFile(source + '/' + file, target + '/' + file, cb);
  });
}

function updateSdk(pluginDir, sdkDir, cb) {
  // console.log('plugin Dir: ', pluginDir);
  // console.log('SDK Dir: ', sdkDir);
  const subDirs = ['/.', '/include', '/lib'];
  const sdkPluginDir = pluginDir + '/src/ios/sdk';
  if (!fs.existsSync(sdkPluginDir)){
    fs.mkdirSync(sdkPluginDir);
  }
  let nbCopies = 0;
  let current = 0;
  let files = subDirs.map((sub) => {
    fs.readdir(sdkDir + sub, (err, files) => {
      files = files.filter((f) =>  /.*\w\.(m|h|a)/i.test(f));
      // console.log(`${sdkDir + sub}: ${files}`);
      nbCopies += 1;
      if (!fs.existsSync(sdkPluginDir + sub)){
        fs.mkdirSync(sdkPluginDir + sub);
      }
      copyFiles(files,sdkDir + sub, sdkPluginDir + sub, done);
    });
  });

  const done = (err) => {
    if (err) {
      return cb(err);
    }
    current += 1;
    if (current === nbCopies) {
      return cb();
    }
  }
}

function main(){
  if(process.argv.length !== 4) {
    console.log('missing arguments!');
    console.log('usage: updateSdk <plugin cloned directory> <unzipped ScanAPI SDK directory>');
    return -1;
  }
  const pluginDir = process.argv[2];
  const sdkDir = process.argv[3];
  updateSdk(pluginDir, sdkDir, (err) => {
    if (err) {
      console.log('Error during the SDK update: ', err);
    } else {
      console.log('Success in updating the SDK files');
    }
  });
}


return main();
