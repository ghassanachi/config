/* READ FILE */

function readFile(path, callback = _.noop) {
    shell(`cat ${path}`, ({ output }) => {
        return callback(output);
    });
}
