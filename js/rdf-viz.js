import * as RDF from 'rdf';
import * as d3 from 'd3';

export default class RDFViz {
    static ns = Object.entries({
        rdf:  'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
        rdfs: 'http://www.w3.org/2000/01/rdf-schema#',
        owl:  'http://www.w3.org/2002/07/owl#',
        xsd:  'http://www.w3.org/2001/XMLSchema#',
        xhv:  'http://www.w3.org/1999/xhtml/vocab#',
        dct:  'http://purl.org/dc/terms/',
        bibo: 'http://purl.org/ontology/bibo/',
        foaf: 'http://xmlns.com/foaf/0.1/',
        org:  'http://www.w3.org/ns/org#',
        skos: 'http://www.w3.org/2004/02/skos/core#',
        ibis: 'https://vocab.methodandstructure.com/ibis#',
    }).reduce(
        // this will return `out` always
        (out, [key, value]) => (out[key] = new RDF.Namespace(value), out), {});

    static validTypes = [
        'foaf:Agent', 'foaf:Person', 'org:Organization',
        'org:FormalOrganization', 'org:OrganizationalUnit', 'skos:Concept',
        'ibis:Issue', 'ibis:Position', 'ibis:Argument'];

    static labels = {
        'foaf:Person':            'foaf:name',
        'foaf:Organization':      'foaf:name',
        'org:Organization':       'foaf:name',
        'org:OrganizationalUnit': 'foaf:name',
        'org:FormalOrganization': 'foaf:name',
        'skos:Concept':           'skos:prefLabel',
        'ibis:Issue':             'rdf:value',
        'ibis:Position':          'rdf:value',
        'ibis:Argument':          'rdf:value',
    };

    static inverses = {
        // IBIS
        'ibis:endorses':      'ibis:endorsed-by',
        'ibis:concerns':      'ibis:concern-of',
        'ibis:generalizes':   'ibis:specializes',
        'ibis:specializes':   'ibis:generalizes',
        'ibis:replaces':      'ibis:replaced-by',
        'ibis:replaced-by':   'ibis:replaces',
        'ibis:questions':     'ibis:questioned-by',
        'ibis:questioned-by': 'ibis:questions',
        'ibis:suggests':      'ibis:suggested-by',
        'ibis:suggested-by':  'ibis:suggests',
        'ibis:response':      'ibis:responds-to',
        'ibis:responds-to':   'ibis:response',
        'ibis:supports':      'ibis:supported-by',
        'ibis:supported-by':  'ibis:supports',
        'ibis:opposes':       'ibis:opposed-by',
        'ibis:opposed-by':    'ibis:opposes',
        // SKOS
        'skos:related':            'skos:related',
        'skos:narrower':           'skos:broader',
        'skos:broader':            'skos:narrower',
        'skos:narrowerTransitive': 'skos:broaderTransitive',
        'skos:broaderTransitive':  'skos:narrowerTransitive',
        'skos:narrowMatch':        'skos:broadMatch',
        'skos:broadMatch':         'skos:narrowMatch',
        'skos:closeMatch':         'skos:closeMatch',
        'skos:exactMatch':         'skos:exactMatch',
    };

    static symmetric = ['skos:related'];
      // layering: Simplex LongestPath CoffmanGraham
      // coord: Simplex Quad Greedy Center

    // note these have been munged from what we actually want them to
    // be so the sugiyama graph is tighter
    static prefer = {
        'ibis:concern-of':    'ibis:concerns',
        'ibis:endorsed-by':   'ibis:endorses',
        'ibis:specializes':   'ibis:generalizes',
        'ibis:replaced-by':   'ibis:replaces',
        // 'ibis:questioned-by': 'ibis:questions',
        'ibis:questions': 'ibis:questioned-by',
        'ibis:suggested-by':  'ibis:suggests',
        // 'ibis:response':      'ibis:responds-to',
        'ibis:responds-to':   'ibis:response',
        // 'ibis:supported-by':  'ibis:supports',
        'ibis:supports':     'ibis:supported-by',
        // 'ibis:opposed-by':    'ibis:opposes',
        'ibis:opposes':   'ibis:opposed-by',
        // 'skos:narrower':      'skos:broader',
        'skos:broader': 'skos:narrower',
    };

    constructor (graph, rdfParams = {}, d3Params = {}) {
        if (!graph) graph = RDF.graph();
        this.graph     = graph;
        this.rdfParams = Object.assign({}, rdfParams ||= {});
        this.d3Params  = Object.assign({ width: 1000, height: 1000 },
                                       d3Params ||= {});

        // XXX there is probably something that easily does this

        this.ns = Object.entries(Object.assign(
            {}, this.constructor.ns, rdfParams.ns || {})).reduce(
                (x, [k, v]) => {
                    // XXX RDF.Namespace isn't a constructor???
                    if (typeof v !== 'function')
                        v = new RDF.Namespace(v.toString());
                    x[k] = v;
                    return x;
                }, {});

        // rdf:type
        this.a = this.ns.rdf('type');

        this.validTypes = [].concat(
            this.constructor.validTypes, rdfParams.validTypes || []).map(
                x => this.expand(x)).reduce((o, x) => {
                    x = this.expand(x);
                    if (!(o.some(y => x.equals(y)))) o.push(x);
                    return o;
                }, []);

        this.labels = Object.entries(Object.assign(
            {}, this.constructor.labels, rdfParams.labels || {})).reduce(
                (x, [k, v]) => {
                    x[this.expand(k).value] = this.expand(v);
                    return x;
                }, {});

        this.inverses = Object.entries(Object.assign(
            {}, this.constructor.inverses, rdfParams.inverses || {})).reduce(
                (x, [k, v]) => {
                    x[this.expand(k).value] = this.expand(v);
                    return x;
                }, {});

        this.symmetric = [].concat(
            this.constructor.symmetric, rdfParams.symmetric || []).map(
                x => this.expand(x)).reduce((o, x) => {
                    x = this.expand(x);
                    if (!(o.some(y => x.equals(y)))) o.push(x);
                    return o;
                }, []);

        this.prefer = Object.entries(Object.assign(
            {}, this.constructor.prefer, rdfParams.prefer || {})).reduce(
                (x, [k, v]) => {
                    x[this.expand(k).value] = this.expand(v);
                    return x;
                }, {});
    }

    init () {
        throw 'Needs to be overridden in a subclass';
    }

    abbreviate (uris, scalar = true) {
        // first we coerce the input into an array
        if (!(uris instanceof Array)) uris = [uris];

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
        if (curie instanceof RDF.NamedNode) return curie;
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
        if (window) {
            // XXX this is dumb but due to https://bugzilla.mozilla.org/show_bug.cgi?id=325891
            const event = e => {
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
            };
            // console.log(document.readyState);
            if (document.readyState === 'complete') event();
            else window.addEventListener('load', event);
        }
        else console.error('window not available yet');
    }

    getRoot () {
        if (this.root) return this.root;

        const root = this.root = new URL(window.location.href);
        const path = root.pathname.split('/').slice(0, -1);
        path.push('');
        root.pathname = path.join('/');
        root.hash     = ''; // the root is never a fragment
        root.search   = ''; // it probably shouldn't be a query either

        // (i might regret the latter but we'll see)

        return root;
    }

    rewriteUUID (uuid) {
        if (!uuid instanceof RDF.NamedNode) uuid = RDF.sym(uuid.toString());

        if (!uuid.value.toLowerCase().startsWith('urn:uuid')) return uuid;

        // clone the uri
        const uri = new URL(this.getRoot().href);

        let path = uuid.value.replace('urn:uuid:', uri.pathname);
        uri.pathname = path;

        // XXX THIS SUCKS JUST REWRITE THE URLS IN THE TURTLE OUTPUT
        return RDF.sym(uri.href);
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
