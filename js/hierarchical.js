import * as RDF from 'rdf';
import * as d3  from 'd3';

import RDFViz from 'rdf-viz';

// const Complex = require('complex.js');
//import * as Complex from 'complex.js';
const C = (re, im) => new Complex(re, im);

// see https://dl.acm.org/doi/pdf/10.1145/223904.223956 or mobius
// transforms in general. |theta| == 1 (ie cos(x) + i sin(y)) and |p| < 1
const Zt = (theta, p) => (z) => theta.mul(z).add(p)
      .div(Complex.ONE.add(p.conjugate().mul(z)));

/*
  okay basic algorithm goes:


  * use the third-party sugiyama layout to get points in arbitrary cartesian
    coordinates where x, y >= 0

  * optionally pad y so that the "roots" (a d3-dag concept) of the hierarchy
    don't overlap

  * (XXX TODO calculate optimal padding based on number of "root" elements;
    may be negative if there is only one, making y = r = 0)

  * (note as well that the y-position of the root elements depends on the
    layering algorithm chosen, so we should take the subset of the roots
    with the lowest y-value as the reference)

  * rescale everything to the unit square

  * map to polar coordinates (r = y but theta = 2 pi x)

  * rescale r -> tanh(ln(1/(1-r))) (or some other concave function that maps
    the unit interval to 0..infinity)

  * map to complex unit disk (multiply by 2 and shift by -1)

*/

export default class HierRDF extends RDFViz {
    constructor (graph, rdfParams = {}, d3Params = {}) {
        super(graph, rdfParams, d3Params);

        const d3p    = this.d3Params;
        const width  = d3p.width  || 1000;
        const height = d3p.height || 1000;

        d3p.yOffset = d3p.yOffset || 0;

        if (d3p.layering) {
            const f = d3['layering' + d3p.layering.toString()];
            if (typeof f === 'function') d3p.layering = f();
        }
        else d3p.layering = d3.layeringSimplex();

        // XXX OVERRIDE THIS FOR NOW UNTIL WE FIGURE OUT A DECENT WAY TO REPRESENT IT
        d3p.decross = d3p.decross || d3.decrossTwoLayer().order(
            d3.twolayerGreedy().base(d3.twolayerAgg()));

        if (d3p.coord) {
            const f = d3['coord' + d3p.coord.toString()];
            if (typeof f === 'function') d3p.coord = f();
        }
        else d3p.coord = d3.coordSimplex();

        d3p.radius = d3p.radius || 5;

        // and node size is a custom function
        //d3p.nodeSize = d3p.nodeSize || () => d3p.radius * 2

        const svg = d3.create('svg')
            .attr('viewBox', [-width/2, -height/2, width, height]);
        if (d3p.width)  svg.attr('width',  d3p.width);
        if (d3p.height) svg.attr('height', d3p.height);
        if (d3p.preserveAspectRatio)
            svg.attr('preserveAspectRatio', d3p.preserveAspectRatio);

        this.svg = svg.node();
        this.svg.plumbing = this;

        this.validateNode = rdfParams.validateNode;
        this.validateEdge = rdfParams.validateEdge;
    }

    init () {
        // XXX PROBABLY ALL OF THIS CAN BE SUPERCLASSED

        const svg = d3.select(this.svg);

        // make these shorter to type lol
        const graph        = this.graph,
              a            = this.a,
              ns           = this.ns,
              validTypes   = this.validTypes,
              labels       = this.labels,
              inverses     = this.inverses,
              symmetric    = this.symmetric,
              prefer       = this.prefer,
              validateNode = this.validateNode,
              validateEdge = this.validateEdge;

        // first we collect the valid nodes
        const nmap  = {};

        // take one pass to obtain all the nominally valid subjects
        graph.match(null, a).forEach(stmt => {
            const s = stmt.subject, type = stmt.object;
            // bail if we aren't on the list
            if (!(RDF.isNamedNode(s) &&
                  s.value.toLowerCase().startsWith('urn:uuid:')) ||
                !validTypes.some(t => t.equals(type))) return;

            // give us an initial label, the node itself
            let label = s.value;

            // get label, beginning with default label predicates
            const lp = [ns['dct']('title'), ns['rdfs']('label')];
            if (labels[type.value]) lp.unshift(labels[type.value]);
            for (let i = 0; i < lp.length; i++) {
                let x = graph.match(s, lp[i]).filter(
                    s => RDF.isLiteral(s.object));
                if (x.length > 0) {
                    label = x[0].object.value;
                    break; // XXX maybe sort??
                }
            }

            // get dereferenceable subject uri
            const uri = this.rewriteUUID(s);

            const obj = nmap[uri.value] ||= {
                id:         uri.value, // for d3
                title:      label,     // for d3
                subject:    s,
                type:       [], // for now
                neighbours: [], // for later
            };
            // add the type
            if (!obj.type.some(o => o.equals(type))) obj.type.push(type);
        });

        // snag predicates and put them aside
        const pmap = {};

        // take a second pass to get the edges spanning the nodes
        const lmap = {};
        Object.values(nmap).forEach(rec => {
            graph.match(rec.subject).forEach(stmt => {
                // shorthands
                let s = stmt.subject, p = stmt.predicate, o = stmt.object;

                // filter only resources
                if (!RDF.isNamedNode(s) && !RDF.isNamedNode(o)) return;

                // optionally reverse edge direction
                if (prefer[p.value])
                    s = stmt.object, p = prefer[p.value], o = stmt.subject;

                // generate dereferenceable URIs
                const src = this.rewriteUUID(s), tgt = this.rewriteUUID(o);

                // only care about edges between nodes with valid types
                if (!nmap[src.value] || !nmap[tgt.value]) return;

                // XXX TODO add pruning constraint, eg at least one
                // node must be the same type (or on the same list)
                // as the page's subject
                if (validateEdge &&
                    !validateEdge(nmap[src.value], nmap[tgt.value], p)) return;

                // okay now we add the record if it isn't already there
                lmap[src.value] ||= {};
                let edge = lmap[src.value][tgt.value] ||= {
                    source: src.value,
                    target: tgt.value,
                    subject: s,
                    predicate: [],
                    object: o,
                };
                // add the predicate to the list
                if (!edge.predicate.some(ep => ep.equals(p)))
                    edge.predicate.push(p);

                // add it to the predicate map too
                pmap[p.value] = p;

                // now we add the node as a neighbour; note this will
                // only happen if the edge hasn't already been filtered
                [[src, tgt], [tgt, src]].forEach(([a, b]) => {
                    if (!nmap[a.value].neighbours.some(n => n.equals(b)))
                        nmap[a.value].neighbours.push(b);
                });
            });
        });

        // take a third pass to prune out the extraneous nodes
        for (const [k, rec] of Object.entries(nmap)) {
            if (validateNode && !validateNode(rec)) {
                rec.neighbours.forEach(n => {
                    const v = n.value;
                    if ((lmap[k] || {})[v]) delete lmap[k][v];
                    if ((lmap[v] || {})[k]) delete lmap[v][k];
                    if (lmap[k] && lmap[k].length == 0) delete lmap[k];
                    if (lmap[v] && lmap[v].length == 0) delete lmap[v];
                });
                delete nmap[k];
            }
        }

        const nodes = this.nodes = Object.values(nmap);
        const links = this.links = Object.values(lmap).reduce(
            (a, o) => (Object.values(o).forEach(e => a.push(e)), a), []);

        const defs = svg.append('defs');

        Object.values(pmap).forEach(predicate => {
            const about = this.abbreviate(predicate);
            const id = about.replace(':', '.'); // make this a legal id
            ['', '.subject'].forEach(x => {
                defs.append('marker').attr('id', id + x)
                    .attr('markerWidth', 10).attr('markerHeight', 7)
                    .attr('refX', -2.5).attr('refY', 3.5).attr('orient', 'auto')
                    .append('polygon').attr('points', '0,0 10,3.5 0,7')
                    .attr('class', () => x ? 'subject' : null)
                    .attr('about', about);
            });
        });

        // XXX END SUPERCLASSABLES

        const d3p = this.d3Params;

        // FU URL
        const me = new URL(window.location.href);
        me.search = '';
        me.hash   = '';

        svg.append('circle').attr('id', 'backdrop')
            .attr('cx', 0).attr('cy', 0).attr('r', d3p.width / 2);

        const edgeg = svg.append('g').attr('class', 'hier edge');
        const nodeg = svg.append('g').attr('class', 'hier node');

        // run the layout

        // XXX THIS ONLY WORKS IF THERE ARE 2+ NODES
        if (nodes.length > 1) {
            const d3c = d3.dagConnect().decycle(true).single(true);

            const seen = new Set();

            const dag = this.dag = d3c(links.map(
                x => (seen.add(x.source), seen.add(x.target),
                      [x.source, x.target])).concat(
                          nodes.filter(
                              x => !seen.has(x.id)).map(x => [x.id, x.id])));

            const nodeSize = node => {
                const padding = 1.5;
                const base = d3p.radius * 2 * padding;
                const size = node ? base : base / 4;
                return [1.2 * size, size];
            };

            // XXX THIS LINE OF CODE IS EXPENSIVE AF AND ONLY NEEDS TO BE
            // RUN ONCE PER GRAPH CHANGE. FIND SOME WAY TO CACHE IT. EVEN
            // BETTER: RUN IT ON THE SERVER.
            const layout = d3.sugiyama().layering(d3p.layering).decross(
                d3p.decross).coord(d3p.coord).nodeSize(nodeSize);
            const { width, height } = layout(dag);
            dag.width  = width;
            dag.height = height;

            // XXX maybe a little more elegant than this?
            const rho = d3p.hyperbolic ?
                  r => r == 0 ? 0 : Math.tanh(Math.log(1 / (1 - r))) : r => r;

            // OKAY HERE WE GET THE MINIMUM Y-OFFSET
            const firsts = new Map();
            dag.roots().forEach(root => {
                const x = firsts.get(root.y) || [];
                x.push(root);
                firsts.set(root.y, x);
            });
            const ymin   = Array.from(firsts.keys()).sort(
                (a, b) => a - b)[0] || 0;
            const nroots = firsts.has(ymin) ? firsts.get(ymin).length : 0;

            // we want a radius that is big enough to fit the entire first
            // row with enough room that it isn't too crowded
            const yoff = nroots > 1 ?
                  (2 * d3p.radius) * (2 * nroots - 1) / Math.PI / 2
                  : nroots == 1 ? -ymin : 0;

            const descs = dag.descendants();

            let offsets =
                descs.find(n => n.data.id == me.href) || { x: 0, y: 0 };
            if (offsets.x !== 0 && offsets.y !== 0) {
                offsets = {
                    x: offsets.x / width,
                    y: (yoff + offsets.y) / (yoff + height)
                };
            }
            let coff = new Complex(
                { phi: offsets.x * 2 * Math.PI, r: rho(offsets.y) }).neg();

            // console.log(offsets);

            const atdeg = (z, half) => {
                let t = Math.atan2(z.im, z.re) * 180 / Math.PI;
                return t < 0 && !half ? t + 360 : t;
            };

            descs.forEach(node => {
                // XXX find a way to put this data in the dag structure
                let rnode = nmap[node.data.id];

                // draw the point

                const r1 = (yoff + node.y) / (yoff + height);
                const t1 = node.x / width * Math.PI * 2;
                const z1 = new Complex({ phi: t1, r: rho(r1) });
                const p1 = (coff.abs() > 0 ? Zt(Complex.ONE, coff)(z1) : z1)
                      .mul(d3p.width / 2);

                const a = nodeg.append('a').attr('xlink:href', node.data.id)
                      .attr('typeof', this.abbreviate(nmap[node.data.id].type))
                      .attr('xlink:title', rnode.title);

                // console.log(node.data.id, me);

                if (node.data.id == me.href) a.attr('class', 'subject');

                a.append('circle').attr('class', 'target').attr('cx', p1.re)
                    .attr('cy', p1.im).attr('r', d3p.radius * 2);
                a.append('circle').attr('cx', p1.re)
                    .attr('cy', p1.im).attr('r', d3p.radius);

                // draw any lines

                node.dataChildren.forEach(c => {
                    const r2 = (yoff + c.child.y) / (yoff + height);
                    const t2 = c.child.x / width * Math.PI * 2;
                    const z2 = new Complex({ phi: t2, r: rho(r2) });
                    const p2 = Zt(Complex.ONE, coff)(z2).mul(d3p.width / 2);

                    // swappable points
                    let l1 = p1, l2 = p2;

                    // subject and object identities
                    let s = node.data.id;
                    let o = c.child.data.id;
                    if (c.reversed) {
                        let tmp = s; // yo can't we do multiple assign?
                        s = o;
                        o = tmp;

                        tmp = l1;
                        l1 = l2;
                        l2 = tmp;
                    }

                    /*
                    let line = edgeg.append('line')
                        .attr('about', s).attr('resource', o)
                        .attr('x1', p1.re).attr('y1', p1.im)
                        .attr('x2', p2.re).attr('y2', p2.im);

                    if (s == me.href || o == me.href)
                        line.attr('class', 'subject');
                    */

                    let m = l1.add(l2).div(2);

                    // r^2 / |m|
                    let r3 = Math.pow(d3p.width / 2, 2) / m.abs();
                    // let t3 = Math.atan2(m.im, m.re);

                    // let n = new Complex({ phi: t3, r: r3 });

                    // edgeg.append('circle').attr('cx', m.re).attr('cy', m.im).attr('r', 2.5);
                    // nodeg.append('circle').attr('cx', n.re).attr('cy', n.im).attr('r', 2.5);

                    let t3d = atdeg(m.conjugate());
                    /*
                    const sb = Math.atan2(l2.im, l2.re) -
                          Math.atan2(l1.im, l1.re) < 0 ? 1 : 0;
                    */

                    const l1d = atdeg(l1.conjugate());
                    const l2d = atdeg(l2.conjugate());
                    let dd = l2d - l1d;
                    if (dd < -180) dd += 360; // fix wrap around

                    const sb = dd >= 0 && dd <= 180 ? 1 : 0;

                    // sb can be if you get from l1 to l2 if you add the angle vs if you subtract it

                    // const sb = dd < 180 ? 1 : dd < 0 || dd > 180 ? 0 : 1;
                    // const sb = dd < 0 ? 0 : 1;

                    // if one of these is the origin draw a line
                    const d = `M${l1.re},${l1.im} ` +
                          ([l1, l2, m].some(p => p.abs() == 0) || dd == 0 ?
                          `L${l2.re},${l2.im}` :
                          `A${r3},${r3} ${t3d} 0,${sb} ${l2.re},${l2.im}`);

                    const path = edgeg.append('path').attr('d', d)
                          .attr('about', s).attr('resource', o);

                    if (s == me.href || o == me.href)
                        path.attr('class', 'subject');

                    // path.attr('data-dd', `${Math.round(l1d, 3)} ${Math.round(l2d, 3)}; ${Math.round(dd, 3)}`);

                    // handle forward and reverse predicates

                    const rel = (lmap[s] || {})[o];
                    const rev = (lmap[o] || {})[s];

                    if (rel) path.attr('rel', this.abbreviate(rel.predicate));
                    if (rev) path.attr('rev', this.abbreviate(rev.predicate));
                });
            });
        }
        else if (nodes.length == 1) {
            // note this is an rdf node, not a dag node
            const node = nodes[0];

            const a = nodeg.append('a').attr('xlink:href', node.id)
                  .attr('typeof', this.abbreviate(node.type))
                  .attr('xlink:title', node.title);

            if (node.id == me.href) a.attr('class', 'subject');

            a.append('circle').attr('class', 'target')
                .attr('cx', 0).attr('cy', 0).attr('r', d3p.radius * 2);
            a.append('circle')
                .attr('cx', 0).attr('cy', 0).attr('r', d3p.radius);
        }
        // otherwise do nothing
    }
}
