import * as RDF from 'rdf';
import * as d3 from 'd3';
import RDFViz from 'rdf-viz';

export default class HierRDF extends RDFViz {
    constructor (graph, rdfParams = {}, d3Params = {}) {
        super(graph, rdfParams, d3Params);
    }
}
