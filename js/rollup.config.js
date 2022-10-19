// rollup.config.js
import resolve  from '@rollup/plugin-node-resolve';
import commonjs from '@rollup/plugin-commonjs';
import pkg      from './package.json';

const PLUGINS = [
    // so Rollup can find its dependencies
	resolve({ preferBuiltins: false, mainFields: ['browser'] }),
	commonjs() // so Rollup can convert dependendies to ES modules
];

export default [
    {
        input: 'rdf.js',
        output: {
            name: 'RDF',
            file: '../root/asset/rdf.js',
            format: 'umd'
        },
		plugins: PLUGINS
    },
    {
        input: 'd3.js',
        output: {
            name: 'd3',
            file: '../root/asset/d3.js',
            format: 'umd'
        },
		plugins: PLUGINS
    },
	// browser-friendly UMD build
    {
        external: ['rdf', 'd3'],
        input: 'rdf-viz.js',
        output: {
            name: 'RDFViz',
            globals: {
                rdf: 'RDF',
                d3:  'd3'
            },
			file: '../root/asset/rdf-viz.js',
			format: 'umd'
        },
		plugins: PLUGINS
    },
    {
        external: ['rdf', 'd3', 'rdf-viz'],
		input: 'force-directed.js',
		output: {
			name: 'ForceRDF',
            globals: {
                rdf:       'RDF',
                d3:        'd3',
                'rdf-viz': 'RDFViz',
            },
			file: '../root/asset/force-directed.js',
			format: 'umd'
		},
		plugins: PLUGINS
	},
    {
        external: ['rdf', 'd3', 'rdf-viz'],
		input: 'hierarchical.js',
		output: {
			name: 'HierRDF',
            globals: {
                rdf:       'RDF',
                d3:        'd3',
                'rdf-viz': 'RDFViz',
            },
			file: '../root/asset/hierarchical.js',
			format: 'umd'
		},
		plugins: PLUGINS
	},
];
