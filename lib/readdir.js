/*
* This function was copied with permission from:
* https://gist.github.com/825583
*
* It was then modified to be synchronous
*/
var fs = require('fs'),
    path = require('path');

module.exports = function readDir(start, callback) {
    // Use lstat to resolve symlink if we are passed a symlink
    var stat = fs.lstatSync(start),
        found = {dirs: [], files: []},
        total = 0,
        processed = 0,
        isDir = function isDir(abspath) {
            var stat = fs.statSync(abspath);
            if(stat.isDirectory()) {
                found.dirs.push(abspath);
                // If we found a directory, recurse!
                var data = readDir(abspath);
                found.dirs = found.dirs.concat(data.dirs);
                found.files = found.files.concat(data.files);
                if(++processed == total) {
                    return false;
                }
            } else {
                found.files.push(abspath);
                if(++processed == total) {
                    return false;
                }
            }
        }
    // Read through all the files in this directory
    if(stat.isDirectory()) {
        var files = fs.readdirSync(start);
        total = files.length;
        for (var x=0, l=files.length; x<l; x++) {
            isDir(path.join(start, files[x]));
        }
    } else {
        return callback(new Error("path: " + start + " is not a directory"));
    }
    return found;
};

