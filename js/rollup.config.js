// rollup.config.js
import resolve  from '@rollup/plugin-node-resolve';
import commonjs from '@rollup/plugin-commonjs';
import pkg      from './package.json';

export default [
	// browser-friendly UMD build
	{
		input: 'index.js',
		output: {
			name: 'ForceDirected',
			file: pkg.browser,
			format: 'umd'
		},
		plugins: [
			resolve(), // so Rollup can find its dependencies
			commonjs() // so Rollup can convert dependendies to ES modules
		]
	},
];
