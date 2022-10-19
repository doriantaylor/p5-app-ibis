import * as RDF from 'rdf';
import * as d3 from 'd3';

export default class RDFViz {
    ns = Object.entries({
        rdf:  'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
        rdfs: 'http://www.w3.org/2000/01/rdf-schema#',
        owl:  'http://www.w3.org/2002/07/owl#',
        xsd:  'http://www.w3.org/2001/XMLSchema#',
        dct:  'http://purl.org/dc/terms/',
        bibo: 'http://purl.org/ontology/bibo/',
        foaf: 'http://xmlns.com/foaf/0.1/',
        org:  'http://www.w3.org/ns/org#',
        skos: 'http://www.w3.org/2004/02/skos/core#',
        ibis: 'https://vocab.methodandstructure.com/ibis#',
    }).reduce(
        // this will return `out` always
        (out, [key, value]) => (out[key] = new RDF.Namespace(value), out), {});

    constructor (graph, rdfParams = {}, d3Params = {}) {
        if (!graph) graph = RDF.graph();
        this.graph     = graph;
        this.rdfParams = rdfParams;
        this.d3Params  = d3Params;
    }

    init () {
        throw 'Needs to be overridden in a subclass';
    }

    abbreviate (uris, scalar = true) {
        // first we coerce the input into an array
        if (!(uris instanceof Array)) uris = [uris];

        /*
        // get some prefixes
        const rev = Object.entries(this.ns).reduce((out, [prefix, ns]) => {
            out[ns('').value] = prefix;
            return out;
        }, {});
        */

        // console.log(this);

        uris = uris.map(uri => {
            uri = uri.value ? uri.value : uri.toString();

            let prefix = null, namespace = null;
            Object.entries(this.ns).forEach(([pfx, nsURI]) => {
                nsURI = nsURI('').value;
                if (uri.startsWith(nsURI)) {
                    if (!namespace || namespace.length < nsURI.length) {
                        prefix    = pfx;
                        namespace = nsURI;
                    }
                }
            });

            // bail out if there is no match
            if (prefix == null) return uri;

            // otherwise we have a curie (or slug potentially)
            const rest = uri.substring(namespace.length);
            return prefix == '' ? rest : [prefix, rest].join(':');
        });

        return scalar ? uris.join(' ') : uris;
    }

    expand (curie) {
        let [prefix, slug] = curie.split(':', 2);
        if (slug == undefined) {
            slug = prefix;
            prefix = '';
        }

        // console.log(this);

        if (this.ns[prefix] !== undefined) return this.ns[prefix](slug);

        return curie;
    }

    installFetchOnLoad (url, target) {
        if (window) window.addEventListener('load', e => {
            // console.log('wat', this);
            const fetcher = new RDF.Fetcher(this.graph);
            // okay now load
            fetcher.load(url, {
                baseURI: window.location.href,
                headers: { Accept: 'text/turtle;q=1' }
            }).then(() => {
                // console.log('lol', this);
                this.init();
                if (target) this.attach(target);
            });
        });
        else console.error('window not available yet');
    }

    getRoot () {
        if (this.root) return this.root;

        const root = this.root = new URL(window.location.href);
        let path = root.pathname.split('/').slice(0, -1);
        path.push('');
        root.pathname = path.join('/');

        return root;
    }

    rewriteUUID (uuid) {
        const root = this.getRoot();

        // XXX THIS SUCKS JUST REWRITE THE URLS IN THE TURTLE OUTPUT
        return RDF.sym(uuid.value.replace('urn:uuid:', root.href));
    }

    attach (selector) {
        // bail out early if this is a node
        if (selector instanceof Node) return selector.appendChild(this.svg);

        if (typeof document !== 'undefined') {
            // now we assume it's an id
            let elem = document.getElementById(selector);
            // otherwise it's a query selector
            if (!elem) elem = document.querySelector(selector);

            if (elem) return elem.appendChild(this.svg);
        }

        console.error(`could not attach to ${selector}`);

        return null;
    }
}
