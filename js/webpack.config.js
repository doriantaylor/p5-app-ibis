const pkg = require('./package.json');

module.exports = {
    mode: 'development',
    entry: './index.js',
    output: {
        filename: pkg.browser
    }
};
