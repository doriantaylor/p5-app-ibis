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

    }

    init () {
        // XXX PROBABLY ALL OF THIS CAN BE SUPERCLASSED

        const svg = d3.select(this.svg);

        // make these shorter to type lol
        const graph      = this.graph,
              a          = this.a,
              ns         = this.ns,
              validTypes = this.validTypes,
              labels     = this.labels,
              inverses   = this.inverses,
              symmetric  = this.symmetric;

        // first we collect the valid nodes
        const nmap  = {};
        const nodes = this.nodes = [];
        graph.match(null, a).forEach(stmt => {
            if (validTypes.some(t => t.equals(stmt.object))) {
                let label = stmt.subject.value;
                // label predicates
                const lp = [ns['dct']('title'), ns['rdfs']('label')];
                if (labels[stmt.object.value])
                    lp.unshift(labels[stmt.object.value]);
                for (let i = 0; i < lp.length; i++) {
                    let x = graph.match(stmt.subject, lp[i]).filter(
                        s => s.object.termType == 'Literal');
                    if (x.length > 0) {
                        label = x[0].object.value;
                        break;
                    }
                }

                // establish the subject URI
                const s = this.rewriteUUID(stmt.subject);

                // get the in+outdegree
                const degree = graph.match(stmt.subject).filter(
                    s => s.object.termType == 'NamedNode').length +
                      graph.match(null, null, stmt.subject).filter(
                          s => s.subject.termType == 'NamedNode').length - 1;

                // add this mess to the list
                if (!nmap[stmt.subject.value])
                    // XXX DECIDE WHAT TO DO ABOUT URLS
                    nodes.push(nmap[stmt.subject.value] = nmap[s.value] = {
                        id:      s.value, // for d3
                        title:   label, // for d3
                        subject: stmt.subject,
                        type:    stmt.object,
                        degree:  degree,
                    });
            }
        });

        const lmap  = {};
        const lmap2 = new Map();
        const links = this.links = [];
        nodes.forEach(rec => {
            graph.match(rec.subject).forEach(stmt => {
                // only look at edges containing nodes we already have
                if (!nmap[stmt.object.value]) return;

                let s = stmt.subject, p = stmt.predicate, o = stmt.object;
                if (inverses[p.value]) {
                    s = stmt.object;
                    p = inverses[p.value];
                    o = stmt.subject;
                }

                let src = this.rewriteUUID(s);
                let tgt = this.rewriteUUID(o);

                let k = `${src} ${tgt}`;
                // lol get all that??
                (lmap2.has(k) ? lmap2 : lmap2.set(k, [])).get(k).push(p);

                // this ensures we have no duplicate edges
                if (!lmap[p.value]) lmap[p.value] = {};
                if (!lmap[p.value][s.value]) lmap[p.value][s.value] = {};
                if (lmap[p.value][s.value][o.value]) return;

                links.push(lmap[p.value][s.value][o.value] = {
                    source: src.value, // for d3
                    target: tgt.value, // for d3
                    subject: s,
                    predicate: p,
                    object: o
                });
            });
        });

        const defs = svg.append('defs');

        Object.keys(lmap).forEach(predicate => {
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
            const ymin   = Array.from(firsts.keys()).sort()[0] || 0;
            const nroots = firsts.has(ymin) ? firsts.get(ymin).length : 0;

            // we want a radius that is big enough to fit the entire first
            // row with enough room that it isn't too crowded
            const yoff = nroots > 1 ?
                  (2 * d3p.radius) * (2 * nroots - 1) / Math.PI
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

            const atdeg = z => {
                let t = Math.atan2(z.im, z.re) * 180 / Math.PI;
                return t < 0 ? t + 360 : t;
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

                    // subject and object identities
                    let s = node.data.id;
                    let o = c.child.data.id;
                    if (c.reversed) {
                        let tmp = s; // yo can't we do multiple assign?
                        s = o;
                        o = tmp;
                    }

                    /*
                    let line = edgeg.append('line')
                        .attr('about', s).attr('resource', o)
                        .attr('x1', p1.re).attr('y1', p1.im)
                        .attr('x2', p2.re).attr('y2', p2.im);

                    if (s == me.href || o == me.href)
                        line.attr('class', 'subject');
                    */

                    let m = p1.add(p2).div(2);

                    // r^2 / |m|
                    let r3 = Math.pow(d3p.width / 2, 2) / m.abs();
                    let t3 = Math.atan2(m.im, m.re);

                    let n = new Complex({ phi: t3, r: r3 });

                    // nodeg.append('circle').attr('cx', m.re).attr('cy', m.im).attr('r', 2.5);
                    // nodeg.append('circle').attr('cx', n.re).attr('cy', n.im).attr('r', 2.5);

                    let t3d = atdeg(m);

                    // if one of these is the origin draw a line
                    const d = p1.abs() == 0 || p2.abs() == 0 ?
                          `M${p1.re},${p1.im} L${p2.re},${p2.im}` :
                          `M${p1.re},${p1.im} A${r3},${r3} ${t3d} 0,${atdeg(p1) > t3d ? 1 : 0 } ${p2.re},${p2.im}`;

                    const path = edgeg.append('path').attr('d', d)
                          .attr('about', s).attr('resource', o);

                    if (s == me.href || o == me.href)
                        path.attr('class', 'subject');

                    // handle forward and reverse predicates

                    const fk = `${RDF.sym(s)} ${RDF.sym(o)}`;
                    const rk = `${RDF.sym(o)} ${RDF.sym(s)}`;

                    if (lmap2.has(fk))
                        path.attr('rel', this.abbreviate(lmap2.get(fk)));
                    if (lmap2.has(rk))
                        path.attr('rev', this.abbreviate(lmap2.get(rk)));
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
