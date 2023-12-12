// yo if we want to sponge the document for information about what to
// do next, we have to wait for it to load

document.addEventListener('load-graph', function () {
    // console.log('zap lol');
    this.graph = RDF.graph();
    this.rdfa  = new RDF.RDFaProcessor(
        this.graph, { base: window.location.href });

    this.rdfa.process(this);

    const ibis = RDF.Namespace('https://vocab.methodandstructure.com/ibis#');
    const skos = RDF.Namespace('http://www.w3.org/2004/02/skos/core#');

    const ibisTypes = ['Issue', 'Position', 'Argument'].map(t => ibis(t));
    const skosc = skos('Concept');

    const me = RDF.sym(window.location.href);
    const a  = RDF.sym('http://www.w3.org/1999/02/22-rdf-syntax-ns#type');
    let types = this.graph.match(me, a).filter(
        s => RDF.isNamedNode(s.object)).map(s => s.object);

    let isEntity = types.some(t => t.equals(skosc));

    if (ibisTypes.some(t => types.some(u => t.equals(u)))) {
        isEntity = true;
        types = ibisTypes;
    }

    const test = ts => ts.filter(t => types.some(x => x.equals(t))).length > 0;

    // console.log(types);

    // D3 STUFF

    // layering: Simplex LongestPath CoffmanGraham
    // coord: Simplex Quad Greedy Center
    const dataviz = this.dataviz = new HierRDF(this.graph, {
        validateNode: function (node) {
            //return true;
            if (!isEntity) return true;
            return node.neighbours.length > 0 ? true : test(node.type);
        },
        validateEdge: function (source, target) {
            //return true;
            if (!isEntity) return true;
            return test(source.type) || test(target.type);
        },
    }, {
        preserveAspectRatio: 'xMidYMid meet', layering: 'Simplex',
        coord: 'Simplex', radius: 5, hyperbolic: true });

    // grab the link
    const link = this.querySelector(
        'html > head > link[href][rel~="alternate"][type~="text/turtle"]');

    // install the window onload
    if (link) this.dataviz.installFetchOnLoad(link.href, '#force');
    else console.log("wah wah link not found");


    return true;
});

window.addEventListener('load', function () {
    const ev = new Event('load-graph');
    this.document.dispatchEvent(ev);
});

window.addEventListener('load', function () {
    // XXX i'm sure the rdf thingy has this already
    const classes = 'Issue Position Argument'.split(/\s+/).map(
        (i) => `https://vocab.methodandstructure.com/ibis#${i}`
    ).concat(['http://www.w3.org/2004/02/skos/core#Concept']);

    const selector = 'section.relations > section > form';

    const forms = this.document.querySelectorAll(selector);

    const focus = e => {
        console.log(e);
    };

    const blur = e => {
        // uncheck

        const form = e.currentTarget;
        let radios = form['= rdf:type :'];

        if (radios instanceof RadioNodeList) radios = Array.from(radios);
        else radios = [radios];

        // radios.forEach(r => r.checked = false);

        console.log(radios);
    };

    const escape = e => {
        if (e.key === 'Escape') {
            e.currentTarget.blur();
        }
        return true;
    };


    Array.from(forms).forEach(form => {

        // console.log(form);
        form.addEventListener('focus', focus, true);
        form.addEventListener('blur', blur, true);
        form.addEventListener('keydown', escape, false);

    });

    return true;
});
