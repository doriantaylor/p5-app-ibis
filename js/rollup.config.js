// rollup.config.js
import resolve  from '@rollup/plugin-node-resolve';
import commonjs from '@rollup/plugin-commonjs';
import pkg      from './package.json';

export default [
    {
        input: 'rdf.js',
        output: {
            name: 'RDF',
            file: '../root/asset/rdf.js',
            format: 'umd'
        },
		plugins: [
            // so Rollup can find its dependencies
			resolve({ preferBuiltins: false, mainFields: ['browser'] }),
			commonjs() // so Rollup can convert dependendies to ES modules
		]
    },
    {
        input: 'd3.js',
        output: {
            name: 'd3',
            file: '../root/asset/d3.js',
            format: 'umd'
        },
		plugins: [
            // so Rollup can find its dependencies
			resolve({ preferBuiltins: false, mainFields: ['browser'] }),
			commonjs() // so Rollup can convert dependendies to ES modules
		]
    },
	// browser-friendly UMD build
    {
        external: ['rdf', 'd3'],
		input: 'index.js',
		output: {
			name: 'ForceRDF',
            globals: {
                rdf: 'RDF',
                d3:  'd3'
            },
			file: '../root/asset/force-directed.js',
			format: 'umd'
		},
		plugins: [
            // so Rollup can find its dependencies
			resolve({ preferBuiltins: false, mainFields: ['browser'] }),
			commonjs() // so Rollup can convert dependendies to ES modules
		]
	},
];
