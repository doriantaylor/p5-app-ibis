// repackage rdflib
import * as d3base from 'd3';
import * as d3dag  from 'd3-dag';

// aand back out
export default Object.assign({}, d3base, d3dag);
